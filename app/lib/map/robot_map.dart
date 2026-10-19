import 'dart:typed_data';

/// Coordinates in robot units (mm). Each grid pixel is [RobotMap.pixelSize] units.
class MapPoint {
  final int x;
  final int y;

  /// Heading in degrees, when the block includes it (robot and dock).
  final int? angle;

  const MapPoint(this.x, this.y, [this.angle]);
}

class MapLine {
  final MapPoint a;
  final MapPoint b;

  const MapLine(this.a, this.b);
}

/// Quadrilateral (no-go, no-mop, no-carpet zones). The 4 corners come in the robot's order.
class MapArea {
  final List<MapPoint> corners;

  const MapArea(this.corners);
}

class MapObstacle {
  final MapPoint position;
  final int? type;
  final String? photo;

  const MapObstacle(this.position, {this.type, this.photo});
}

/// Furniture recognised by the robot: rectangle and type code (byte of Saros 20 block 25).
class MapFurniture {
  final MapArea area;
  final int type;

  const MapFurniture(this.area, this.type);
}

class RoomBounds {
  final int id;
  final int x0, y0, x1, y1;

  const RoomBounds(this.id, this.x0, this.y0, this.x1, this.y1);
}

enum CellKind { outside, wall, floor, scanned, room, unknown }

/// Occupancy grid. Row 0 is the bottom one (y grows upwards, like robot coordinates).
class MapGrid {
  final int left;
  final int top;
  final int width;
  final int height;
  final Uint8List cells;

  /// Submap bits per cell: 1 = carpet, 8|16 = removed area.
  final Uint8List? submap;

  const MapGrid({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.cells,
    this.submap,
  });

  int raw(int col, int row) => cells[col + width * row];

  CellKind kind(int col, int row) => kindOf(raw(col, row));

  /// Room id of the cell, or null if it belongs to none.
  int? roomAt(int col, int row) {
    final v = raw(col, row);
    return kindOf(v) == CellKind.room ? v >> 3 : null;
  }

  /// Room the cell belongs to, even if it is a wall or obstacle inside it.
  /// The high bits hold the room id; the low 3 bits the cell type.
  int? roomTagAt(int col, int row) {
    final v = raw(col, row);
    if (v == 0x00 || v == 0x01 || v == 0x07 || v == 0xFF) return null;
    final id = v >> 3;
    return id == 0 ? null : id;
  }

  bool isCarpet(int col, int row) => ((submap?[col + width * row] ?? 0) & 1) != 0;

  bool isRemoved(int col, int row) => ((submap?[col + width * row] ?? 0) & (8 | 16)) != 0;

  static CellKind kindOf(int v) {
    switch (v) {
      case 0x00:
        return CellKind.outside;
      case 0x01:
        return CellKind.wall;
      case 0xFF:
        return CellKind.floor;
      case 0x07:
        return CellKind.scanned;
    }
    switch (v & 0x07) {
      case 0:
      case 1:
        return CellKind.wall;
      case 7:
        return CellKind.room;
    }
    return CellKind.unknown;
  }
}

class RobotMap {
  static const pixelSize = 50;

  final int majorVersion;
  final int minorVersion;
  final int mapIndex;
  final int mapSequence;
  final MapGrid? grid;
  final Map<int, RoomBounds> rooms;
  final MapPoint? charger;
  final MapPoint? robot;
  final List<MapPoint> path;

  /// Mask parallel to [path]: true where the robot passed with the mop.
  final List<bool>? mopMask;
  final List<MapPoint> gotoPath;
  final List<MapPoint> predictedPath;
  final MapPoint? gotoTarget;
  final List<MapLine> virtualWalls;
  final List<MapArea> noGoAreas;
  final List<MapArea> noMopAreas;
  final List<MapArea> noCarpetAreas;
  final List<MapLine> cleanedZones;
  final List<MapObstacle> obstacles;

  /// Furniture recognised by the robot (Saros 20 block 25).
  final List<MapFurniture> furniture;

  /// Detected door sills ("potential threshold" in the official app; block 28).
  final List<MapArea> thresholds;
  final bool valid;

  const RobotMap({
    required this.majorVersion,
    required this.minorVersion,
    required this.mapIndex,
    required this.mapSequence,
    this.grid,
    this.rooms = const {},
    this.charger,
    this.robot,
    this.path = const [],
    this.mopMask,
    this.gotoPath = const [],
    this.predictedPath = const [],
    this.gotoTarget,
    this.virtualWalls = const [],
    this.noGoAreas = const [],
    this.noMopAreas = const [],
    this.noCarpetAreas = const [],
    this.cleanedZones = const [],
    this.obstacles = const [],
    this.furniture = const [],
    this.thresholds = const [],
    this.valid = false,
  });

  /// Room the robot is in, if any.
  int? get robotRoom {
    final g = grid, r = robot;
    if (g == null || r == null) return null;
    final col = (r.x / pixelSize).round() - g.left;
    final row = (r.y / pixelSize).round() - g.top;
    if (col < 0 || row < 0 || col >= g.width || row >= g.height) return null;
    return g.roomAt(col, row);
  }
}
