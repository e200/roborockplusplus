/// One clean as the robot stores it (it only keeps the last ~21), plus what the app measured.
class CleanRecord {
  final int begin;
  final int end;
  final int durationSeconds;
  final int areaMm2;
  final bool complete;
  final int finishReason;
  final int startType;
  final int cleanType;
  final int washCount;
  final int avoidCount;
  final bool hasOmission;

  /// Seconds per room, measured by the app during the clean (the robot does not store this).
  final Map<int, int> roomSeconds;

  /// Rooms requested by the app, when the app started the clean.
  final List<int> rooms;

  const CleanRecord({
    required this.begin,
    required this.end,
    required this.durationSeconds,
    required this.areaMm2,
    required this.complete,
    required this.finishReason,
    required this.startType,
    required this.cleanType,
    required this.washCount,
    required this.avoidCount,
    required this.hasOmission,
    this.roomSeconds = const {},
    this.rooms = const [],
  });

  factory CleanRecord.fromRobot(Map<String, dynamic> m) => CleanRecord(
    begin: m['begin'] ?? 0,
    end: m['end'] ?? 0,
    durationSeconds: m['duration'] ?? 0,
    areaMm2: m['area'] ?? 0,
    complete: m['complete'] == 1,
    finishReason: m['finish_reason'] ?? 0,
    startType: m['start_type'] ?? 0,
    cleanType: m['clean_type'] ?? 0,
    washCount: m['wash_count'] ?? 0,
    avoidCount: m['avoid_count'] ?? 0,
    hasOmission: m['has_omission'] == 1,
  );

  factory CleanRecord.fromJson(Map<String, dynamic> j) => CleanRecord(
    begin: j['begin'],
    end: j['end'],
    durationSeconds: j['duration'],
    areaMm2: j['area'],
    complete: j['complete'],
    finishReason: j['finishReason'],
    startType: j['startType'],
    cleanType: j['cleanType'],
    washCount: j['washCount'],
    avoidCount: j['avoidCount'],
    hasOmission: j['hasOmission'],
    roomSeconds: {for (final e in (j['roomSeconds'] as Map? ?? {}).entries) int.parse(e.key): e.value as int},
    rooms: [for (final r in (j['rooms'] as List? ?? const [])) r as int],
  );

  Map<String, dynamic> toJson() => {
    'begin': begin,
    'end': end,
    'duration': durationSeconds,
    'area': areaMm2,
    'complete': complete,
    'finishReason': finishReason,
    'startType': startType,
    'cleanType': cleanType,
    'washCount': washCount,
    'avoidCount': avoidCount,
    'hasOmission': hasOmission,
    'roomSeconds': {for (final e in roomSeconds.entries) '${e.key}': e.value},
    'rooms': rooms,
  };

  CleanRecord withAppData({Map<int, int>? roomSeconds, List<int>? rooms}) => CleanRecord(
    begin: begin,
    end: end,
    durationSeconds: durationSeconds,
    areaMm2: areaMm2,
    complete: complete,
    finishReason: finishReason,
    startType: startType,
    cleanType: cleanType,
    washCount: washCount,
    avoidCount: avoidCount,
    hasOmission: hasOmission,
    roomSeconds: roomSeconds ?? this.roomSeconds,
    rooms: rooms ?? this.rooms,
  );

  DateTime get startedAt => DateTime.fromMillisecondsSinceEpoch(begin * 1000);

  double get areaM2 => areaMm2 / 1e6;

  RecordOutcome get outcome => complete
      ? RecordOutcome.finished
      : switch (finishReason) {
          61 || 62 => RecordOutcome.unreachable,
          45 || 65 => RecordOutcome.lostLocation,
          67 || 68 => RecordOutcome.washError,
          _ => RecordOutcome.interrupted,
        };

  RecordSource get source => switch (startType) {
    1 => RecordSource.button,
    2 => RecordSource.app,
    3 => RecordSource.schedule,
    101 => RecordSource.routine,
    >= 801 && <= 811 => RecordSource.voice,
    _ => RecordSource.other,
  };
}

enum RecordOutcome { finished, unreachable, lostLocation, washError, interrupted }

/// What started a clean (`start_type`).
enum RecordSource { button, app, schedule, routine, voice, other }
