import 'package:aspira/platform/takeover.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app closed: the service takes over', () {
    expect(takeover(uiAlive: false, runnerActive: false, hasSession: true), TakeoverAction.start);
  });
  test('app back: the service hands control back', () {
    expect(takeover(uiAlive: true, runnerActive: true, hasSession: true), TakeoverAction.stop);
  });
  test('never two owners, never a start without a session', () {
    expect(takeover(uiAlive: true, runnerActive: false, hasSession: true), TakeoverAction.none);
    expect(takeover(uiAlive: false, runnerActive: true, hasSession: true), TakeoverAction.none);
    expect(takeover(uiAlive: false, runnerActive: false, hasSession: false), TakeoverAction.none);
    expect(takeover(uiAlive: false, runnerActive: true, hasSession: false), TakeoverAction.stop, reason: 'logged out');
  });
}
