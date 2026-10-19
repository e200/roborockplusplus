/// Cleaning settings for a room (or the whole home).
class CleanSettings {
  final int fan;
  final int water;
  final int mopRoute;
  final int repeat;

  /// Vacuum everything first and mop afterwards: the queue runs two passes back to back.
  final bool twoPass;

  const CleanSettings({this.fan = 102, this.water = 225, this.mopRoute = 300, this.repeat = 1, this.twoPass = false});

  static const vacuumThenMop = CleanSettings(fan: 102, water: 235, twoPass: true);

  static const vacuumOnly = CleanSettings(fan: 102, water: 200);

  /// The robot picks suction, water and route by floor type and dirt (the official app's "Smart" mode).
  static const smart = CleanSettings(fan: 110, water: 209, mopRoute: 306);
  static const vacuumAndMop = CleanSettings(fan: 102, water: 225);
  static const mopOnly = CleanSettings(fan: 105, water: 235);

  bool get isSmart => fan == 110;

  CleanSettings copyWith({int? fan, int? water, int? mopRoute, int? repeat, bool? twoPass}) => CleanSettings(
    fan: fan ?? this.fan,
    water: water ?? this.water,
    mopRoute: mopRoute ?? this.mopRoute,
    repeat: repeat ?? this.repeat,
    twoPass: twoPass ?? this.twoPass,
  );

  /// The actual passes: one, or vacuum then mop.
  List<CleanSettings> get passes =>
      twoPass ? [vacuumOnly.copyWith(repeat: repeat), mopOnly.copyWith(water: water, repeat: repeat)] : [this];

  factory CleanSettings.fromJson(Map<String, dynamic> j) => CleanSettings(
    fan: j['fan'],
    water: j['water'],
    mopRoute: j['mopRoute'],
    repeat: j['repeat'],
    twoPass: j['twoPass'] == true,
  );

  Map<String, dynamic> toJson() => {
    'fan': fan,
    'water': water,
    'mopRoute': mopRoute,
    'repeat': repeat,
    if (twoPass) 'twoPass': true,
  };

  @override
  bool operator ==(Object other) =>
      other is CleanSettings &&
      other.fan == fan &&
      other.water == water &&
      other.mopRoute == mopRoute &&
      other.repeat == repeat &&
      other.twoPass == twoPass;

  @override
  int get hashCode => Object.hash(fan, water, mopRoute, repeat, twoPass);
}

/// Rectangle in robot coordinates (mm), for zone cleaning.
class CleanZone {
  final int x0, y0, x1, y1;

  const CleanZone(this.x0, this.y0, this.x1, this.y1);

  factory CleanZone.fromJson(List j) => CleanZone(j[0], j[1], j[2], j[3]);

  List<int> toJson() => [x0, y0, x1, y1];

  double get areaM2 => (x1 - x0).abs() * (y1 - y0).abs() / 1e6;
}

/// A queued job: rooms sharing the same settings, or drawn zones. Neither means the whole home.
class CleanJob {
  final String id;
  final List<int> rooms;
  final List<CleanZone> zones;
  final CleanSettings settings;

  const CleanJob({required this.id, required this.rooms, required this.settings, this.zones = const []});

  factory CleanJob.fromJson(Map<String, dynamic> j) => CleanJob(
    id: j['id'],
    rooms: [for (final r in j['rooms'] as List) r as int],
    zones: [for (final z in (j['zones'] as List? ?? const [])) CleanZone.fromJson(z as List)],
    settings: CleanSettings.fromJson(j['settings']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'rooms': rooms,
    if (zones.isNotEmpty) 'zones': [for (final z in zones) z.toJson()],
    'settings': settings.toJson(),
  };

  /// "Vacuum then mop" becomes two consecutive jobs over the same rooms or zones.
  List<CleanJob> expandPasses(String Function() newId) => [
    for (final (i, p) in settings.passes.indexed)
      CleanJob(id: i == 0 ? id : newId(), rooms: rooms, zones: zones, settings: p),
  ];

  /// A plan with different settings per room becomes one job per group of identical settings,
  /// in the order the rooms were picked.
  static List<CleanJob> fromPlan(List<(int room, CleanSettings settings)> plan, String Function() newId) {
    final jobs = <CleanJob>[];
    for (final (room, settings) in plan) {
      if (jobs.isNotEmpty && jobs.last.settings == settings) {
        jobs[jobs.length - 1] = CleanJob(id: jobs.last.id, rooms: [...jobs.last.rooms, room], settings: settings);
      } else {
        jobs.add(CleanJob(id: newId(), rooms: [room], settings: settings));
      }
    }
    return [for (final j in jobs) ...j.expandPasses(newId)];
  }
}
