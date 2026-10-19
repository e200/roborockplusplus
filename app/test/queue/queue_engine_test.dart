import 'package:aspira/history/clean_record.dart';
import 'package:aspira/queue/clean_job.dart';
import 'package:aspira/queue/queue_engine.dart';
import 'package:aspira/robot/robot_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/kitchen_run.dart';

class FakeActions implements QueueActions {
  final started = <CleanJob>[];
  bool complete = true;

  @override
  Future<void> run(CleanJob job) async => started.add(job);

  @override
  Future<CleanRecord?> lastRecord() async => CleanRecord(
    begin: 1,
    end: 2,
    durationSeconds: 796,
    areaMm2: 9542500,
    complete: complete,
    finishReason: complete ? 56 : 21,
    startType: 2,
    cleanType: 3,
    washCount: 2,
    avoidCount: 0,
    hasOmission: false,
  );
}

RobotStatus status(List<int> r) => RobotStatus(
  state: r[1],
  battery: 100,
  inCleaning: r[2],
  inReturning: r[3] == 1,
  cleanPercent: 0,
  errorCode: r[5],
  fanPower: 102,
  waterMode: 225,
  mopRoute: 300,
  currentRoom: r[4] > 0 ? r[4] : null,
);

void main() {
  final t0 = DateTime(2026, 10, 18, 21, 27, 26);
  late FakeActions actions;
  late QueueEngine engine;
  late List<(CleanRecord, CleanJob?)> finished;

  setUp(() {
    actions = FakeActions();
    finished = [];
    engine = QueueEngine(actions: actions, onChanged: () {}, onFinished: (r, j) => finished.add((r, j)));
  });

  Future<void> replay(List<List<int>> rows) async {
    for (final r in rows) {
      await engine.onStatus(status(r), t0.add(Duration(seconds: r[0])));
    }
  }

  const kitchen = CleanJob(id: 'a', rooms: [7], settings: CleanSettings());
  const dining = CleanJob(id: 'b', rooms: [5], settings: CleanSettings.vacuumOnly);

  test('starts the next job only when the real clean ends (mop washes and docking do not count)', () async {
    engine.add([kitchen, dining]);
    await replay(kitchenRun.take(kitchenRun.length - 1).toList());
    expect(actions.started.map((j) => j.id), ['a'], reason: 'no next job during the clean and the washes');

    await replay([kitchenRun.last]);
    expect(finished, hasLength(1));
    expect(finished.single.$2?.id, 'a');
    expect(finished.single.$1.roomSeconds[7], greaterThan(10 * 60), reason: '~13 min cleaning the kitchen');

    await replay([
      [kitchenRun.last[0] + 3, 8, 0, 0, -1, 0],
    ]);
    expect(actions.started.map((j) => j.id), ['a', 'b']);
  });

  test('jobs added during a clean wait and cancel nothing', () async {
    engine.add([kitchen]);
    await replay(kitchenRun.take(40).toList());
    engine.add([dining]);
    expect(actions.started.map((j) => j.id), ['a']);
    expect(engine.pending.map((j) => j.id), ['b']);
  });

  test('an interrupted clean pauses the queue', () async {
    actions.complete = false;
    engine.add([kitchen, dining]);
    await replay(kitchenRun);
    await replay([
      [kitchenRun.last[0] + 3, 8, 0, 0, -1, 0],
    ]);
    expect(engine.state, QueueState.paused);
    expect(actions.started.map((j) => j.id), ['a']);
  });

  test('an interrupted clean with nothing else queued does not leave the queue paused', () async {
    actions.complete = false;
    engine.add([kitchen]);
    await replay(kitchenRun);
    expect(engine.state, QueueState.idle);
    expect(finished, hasLength(1));
  });

  test('with the robot idle the job starts on the first reading, and later readings do not repeat it', () async {
    engine.add([kitchen, dining]);
    final idle = [0, 8, 0, 0, -1, 0];
    await replay([idle]);
    expect(actions.started.map((j) => j.id), ['a']);
    // The robot takes a few seconds to become "busy": no second start, and no starting the next job.
    await replay([
      [1, 8, 0, 0, -1, 0],
      [2, 8, 0, 0, -1, 0],
      [5, 8, 0, 0, -1, 0],
    ]);
    expect(actions.started.map((j) => j.id), ['a']);
  });

  test('if the robot does not take the job, the queue pauses instead of insisting', () async {
    engine.add([kitchen]);
    await replay([
      [0, 8, 0, 0, -1, 0],
    ]);
    await replay([
      [QueueEngine.startTimeout.inSeconds + 1, 8, 0, 0, -1, 0],
    ]);
    expect(engine.state, QueueState.paused);
    expect(engine.pending.map((j) => j.id), ['a'], reason: 'the job goes back to the front of the queue');
    expect(actions.started, hasLength(1));
  });

  test('skip: the current task is stopped and the queue moves on without pausing', () async {
    actions.complete = false; // the stop is recorded as interrupted
    engine.add([kitchen, dining]);
    await replay(kitchenRun.take(40).toList());
    expect(engine.skipCurrent(), isTrue);
    await replay([
      [3000, 3, 0, 0, -1, 0],
    ]); // the robot stopped where it was (state 3)
    expect(engine.state, isNot(QueueState.paused));
    await replay([
      [3003, 3, 0, 0, -1, 0],
    ]);
    expect(actions.started.map((j) => j.id), ['a', 'b']);
  });

  test('skip with no running task does nothing', () {
    expect(engine.skipCurrent(), isFalse);
  });

  test('reopening the app mid-clean keeps tracking it (without pausing)', () async {
    engine.add([kitchen, dining]);
    await replay(kitchenRun.take(40).toList());
    final saved = engine.toJson();
    // "Reopen the app": a new engine from what was persisted.
    final reopened = QueueEngine(actions: actions, onChanged: () {}, onFinished: (r, j) => finished.add((r, j)))
      ..restore(saved, now: t0.add(const Duration(seconds: 600)));
    expect(reopened.state, QueueState.running);
    expect(reopened.current?.id, 'a');
    for (final r in kitchenRun.skip(40)) {
      await reopened.onStatus(status(r), t0.add(Duration(seconds: r[0])));
    }
    await reopened.onStatus(
      status([kitchenRun.last[0] + 3, 8, 0, 0, -1, 0]),
      t0.add(Duration(seconds: kitchenRun.last[0] + 3)),
    );
    expect(finished.single.$2?.id, 'a');
    expect(actions.started.map((j) => j.id), ['a', 'b'], reason: 'moves on to the next job');
  });

  test('reopening the app after the clean ended records it and moves on', () async {
    engine.add([kitchen, dining]);
    await replay(kitchenRun.take(40).toList());
    final reopened = QueueEngine(actions: actions, onChanged: () {}, onFinished: (r, j) => finished.add((r, j)))
      ..restore(engine.toJson(), now: t0.add(const Duration(hours: 1)));
    await reopened.onStatus(status([4000, 8, 0, 0, -1, 0]), t0.add(const Duration(hours: 1, seconds: 3)));
    expect(finished, hasLength(1));
    await reopened.onStatus(status([4003, 8, 0, 0, -1, 0]), t0.add(const Duration(hours: 1, seconds: 6)));
    expect(actions.started.map((j) => j.id), ['a', 'b']);
  });

  test('a robot error pauses the queue without starting the next job', () async {
    engine.add([kitchen, dining]);
    await replay(kitchenRun.take(30).toList());
    await replay([
      [2000, 12, 3, 0, 7, 8],
    ]);
    expect(engine.state, QueueState.paused);
    expect(actions.started, hasLength(1));
  });

  test('a plan with different modes becomes one job per settings group, in the chosen order', () {
    var n = 0;
    final jobs = CleanJob.fromPlan([
      (7, const CleanSettings()),
      (6, const CleanSettings()),
      (5, CleanSettings.vacuumOnly),
    ], () => '${n++}');
    expect(
      [for (final j in jobs) j.rooms],
      [
        [7, 6],
        [5],
      ],
    );
  });
}
