import 'package:aspira/map/restrictions.dart';
import 'package:aspira/map/robot_map.dart';
import 'package:flutter_test/flutter_test.dart';

/// Formats confirmed on the Saros 20 with save_map (zone created, read back from the map, deleted).
void main() {
  test('no-go zone, wall and no-mop zone in the robot format', () {
    final all = [
      Restriction.rect(RestrictionKind.noGo, 23000, 23900, 23200, 24100),
      const Restriction(RestrictionKind.wall, [MapPoint(23000, 23900), MapPoint(23300, 23900)]),
      Restriction.rect(RestrictionKind.noMop, 23000, 24300, 23200, 24500),
    ];
    expect(Restriction.toSaveMap(all), [
      [0, 23000, 23900, 23200, 23900, 23200, 24100, 23000, 24100],
      [1, 23000, 23900, 23300, 23900],
      [2, 23000, 24300, 23200, 24300, 23200, 24500, 23000, 24500],
    ]);
  });

  test('saving no restrictions deletes them all', () {
    expect(Restriction.toSaveMap(const []), isEmpty);
  });

  test('a tap finds the restriction (topmost wins); outside all of them, none', () {
    final all = [
      Restriction.rect(RestrictionKind.noGo, 0, 0, 1000, 1000),
      Restriction.rect(RestrictionKind.noMop, 500, 500, 1500, 1500),
      const Restriction(RestrictionKind.wall, [MapPoint(3000, 0), MapPoint(3000, 2000)]),
    ];
    expect(Restriction.hitTest(all, const MapPoint(200, 200)), 0);
    expect(Restriction.hitTest(all, const MapPoint(700, 700)), 1, reason: 'overlapping: the newest');
    expect(Restriction.hitTest(all, const MapPoint(3150, 1000)), 2, reason: 'near the wall');
    expect(Restriction.hitTest(all, const MapPoint(2500, 1000)), isNull);
  });
}
