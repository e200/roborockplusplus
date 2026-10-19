import 'dart:math' as math;
import 'dart:ui';

import 'robot_map.dart';

/// Converts robot coordinates (mm, y up) to grid coordinates (cells, y down).
class MapProjection {
  final MapGrid grid;

  const MapProjection(this.grid);

  Size get size => Size(grid.width.toDouble(), grid.height.toDouble());

  Offset toCanvas(MapPoint p) =>
      Offset(p.x / RobotMap.pixelSize - grid.left, grid.height - (p.y / RobotMap.pixelSize - grid.top));

  /// Grid corner (col, row), with row counted from the bottom, in screen coordinates.
  Offset corner(int col, int row) => Offset(col.toDouble(), (grid.height - row).toDouble());

  MapPoint toRobot(Offset o) => MapPoint(
    ((o.dx + grid.left) * RobotMap.pixelSize).round(),
    ((grid.height - o.dy + grid.top) * RobotMap.pixelSize).round(),
  );
}

class RoomShape {
  final int id;
  final Path path;

  /// Label anchor: the room cell farthest from the outline.
  final Offset labelAnchor;
  final double areaM2;

  const RoomShape(this.id, this.path, this.labelAnchor, this.areaM2);
}

/// Vector shapes of the map, computed once per grid.
class MapGeometry {
  final MapProjection projection;
  final Map<int, RoomShape> rooms;
  final Path walls;
  final Path floor;
  final Path carpets;

  MapGeometry._(this.projection, this.rooms, this.walls, this.floor, this.carpets);

  factory MapGeometry.from(MapGrid grid) {
    final proj = MapProjection(grid);
    final cellsByRoom = <int, List<int>>{};
    final walls = Path(), floor = Path(), carpets = Path();
    for (var row = 0; row < grid.height; row++) {
      int? runStart;
      CellKind? runKind;
      void flush(int end) {
        if (runStart == null) return;
        final rect = Rect.fromPoints(proj.corner(runStart!, row), proj.corner(end, row + 1));
        if (runKind == CellKind.wall) walls.addRect(rect);
        if (runKind == CellKind.floor || runKind == CellKind.scanned) floor.addRect(rect);
        runStart = null;
      }

      for (var col = 0; col < grid.width; col++) {
        if (grid.isRemoved(col, row)) {
          flush(col);
          continue;
        }
        final kind = grid.kind(col, row);
        final tag = grid.roomTagAt(col, row);
        if (tag != null) cellsByRoom.putIfAbsent(tag, () => []).add(col + grid.width * row);
        if (grid.isCarpet(col, row)) {
          final c = proj.corner(col, row);
          carpets.addOval(Rect.fromCircle(center: c.translate(0.5, -0.5), radius: 0.22));
        }
        if (kind != runKind) {
          flush(col);
          if (kind == CellKind.wall || kind == CellKind.floor || kind == CellKind.scanned) runStart = col;
          runKind = kind;
        }
      }
      flush(grid.width);
    }
    final rooms = {
      for (final MapEntry(key: id, value: cells) in cellsByRoom.entries) id: _roomShape(id, cells, grid, proj),
    };
    return MapGeometry._(proj, rooms, walls, floor, carpets);
  }

  /// Room containing a screen point (for map taps).
  int? roomAt(Offset canvasPoint) {
    for (final room in rooms.values) {
      if (room.path.contains(canvasPoint)) return room.id;
    }
    return null;
  }

  static RoomShape _roomShape(int id, List<int> cells, MapGrid grid, MapProjection proj) {
    final inRoom = cells.toSet();
    bool has(int col, int row) =>
        col >= 0 && row >= 0 && col < grid.width && row < grid.height && inRoom.contains(col + grid.width * row);

    // Directed edges with the room on the left; chained, they form closed outlines (outer ones and holes).
    final next = <int, List<int>>{};
    final stride = grid.width + 1;
    int v(int col, int row) => col + stride * row;
    void edge(int a, int b) => next.putIfAbsent(a, () => []).add(b);
    for (final cell in cells) {
      final col = cell % grid.width, row = cell ~/ grid.width;
      if (!has(col, row - 1)) edge(v(col, row), v(col + 1, row));
      if (!has(col + 1, row)) edge(v(col + 1, row), v(col + 1, row + 1));
      if (!has(col, row + 1)) edge(v(col + 1, row + 1), v(col, row + 1));
      if (!has(col - 1, row)) edge(v(col, row + 1), v(col, row));
    }

    final path = Path()..fillType = PathFillType.evenOdd;
    while (next.isNotEmpty) {
      final start = next.keys.first;
      final loop = <int>[start];
      var cur = start;
      int? prev;
      while (true) {
        final outs = next[cur]!;
        final to = outs.removeAt(prev == null ? outs.length - 1 : _leftmost(prev, cur, outs, stride));
        prev = cur;
        if (outs.isEmpty) next.remove(cur);
        if (to == start) break;
        loop.add(to);
        cur = to;
        if (!next.containsKey(cur)) break;
      }
      final pts = _simplify([for (final p in loop) proj.corner(p % stride, p ~/ stride)]);
      final area = _area(pts);
      // Few-cell noise and small holes (furniture legs) are left out of the outline.
      // On screen y is flipped: outer outlines have negative area and holes positive.
      if (pts.length < 3 || area.abs() < 4 || (area > 0 && area < _minHoleCells)) continue;
      _addSmooth(path, pts);
    }

    return RoomShape(id, path, _labelAnchor(cells, grid, proj, has), cells.length * 0.0025);
  }

  static const _minHoleCells = 80;
  static const _labelRoom = 14;

  /// At a vertex where two cells only touch at a corner there are two exits. Turning left (keeping the room
  /// on the left) walks around the same cell, which splits outlines instead of merging them into a figure eight.
  static int _leftmost(int prev, int cur, List<int> outs, int stride) {
    if (outs.length == 1) return 0;
    final dx = cur % stride - prev % stride, dy = cur ~/ stride - prev ~/ stride;
    for (var i = 0; i < outs.length; i++) {
      final ex = outs[i] % stride - cur % stride, ey = outs[i] ~/ stride - cur ~/ stride;
      if (dx * ey - dy * ex > 0) return i;
    }
    return outs.length - 1;
  }

  /// Drops collinear points (staircase outlines have lots).
  static List<Offset> _simplify(List<Offset> pts) {
    final out = <Offset>[];
    for (var i = 0; i < pts.length; i++) {
      final prev = pts[(i - 1 + pts.length) % pts.length], cur = pts[i], nxt = pts[(i + 1) % pts.length];
      final cross = (cur.dx - prev.dx) * (nxt.dy - cur.dy) - (cur.dy - prev.dy) * (nxt.dx - cur.dx);
      if (cross != 0) out.add(cur);
    }
    return out;
  }

  static double _area(List<Offset> pts) {
    var a = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i], q = pts[(i + 1) % pts.length];
      a += p.dx * q.dy - q.dx * p.dy;
    }
    return a / 2;
  }

  /// Rounded corners: each corner becomes a curve between the midpoints of the neighbouring edges,
  /// capped at [_cornerRadius] cells so long walls are not distorted.
  static const _cornerRadius = 1.2;

  static void _addSmooth(Path path, List<Offset> pts) {
    Offset towards(Offset from, Offset to) {
      final d = to - from;
      final len = d.distance;
      return len <= 2 * _cornerRadius ? from + d / 2 : from + d * (_cornerRadius / len);
    }

    final n = pts.length;
    path.moveTo(towards(pts[0], pts[n - 1]).dx, towards(pts[0], pts[n - 1]).dy);
    for (var i = 0; i < n; i++) {
      final cur = pts[i], nxt = pts[(i + 1) % n];
      final out = towards(cur, nxt), into = towards(nxt, cur);
      path.quadraticBezierTo(cur.dx, cur.dy, out.dx, out.dy);
      path.lineTo(into.dx, into.dy);
    }
    path.close();
  }

  static Offset _labelAnchor(List<int> cells, MapGrid grid, MapProjection proj, bool Function(int, int) has) {
    // Labels are wide: horizontal clearance counts double the vertical.
    // Above _labelRoom cells of clearance any point works; then the one closest to the room centre wins.
    var sumCol = 0.0, sumRow = 0.0;
    for (final c in cells) {
      sumCol += c % grid.width;
      sumRow += c ~/ grid.width;
    }
    final cx = sumCol / cells.length, cy = sumRow / cells.length;
    int arm(int col, int row, int dc, int dr, int max) {
      var d = 0;
      while (d < max && has(col + dc * (d + 1), row + dr * (d + 1))) {
        d++;
      }
      return d;
    }

    var best = cells.first;
    var bestScore = -1.0, bestDist = double.infinity;
    final step = math.max(1, cells.length ~/ 6000);
    for (var i = 0; i < cells.length; i += step) {
      final col = cells[i] % grid.width, row = cells[i] ~/ grid.width;
      final h = math.min(arm(col, row, -1, 0, 2 * _labelRoom), arm(col, row, 1, 0, 2 * _labelRoom)) / 2;
      final v = math.min(arm(col, row, 0, -1, _labelRoom), arm(col, row, 0, 1, _labelRoom)).toDouble();
      final score = math.min(h, v);
      final dist = (col - cx) * (col - cx) + (row - cy) * (row - cy);
      if (score > bestScore || (score == bestScore && dist < bestDist)) {
        bestScore = score;
        bestDist = dist;
        best = cells[i];
      }
    }
    return proj.corner(best % grid.width, best ~/ grid.width).translate(0.5, -0.5);
  }
}
