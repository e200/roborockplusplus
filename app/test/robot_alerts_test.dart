import 'dart:ui';

import 'package:aspira/l10n/l10n.dart';
import 'package:aspira/robot/alerts.dart';
import 'package:aspira/robot/robot_status.dart';
import 'package:flutter_test/flutter_test.dart';

RobotStatus s({int error = 0, int dock = 0, bool water = false}) => RobotStatus(
  state: 8,
  battery: 100,
  inCleaning: 0,
  inReturning: false,
  cleanPercent: 0,
  errorCode: error,
  fanPower: 102,
  waterMode: 225,
  mopRoute: 300,
  dockError: dock,
  waterShortage: water,
);

void main() {
  final en = lookupL10n(const Locale('en')), pt = lookupL10n(const Locale('pt'));

  test('alerts once when an error appears, not on every reading', () {
    final d = AlertDetector();
    expect(d.update(s(), en), isEmpty);
    final first = d.update(s(error: 8), en);
    expect(first.single.body, contains('trapped'));
    expect(d.update(s(error: 8), en), isEmpty);
    expect(d.update(s(), en), isEmpty);
    expect(d.update(s(error: 8), en), hasLength(1), reason: 'alerts again if the error comes back');
  });

  test('dock errors, without a duplicate water alert', () {
    final d = AlertDetector();
    expect(d.update(s(dock: 39), en).single.body, contains('Dirty water'));
    expect(d.update(s(dock: 38, water: true), en).map((a) => a.kind), [AlertKind.dockError]);
  });

  test('alert texts follow the language, unknown codes still read well', () {
    expect(robotErrorText(pt, 8), contains('encurralado'));
    expect(dockErrorText(pt, 39), contains('água suja'));
    expect(robotErrorText(en, 999), 'Error 999.');
    expect(robotErrorText(pt, 999), 'Erro 999.');
  });

  test('persisted state avoids repeating an alert after the app/service handover', () {
    final full = RobotStatus.fromJson({'state': 8, 'battery': 100, 'error_code': 0, 'dock_error_status': 39});
    final a = AlertDetector();
    expect(a.update(full, en), hasLength(1));
    final b = AlertDetector.restore(a.toJson());
    expect(b.update(full, en), isEmpty);
  });
}
