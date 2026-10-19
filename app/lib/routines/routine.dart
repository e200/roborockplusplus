import '../queue/clean_job.dart';

/// A named saved plan (rooms/zones, modes and order) that runs with one tap and can be scheduled.
/// It always runs through the queue, so it never cancels whatever is running.
class Routine {
  final String id;
  final String name;
  final List<CleanJob> jobs;

  /// Weekdays (1 = Monday … 7 = Sunday). Empty = not scheduled.
  final Set<int> days;
  final int hour, minute;
  final bool enabled;

  const Routine({
    required this.id,
    required this.name,
    required this.jobs,
    this.days = const {},
    this.hour = 9,
    this.minute = 0,
    this.enabled = true,
  });

  bool get scheduled => days.isNotEmpty;

  Routine copyWith({String? name, Set<int>? days, int? hour, int? minute, bool? enabled}) => Routine(
    id: id,
    name: name ?? this.name,
    jobs: jobs,
    days: days ?? this.days,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    enabled: enabled ?? this.enabled,
  );

  factory Routine.fromJson(Map<String, dynamic> j) => Routine(
    id: j['id'],
    name: j['name'],
    jobs: [for (final x in j['jobs'] as List) CleanJob.fromJson(Map<String, dynamic>.from(x))],
    days: {for (final d in (j['days'] as List? ?? const [])) d as int},
    hour: j['hour'] ?? 9,
    minute: j['minute'] ?? 0,
    enabled: j['enabled'] != false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'jobs': [for (final x in jobs) x.toJson()],
    'days': days.toList()..sort(),
    'hour': hour,
    'minute': minute,
    'enabled': enabled,
  };
}

/// Which routines should start now. [lastRun] holds when each one last started (so it does not repeat the same
/// day). Tolerates delays up to [grace] (the app may only wake up a few minutes late).
List<Routine> dueRoutines(
  List<Routine> all,
  Map<String, DateTime> lastRun,
  DateTime now, {
  Duration grace = const Duration(minutes: 30),
}) {
  final out = <Routine>[];
  for (final r in all) {
    if (!r.enabled || !r.scheduled || !r.days.contains(now.weekday)) continue;
    final at = DateTime(now.year, now.month, now.day, r.hour, r.minute);
    if (now.isBefore(at) || now.difference(at) > grace) continue;
    final last = lastRun[r.id];
    if (last != null && !last.isBefore(at)) continue; // already started today
    out.add(r);
  }
  return out;
}
