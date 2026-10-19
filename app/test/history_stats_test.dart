import 'package:aspira/history/clean_record.dart';
import 'package:aspira/history/stats.dart';
import 'package:flutter_test/flutter_test.dart';

CleanRecord _rec(DateTime at, int minutes) => CleanRecord(
  begin: at.millisecondsSinceEpoch ~/ 1000,
  end: at.millisecondsSinceEpoch ~/ 1000 + minutes * 60,
  durationSeconds: minutes * 60,
  areaMm2: minutes * 1000000,
  complete: true,
  finishReason: 56,
  startType: 2,
  cleanType: 3,
  washCount: 0,
  avoidCount: 0,
  hasOmission: false,
);

void main() {
  final now = DateTime(2026, 10, 19, 2, 30); // Monday

  test('days: includes empty ones, groups the same day, ignores old ones', () {
    final b = activity(
      [
        _rec(DateTime(2026, 10, 19, 1), 10),
        _rec(DateTime(2026, 10, 19, 0, 5), 20),
        _rec(DateTime(2026, 10, 17, 23, 59), 5),
        _rec(DateTime(2026, 9, 1), 99),
      ],
      now,
      count: 7,
    );
    expect(b, hasLength(7));
    expect(b.last.start, DateTime(2026, 10, 19));
    expect([b.last.count, b.last.seconds], [2, 1800]);
    expect(b[4].count, 1, reason: 'Saturday 17th');
    expect(b[5].count, 0, reason: 'empty Sunday');
  });

  test('weeks start on Monday', () {
    final b = activity(
      [_rec(DateTime(2026, 10, 18, 20), 30), _rec(DateTime(2026, 10, 12, 9), 10)],
      now,
      count: 3,
      weeks: true,
    );
    expect(b.map((x) => x.start).toList(), [DateTime(2026, 10, 5), DateTime(2026, 10, 12), DateTime(2026, 10, 19)]);
    expect(b[1].seconds, 2400, reason: 'Sunday 18th and Monday 12th belong to the week of the 12th');
    expect(b[2].count, 0);
  });

  test('a DST change does not misalign the days', () {
    final b = activity([_rec(DateTime(2026, 10, 25, 12), 10)], DateTime(2026, 10, 27, 12), count: 4);
    expect(b.map((x) => x.start.day).toList(), [24, 25, 26, 27]);
    expect(b[1].count, 1);
  });
}
