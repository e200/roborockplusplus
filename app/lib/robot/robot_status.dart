/// Robot state from `get_status` (Saros 20, V1 protocol).
class RobotStatus {
  final int state;
  final int battery;
  final int inCleaning;
  final bool inReturning;
  final int cleanPercent;
  final int errorCode;
  final int fanPower;
  final int waterMode;
  final int mopRoute;
  final int dockError;
  final bool waterShortage;

  /// Room being cleaned now (`cleaning_info.segment_id`), or null.
  final int? currentRoom;

  /// Suction/water in use by the current task, which may differ from the defaults.
  final int? activeFanPower;
  final int? activeWaterMode;

  const RobotStatus({
    required this.state,
    required this.battery,
    required this.inCleaning,
    required this.inReturning,
    required this.cleanPercent,
    required this.errorCode,
    required this.fanPower,
    required this.waterMode,
    required this.mopRoute,
    this.dockError = 0,
    this.waterShortage = false,
    this.currentRoom,
    this.activeFanPower,
    this.activeWaterMode,
  });

  factory RobotStatus.fromJson(Map<String, dynamic> j) {
    final info = j['cleaning_info'] is Map ? j['cleaning_info'] as Map : const {};
    final seg = info['segment_id'];
    return RobotStatus(
      state: j['state'] ?? 0,
      battery: j['battery'] ?? 0,
      inCleaning: j['in_cleaning'] ?? 0,
      inReturning: (j['in_returning'] ?? 0) != 0,
      cleanPercent: j['clean_percent'] ?? 0,
      errorCode: j['error_code'] ?? 0,
      fanPower: j['fan_power'] ?? 0,
      waterMode: j['water_box_mode'] ?? 0,
      mopRoute: j['mop_mode'] ?? 0,
      dockError: j['dock_error_status'] ?? 0,
      waterShortage: (j['water_shortage_status'] ?? 0) != 0,
      currentRoom: seg is int && seg > 0 ? seg : null,
      activeFanPower: info['fan_power'] is int ? info['fan_power'] : null,
      activeWaterMode: info['water_box_status'] is int ? info['water_box_status'] : null,
    );
  }

  /// A task is running (including mop washes and dock trips mid-clean).
  bool get busy => inCleaning != 0;

  bool get docked => const {8, 100, 22, 23, 25, 26}.contains(state) && !busy;
}
