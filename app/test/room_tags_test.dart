import 'package:aspira/map/map_view.dart';
import 'package:aspira/robot/robot_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shape of the Saros 20's `get_multi_maps_list` reply (trimmed).
void main() {
  const reply = [
    {
      'max_multi_map': 1,
      'map_info': [
        {
          'mapFlag': 0,
          'rooms': [
            {'id': 2, 'tag': 15, 'iot_name': 'Bathroom'},
            {'id': 5, 'tag': 13, 'iot_name': 'Dining room'},
            {'id': 7, 'tag': 14, 'iot_name': 'Kitchen'},
          ],
        },
      ],
    },
  ];

  test('room types come from the current map', () {
    expect(roomTagsFrom(reply), {2: 15, 5: 13, 7: 14});
    expect(roomTagsFrom(null), isEmpty);
    expect(roomTagsFrom(const ['unknown_method']), isEmpty);
  });

  test('known room types have an icon, unknown ones none', () {
    expect(roomTypeIcon(14), Icons.soup_kitchen_rounded);
    expect(roomTypeIcon(99), isNull);
    expect(roomTypeIcon(null), isNull);
  });
}
