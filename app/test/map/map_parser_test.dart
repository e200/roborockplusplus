import 'dart:convert';
import 'dart:io';

import 'package:aspira/map/map_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compared with what vacuum_map_parser_roborock extracts from the same real map (Saros 20, a288).
void main() {
  // The real home map is private and not in the repository: without it these tests are skipped.
  if (!File('test/fixtures/map_a288.bin').existsSync()) {
    test('mapa real', () {}, skip: 'missing test/fixtures/map_a288.bin (private map, not in the repository)');
    return;
  }
  final map = MapParser.parse(File('test/fixtures/map_a288.bin').readAsBytesSync());
  final ref = jsonDecode(File('test/fixtures/map_a288.json').readAsStringSync()) as Map<String, dynamic>;

  test('grid', () {
    final img = ref['image'] as Map<String, dynamic>;
    expect(map.grid!.top, img['top']);
    expect(map.grid!.left, img['left']);
    expect(map.grid!.height, img['height']);
    expect(map.grid!.width, img['width']);
    expect(map.valid, isTrue);
    expect(map.mapIndex, ref['map_index']);
  });

  test('rooms and bounds', () {
    final rooms = (ref['rooms'] as Map<String, dynamic>).map((k, v) => MapEntry(int.parse(k), List<int>.from(v)));
    expect(map.rooms.keys.toSet(), rooms.keys.toSet());
    for (final MapEntry(:key, :value) in rooms.entries) {
      final r = map.rooms[key]!;
      expect([r.x0, r.y0, r.x1, r.y1], value, reason: 'room $key');
    }
  });

  test('dock, robot and path', () {
    expect([map.charger!.x, map.charger!.y, map.charger!.angle], ref['charger']);
    expect([map.robot!.x, map.robot!.y, map.robot!.angle], ref['robot']);
    expect(map.path, hasLength(ref['path_points']));
    expect([map.path.first.x, map.path.first.y], ref['path_first']);
    expect(map.robotRoom, ref['vacuum_room']);
  });

  test('obstacles with photos (block 15) are read', () {
    expect(map.obstacles, isNotEmpty);
    final o = map.obstacles.first;
    expect(o.position.x, inInclusiveRange(map.grid!.left * 50, (map.grid!.left + map.grid!.width) * 50));
  });

  test('Saros 20 furniture (block 25) and door sills (block 28)', () {
    expect(map.furniture, hasLength(5));
    expect(map.furniture.map((f) => f.type).toList(), [
      44,
      44,
      45,
      46,
      47,
    ], reason: 'two hidden bathroom items, bed, sofa, table');
    final big = map.furniture[2].area.corners;
    expect([big[0].x, big[0].y, big[2].x, big[2].y], [34800, 18000, 32750, 19550], reason: '2.05 × 1.55 m piece');
    expect(map.thresholds, hasLength(2));
    expect([map.thresholds[0].corners[0].x, map.thresholds[0].corners[0].y], [30345, 22780]);
  });

  test('carpets and restrictions', () {
    final g = map.grid!;
    var carpets = 0;
    for (var row = 0; row < g.height; row++) {
      for (var col = 0; col < g.width; col++) {
        if (g.isCarpet(col, row)) carpets++;
      }
    }
    expect(carpets, ref['carpet_cells']);
    expect(map.virtualWalls, hasLength(ref['walls']));
    expect(map.noGoAreas, hasLength(ref['no_go']));
  });
}
