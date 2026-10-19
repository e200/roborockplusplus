import 'dart:ui';

import 'package:aspira/l10n/l10n.dart';
import 'package:aspira/robot/robot_settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reply and write formats verified on the Saros 20 (writes sent with unchanged values).
void main() {
  final all = {for (final s in robotSettings(lookupL10n(const Locale('en')))) s.id: s};
  const dryer = [
    {
      'status': 1,
      'on': {'cliff_on': 1000, 'count': 10, 'dry_time': 7200, 'dry_heating_film_time': 3600},
      'off': {'cliff_on': 500},
    },
  ];

  test('drying time is read from `on` and written with the current status', () {
    expect(all['dry_time']!.read(dryer), 7200);
    final w = all['dry_time']!.write(10800, dryer);
    expect(w.method, 'app_set_dryer_setting');
    expect(w.params, {
      'on': {'dry_time': 10800},
      'status': 1,
    });
  });

  test('the dryer switch keeps the current drying time', () {
    expect(all['dryer']!.write(0, dryer).params, {
      'on': {'dry_time': 7200},
      'status': 0,
    });
  });

  test('mop wash water temperature', () {
    expect(
      all['water_temp']!.read([
        {'wash_water_temperature': 1},
      ]),
      1,
    );
    final w = all['water_temp']!.write(2, null);
    expect(
      [w.method, w.params],
      [
        'set_wash_water_temperature',
        {'values': 2},
      ],
    );
  });
}
