import 'package:aspira/queue/clean_job.dart';
import 'package:aspira/routines/routine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const job = CleanJob(id: 'j', rooms: [7], settings: CleanSettings.smart);
  // Segunda-feira, 19/10/2026.
  final monday9 = DateTime(2026, 10, 19, 9, 0);
  const r = Routine(id: 'r', name: 'Morning', jobs: [job], days: {1, 3, 5}, hour: 9, minute: 0);

  test('starts at the set time on the right day', () {
    expect(dueRoutines([r], {}, monday9), [r]);
    expect(dueRoutines([r], {}, monday9.add(const Duration(minutes: 10))), [
      r,
    ], reason: 'tolera a app acordar mais tarde');
  });

  test('does not start early, on other days, or much later', () {
    expect(dueRoutines([r], {}, monday9.subtract(const Duration(minutes: 1))), isEmpty);
    expect(dueRoutines([r], {}, monday9.add(const Duration(days: 1))), isEmpty, reason: 'Tuesday is not selected');
    expect(dueRoutines([r], {}, monday9.add(const Duration(hours: 2))), isEmpty);
  });

  test('does not repeat the same day, but starts again on the next selected day', () {
    final last = {'r': monday9.add(const Duration(minutes: 1))};
    expect(dueRoutines([r], last, monday9.add(const Duration(minutes: 5))), isEmpty);
    final wednesday9 = monday9.add(const Duration(days: 2));
    expect(dueRoutines([r], last, wednesday9), [r]);
  });

  test('a disabled or unscheduled routine never starts on its own', () {
    expect(dueRoutines([r.copyWith(enabled: false)], {}, monday9), isEmpty);
    expect(dueRoutines([r.copyWith(days: {})], {}, monday9), isEmpty);
  });

  test('round-trips through JSON without losing anything', () {
    final back = Routine.fromJson(r.toJson());
    expect(back.toJson(), r.toJson());
  });
}
