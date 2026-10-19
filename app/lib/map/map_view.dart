import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';

import 'map_geometry.dart';
import '../queue/clean_job.dart';
import 'robot_map.dart';

/// Icon per furniture type, confirmed against the official app on the reference home:
/// 45 = bed, 46 = sofa, 47 = dining table. Unknown types get a generic icon.
IconData furnitureIcon(int type) => switch (type) {
  45 => Icons.bed_rounded,
  46 => Icons.weekend_rounded,
  47 => Icons.table_restaurant_rounded,
  _ => Icons.chair_alt_rounded,
};

/// Types the official app does not draw on the map (44 shows up in bathrooms and the official app hides it).
const hiddenFurnitureTypes = {44};

/// Room palette: soft tones that work on light and dark backgrounds.
const roomPalette = [
  Color(0xFF7FB7E8),
  Color(0xFF8FD3B6),
  Color(0xFFF2B880),
  Color(0xFFE79A9A),
  Color(0xFFB9A6E8),
  Color(0xFFF0D27A),
  Color(0xFF8CCBD6),
  Color(0xFFD6A6C9),
];

Color roomColor(int id) => roomPalette[(id - 1) % roomPalette.length];

class MapStyle {
  final Color background;
  final Color floor;
  final Color wall;
  final Color label;
  final Color labelHalo;
  final Color path;
  final Color robot;
  final String? fontFamily;

  /// In the dark theme the pastel tones are darkened so light text keeps its contrast.
  final bool dark;

  Color room(int id) => dark ? Color.lerp(roomColor(id), const Color(0xFF101418), 0.45)! : roomColor(id);

  const MapStyle({
    required this.background,
    required this.floor,
    required this.wall,
    required this.label,
    required this.labelHalo,
    required this.path,
    required this.robot,
    this.fontFamily,
    this.dark = false,
  });

  factory MapStyle.of(ThemeData theme) => MapStyle.from(theme.colorScheme, theme.textTheme.bodyMedium?.fontFamily);

  factory MapStyle.from(ColorScheme c, String? fontFamily) => MapStyle(
    fontFamily: fontFamily,
    dark: c.brightness == Brightness.dark,
    background: c.surface,
    floor: c.surfaceContainerHighest,
    wall: c.onSurface.withValues(alpha: 0.55),
    label: c.onSurface,
    labelHalo: c.surface.withValues(alpha: 0.85),
    path: c.onSurface.withValues(alpha: 0.35),
    robot: c.primary,
  );
}

/// Live map: vector rooms, current room highlighted, path, and the robot with a pulse.
/// With [onZoneDrawn], dragging draws a zone (one-finger panning is disabled).
class MapView extends StatefulWidget {
  final RobotMap map;
  final MapGeometry geometry;
  final Map<int, String> roomNames;
  final int? currentRoom;
  final Set<int> doneRooms;

  /// Rooms picked in the planner, in cleaning order.
  final List<int> selectedRooms;
  final ValueChanged<int>? onRoomTap;

  /// Zones to show (planned or queued), in robot coordinates.
  final List<CleanZone> zones;
  final ValueChanged<CleanZone>? onZoneDrawn;

  /// Dragging draws a line (virtual walls) instead of a rectangle.
  final void Function(MapPoint a, MapPoint b)? onLineDrawn;

  /// Lines to draw on top (unsaved walls), in robot coordinates.
  final List<MapLine> lines;

  /// Tap on any map point ("go to" mode), in robot coordinates.
  final ValueChanged<MapPoint>? onPointTap;

  /// Target point to mark on the map.
  final MapPoint? target;

  /// Path to show instead of the live one (past cleans).
  final List<MapPoint>? pathOverride;

  /// Shows the robot (pointless in history).
  final bool showRobot;

  /// Highlighted path (in history it is the main subject).
  final bool highlightPath;

  /// Robot active: only then is there a pulse (and only then does the animation run).
  final bool active;

  const MapView({
    super.key,
    required this.map,
    required this.geometry,
    this.roomNames = const {},
    this.currentRoom,
    this.doneRooms = const {},
    this.selectedRooms = const [],
    this.onRoomTap,
    this.zones = const [],
    this.onZoneDrawn,
    this.onPointTap,
    this.target,
    this.onLineDrawn,
    this.lines = const [],
    this.pathOverride,
    this.showRobot = true,
    this.active = false,
    this.highlightPath = false,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
    if (widget.active) _pulse.repeat();
  }

  /// The robot glides from its previous to its new position between readings.
  late final _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
  Offset? _from, _to;
  Offset? _dragStart, _dragEnd;

  /// User zoom. Labels, markers and the robot divide their size by it to keep the same on-screen size;
  /// rounded to 10% so the map is not repainted on every pixel of the gesture.
  final _transform = TransformationController();
  double _zoom = 1;

  void _onTransform() {
    final z = (_transform.value.getMaxScaleOnAxis() * 10).round() / 10;
    if (z != _zoom) setState(() => _zoom = z);
  }

  MapProjection get _proj => widget.geometry.projection;

  @override
  void didUpdateWidget(MapView old) {
    super.didUpdateWidget(old);
    if (widget.active && !_pulse.isAnimating) _pulse.repeat();
    if (!widget.active && _pulse.isAnimating) _pulse.stop();
    final r = widget.map.robot;
    if (r == null) return;
    final next = _proj.toCanvas(r);
    if (next == _to) return;
    _from = _currentRobot ?? next;
    _to = next;
    _move.forward(from: 0);
  }

  Offset? get _currentRobot {
    final to = _to;
    if (to == null) return widget.map.robot == null ? null : _proj.toCanvas(widget.map.robot!);
    return Offset.lerp(_from ?? to, to, Curves.easeInOut.transform(_move.value));
  }

  @override
  void dispose() {
    _transform.dispose();
    _pulse.dispose();
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = MapStyle.of(Theme.of(context));
    final bounds = _contentBounds();
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(constraints.maxWidth / bounds.width, constraints.maxHeight / bounds.height) * 0.92;
        final offset = Offset(
          (constraints.maxWidth - bounds.width * scale) / 2,
          (constraints.maxHeight - bounds.height * scale) / 2,
        );
        Offset toCanvas(Offset local) => (local - offset) / scale + bounds.topLeft;
        final drawing = widget.onZoneDrawn != null || widget.onLineDrawn != null;
        final ts = 1 / (scale * _zoom);
        return InteractiveViewer(
          transformationController: _transform,
          minScale: 0.8,
          maxScale: 8,
          panEnabled: !drawing,
          boundaryMargin: const EdgeInsets.all(200),
          child: GestureDetector(
            // While drawing, a tap (no drag) still reaches onPointTap: the editor uses it to delete.
            onTapUp: (drawing && widget.onPointTap == null) || (widget.onRoomTap == null && widget.onPointTap == null)
                ? null
                : (d) {
                    final p = toCanvas(d.localPosition);
                    if (widget.onPointTap != null) {
                      widget.onPointTap!(_proj.toRobot(p));
                      return;
                    }
                    final id = widget.geometry.roomAt(p);
                    if (id != null) widget.onRoomTap!(id);
                  },
            onPanStart: drawing ? (d) => setState(() => _dragStart = _dragEnd = toCanvas(d.localPosition)) : null,
            onPanUpdate: drawing ? (d) => setState(() => _dragEnd = toCanvas(d.localPosition)) : null,
            onPanEnd: drawing
                ? (_) {
                    final a = _dragStart, b = _dragEnd;
                    setState(() => _dragStart = _dragEnd = null);
                    if (a == null || b == null || (a - b).distance < 6) return; // toque acidental
                    final p0 = _proj.toRobot(a), p1 = _proj.toRobot(b);
                    if (widget.onLineDrawn != null) {
                      widget.onLineDrawn!(p0, p1);
                      return;
                    }
                    widget.onZoneDrawn!(
                      CleanZone(math.min(p0.x, p1.x), math.min(p0.y, p1.y), math.max(p0.x, p1.x), math.max(p0.y, p1.y)),
                    );
                  }
                : null,
            // Two layers: the (expensive) map only repaints when it changes; the robot and zones animate on top.
            child: Stack(
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _Framed(
                      MapPainter(
                        map: widget.map,
                        geometry: widget.geometry,
                        style: style,
                        // Rooms without a name in the official app still get a readable label.
                        roomNames: {
                          for (final id in widget.geometry.rooms.keys) id: widget.roomNames[id] ?? context.l.roomN(id),
                        },
                        currentRoom: widget.currentRoom,
                        doneRooms: widget.doneRooms,
                        selectedRooms: widget.selectedRooms,
                        textScale: ts,
                        pathOverride: widget.pathOverride,
                        showRobot: false,
                        highlightPath: widget.highlightPath,
                      ),
                      bounds,
                      scale,
                      offset,
                    ),
                  ),
                ),
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _Framed(
                    null,
                    bounds,
                    scale,
                    offset,
                    repaint: Listenable.merge([_pulse, _move]),
                    overlay: (canvas) => _paintOverlay(canvas, style, ts),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _paintOverlay(Canvas canvas, MapStyle style, double ts) {
    for (final z in widget.zones) {
      final r = Rect.fromPoints(_proj.toCanvas(MapPoint(z.x0, z.y0)), _proj.toCanvas(MapPoint(z.x1, z.y1)));
      _zone(canvas, r, style.robot, ts);
    }
    final line = Paint()
      ..strokeWidth = 3 * ts
      ..strokeCap = StrokeCap.round
      ..color = Colors.red;
    for (final l in widget.lines) {
      canvas.drawLine(_proj.toCanvas(l.a), _proj.toCanvas(l.b), line);
    }
    final a = _dragStart, b = _dragEnd;
    if (a != null && b != null) {
      if (widget.onLineDrawn != null) {
        canvas.drawLine(a, b, line);
      } else {
        _zone(canvas, Rect.fromPoints(a, b), style.robot, ts);
      }
    }
    final target = widget.target;
    if (target != null) {
      // Target pin.
      final at = _proj.toCanvas(target);
      final r = 7 * ts;
      canvas.drawCircle(at, r * 2.2, Paint()..color = style.robot.withValues(alpha: 0.18));
      canvas.drawCircle(at, r, Paint()..color = style.robot);
      canvas.drawCircle(at, r * 0.4, Paint()..color = Colors.white);
    }
    final robot = _currentRobot;
    if (widget.showRobot && robot != null) {
      final r = 9 * ts;
      // Pulse: a ring that grows and fades, so the robot is easy to spot.
      if (widget.active) {
        final t = _pulse.value;
        canvas.drawCircle(robot, r * (1.2 + 1.8 * t), Paint()..color = style.robot.withValues(alpha: 0.35 * (1 - t)));
      }
      canvas.drawCircle(robot, r * 1.6, Paint()..color = style.robot.withValues(alpha: 0.15));
      canvas.drawCircle(robot, r, Paint()..color = Colors.white);
      canvas.drawCircle(
        robot,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.28
          ..color = style.robot,
      );
      final angle = -(widget.map.robot?.angle ?? 0) * math.pi / 180;
      canvas.drawCircle(
        robot + Offset(math.cos(angle), math.sin(angle)) * r * 0.5,
        r * 0.22,
        Paint()..color = style.robot,
      );
    }
  }

  void _zone(Canvas canvas, Rect r, Color c, double ts) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(3 * ts));
    canvas.drawRRect(rr, Paint()..color = c.withValues(alpha: 0.18));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * ts
        ..color = c,
    );
  }

  /// Frames the rooms, not the whole grid (which has a lot of empty margin).
  Rect _contentBounds() {
    Rect? r;
    for (final room in widget.geometry.rooms.values) {
      final b = room.path.getBounds();
      r = r == null ? b : r.expandToInclude(b);
    }
    return (r ?? Offset.zero & widget.geometry.projection.size).inflate(4);
  }
}

class _Framed extends CustomPainter {
  final MapPainter? inner;
  final Rect bounds;
  final double scale;
  final Offset offset;
  final void Function(Canvas)? overlay;

  _Framed(this.inner, this.bounds, this.scale, this.offset, {this.overlay, super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..scale(scale)
      ..translate(-bounds.left, -bounds.top);
    inner?.paint(canvas, size);
    overlay?.call(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Framed old) =>
      overlay != null ||
      old.scale != scale ||
      old.offset != offset ||
      (inner != null && inner!.shouldRepaint(old.inner!));
}

class MapPainter extends CustomPainter {
  final RobotMap map;
  final MapGeometry geometry;
  final MapStyle style;
  final Map<int, String> roomNames;
  final int? currentRoom;
  final Set<int> doneRooms;
  final List<int> selectedRooms;
  final List<MapPoint>? pathOverride;
  final bool showRobot;
  final bool highlightPath;

  /// Inverse of the screen scale: keeps text and icons a constant size in cells.
  final double textScale;

  MapPainter({
    required this.map,
    required this.geometry,
    required this.style,
    required this.roomNames,
    required this.currentRoom,
    required this.doneRooms,
    this.selectedRooms = const [],
    required this.textScale,
    this.pathOverride,
    this.showRobot = true,
    this.highlightPath = false,
  });

  MapProjection get _proj => geometry.projection;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(geometry.floor, Paint()..color = style.floor);

    for (final room in geometry.rooms.values) {
      final base = style.room(room.id);
      final active = room.id == currentRoom;
      final selecting = selectedRooms.isNotEmpty;
      final selected = selectedRooms.contains(room.id);
      final done = doneRooms.contains(room.id) || (selecting && !selected);
      final fill = done ? Color.lerp(base, style.background, 0.55)! : base;
      if (active) {
        canvas.drawPath(
          room.path,
          Paint()
            ..color = base.withValues(alpha: 0.7)
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3),
        );
      }
      canvas.drawPath(room.path, Paint()..color = fill);
      canvas.drawPath(
        room.path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = active || selected ? 0.9 : 0.45
          ..strokeJoin = StrokeJoin.round
          ..color = active || selected ? style.robot : Color.lerp(base, Colors.black, 0.25)!,
      );
    }

    canvas.drawPath(geometry.carpets, Paint()..color = Colors.black.withValues(alpha: 0.12));
    canvas.drawPath(geometry.walls, Paint()..color = style.wall);

    _drawFurniture(canvas);
    _drawRestrictions(canvas);
    _drawPath(canvas);
    _drawObstacles(canvas);
    _drawLabels(canvas);
    if (map.charger != null) _drawCharger(canvas, _proj.toCanvas(map.charger!));
    if (showRobot && map.robot != null) _drawRobot(canvas, _proj.toCanvas(map.robot!), map.robot!.angle ?? 0);
  }

  void _drawRestrictions(Canvas canvas) {
    void area(MapArea a, Color c) {
      final pts = a.corners.map(_proj.toCanvas).toList();
      final p = Path()..addPolygon(pts, true);
      canvas.drawPath(p, Paint()..color = c.withValues(alpha: 0.18));
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = c,
      );
    }

    for (final a in map.noGoAreas) {
      area(a, Colors.red);
    }
    for (final a in map.noMopAreas) {
      area(a, Colors.blue);
    }
    final wall = Paint()
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round
      ..color = Colors.red;
    for (final w in map.virtualWalls) {
      canvas.drawLine(_proj.toCanvas(w.a), _proj.toCanvas(w.b), wall);
    }
  }

  /// Furniture (neutral rounded rectangles) and door sills (amber bars), like the official app.
  void _drawFurniture(Canvas canvas) {
    final fill = Paint()..color = style.label.withValues(alpha: 0.16);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45
      ..color = style.label.withValues(alpha: 0.45);
    for (final f in map.furniture.where((f) => !hiddenFurnitureTypes.contains(f.type))) {
      final r = Rect.fromPoints(_proj.toCanvas(f.area.corners[0]), _proj.toCanvas(f.area.corners[2]));
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(1.2));
      canvas.drawRRect(rr, fill);
      canvas.drawRRect(rr, edge);
      _drawIcon(canvas, furnitureIcon(f.type), r.center, math.min(14 * textScale, r.shortestSide * 0.9));
    }
    final sill = Paint()..color = const Color(0xFFE0A100).withValues(alpha: 0.9);
    for (final t in map.thresholds) {
      canvas.drawPath(Path()..addPolygon(t.corners.map(_proj.toCanvas).toList(), true), sill);
    }
  }

  void _drawIcon(Canvas canvas, IconData icon, Offset center, double size) {
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: style.label.withValues(alpha: 0.75),
        ),
      ),
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// Detected obstacles (cables, shoes, pet waste…): orange marker; with a photo, a white dot in the middle.
  void _drawObstacles(Canvas canvas) {
    final r = 5 * textScale;
    for (final o in map.obstacles) {
      final at = _proj.toCanvas(o.position);
      canvas.drawCircle(at, r * 1.6, Paint()..color = const Color(0xFFE0703C).withValues(alpha: 0.25));
      canvas.drawCircle(at, r, Paint()..color = const Color(0xFFE0703C));
      canvas.drawCircle(
        at,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.3
          ..color = Colors.white,
      );
      if (o.photo != null) canvas.drawCircle(at, r * 0.35, Paint()..color = Colors.white);
    }
  }

  void _drawPath(Canvas canvas) {
    final points = pathOverride ?? map.path;
    if (points.length < 2) return;
    final p = Path();
    final first = _proj.toCanvas(points.first);
    p.moveTo(first.dx, first.dy);
    for (final pt in points.skip(1)) {
      final o = _proj.toCanvas(pt);
      p.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlightPath ? 0.7 : 0.35
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = highlightPath ? style.robot.withValues(alpha: 0.9) : style.path,
    );
  }

  void _drawLabels(Canvas canvas) {
    for (final room in geometry.rooms.values) {
      final name = roomNames[room.id] ?? '${room.id}';
      final active = room.id == currentRoom;
      final tp = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: name,
          style: TextStyle(
            fontFamily: style.fontFamily,
            fontSize: 13 * textScale,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            color: style.label,
            shadows: [Shadow(color: style.labelHalo, blurRadius: 4 * textScale)],
          ),
        ),
      )..layout();
      // Order number and name form one label, centred as a whole (not just the text).
      final order = selectedRooms.indexOf(room.id);
      final badge = order >= 0 ? 16 * textScale : 0.0;
      final gap = order >= 0 ? 4 * textScale : 0.0;
      final width = badge + gap + tp.width;
      var rect = Rect.fromCenter(center: room.labelAnchor, width: width, height: tp.height);
      // The robot covers the name when it is on top of it: the label moves below the robot.
      final robot = map.robot == null ? null : _proj.toCanvas(map.robot!);
      final robotRadius = 9 * textScale * 1.9;
      if (robot != null && rect.inflate(robotRadius).contains(robot)) {
        rect = rect.shift(Offset(robot.dx - rect.center.dx, robot.dy + robotRadius + tp.height / 2 - rect.center.dy));
      }
      if (order >= 0) _drawBadge(canvas, Offset(rect.left + badge / 2, rect.center.dy), '${order + 1}');
      tp.paint(canvas, Offset(rect.left + badge + gap, rect.top));
    }
  }

  void _drawBadge(Canvas canvas, Offset center, String text) {
    final r = 8 * textScale;
    canvas.drawCircle(center, r, Paint()..color = style.robot);
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: style.fontFamily,
          fontSize: 10 * textScale,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawCharger(Canvas canvas, Offset at) {
    final r = 7 * textScale;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: r * 1.6, height: r * 1.6), Radius.circular(r * 0.4)),
      Paint()..color = style.label.withValues(alpha: 0.85),
    );
    final bolt = Path()
      ..moveTo(at.dx + r * 0.1, at.dy - r * 0.6)
      ..lineTo(at.dx - r * 0.35, at.dy + r * 0.1)
      ..lineTo(at.dx, at.dy + r * 0.1)
      ..lineTo(at.dx - r * 0.1, at.dy + r * 0.6)
      ..lineTo(at.dx + r * 0.35, at.dy - r * 0.1)
      ..lineTo(at.dx, at.dy - r * 0.1)
      ..close();
    canvas.drawPath(bolt, Paint()..color = style.background);
  }

  void _drawRobot(Canvas canvas, Offset at, int angle) {
    final r = 9 * textScale;
    canvas.drawCircle(at, r * 1.9, Paint()..color = style.robot.withValues(alpha: 0.16));
    canvas.drawCircle(at, r, Paint()..color = Colors.white);
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.28
        ..color = style.robot,
    );
    // On the map y is flipped, and so is the angle.
    final a = -angle * math.pi / 180;
    canvas.drawCircle(at + Offset(math.cos(a), math.sin(a)) * r * 0.5, r * 0.22, Paint()..color = style.robot);
  }

  @override
  bool shouldRepaint(MapPainter old) =>
      old.map != map ||
      old.currentRoom != currentRoom ||
      old.doneRooms != doneRooms ||
      !listEquals(old.selectedRooms, selectedRooms) ||
      old.style.background != style.background ||
      old.textScale != textScale;
}
