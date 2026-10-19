import 'dart:async';

import 'dart:io';

import 'package:archive/archive.dart' show GZipDecoder, GZipEncoder;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../cloud/roborock_cloud.dart';
import '../history/clean_record.dart';
import '../l10n/describe.dart';
import '../l10n/strings.dart';
import '../map/map_geometry.dart';
import '../map/map_parser.dart';
import '../map/robot_map.dart';
import '../platform/notifier.dart';
import '../queue/clean_job.dart';
import '../queue/queue_engine.dart';
import '../routines/routine.dart';
import '../session_store.dart';
import 'action_gate.dart';
import 'alerts.dart';
import 'robot_client.dart';
import 'robot_commands.dart';
import 'robot_status.dart';

/// Live state for the UI, and owner of the queue and the history.
/// Robot status every 3 s (every second right after a command); map every second while cleaning, every 60 s
/// at rest.
class RobotController extends ChangeNotifier implements QueueActions {
  /// The robot's position only comes with the map (≈300 ms per fetch over the cloud), so while cleaning it is
  /// fetched every second, like the official app. In the background service nobody is looking at it.
  Duration get _mapBusyEvery => background ? const Duration(seconds: 30) : const Duration(seconds: 1);
  static const _mapIdleEvery = Duration(seconds: 60);

  final RobotClient client;
  final CloudSession session;
  final SessionStore store;
  final Notifier notifier;
  late final AlertDetector _alerts = AlertDetector.restore(store.readJson('alert_state'));

  /// Running in the Android service (app closed): nobody is watching, so the robot is polled less often.
  final bool background;
  late final QueueEngine queue = QueueEngine(actions: this, onChanged: _queueChanged, onFinished: _recordFinished);

  RobotStatus? status;
  RobotMap? map;
  MapGeometry? geometry;
  Map<int, String> roomNames = const {};

  /// Room type per segment (`tag` in `get_multi_maps_list`), for the icon next to each name.
  Map<int, int> roomTags = const {};
  ({int remainingSeconds, int percent})? estimate;
  Map<String, int>? consumables;
  ({int seconds, int areaMm2, int count})? totals;

  /// History, newest first. Merges the robot's records (it only keeps ~21) with those the app already saved.
  List<CleanRecord> history = [];

  List<Routine> routines = [];
  Map<String, DateTime> _routineRuns = {};
  DateTime _lastRoutineCheck = DateTime.fromMillisecondsSinceEpoch(0);

  /// Alerts received (newest first), stored on the phone.
  List<({DateTime at, String title, String body})> alertLog = [];

  List<RobotAlert> get problems => status == null ? const [] : activeProblems(status!, l);

  /// Summary of the last clean that finished while the app was open; the UI shows it and then clears it.
  CleanRecord? justFinished;

  /// Last error, shown with [errorText] in the user's language.
  Object? error;

  /// Texts for notifications and the alert log (the phone's language; the UI follows the same one).
  final L10n l = deviceStrings();
  LinkState link = LinkState.offline;

  Timer? _statusTimer;
  final _gate = ActionGate();
  late final _poll = PollSchedule(normal: background ? const Duration(seconds: 10) : const Duration(seconds: 3));

  /// A command with this key is on its way to the robot (the UI shows "sending" and ignores repeated taps).
  bool isPending(String key) => _gate.isPending(key);
  DateTime _lastMap = DateTime.fromMillisecondsSinceEpoch(0);
  bool _mapLoading = false;
  bool _ticking = false;
  DateTime _lastNamesTry = DateTime.now().subtract(const Duration(seconds: 25));
  bool _namesLoaded = false;
  StreamSubscription<LinkState>? _linkSub;

  RobotController(this.session, CloudDevice device, this.store, this.notifier, {this.background = false})
    : client = RobotClient(session, device) {
    final q = store.readJson('queue');
    if (q is Map) queue.restore(Map<String, dynamic>.from(q));
    final log = store.readJson('alerts');
    if (log is List) {
      alertLog = [
        for (final e in log)
          (at: DateTime.fromMillisecondsSinceEpoch(e['at'] as int), title: '${e['title']}', body: '${e['body']}'),
      ];
    }
    final rs = store.readJson('routines');
    if (rs is List) routines = [for (final r in rs) Routine.fromJson(Map<String, dynamic>.from(r))];
    final runs = store.readJson('routine_runs');
    if (runs is Map) {
      _routineRuns = {for (final e in runs.entries) '${e.key}': DateTime.fromMillisecondsSinceEpoch(e.value as int)};
    }
    final names = store.readJson('room_names');
    if (names is Map) roomNames = {for (final e in names.entries) int.parse('${e.key}'): '${e.value}'};
    final tags = store.readJson('room_tags');
    if (tags is Map) roomTags = {for (final e in tags.entries) int.parse('${e.key}'): e.value as int};
    final h = store.readJson('history');
    if (h is List) history = [for (final r in h) CleanRecord.fromJson(Map<String, dynamic>.from(r))];
  }

  Future<void> start() async {
    _linkSub = client.linkChanges.listen((l) {
      final wasOffline = link == LinkState.offline;
      link = l;
      if (wasOffline && l != LinkState.offline) unawaited(syncHistory());
      notifyListeners();
    });
    try {
      await client.connect();
      link = client.link;
      await Future.wait([_loadRoomNames(), _tick()]);
      unawaited(syncHistory());
      unawaited(refreshConsumables());
    } on Exception catch (e) {
      error = e;
      notifyListeners();
    }
    // 1 s clock; the real pace (1 s right after a command, 3 s otherwise) comes from PollSchedule.
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_poll.due(DateTime.now())) _tick();
      _maybeRefreshMap();
    });
  }

  Future<void> _loadRoomNames() async {
    try {
      final home = await RoborockCloud.home(session);
      final mapping = await client.roomMapping();
      roomNames = {for (final e in mapping.entries) e.key: home.rooms[e.value] ?? l.roomN(e.key)};
      _namesLoaded = true;
      unawaited(store.writeJson('room_names', {for (final e in roomNames.entries) '${e.key}': e.value}));
      roomTags = roomTagsFrom(await client.call('get_multi_maps_list'));
      unawaited(store.writeJson('room_tags', {for (final e in roomTags.entries) '${e.key}': e.value}));
    } on Exception {
      // without names the map shows "Room N"
    }
  }

  String roomName(int id) => roomNames[id] ?? l.roomN(id);

  Future<void> _tick() async {
    if (_ticking) return;
    _ticking = true;
    try {
      final s = status = await client.status();
      if (s.busy) {
        final res = await client.call('app_get_clean_estimate_info').catchError((_) => null);
        final e = res is Map ? res['clean_estimate'] : null;
        estimate = e is Map ? (remainingSeconds: e['remaining_time'] as int, percent: e['percent'] as int) : null;
      } else {
        estimate = null;
      }
      error = null;
      final alerts = _alerts.update(s, l);
      for (final a in alerts) {
        _logAlert(a.title, a.body);
        unawaited(notifier.alert(a));
      }
      final alertState = _alerts.toJson()!;
      if ('$alertState' != '${store.readJson('alert_state')}') unawaited(store.writeJson('alert_state', alertState));
      await queue.onStatus(s, DateTime.now());
      _checkRoutines(DateTime.now());
      // Names sometimes fail at startup (link still settling): retry every 30 s.
      // The cached ones show up immediately; this only refreshes them.
      if (!_namesLoaded && DateTime.now().difference(_lastNamesTry) > const Duration(seconds: 30)) {
        _lastNamesTry = DateTime.now();
        unawaited(_loadRoomNames().then((_) => notifyListeners()));
      }
      unawaited(_updateOngoing(s));
    } on Exception catch (e) {
      error = e;
    } finally {
      _ticking = false;
    }
    notifyListeners();
    _maybeRefreshMap();
  }

  /// Checked on every clock tick, independently of the status pace (refreshMap skips while one is in flight).
  void _maybeRefreshMap() {
    final every = status?.busy == true ? _mapBusyEvery : _mapIdleEvery;
    if (DateTime.now().difference(_lastMap) >= every) unawaited(refreshMap());
  }

  Future<void> refreshMap() async {
    if (_mapLoading) return;
    _mapLoading = true;
    // Paced from the start of the request, so a 300 ms fetch still gives one map per second.
    _lastMap = DateTime.now();
    try {
      final next = MapParser.parse(await client.map());
      final grid = next.grid;
      // Recomputing outlines is expensive; only when the grid changes (the robot discovers or erases areas).
      if (grid != null && (geometry == null || !_sameGrid(map?.grid, grid))) geometry = MapGeometry.from(grid);
      map = next;
      notifyListeners();
    } on Exception catch (e) {
      error ??= e;
    } finally {
      _mapLoading = false;
    }
  }

  static bool _sameGrid(MapGrid? a, MapGrid b) =>
      a != null &&
      a.left == b.left &&
      a.top == b.top &&
      a.width == b.width &&
      a.height == b.height &&
      listEquals(a.cells, b.cells);

  /// Runs an action on the robot and shows the error instead of crashing the UI.
  /// With [key], repeated taps while the first one is in flight are ignored.
  /// After each command the status is read every second for a few seconds, so the screen keeps up.
  Future<bool> act(Future<void> Function(RobotClient c) action, {String? key}) async {
    var ok = false;
    Future<void> run() async {
      try {
        await action(client);
        ok = true;
      } on Exception catch (e) {
        error = e;
      }
      _poll.commandSent(DateTime.now());
    }

    if (key == null) {
      await run();
    } else if (!await _gate.run(key, run, onChange: notifyListeners)) {
      return false; // already in flight
    }
    notifyListeners();
    return ok;
  }

  void dismissFinished() {
    justFinished = null;
    notifyListeners();
  }

  // --- Fila ---------------------------------------------------------------------------------------------------

  int _jobSeq = 0;

  String newJobId() => '${DateTime.now().microsecondsSinceEpoch}-${_jobSeq++}';

  void enqueue(List<(int, CleanSettings)> plan) {
    queue.add(CleanJob.fromPlan(plan, newJobId));
    _kickQueue();
  }

  /// With the robot idle, the job starts right away instead of waiting for the next reading.
  void _kickQueue() {
    final s = status;
    _poll.commandSent(DateTime.now());
    if (s != null) unawaited(queue.onStatus(s, DateTime.now()).then((_) => notifyListeners()));
  }

  /// Each zone is its own job: they queue one after another, without touching the running clean.
  void enqueueZones(List<CleanZone> zones, CleanSettings s) {
    queue.add([
      for (final z in zones)
        ...CleanJob(id: newJobId(), rooms: const [], zones: [z], settings: s).expandPasses(newJobId),
    ]);
    _kickQueue();
  }

  void enqueueWholeHome(CleanSettings s) {
    queue.add(CleanJob(id: newJobId(), rooms: const [], settings: s).expandPasses(newJobId));
    _kickQueue();
  }

  // --- Rotinas -----------------------------------------------------------------------------------------------

  void saveRoutine(Routine r) {
    final i = routines.indexWhere((x) => x.id == r.id);
    if (i >= 0) {
      routines[i] = r;
    } else {
      routines.add(r);
    }
    _saveRoutines();
  }

  void deleteRoutine(String id) {
    routines.removeWhere((r) => r.id == id);
    _saveRoutines();
  }

  /// Queues the routine (with fresh ids: it can run several times).
  void runRoutine(Routine r) {
    queue.add([for (final j in r.jobs) CleanJob(id: newJobId(), rooms: j.rooms, zones: j.zones, settings: j.settings)]);
    _routineRuns[r.id] = DateTime.now();
    _saveRoutines();
    _kickQueue();
  }

  void _checkRoutines(DateTime now) {
    if (now.difference(_lastRoutineCheck) < const Duration(seconds: 30)) return;
    _lastRoutineCheck = now;
    for (final r in dueRoutines(routines, _routineRuns, now)) {
      _logAlert(l.routineQueuedTitle(r.name), l.routineQueuedBody);
      runRoutine(r);
    }
  }

  void _saveRoutines() {
    unawaited(store.writeJson('routines', [for (final r in routines) r.toJson()]));
    unawaited(
      store.writeJson('routine_runs', {for (final e in _routineRuns.entries) e.key: e.value.millisecondsSinceEpoch}),
    );
    notifyListeners();
  }

  /// Cancels the current task and moves on to the next queued one (the stop does not pause the queue).
  Future<bool> skipCurrent() async {
    if (!queue.skipCurrent()) return false;
    final last = queue.pending.isEmpty;
    return act((r) async {
      await r.stop();
      // With nothing left in the queue, the robot returns to the dock instead of stopping mid-home.
      if (last) await r.dock();
    }, key: 'skip');
  }

  @override
  Future<void> run(CleanJob job) async {
    final s = job.settings;
    // The three settings are independent: send them together, and only then start.
    await Future.wait([client.setFan(s.fan), client.setWater(s.water), client.setMopRoute(s.mopRoute)]);
    if (job.zones.isNotEmpty) {
      await client.cleanZones([for (final z in job.zones) z.toJson()], repeat: s.repeat);
    } else if (job.rooms.isEmpty) {
      await client.startWholeHome();
    } else {
      await client.cleanRooms(job.rooms, repeat: s.repeat);
    }
  }

  @override
  Future<CleanRecord?> lastRecord() async {
    final sum = await client.cleanSummary();
    return sum.recordIds.isEmpty ? null : client.cleanRecord(sum.recordIds.first);
  }

  PauseReason? _lastPause;

  void _logAlert(String title, String body) {
    alertLog.insert(0, (at: DateTime.now(), title: title, body: body));
    if (alertLog.length > 100) alertLog.removeLast();
    unawaited(
      store.writeJson('alerts', [
        for (final a in alertLog) {'at': a.at.millisecondsSinceEpoch, 'title': a.title, 'body': a.body},
      ]),
    );
  }

  void _queueChanged() {
    unawaited(store.writeJson('queue', queue.toJson()));
    final reason = queue.pauseReason;
    if (queue.state == QueueState.paused && reason != null && reason != _lastPause) {
      _logAlert(l.queuePaused, pauseText(l, reason));
      unawaited(notifier.alert(RobotAlert(AlertKind.robotError, 0, l.queuePaused, pauseText(l, reason))));
    }
    _lastPause = reason;
    if (status != null) unawaited(_updateOngoing(status!));
    notifyListeners();
  }

  String jobTitle(CleanJob j) => j.zones.isNotEmpty
      ? l.jobZones(j.zones.length, j.zones.fold(0.0, (a, z) => a + z.areaM2).toStringAsFixed(1))
      : (j.rooms.isEmpty ? l.wholeHome : j.rooms.map(roomName).join(' + '));

  /// Ongoing notification: what it is doing now and what comes next.
  Future<void> _updateOngoing(RobotStatus s) {
    final room = s.currentRoom == null ? null : roomName(s.currentRoom!);
    final title = s.state == 18 && room != null ? l.cleaningRoom(room) : s.stateLabel(l);
    final next = queue.pending.isEmpty ? null : jobTitle(queue.pending.first);
    final est = estimate;
    final text = [
      if (est != null) l.minutesLeft((est.remainingSeconds / 60).ceil()) else l.batteryPercent(s.battery),
      if (next != null) l.upNext(next),
      if (queue.state == QueueState.paused) l.queuePausedLower,
    ].join(' · ');
    return notifier.status(title, text, progress: s.busy ? est?.percent : null);
  }

  /// Map of a clean (rooms, path and objects at that moment).
  /// The robot only keeps the most recent ones, so the app stores each one on the phone (compressed).
  Future<Uint8List> recordMap(int begin) async {
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/record_maps');
    final file = File('${dir.path}/$begin.bin.gz');
    if (await file.exists()) return Uint8List.fromList(GZipDecoder().decodeBytes(await file.readAsBytes()));
    final raw = await client.recordMap(begin);
    await dir.create(recursive: true);
    await file.writeAsBytes(GZipEncoder().encodeBytes(raw));
    return raw;
  }

  void _recordFinished(CleanRecord rec, CleanJob? job) {
    _upsert(rec);
    // Save this clean's map now, while the robot still has it.
    unawaited(recordMap(rec.begin).then<void>((_) {}, onError: (_) {}));
    justFinished = rec;
    final what = job == null ? l.cleanGeneric : jobTitle(job);
    final summary = l.minutesArea((rec.durationSeconds / 60).round(), rec.areaM2.toStringAsFixed(1));
    _logAlert(rec.complete ? l.jobFinished(what) : l.cleanInterrupted, summary);
    unawaited(
      notifier.finished(
        rec.complete ? l.jobFinished(what) : l.jobOutcome(what, outcomeText(l, rec.outcome).toLowerCase()),
        [
          summary,
          if (rec.washCount > 0) l.mopWashes(rec.washCount),
          if (queue.pending.isNotEmpty) l.upNext(jobTitle(queue.pending.first)),
        ].join(' · '),
      ),
    );
    unawaited(refreshConsumables());
    notifyListeners();
  }

  // --- History and consumables ----------------------------------------------------------------------------------

  Future<void> syncHistory() async {
    try {
      final sum = await client.cleanSummary();
      totals = (seconds: sum.seconds, areaMm2: sum.areaMm2, count: sum.count);
      final known = {for (final r in history) r.begin};
      // One failing record does not block the others; it is retried on the next sync.
      for (final id in sum.recordIds.where((id) => !known.contains(id))) {
        try {
          final rec = await client.cleanRecord(id);
          if (rec != null) _upsert(rec, save: false);
        } on Exception {
          continue;
        }
      }
      await _saveHistory();
      notifyListeners();
      unawaited(_cacheRecordMaps(sum.recordIds));
    } on Exception catch (e) {
      error ??= e;
    }
  }

  /// Saves the maps the robot still has (it only keeps the newest), one at a time, in the background.
  Future<void> _cacheRecordMaps(List<int> ids) async {
    for (final id in ids) {
      try {
        await recordMap(id);
      } on Exception {
        continue; // the robot no longer has this one; move on
      }
    }
  }

  /// Data measured by the app (time per room) is kept when the robot's record is read again.
  void _upsert(CleanRecord rec, {bool save = true}) {
    final i = history.indexWhere((r) => r.begin == rec.begin);
    if (i >= 0) {
      final old = history[i];
      history[i] = rec.roomSeconds.isEmpty && old.roomSeconds.isNotEmpty
          ? rec.withAppData(roomSeconds: old.roomSeconds, rooms: old.rooms)
          : rec;
    } else {
      history.add(rec);
    }
    history.sort((a, b) => b.begin.compareTo(a.begin));
    if (save) unawaited(_saveHistory());
  }

  Future<void> _saveHistory() => store.writeJson('history', [for (final r in history) r.toJson()]);

  Future<void> refreshConsumables() async {
    try {
      consumables = await client.consumables();
      notifyListeners();
    } on Exception {
      // shown as unavailable
    }
  }

  @override
  /// The notification stays: whoever takes over next (app or service) updates it; only logging out removes it.
  void dispose() {
    _statusTimer?.cancel();
    _linkSub?.cancel();
    client.close();
    super.dispose();
  }
}

/// Room types from a `get_multi_maps_list` reply (the current map's `rooms[].tag`).
Map<int, int> roomTagsFrom(Object? reply) {
  final first = reply is List && reply.isNotEmpty ? reply.first : reply;
  final maps = first is Map ? first['map_info'] : null;
  final rooms = maps is List && maps.isNotEmpty && maps.first is Map ? (maps.first as Map)['rooms'] : null;
  return {
    if (rooms is List)
      for (final r in rooms)
        if (r is Map && r['id'] is int && r['tag'] is int) r['id'] as int: r['tag'] as int,
  };
}
