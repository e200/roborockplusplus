import 'dart:math' as math;

import 'robot_map.dart';

enum RestrictionKind { noGo, wall, noMop }

/// A map restriction in `save_map` format (confirmed on the Saros 20):
/// no-go zone `[0, 4 corners]`, wall `[1, x0, y0, x1, y1]`, no-mop zone `[2, 4 corners]`.
class Restriction {
  final RestrictionKind kind;
  final List<MapPoint> points;

  const Restriction(this.kind, this.points);

  factory Restriction.rect(RestrictionKind kind, int x0, int y0, int x1, int y1) =>
      Restriction(kind, [MapPoint(x0, y0), MapPoint(x1, y0), MapPoint(x1, y1), MapPoint(x0, y1)]);

  List<int> toParams() => [
    switch (kind) {
      RestrictionKind.noGo => 0,
      RestrictionKind.wall => 1,
      RestrictionKind.noMop => 2,
    },
    for (final p in points) ...[p.x, p.y],
  ];

  /// The restrictions the robot has now (saving always sends the full list: anything missing is deleted).
  static List<Restriction> fromMap(RobotMap m) => [
    for (final a in m.noGoAreas) Restriction(RestrictionKind.noGo, a.corners),
    for (final a in m.noMopAreas) Restriction(RestrictionKind.noMop, a.corners),
    for (final w in m.virtualWalls) Restriction(RestrictionKind.wall, [w.a, w.b]),
  ];

  /// The restriction under a tap: a zone containing the point or a wall within [tolerance] mm (the newest wins,
  /// since it is drawn on top). Null if the tap hit none.
  static int? hitTest(List<Restriction> all, MapPoint p, {int tolerance = 250}) {
    for (var i = all.length - 1; i >= 0; i--) {
      final r = all[i];
      if (r.kind == RestrictionKind.wall) {
        if (_distanceToSegment(p, r.points[0], r.points[1]) <= tolerance) return i;
      } else {
        final xs = r.points.map((q) => q.x), ys = r.points.map((q) => q.y);
        if (p.x >= xs.reduce(_min) && p.x <= xs.reduce(_max) && p.y >= ys.reduce(_min) && p.y <= ys.reduce(_max)) {
          return i;
        }
      }
    }
    return null;
  }

  static int _min(int a, int b) => a < b ? a : b;
  static int _max(int a, int b) => a > b ? a : b;

  static double _distanceToSegment(MapPoint p, MapPoint a, MapPoint b) {
    final dx = (b.x - a.x).toDouble(), dy = (b.y - a.y).toDouble();
    final len2 = dx * dx + dy * dy;
    final t = len2 == 0 ? 0.0 : (((p.x - a.x) * dx + (p.y - a.y) * dy) / len2).clamp(0.0, 1.0);
    final cx = a.x + t * dx - p.x, cy = a.y + t * dy - p.y;
    return math.sqrt(cx * cx + cy * cy);
  }

  static List<List<int>> toSaveMap(List<Restriction> all) => [for (final r in all) r.toParams()];
}
