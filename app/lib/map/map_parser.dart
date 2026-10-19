import 'dart:typed_data';

import 'package:archive/archive.dart' show GZipDecoder;

import 'robot_map.dart';

/// Parser for Roborock's V1 map format ("rr" + little-endian blocks).
/// Ported from vacuum_map_parser_roborock.
class MapParser {
  static const _charger = 1;
  static const _image = 2;
  static const _path = 3;
  static const _gotoPath = 4;
  static const _predictedPath = 5;
  static const _cleanedZones = 6;
  static const _gotoTarget = 7;
  static const _robotPosition = 8;
  static const _noGoAreas = 9;
  static const _virtualWalls = 10;
  static const _noMopAreas = 12;
  static const _obstacles = 13;
  static const _obstaclesWithPhoto = 15;
  static const _submap = 17;
  static const _mopPath = 18;
  static const _noCarpetAreas = 19;
  // Saros 20 blocks the reference library does not know (decoded from real maps).
  static const _furniture = 25; // n × 23 bytes: 4 cantos u16 + 7 bytes (id, ordem)
  static const _thresholds = 28; // n × 16 bytes: 4 cantos u16
  static const _digest = 1024;

  /// Accepts the map as the robot sends it (gzip) or already decompressed.
  static RobotMap parse(Uint8List input) {
    final raw = input.length > 2 && input[0] == 0x1f && input[1] == 0x8b
        ? Uint8List.fromList(GZipDecoder().decodeBytes(input))
        : input;
    final r = _Reader(raw);
    if (raw.length < 0x14 || raw[0] != 0x72 || raw[1] != 0x72) {
      throw const FormatException('not a Roborock map');
    }

    MapPoint? charger, robot, gotoTarget;
    var path = <MapPoint>[], gotoPath = <MapPoint>[], predicted = <MapPoint>[];
    List<bool>? mopMask;
    var walls = <MapLine>[], zones = <MapLine>[];
    var noGo = <MapArea>[], noMop = <MapArea>[], noCarpet = <MapArea>[];
    final obstacles = <MapObstacle>[];
    var furniture = <MapFurniture>[];
    var thresholds = <MapArea>[];
    Uint8List? submap;
    ({int headerLen, int dataStart, int dataLen})? image;
    var valid = false;

    var pos = r.u16(0x02);
    while (pos + 8 <= raw.length) {
      final headerLen = r.u16(pos + 0x02);
      final type = r.u16(pos);
      final dataLen = r.u32(pos + 0x04);
      final dataStart = pos + headerLen;
      if (dataStart + dataLen > raw.length) break;
      switch (type) {
        case _charger:
          charger = r.objectPosition(dataStart, dataLen);
        case _robotPosition:
          robot = r.objectPosition(dataStart, dataLen);
        case _image:
          image = (headerLen: headerLen, dataStart: dataStart, dataLen: dataLen);
        case _path:
          path = r.path(pos);
        case _gotoPath:
          gotoPath = r.path(pos);
        case _predictedPath:
          predicted = r.path(pos);
        case _cleanedZones:
          zones = r.lines(dataStart, r.u16(pos + 0x08));
        case _gotoTarget:
          gotoTarget = MapPoint(r.u16(dataStart), r.u16(dataStart + 2));
        case _virtualWalls:
          walls = r.lines(dataStart, r.u16(pos + 0x08));
        case _noGoAreas:
          noGo = r.areas(dataStart, r.u16(pos + 0x08));
        case _noMopAreas:
          noMop = r.areas(dataStart, r.u16(pos + 0x08));
        case _noCarpetAreas:
          noCarpet = r.areas(dataStart, r.u16(pos + 0x08));
        case _obstacles:
        case _obstaclesWithPhoto:
          obstacles.addAll(r.obstacles(dataStart, dataLen, r.u16(pos + 0x08)));
        case _submap:
          submap = Uint8List.sublistView(raw, dataStart, dataStart + dataLen);
        case _mopPath:
          mopMask = [for (var i = 0; i < dataLen; i++) raw[dataStart + i] != 0];
        case _furniture:
          furniture = r.furniture(dataStart, r.u16(pos + 0x08), dataLen);
        case _thresholds:
          thresholds = r.quads(dataStart, r.u16(pos + 0x08), dataLen);
        case _digest:
          valid = true;
      }
      // As in the reference parser: the step only uses the low byte of the header length.
      pos += raw[pos + 2] + dataLen;
    }

    MapGrid? grid;
    final rooms = <int, RoomBounds>{};
    if (image != null) {
      final h = image.headerLen;
      final base = image.dataStart - h;
      final top = r.i32(base + h - 16);
      final left = r.i32(base + h - 12);
      final height = r.i32(base + h - 8);
      final width = r.i32(base + h - 4);
      if (width > 0 && height > 0 && width * height <= image.dataLen) {
        final cells = Uint8List.sublistView(raw, image.dataStart, image.dataStart + width * height);
        grid = MapGrid(
          left: left,
          top: top,
          width: width,
          height: height,
          cells: cells,
          submap: submap != null && submap.length >= cells.length ? submap : null,
        );
        rooms.addAll(_roomBounds(grid));
      }
    }

    return RobotMap(
      majorVersion: r.u16(0x08),
      minorVersion: r.u16(0x0A),
      mapIndex: r.u32(0x0C),
      mapSequence: r.u32(0x10),
      grid: grid,
      rooms: rooms,
      charger: charger,
      robot: robot,
      path: path,
      mopMask: mopMask,
      gotoPath: gotoPath,
      predictedPath: predicted,
      gotoTarget: gotoTarget,
      virtualWalls: walls,
      noGoAreas: noGo,
      noMopAreas: noMop,
      noCarpetAreas: noCarpet,
      cleanedZones: zones,
      obstacles: obstacles,
      furniture: furniture,
      thresholds: thresholds,
      valid: valid,
    );
  }

  static Map<int, RoomBounds> _roomBounds(MapGrid g) {
    final minX = <int, int>{}, minY = <int, int>{}, maxX = <int, int>{}, maxY = <int, int>{};
    for (var row = 0; row < g.height; row++) {
      for (var col = 0; col < g.width; col++) {
        final id = g.roomAt(col, row);
        if (id == null) continue;
        minX[id] = col < (minX[id] ?? col) ? col : (minX[id] ?? col);
        minY[id] ??= row;
        maxX[id] = col > (maxX[id] ?? col) ? col : (maxX[id] ?? col);
        maxY[id] = row;
      }
    }
    const s = RobotMap.pixelSize;
    return {
      for (final id in minX.keys)
        id: RoomBounds(
          id,
          (minX[id]! + g.left) * s,
          (minY[id]! + g.top) * s,
          (maxX[id]! + g.left) * s,
          (maxY[id]! + g.top) * s,
        ),
    };
  }
}

class _Reader {
  final Uint8List b;
  final ByteData d;

  _Reader(this.b) : d = ByteData.sublistView(b);

  int u16(int at) => d.getUint16(at, Endian.little);

  int u32(int at) => d.getUint32(at, Endian.little);

  int i32(int at) => d.getInt32(at, Endian.little);

  MapPoint objectPosition(int at, int len) {
    int? angle;
    if (len > 8) {
      angle = u32(at + 8);
      if (angle > 0xFF) angle = (angle & 0xFF) - 256;
    }
    return MapPoint(u32(at), u32(at + 4), angle);
  }

  /// In the path block the data length is at +4 and the points start at +0x14.
  List<MapPoint> path(int blockStart) {
    final len = u32(blockStart + 0x04);
    final start = blockStart + 0x14;
    return [for (var p = start; p + 4 <= start + len; p += 4) MapPoint(u16(p), u16(p + 2))];
  }

  List<MapLine> lines(int at, int count) => [
    for (var i = 0; i < count; i++)
      MapLine(MapPoint(u16(at + i * 8), u16(at + i * 8 + 2)), MapPoint(u16(at + i * 8 + 4), u16(at + i * 8 + 6))),
  ];

  List<MapArea> areas(int at, int count) => [
    for (var i = 0; i < count; i++)
      MapArea([for (var c = 0; c < 4; c++) MapPoint(u16(at + i * 16 + c * 4), u16(at + i * 16 + c * 4 + 2))]),
  ];

  /// Furniture: per item, 4 u16 corners then extra bytes; byte 18 is the type (confirmed against the
  /// official app), byte 21 the order.
  List<MapFurniture> furniture(int at, int count, int len) {
    final areas = quads(at, count, len);
    if (areas.isEmpty) return const [];
    final stride = len ~/ count;
    return [for (var i = 0; i < areas.length; i++) MapFurniture(areas[i], stride > 18 ? b[at + i * stride + 18] : 0)];
  }

  /// Quadrilaterals (4 u16 corners) with stride = len / count (some blocks carry extra bytes per item).
  List<MapArea> quads(int at, int count, int len) {
    if (count == 0) return const [];
    final stride = len ~/ count;
    if (stride < 16) return const [];
    return [
      for (var i = 0; i < count; i++)
        MapArea([for (var c = 0; c < 4; c++) MapPoint(u16(at + i * stride + c * 4), u16(at + i * stride + c * 4 + 2))]),
    ];
  }

  List<MapObstacle> obstacles(int at, int len, int count) {
    if (count == 0) return const [];
    final size = len ~/ count;
    return [
      for (var i = 0; i < count; i++)
        MapObstacle(
          MapPoint(u16(at + i * size), u16(at + i * size + 2)),
          type: size >= 6 ? u16(at + i * size + 4) : null,
          photo: size == 28 && b[at + i * size + 12] > 0
              ? String.fromCharCodes(b.sublist(at + i * size + 12, at + i * size + 28)).replaceAll('\x00', '')
              : null,
        ),
    ];
  }
}
