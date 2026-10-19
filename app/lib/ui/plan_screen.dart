import 'package:flutter/material.dart';

import '../l10n/strings.dart';

import '../map/map_view.dart';
import '../map/robot_map.dart';
import '../queue/clean_job.dart';
import '../robot/robot_commands.dart';
import '../robot/robot_controller.dart';
import '../routines/routine.dart';
import 'design/components.dart';
import 'design/kit.dart';
import 'settings_picker.dart';

enum PlanMode { rooms, zones, point, home }

String _modeLabel(L10n l, PlanMode m) => switch (m) {
  PlanMode.rooms => l.modeRooms,
  PlanMode.zones => l.modeZones,
  PlanMode.point => l.modePoint,
  PlanMode.home => l.modeHome,
};

String _modeHint(L10n l, PlanMode m) => switch (m) {
  PlanMode.rooms => l.hintRooms,
  PlanMode.zones => l.hintZones,
  PlanMode.point => l.hintPoint,
  PlanMode.home => l.hintHome,
};

/// Plan: choose what to clean (rooms, zones, a point or the whole home), how, and send it to the queue.
class PlanScreen extends StatefulWidget {
  final RobotController controller;
  final VoidCallback onQueued;

  const PlanScreen({super.key, required this.controller, required this.onQueued});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  PlanMode _mode = PlanMode.rooms;
  final _plan = <(int, CleanSettings)>[];
  final _zones = <CleanZone>[];
  MapPoint? _target;

  /// Style applied to whatever is picked next (and to everything, if changed in the panel).
  CleanSettings _style = CleanSettings.smart;

  RobotController get c => widget.controller;

  List<int> get _rooms => [for (final (r, _) in _plan) r];

  bool get _busy => c.queue.current != null || c.status?.busy == true;

  void _toggleRoom(int room) => setState(() {
    final i = _rooms.indexOf(room);
    if (i >= 0) {
      _plan.removeAt(i);
    } else {
      _plan.add((room, _style));
    }
  });

  void _clear() => setState(() {
    _plan.clear();
    _zones.clear();
    _target = null;
  });

  Future<void> _pickStyle() async {
    var s = _style;
    await showAppSheet<void>(
      context,
      title: context.l.howToClean,
      subtitle: _mode == PlanMode.rooms && _plan.isNotEmpty ? context.l.appliesToAllRooms : null,
      builder: (ctx, set) => SettingsPicker(
        value: s,
        onChanged: (v) {
          set(() => s = v);
          setState(() {
            _style = v;
            for (var i = 0; i < _plan.length; i++) {
              _plan[i] = (_plan[i].$1, v);
            }
          });
        },
      ),
    );
  }

  Future<void> _editRoom(int index) async {
    var (room, settings) = _plan[index];
    await showAppSheet<void>(
      context,
      title: c.roomName(room),
      subtitle: context.l.roomOnlySettings,
      builder: (ctx, set) => SettingsPicker(
        value: settings,
        onChanged: (v) {
          set(() => settings = v);
          setState(() => _plan[index] = (room, v));
        },
      ),
    );
  }

  Future<void> _go() async {
    switch (_mode) {
      case PlanMode.rooms:
        c.enqueue(List.of(_plan));
      case PlanMode.zones:
        c.enqueueZones(List.of(_zones), _style);
      case PlanMode.home:
        c.enqueueWholeHome(_style);
      case PlanMode.point:
        final t = _target!;
        await c.act((r) => r.goTo(t.x, t.y), key: 'goto');
    }
    _clear();
    widget.onQueued();
  }

  bool get _canSaveRoutine =>
      (_mode == PlanMode.rooms && _plan.isNotEmpty) ||
      (_mode == PlanMode.zones && _zones.isNotEmpty) ||
      _mode == PlanMode.home;

  List<CleanJob> _jobsForRoutine() => switch (_mode) {
    PlanMode.rooms => CleanJob.fromPlan(List.of(_plan), c.newJobId),
    PlanMode.zones => [
      for (final z in _zones)
        ...CleanJob(id: c.newJobId(), rooms: const [], zones: [z], settings: _style).expandPasses(c.newJobId),
    ],
    _ => CleanJob(id: c.newJobId(), rooms: const [], settings: _style).expandPasses(c.newJobId),
  };

  Future<void> _saveAsRoutine() async {
    final r = Routine(id: c.newJobId(), name: _defaultRoutineName(), jobs: _jobsForRoutine());
    final saved = await _routineSheet(r, isNew: true);
    if (saved != null) {
      c.saveRoutine(saved);
      _clear();
    }
  }

  String _defaultRoutineName() => switch (_mode) {
    PlanMode.rooms => _rooms.map(c.roomName).take(2).join(' + ') + (_rooms.length > 2 ? '…' : ''),
    PlanMode.zones => context.l.modeZones,
    _ => context.l.wholeHome,
  };

  Future<void> _runRoutine(Routine r) async {
    final ok = await showAppSheet<bool>(
      context,
      title: r.name,
      subtitle: context.l.routineSummary(r.jobs.length, _busy ? context.l.joinsQueueNoCancel : context.l.startsNow),
      builder: (_, _) => const SizedBox(height: 4),
      action: _busy ? context.l.addToQueue : context.l.cleanNow,
      onAction: () => Navigator.of(context).pop(true),
    );
    if (ok == true) {
      c.runRoutine(r);
      widget.onQueued();
    }
  }

  Future<void> _editRoutine(Routine r) async {
    final saved = await _routineSheet(r, isNew: false);
    if (saved != null) c.saveRoutine(saved);
  }

  /// Edit sheet: name, days, time, enabled. Returns the changed routine (or null if cancelled/deleted).
  Future<Routine?> _routineSheet(Routine r, {required bool isNew}) {
    var cur = r;
    final name = TextEditingController(text: r.name);
    final initials = context.l.weekdaysNarrow.split(' ');
    final dayNames = {for (var d = 1; d <= 7; d++) d: initials[d - 1]};
    return showAppSheet<Routine>(
      context,
      title: isNew ? context.l.newRoutine : context.l.routine,
      builder: (ctx, set) {
        final s = Theme.of(ctx).colorScheme, t = Theme.of(ctx).textTheme;
        String hm(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Field(controller: name, hint: context.l.name, icon: Icons.bookmark_rounded),
            const SizedBox(height: 16),
            Text(context.l.repeat, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final d in dayNames.entries)
                  Pressable(
                    onTap: () => set(
                      () => cur = cur.copyWith(
                        days: cur.days.contains(d.key) ? ({...cur.days}..remove(d.key)) : {...cur.days, d.key},
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: cur.days.contains(d.key) ? s.primary : s.primary.withValues(alpha: 0.08),
                      child: Text(
                        d.value,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: cur.days.contains(d.key) ? s.onPrimary : s.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    cur.scheduled ? context.l.atTime(hm(cur.hour, cur.minute)) : context.l.unscheduled,
                    style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (cur.scheduled)
                  Pressable(
                    onTap: () async {
                      final p = await pickTime(
                        ctx,
                        TimeOfDay(hour: cur.hour, minute: cur.minute),
                        title: context.l.time,
                      );
                      if (p != null) set(() => cur = cur.copyWith(hour: p.hour, minute: p.minute));
                    },
                    child: Text(
                      context.l.changeTime,
                      style: TextStyle(fontWeight: FontWeight.w700, color: s.primary),
                    ),
                  ),
              ],
            ),
            if (cur.scheduled)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(context.l.enabled)),
                    Toggle(
                      value: cur.enabled,
                      onChanged: (v) => set(() => cur = cur.copyWith(enabled: v)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            BigButton(
              label: context.l.save,
              onTap: () =>
                  Navigator.of(ctx).pop(cur.copyWith(name: name.text.trim().isEmpty ? r.name : name.text.trim())),
            ),
            if (!isNew)
              Pressable(
                onTap: () {
                  c.deleteRoutine(r.id);
                  Navigator.of(ctx).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Center(
                    child: Text(
                      context.l.deleteRoutine,
                      style: TextStyle(color: s.error, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String get _actionLabel {
    final l = context.l;
    return switch (_mode) {
      PlanMode.rooms =>
        _plan.isEmpty ? l.pickRoomsOnMap : (_busy ? l.queueRooms(_plan.length) : l.cleanRooms(_plan.length)),
      PlanMode.zones =>
        _zones.isEmpty ? l.drawZoneOnMap : (_busy ? l.queueZones(_zones.length) : l.cleanZones(_zones.length)),
      PlanMode.point => _target == null ? l.tapPointOnMap : l.goHere,
      PlanMode.home => _busy ? l.queueWholeHome : l.cleanWholeHome,
    };
  }

  bool get _ready => switch (_mode) {
    PlanMode.rooms => _plan.isNotEmpty,
    PlanMode.zones => _zones.isNotEmpty,
    PlanMode.point => _target != null && !c.isPending('goto'),
    PlanMode.home => true,
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme, s = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final map = c.map, geometry = c.geometry;
        return PageBackground(
          child: Column(
            children: [
              PageHeader(title: context.l.plan, subtitle: _modeHint(context.l, _mode)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ModeSwitch(
                  value: _mode,
                  onChanged: (m) => setState(() {
                    _mode = m;
                    _clear();
                  }),
                ),
              ),
              if (c.routines.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    children: [
                      for (final r in c.routines)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onLongPress: () => _editRoutine(r),
                            child: Pressable(
                              semanticLabel: context.l.runRoutine(r.name),
                              onTap: () => _runRoutine(r),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: s.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      r.scheduled && r.enabled ? Icons.schedule_rounded : Icons.bolt_rounded,
                                      size: 18,
                                      color: s.onTertiaryContainer,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      r.name,
                                      style: TextStyle(fontWeight: FontWeight.w700, color: s.onTertiaryContainer),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: map == null || geometry == null
                    ? const Center(child: Dots())
                    : MapView(
                        map: map,
                        geometry: geometry,
                        roomNames: c.roomNames,
                        selectedRooms: _mode == PlanMode.rooms ? _rooms : const [],
                        onRoomTap: _mode == PlanMode.rooms ? _toggleRoom : null,
                        zones: _zones,
                        onZoneDrawn: _mode == PlanMode.zones ? (z) => setState(() => _zones.add(z)) : null,
                        onPointTap: _mode == PlanMode.point ? (p) => setState(() => _target = p) : null,
                        target: _target,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Glass(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_mode == PlanMode.rooms && _plan.isNotEmpty) ...[
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final (i, (room, settings)) in _plan.indexed)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _RoomChip(
                                    order: i + 1,
                                    name: c.roomName(room),
                                    custom: settings != _style,
                                    onTap: () => _editRoom(i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_mode == PlanMode.zones && _zones.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.l.zonesArea(
                                  _zones.length,
                                  _zones.fold(0.0, (a, z) => a + z.areaM2).toStringAsFixed(1),
                                ),
                                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Pressable(
                              semanticLabel: context.l.undoLastZone,
                              onTap: () => setState(_zones.removeLast),
                              child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.undo_rounded)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (_mode != PlanMode.point)
                        Pressable(
                          onTap: _pickStyle,
                          child: Row(
                            children: [
                              IconBadge(Icons.tune_rounded, color: s.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(context.l.how, style: t.labelSmall?.copyWith(color: s.onSurfaceVariant)),
                                    Text(
                                      settingsSummary(context.l, _style),
                                      style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.expand_more_rounded, color: s.onSurfaceVariant),
                            ],
                          ),
                        ),
                      if (_canSaveRoutine)
                        Pressable(
                          onTap: _saveAsRoutine,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                Icon(Icons.bookmark_add_rounded, color: s.primary, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  context.l.saveAsRoutine,
                                  style: TextStyle(fontWeight: FontWeight.w700, color: s.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (_plan.isNotEmpty || _zones.isNotEmpty || _target != null)
                            Pressable(
                              semanticLabel: context.l.clearSelection,
                              onTap: _clear,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(Icons.close_rounded, color: s.onSurfaceVariant),
                              ),
                            ),
                          Expanded(
                            child: BigButton(
                              icon: _mode == PlanMode.point ? Icons.near_me_rounded : Icons.play_arrow_rounded,
                              label: _actionLabel,
                              onTap: _ready ? _go : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom mode switch: pills with an icon, the active one filled.
class _ModeSwitch extends StatelessWidget {
  final PlanMode value;
  final ValueChanged<PlanMode> onChanged;

  const _ModeSwitch({required this.value, required this.onChanged});

  static const _icons = {
    PlanMode.rooms: Icons.grid_view_rounded,
    PlanMode.zones: Icons.highlight_alt_rounded,
    PlanMode.point: Icons.near_me_rounded,
    PlanMode.home: Icons.home_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: s.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          for (final m in PlanMode.values)
            Expanded(
              child: Pressable(
                semanticLabel: _modeLabel(context.l, m),
                onTap: () => onChanged(m),
                child: AnimatedContainer(
                  duration: Tokens.fast,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: m == value ? s.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(_icons[m], size: 20, color: m == value ? s.onPrimary : s.primary),
                      const SizedBox(height: 2),
                      Text(
                        _modeLabel(context.l, m),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: m == value ? s.onPrimary : s.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  final int order;
  final String name;
  final bool custom;
  final VoidCallback onTap;

  const _RoomChip({required this.order, required this.name, required this.custom, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Pressable(
      semanticLabel: context.l.settingsOf(name),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
        decoration: BoxDecoration(color: s.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: s.primary,
              child: Text(
                '$order',
                style: TextStyle(color: s.onPrimary, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (custom) ...[const SizedBox(width: 6), Icon(Icons.tune_rounded, size: 16, color: s.primary)],
          ],
        ),
      ),
    );
  }
}
