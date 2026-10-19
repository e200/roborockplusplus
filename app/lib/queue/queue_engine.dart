import 'dart:async';

import '../history/clean_record.dart';
import '../robot/robot_status.dart';
import 'clean_job.dart';

/// What the engine needs from the robot. Kept separate so it can be tested against recorded real states.
abstract interface class QueueActions {
  Future<void> run(CleanJob job);

  /// Latest record stored by the robot (to tell a normal finish from a cancellation).
  Future<CleanRecord?> lastRecord();
}

enum QueueState { idle, running, paused }

enum PauseKind { notStarted, robotError, startFailed, interrupted }

/// Why the queue paused. Structured (not text) so it can be shown in the user's language and persisted.
class PauseReason {
  final PauseKind kind;

  /// Robot error code for [PauseKind.robotError].
  final int code;

  const PauseReason(this.kind, [this.code = 0]);

  Map<String, dynamic> toJson() => {'kind': kind.name, 'code': code};

  /// Null for anything unreadable, including the free-text reasons older versions stored.
  static PauseReason? fromJson(Object? j) {
    if (j is! Map) return null;
    final kind = PauseKind.values.asNameMap()[j['kind']];
    return kind == null ? null : PauseReason(kind, j['code'] as int? ?? 0);
  }

  @override
  bool operator ==(Object other) => other is PauseReason && other.kind == kind && other.code == code;

  @override
  int get hashCode => Object.hash(kind, code);
}

/// Cleaning queue. The robot runs one task at a time and has no queue of its own, so the queue lives here:
/// adding or reordering jobs never touches the robot; the next job only starts once the current task has really
/// finished (`in_cleaning` back to 0 with the robot stopped), even if it was started from another app.
class QueueEngine {
  /// If the robot has not taken the task by then, the queue pauses instead of insisting.
  static const startTimeout = Duration(seconds: 90);
  static const _stoppedStates = {3, 8, 100};

  final QueueActions actions;
  final void Function() onChanged;
  final void Function(CleanRecord record, CleanJob? job) onFinished;

  final List<CleanJob> pending = [];
  CleanJob? current;
  QueueState state = QueueState.idle;
  PauseReason? pauseReason;

  DateTime? _startedAt;
  bool _sawBusy = false;
  int? _lastRoom;
  DateTime? _lastTick;
  final Map<int, int> _roomSeconds = {};
  bool _robotBusy = false;
  bool _working = false;

  /// The user skipped the current task: the stop that follows is intentional and the queue carries on.
  bool _skipping = false;

  /// Marks the current task as skipped (the caller stops the robot). Returns false when there is no task.
  bool skipCurrent() {
    if (current == null) return false;
    _skipping = true;
    if (state == QueueState.paused) {
      state = QueueState.running;
      pauseReason = null;
    }
    onChanged();
    return true;
  }

  QueueEngine({required this.actions, required this.onChanged, required this.onFinished});

  void add(List<CleanJob> jobs) {
    pending.addAll(jobs);
    if (state == QueueState.idle) state = QueueState.running;
    onChanged();
  }

  void remove(String id) {
    pending.removeWhere((j) => j.id == id);
    onChanged();
  }

  /// [to] is the final position, already accounting for the removed item (like Flutter's `onReorderItem`).
  void reorder(int from, int to) {
    pending.insert(to, pending.removeAt(from));
    onChanged();
  }

  /// A pause with an empty queue is pointless (e.g. persisted by an older version).
  void _dropEmptyPause() {
    if (state == QueueState.paused && pending.isEmpty && current == null) {
      state = QueueState.idle;
      pauseReason = null;
    }
  }

  void resume() {
    pauseReason = null;
    state = pending.isEmpty && current == null ? QueueState.idle : QueueState.running;
    onChanged();
  }

  void pause(PauseReason reason) {
    state = QueueState.paused;
    pauseReason = reason;
    onChanged();
  }

  /// Called on every robot status reading.
  Future<void> onStatus(RobotStatus s, DateTime now) async {
    if (_working) return;
    _working = true;
    try {
      await _step(s, now);
    } finally {
      _working = false;
    }
  }

  Future<void> _step(RobotStatus s, DateTime now) async {
    final wasBusy = _robotBusy;
    _robotBusy = s.busy;

    final job = current;
    if (job != null) {
      if (!_sawBusy) {
        if (s.busy) {
          _sawBusy = true;
        } else if (now.difference(_startedAt!) > startTimeout) {
          current = null;
          pending.insert(0, job);
          pause(const PauseReason(PauseKind.notStarted));
          return;
        } else {
          return;
        }
      }
      _trackRoom(s, now);
      if (!_skipping && (s.errorCode != 0 || s.state == 12)) {
        if (state != QueueState.paused) pause(PauseReason(PauseKind.robotError, s.errorCode));
        return;
      }
      if (s.busy || !_stoppedStates.contains(s.state)) return;
      await _finish(job);
      return;
    }

    // A task started outside the queue (button, schedule, official app): record it when it ends.
    if (wasBusy && !s.busy && _stoppedStates.contains(s.state)) {
      final rec = await actions.lastRecord();
      if (rec != null) onFinished(rec, null);
    }

    if (state != QueueState.running || s.busy || s.errorCode != 0 || pending.isEmpty) {
      if (state == QueueState.running && pending.isEmpty) {
        state = QueueState.idle;
        onChanged();
      }
      return;
    }
    await _startNext(now);
  }

  Future<void> _startNext(DateTime now) async {
    final job = pending.removeAt(0);
    current = job;
    _startedAt = now;
    _sawBusy = false;
    _lastRoom = null;
    _lastTick = null;
    _roomSeconds.clear();
    onChanged();
    try {
      await actions.run(job);
    } on Exception {
      current = null;
      pending.insert(0, job);
      pause(const PauseReason(PauseKind.startFailed));
    }
  }

  void _trackRoom(RobotStatus s, DateTime now) {
    final last = _lastRoom, lastTick = _lastTick;
    if (last != null && lastTick != null) {
      _roomSeconds[last] = (_roomSeconds[last] ?? 0) + now.difference(lastTick).inSeconds;
    }
    // Only count time actually cleaning (state 18), not mop washes or trips.
    _lastRoom = s.state == 18 ? s.currentRoom : null;
    _lastTick = now;
  }

  Future<void> _finish(CleanJob job) async {
    current = null;
    final skipped = _skipping;
    _skipping = false;
    final rec = await actions.lastRecord();
    if (rec != null) {
      onFinished(rec.withAppData(roomSeconds: Map.of(_roomSeconds), rooms: job.rooms), job);
    }
    // With nothing else queued there is nothing to decide: the interruption only goes to history.
    if (rec != null && !rec.complete && pending.isNotEmpty && !skipped) {
      pause(const PauseReason(PauseKind.interrupted));
      return;
    }
    if (pending.isEmpty) state = QueueState.idle;
    onChanged();
  }

  Map<String, dynamic> toJson() => {
    'pending': [for (final j in pending) j.toJson()],
    'current': current?.toJson(),
    'state': state.name,
    'pauseReason': pauseReason?.toJson(),
  };

  /// When the app reopens, a job that was running keeps being tracked: if the robot is still cleaning we wait
  /// for it to end; if it already ended, it is recorded and the queue moves on.
  void restore(Map<String, dynamic> j, {DateTime? now}) {
    pending
      ..clear()
      ..addAll([for (final p in j['pending'] as List) CleanJob.fromJson(Map<String, dynamic>.from(p))]);
    final cur = j['current'];
    if (cur != null) {
      current = CleanJob.fromJson(Map<String, dynamic>.from(cur));
      _startedAt = now ?? DateTime.now();
      _sawBusy = true; // it had already started before the app closed
      state = j['state'] == QueueState.paused.name ? QueueState.paused : QueueState.running;
      pauseReason = PauseReason.fromJson(j['pauseReason']);
    } else {
      state = QueueState.values.byName(j['state'] as String);
      pauseReason = PauseReason.fromJson(j['pauseReason']);
      if (state == QueueState.running && pending.isEmpty) state = QueueState.idle;
    }
    _dropEmptyPause();
  }
}
