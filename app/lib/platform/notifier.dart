import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_foreground_task/flutter_foreground_task.dart' hide NotificationVisibility;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/strings.dart';
import '../robot/alerts.dart';

/// Ongoing notification ("what it is doing / up next") and alerts (errors, dock, clean finished).
/// Does nothing on unsupported platforms.
///
/// In the app, [serviceEntry] starts the Android service (which keeps it alive and takes over when it closes).
/// Inside the service itself ([background]) it asks for no permissions and starts no services: it only posts.
class Notifier {
  final void Function()? serviceEntry;
  final bool background;

  Notifier({this.serviceEntry, this.background = false});

  /// Channel names follow the phone's language (the service has no widget tree to ask).
  final L10n _l = deviceStrings();

  AndroidNotificationDetails get _alertsChannel => AndroidNotificationDetails(
    'alerts',
    _l.chAlerts,
    channelDescription: _l.chAlertsDesc,
    importance: Importance.high,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
  );

  AndroidNotificationDetails get _doneChannel => AndroidNotificationDetails(
    'cleans',
    _l.chCleans,
    channelDescription: _l.chCleansDesc,
    importance: Importance.defaultImportance,
    visibility: NotificationVisibility.public,
  );

  /// Channel ids used by versions before the move to English ids; removed so they do not linger in settings.
  static const _oldChannels = ['alertas', 'limpezas', 'estado'];
  static const _finishedId = 2000;

  /// Same id and channel as the service notification: posting here replaces it, with a progress bar and
  /// visible on the lock screen.
  static const _serviceId = 1;
  static const _statusChannel = 'status';

  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Alerts that arrived before the system was ready (the first robot reading comes very early).
  final _pending = <RobotAlert>[];
  String? _lastText;

  bool get _supported => !kIsWeb && Platform.isAndroid;

  Future<void> init() async {
    if (!_supported) return;
    await _local.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    if (background) {
      _ready = true;
      return;
    }
    final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    for (final id in _oldChannels) {
      try {
        await android?.deleteNotificationChannel(channelId: id);
      } on PlatformException {
        // Android refuses while a running foreground service still uses it; a later launch removes it.
      }
    }
    if (await FlutterForegroundTask.checkNotificationPermission() != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    // Without this Android (Xiaomi/HyperOS in particular) puts the service to sleep and the queue stalls.
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _statusChannel,
        channelName: _l.chStatus,
        channelDescription: _l.chStatusDesc,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Every 5 s the service checks whether the app still sends heartbeats; if not, it takes over queue and alerts.
        eventAction: ForegroundTaskEventAction.repeat(5000),
        allowWifiLock: true,
        allowWakeLock: true,
        autoRunOnBoot: true,
        stopWithTask: false,
      ),
    );
    _ready = true;
    for (final a in List.of(_pending)) {
      await alert(a);
    }
    _pending.clear();
  }

  /// Updates (or starts) the ongoing notification. [progress] 0–100 shows the bar; null hides it.
  /// Only talks to the system when something changed.
  Future<void> status(String title, String text, {int? progress}) async {
    if (!_ready) return;
    final key = '$title|$text|$progress';
    if (key == _lastText) return;
    _lastText = key;
    if (!background && serviceEntry != null && !await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        serviceTypes: [ForegroundServiceTypes.specialUse],
        notificationTitle: title,
        notificationText: text,
        callback: serviceEntry,
      );
    }
    await _local.show(
      id: _serviceId,
      title: title,
      body: text,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _statusChannel,
          _l.chStatus,
          channelDescription: _l.chStatusDesc,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          silent: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.progress,
          showProgress: progress != null,
          maxProgress: 100,
          progress: progress ?? 0,
          showWhen: false,
        ),
      ),
    );
  }

  Future<void> alert(RobotAlert a) async {
    if (!_ready) {
      if (_supported) _pending.add(a);
      return;
    }
    await _local.show(
      id: a.notificationId,
      title: a.title,
      body: a.body,
      notificationDetails: NotificationDetails(android: _alertsChannel),
    );
  }

  Future<void> finished(String title, String body) async {
    if (!_ready) return;
    await _local.show(
      id: _finishedId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: _doneChannel),
    );
  }

  Future<void> stop() async {
    if (_ready && await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService();
    if (_ready) await _local.cancel(id: _serviceId);
    _lastText = null;
  }
}
