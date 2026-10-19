import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../robot/robot_controller.dart';
import '../session_store.dart';
import 'notifier.dart';
import 'takeover.dart';

const _uiHere = 'ui';
const _released = 'released';

/// Android service entry point (own isolate; lives on even when the app is swiped from recents).
@pragma('vm:entry-point')
void backgroundServiceEntry() => FlutterForegroundTask.setTaskHandler(_ServiceHandler());

/// While the app sends heartbeats, the service only keeps the process alive. When the app goes away, the same
/// [RobotController] (queue, routines, alerts, notification) starts here until the app comes back.
class _ServiceHandler extends TaskHandler {
  SessionStore? _store;
  final _notifier = Notifier(background: true);
  RobotController? _runner;
  bool _checking = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    DartPluginRegistrant.ensureInitialized();
    _store = await SessionStore.open();
    await _notifier.init();
    await _check();
  }

  @override
  void onRepeatEvent(DateTime timestamp) => unawaited(_check());

  Future<void> _check() async {
    final store = _store;
    if (store == null || _checking) return;
    _checking = true;
    try {
      await store.reload();
      final session = store.session, device = store.device;
      final hasSession = session != null && device != null;
      switch (takeover(uiAlive: store.uiAlive(), runnerActive: _runner != null, hasSession: hasSession)) {
        case TakeoverAction.start:
          debugPrint('service: app closed, taking over the queue');
          _runner = RobotController(session!, device!, store, _notifier, background: true)..start();
        case TakeoverAction.stop:
          _release();
          if (!hasSession) await FlutterForegroundTask.stopService();
        case TakeoverAction.none:
      }
    } finally {
      _checking = false;
    }
  }

  void _release() {
    _runner?.dispose();
    _runner = null;
  }

  /// The app is back: let go right away (without waiting for the next check) and confirm, so the app starts
  /// without two controllers commanding the robot at once.
  @override
  void onReceiveData(Object data) {
    if (data != _uiHere) return;
    _release();
    FlutterForegroundTask.sendDataToMain(_released);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async => _release();

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp();
}

/// Called by the app on launch, before creating its controller: marks itself alive and, if the service was in
/// charge, waits for it to let go (a few seconds at most) and reloads what it saved.
Future<void> claimFromService(SessionStore store) async {
  await store.markUiAlive();
  if (kIsWeb || !Platform.isAndroid || !await FlutterForegroundTask.isRunningService) return;
  final released = Completer<void>();
  void onData(Object data) {
    if (data == _released && !released.isCompleted) released.complete();
  }

  FlutterForegroundTask.addTaskDataCallback(onData);
  try {
    FlutterForegroundTask.sendDataToTask(_uiHere);
    await released.future.timeout(const Duration(seconds: 4), onTimeout: () {});
  } finally {
    FlutterForegroundTask.removeTaskDataCallback(onData);
  }
  await store.reload();
}
