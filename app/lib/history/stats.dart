import 'clean_record.dart';

/// One activity chart period (a day, or a week starting on Monday).
class ActivityBucket {
  final DateTime start;
  final int seconds;
  final double areaM2;
  final int count;

  const ActivityBucket(this.start, this.seconds, this.areaM2, this.count);
}

/// The last [count] days (or weeks, with [weeks]) up to [now], oldest first,
/// including periods without cleans (empty bar).
List<ActivityBucket> activity(List<CleanRecord> history, DateTime now, {int count = 14, bool weeks = false}) {
  DateTime startOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return weeks ? day.subtract(Duration(days: day.weekday - 1)) : day;
  }

  final last = startOf(now);
  // By calendar (not 24 h steps), so DST changes do not misalign the days.
  final starts = [for (var i = count - 1; i >= 0; i--) DateTime(last.year, last.month, last.day - i * (weeks ? 7 : 1))];
  final seconds = List.filled(count, 0), counts = List.filled(count, 0), area = List.filled(count, 0.0);
  for (final r in history) {
    final i = starts.indexOf(startOf(r.startedAt));
    if (i < 0) continue;
    seconds[i] += r.durationSeconds;
    area[i] += r.areaM2;
    counts[i]++;
  }
  return [for (var i = 0; i < count; i++) ActivityBucket(starts[i], seconds[i], area[i], counts[i])];
}
