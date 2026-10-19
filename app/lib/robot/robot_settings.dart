import '../l10n/strings.dart';
import 'robot_client.dart';

/// A robot setting: how to read it from the `get_*` reply and how to write it.
/// Formats confirmed on the Saros 20 (reads) and in python-roborock (writes).
enum SettingSection { carpets, dock, cleaning, robot }

String sectionLabel(L10n l, SettingSection s) => switch (s) {
  SettingSection.carpets => l.sectionCarpets,
  SettingSection.dock => l.sectionDock,
  SettingSection.cleaning => l.sectionCleaning,
  SettingSection.robot => l.sectionRobot,
};

class RobotSetting {
  final String id;
  final SettingSection section;
  final String title;
  final String? subtitle;
  final String readMethod;

  /// Options (value → name). Null = on/off switch (1/0).
  final Map<int, String>? options;
  final int? Function(Object? raw) read;

  /// Write command; it also receives the reply that was read, to keep fields that do not change.
  final ({String method, Object params}) Function(int value, Object? raw) write;

  const RobotSetting({
    required this.id,
    required this.section,
    required this.title,
    this.subtitle,
    required this.readMethod,
    this.options,
    required this.read,
    required this.write,
  });

  bool get isSwitch => options == null;
}

Object? _first(Object? raw) => raw is List && raw.isNotEmpty ? raw.first : raw;

int? _field(Object? raw, String key) {
  final m = _first(raw);
  return m is Map && m[key] is num ? (m[key] as num).toInt() : null;
}

({String method, Object params}) _status(String method, int v, Object? _) => (method: method, params: {'status': v});

/// The settings shown on the Robot tab, with texts in [l]'s language.
List<RobotSetting> robotSettings(L10n l) => [
  RobotSetting(
    id: 'carpet_mode',
    section: SettingSection.carpets,
    title: l.setCarpetMode,
    readMethod: 'get_carpet_clean_mode',
    options: {0: l.optAvoid, 1: l.optLiftMop, 2: l.optIgnore, 3: l.optCross},
    read: (r) => _field(r, 'carpet_clean_mode'),
    write: (v, _) => (method: 'set_carpet_clean_mode', params: {'carpet_clean_mode': v}),
  ),
  RobotSetting(
    id: 'carpet_boost',
    section: SettingSection.carpets,
    title: l.setCarpetBoost,
    readMethod: 'get_carpet_mode',
    read: (r) => _field(r, 'enable'),
    write: (v, raw) => (
      method: 'set_carpet_mode',
      params: [
        {...?(_first(raw) as Map?)?.cast<String, Object?>(), 'enable': v},
      ],
    ),
  ),
  RobotSetting(
    id: 'carpet_deep',
    section: SettingSection.carpets,
    title: l.setCarpetDeep,
    readMethod: 'app_get_carpet_deep_clean_status',
    read: (r) => _field(r, 'status'),
    write: (v, raw) => _status('app_set_carpet_deep_clean_status', v, raw),
  ),
  RobotSetting(
    id: 'auto_empty',
    section: SettingSection.dock,
    title: l.setAutoEmpty,
    readMethod: 'get_dust_collection_switch_status',
    read: (r) => _field(r, 'status'),
    write: (v, raw) => _status('set_dust_collection_switch_status', v, raw),
  ),
  RobotSetting(
    id: 'empty_mode',
    section: SettingSection.dock,
    title: l.setEmptyMode,
    readMethod: 'get_dust_collection_mode',
    options: {0: l.optSmart, 1: l.optLight, 2: l.optBalanced, 4: l.optMax},
    read: (r) => _field(r, 'mode'),
    write: (v, _) => (method: 'set_dust_collection_mode', params: {'mode': v}),
  ),
  RobotSetting(
    id: 'dryer',
    section: SettingSection.dock,
    title: l.setDryer,
    readMethod: 'app_get_dryer_setting',
    read: (r) => _field(r, 'status'),
    write: (v, raw) => _status('app_set_dryer_setting', v, raw),
  ),
  RobotSetting(
    id: 'wash_mode',
    section: SettingSection.dock,
    title: l.setWashMode,
    readMethod: 'get_wash_towel_mode',
    options: {10: l.optSmart, 0: l.optLight, 1: l.optBalanced, 2: l.optDeep, 8: l.optVeryDeep},
    read: (r) => _field(r, 'wash_mode'),
    write: (v, _) => (method: 'set_wash_towel_mode', params: {'wash_mode': v}),
  ),
  RobotSetting(
    id: 'wash_interval',
    section: SettingSection.dock,
    title: l.setWashInterval,
    subtitle: l.setWashIntervalSub,
    readMethod: 'get_smart_wash_params',
    options: {
      for (final m in [10, 15, 20, 25, 30]) m * 60: l.minutes(m),
    },
    read: (r) => _field(r, 'wash_interval'),
    write: (v, raw) =>
        (method: 'set_smart_wash_params', params: {'smart_wash': _field(raw, 'smart_wash') ?? 0, 'wash_interval': v}),
  ),
  RobotSetting(
    id: 'corner_mop',
    section: SettingSection.cleaning,
    title: l.setCornerMop,
    readMethod: 'get_stretch_tag_status',
    read: (r) => _field(r, 'status'),
    write: (v, raw) => _status('set_stretch_tag_status', v, raw),
  ),
  RobotSetting(
    id: 'furniture',
    section: SettingSection.cleaning,
    title: l.setFurniture,
    subtitle: l.setFurnitureSub,
    readMethod: 'get_identify_furniture_status',
    read: (r) => _field(r, 'status'),
    write: (v, raw) => _status('set_identify_furniture_status', v, raw),
  ),
  RobotSetting(
    id: 'led',
    section: SettingSection.robot,
    title: l.setLed,
    readMethod: 'get_led_status',
    read: (r) => (_first(r) as num?)?.toInt(),
    write: (v, _) => (method: 'set_led_status', params: [v]),
  ),
];

/// Do not disturb: hours when the robot neither starts cleans nor speaks.
class DndSchedule {
  final bool enabled;
  final int startHour, startMinute, endHour, endMinute;

  const DndSchedule(this.enabled, this.startHour, this.startMinute, this.endHour, this.endMinute);

  static Future<DndSchedule?> read(RobotClient c) async {
    final m = _first(await c.call('get_dnd_timer'));
    if (m is! Map) return null;
    return DndSchedule(m['enabled'] == 1, m['start_hour'], m['start_minute'], m['end_hour'], m['end_minute']);
  }

  Future<void> write(RobotClient c) =>
      enabled ? c.call('set_dnd_timer', [startHour, startMinute, endHour, endMinute]) : c.call('close_dnd_timer');
}
