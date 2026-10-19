import '../history/clean_record.dart';
import 'robot_client.dart';

/// Saros 20 commands (names taken from the official a288 plugin).
extension RobotCommands on RobotClient {
  Future<void> startWholeHome() => call('app_start');
  Future<void> pause() => call('app_pause');
  Future<void> resume() => call('app_resume');
  Future<void> stop() => call('app_stop');
  Future<void> dock() => call('app_charge');
  Future<void> findMe() => call('find_me');

  Future<void> collectDust() => call('app_start_collect_dust');
  Future<void> washMop() => call('app_start_wash');
  Future<void> stopWash() => call('app_stop_wash');

  /// Suction and water also apply to the running task; the mop route only to the next one (tested on the a288).
  Future<void> setFan(int mode) => call('set_custom_mode', [mode]);
  Future<void> setWater(int mode) => call('set_water_box_custom_mode', [mode]);
  Future<void> setMopRoute(int mode) => call('set_mop_mode', [mode]);

  Future<void> cleanRooms(List<int> rooms, {int repeat = 1}) => call('app_segment_clean', [
    {'segments': rooms, 'repeat': repeat},
  ]);

  /// Zones: `[[x0, y0, x1, y1, passes], ...]` in mm (python-roborock format; accepted by the a288).
  Future<void> cleanZones(List<List<int>> zones, {int repeat = 1}) => call('app_zoned_clean', [
    for (final z in zones) [...z, repeat],
  ]);

  /// Goes to a point and stays there.
  Future<void> goTo(int x, int y) => call('app_goto_target', [x, y]);

  Future<void> spot() => call('app_spot');

  Future<Map<String, int>> consumables() async {
    final res = await call('get_consumable');
    final m = res is List && res.isNotEmpty ? res.first : res;
    return {for (final e in (m as Map).entries) '${e.key}': (e.value as num).toInt()};
  }

  Future<void> resetConsumable(String key) => call('reset_consumable', [key]);

  Future<({int seconds, int areaMm2, int count, List<int> recordIds})> cleanSummary() async {
    final s = await call('get_clean_summary') as Map;
    return (
      seconds: (s['clean_time'] as num).toInt(),
      areaMm2: (s['clean_area'] as num).toInt(),
      count: (s['clean_count'] as num).toInt(),
      recordIds: [for (final r in (s['records'] as List? ?? const [])) (r as num).toInt()],
    );
  }

  Future<CleanRecord?> cleanRecord(int id) async {
    final res = await call('get_clean_record', [id]);
    final m = res is List && res.isNotEmpty ? res.first : null;
    return m is Map ? CleanRecord.fromRobot(Map<String, dynamic>.from(m)) : null;
  }

  Future<int> volume() async {
    final res = await call('get_sound_volume');
    return ((res is List ? res.first : res) as num).toInt();
  }

  Future<void> setVolume(int v) => call('change_sound_volume', [v]);

  Future<bool> childLock() async {
    final res = await call('get_child_lock_status');
    final m = res is List ? res.first : res;
    return m is Map && m['lock_status'] == 1;
  }

  Future<void> setChildLock(bool on) => call('set_child_lock_status', {'lock_status': on ? 1 : 0});
}
