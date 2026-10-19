import 'dart:async';

import 'package:aspira/robot/action_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActionGate', () {
    test('repeated taps while a command is in flight send it once', () async {
      final gate = ActionGate();
      final release = Completer<void>();
      var sent = 0;
      Future<void> send() async {
        sent++;
        await release.future;
      }

      final first = gate.run('pause', send);
      expect(gate.isPending('pause'), isTrue);
      expect(await gate.run('pause', send), isFalse, reason: 'segundo toque ignorado');
      expect(await gate.run('pause', send), isFalse, reason: 'terceiro toque ignorado');
      release.complete();
      expect(await first, isTrue);
      expect(sent, 1);
      expect(gate.isPending('pause'), isFalse);
    });

    test('different actions do not block each other', () async {
      final gate = ActionGate();
      final release = Completer<void>();
      final a = gate.run('pause', () => release.future);
      expect(await gate.run('find', () async {}), isTrue);
      release.complete();
      await a;
    });

    test('after an error the action can be sent again', () async {
      final gate = ActionGate();
      await expectLater(gate.run('dock', () async => throw Exception('offline')), throwsException);
      expect(gate.isPending('dock'), isFalse);
      expect(await gate.run('dock', () async {}), isTrue);
    });

    test('notifies the UI on start and end (to show "sending")', () async {
      final gate = ActionGate();
      final states = <bool>[];
      await gate.run('start', () async {}, onChange: () => states.add(gate.isPending('start')));
      expect(states, [true, false]);
    });
  });

  group('PollSchedule', () {
    final t0 = DateTime(2026, 10, 19, 10);

    test('reads right after a command, then every second during the burst', () {
      final p = PollSchedule();
      expect(p.due(t0), isTrue);
      expect(p.due(t0.add(const Duration(seconds: 1))), isFalse, reason: 'at rest it reads every 3 s');
      p.commandSent(t0.add(const Duration(seconds: 1)));
      expect(p.due(t0.add(const Duration(seconds: 1))), isTrue, reason: 'reads immediately after the command');
      expect(p.due(t0.add(const Duration(seconds: 2))), isTrue);
      expect(p.due(t0.add(const Duration(seconds: 3))), isTrue);
    });

    test('returns to the normal pace when the burst ends', () {
      final p = PollSchedule()..commandSent(t0);
      expect(p.intervalAt(t0.add(const Duration(seconds: 5))), PollSchedule.fast);
      expect(p.intervalAt(t0.add(const Duration(seconds: 13))), const Duration(seconds: 3));
    });

    test('the service (app closed) reads less often', () {
      final p = PollSchedule(normal: const Duration(seconds: 10));
      expect(p.intervalAt(t0), const Duration(seconds: 10));
      p.commandSent(t0);
      expect(p.intervalAt(t0.add(const Duration(seconds: 1))), PollSchedule.fast, reason: 'a command is still fast');
    });
  });
}
