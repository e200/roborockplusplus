import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/describe.dart';
import '../l10n/strings.dart';
import '../map/map_view.dart';
import '../map/restrictions.dart';
import '../map/robot_map.dart';
import '../queue/clean_job.dart';
import '../robot/robot_controller.dart';
import 'design/components.dart';
import 'design/kit.dart';

(String, IconData, String) _toolInfo(L10n l, RestrictionKind k) => switch (k) {
  RestrictionKind.noGo => (l.toolNoGo, Icons.block_rounded, l.toolNoGoHint),
  RestrictionKind.noMop => (l.toolNoMop, Icons.water_drop_outlined, l.toolNoMopHint),
  RestrictionKind.wall => (l.toolWall, Icons.horizontal_rule_rounded, l.toolWallHint),
};

/// Map editor: no-go zones, no-mop zones and virtual walls.
/// Changes only reach the robot on "Save"; the map is then read back to confirm.
class MapEditScreen extends StatefulWidget {
  final RobotController controller;

  const MapEditScreen({super.key, required this.controller});

  @override
  State<MapEditScreen> createState() => _MapEditScreenState();
}

class _MapEditScreenState extends State<MapEditScreen> {
  late final List<Restriction> _items = Restriction.fromMap(widget.controller.map!);
  late final List<Restriction> _original = List.of(_items);

  /// Previous states, so "undo" can revert any step (draw, delete one, delete all).
  final List<List<Restriction>> _undo = [];
  RestrictionKind _tool = RestrictionKind.noGo;
  bool _saving = false;
  String? _message;

  RobotController get c => widget.controller;

  void _edit(void Function() change) {
    setState(() {
      _undo.add(List.of(_items));
      change();
    });
  }

  void _deleteAt(MapPoint p) {
    final i = Restriction.hitTest(_items, p);
    if (i != null) _edit(() => _items.removeAt(i));
  }

  bool get _changed => Restriction.toSaveMap(_items).toString() != Restriction.toSaveMap(_original).toString();

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    final ok = await c.act((r) => r.call('save_map', Restriction.toSaveMap(_items)), key: 'save_map');
    if (ok) await c.refreshMap();
    final now = c.map == null ? null : Restriction.fromMap(c.map!);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok && now != null && now.length == _items.length) {
        Navigator.of(context).pop();
      } else {
        _message = ok ? context.l.saveNotShownYet : (c.error == null ? null : errorText(context.l, c.error!));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tools = {
      for (final k in [RestrictionKind.noGo, RestrictionKind.noMop, RestrictionKind.wall]) k: _toolInfo(context.l, k),
    };
    final map = c.map, geometry = c.geometry, s = Theme.of(context).colorScheme, t = Theme.of(context).textTheme;
    final pendingZones = [
      for (final r in _items.where((r) => r.kind != RestrictionKind.wall))
        CleanZone(
          r.points.map((p) => p.x).reduce(math.min),
          r.points.map((p) => p.y).reduce(math.min),
          r.points.map((p) => p.x).reduce(math.max),
          r.points.map((p) => p.y).reduce(math.max),
        ),
    ];
    final pendingWalls = [
      for (final r in _items.where((r) => r.kind == RestrictionKind.wall)) MapLine(r.points[0], r.points[1]),
    ];
    // The base map is shown without the saved restrictions: the ones that count are this edit's.
    final base = map == null
        ? null
        : RobotMap(
            majorVersion: map.majorVersion,
            minorVersion: map.minorVersion,
            mapIndex: map.mapIndex,
            mapSequence: map.mapSequence,
            grid: map.grid,
            rooms: map.rooms,
            charger: map.charger,
            obstacles: map.obstacles,
            valid: map.valid,
          );
    return Scaffold(
      body: PageBackground(
        child: SafeArea(
          child: Column(
            children: [
              PageHeader(title: context.l.editMap, subtitle: tools[_tool]!.$3, leading: const BackPill()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final e in tools.entries)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Pressable(
                            semanticLabel: e.value.$1,
                            onTap: () => setState(() => _tool = e.key),
                            child: AnimatedContainer(
                              duration: Tokens.fast,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: e.key == _tool ? s.primary : s.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(e.value.$2, color: e.key == _tool ? s.onPrimary : s.primary),
                                  Text(
                                    e.value.$1,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: e.key == _tool ? s.onPrimary : s.primary,
                                    ),
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
                child: base == null || geometry == null
                    ? const Center(child: Dots())
                    : MapView(
                        map: base,
                        geometry: geometry,
                        roomNames: c.roomNames,
                        showRobot: false,
                        zones: pendingZones,
                        lines: pendingWalls,
                        onZoneDrawn: _tool == RestrictionKind.wall
                            ? null
                            : (z) => _edit(() => _items.add(Restriction.rect(_tool, z.x0, z.y0, z.x1, z.y1))),
                        onLineDrawn: _tool == RestrictionKind.wall
                            ? (a, b) => _edit(() => _items.add(Restriction(RestrictionKind.wall, [a, b])))
                            : null,
                        onPointTap: _deleteAt,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Glass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _items.isEmpty ? context.l.restrictions(0) : context.l.restrictions(_items.length),
                              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (_undo.isNotEmpty)
                            Pressable(
                              semanticLabel: context.l.undo,
                              onTap: () => setState(
                                () => _items
                                  ..clear()
                                  ..addAll(_undo.removeLast()),
                              ),
                              child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.undo_rounded)),
                            ),
                          if (_items.isNotEmpty)
                            Pressable(
                              semanticLabel: context.l.deleteAll,
                              onTap: () => _edit(_items.clear),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(Icons.delete_sweep_rounded, color: s.error),
                              ),
                            ),
                        ],
                      ),
                      if (_message != null) Text(_message!, style: TextStyle(color: s.error)),
                      const SizedBox(height: 10),
                      _saving
                          ? const SizedBox(height: 54, child: Center(child: Dots()))
                          : BigButton(
                              icon: Icons.save_rounded,
                              label: _changed ? context.l.saveToRobot : context.l.noChanges,
                              onTap: _changed ? _save : null,
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
