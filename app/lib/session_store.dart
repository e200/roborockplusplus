import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'cloud/roborock_cloud.dart';

/// Keeps the Roborock session and the chosen robot in the app's private storage.
class SessionStore {
  static const _deviceIdKey = 'device_id';
  static const _sessionKey = 'session';
  static const _deviceKey = 'device';

  final SharedPreferences _prefs;

  SessionStore._(this._prefs);

  static Future<SessionStore> open() async => SessionStore._(await SharedPreferences.getInstance());

  /// Fixed per install: the login code is bound to this id.
  String get deviceId {
    final existing = _prefs.getString(_deviceIdKey);
    if (existing != null) return existing;
    final rnd = Random.secure();
    final id = base64Url.encode(List.generate(16, (_) => rnd.nextInt(256))).replaceAll('=', '');
    _prefs.setString(_deviceIdKey, id);
    return id;
  }

  CloudSession? get session {
    final raw = _prefs.getString(_sessionKey);
    return raw == null ? null : CloudSession.fromJson(jsonDecode(raw));
  }

  CloudDevice? get device {
    final raw = _prefs.getString(_deviceKey);
    if (raw == null) return null;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return CloudDevice(
      duid: j['duid'],
      name: j['name'],
      localKey: j['localKey'],
      productId: j['productId'],
      online: true,
    );
  }

  Future<void> save(CloudSession session, CloudDevice device) async {
    await _prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    await _prefs.setString(
      _deviceKey,
      jsonEncode({
        'duid': device.duid,
        'name': device.name,
        'localKey': device.localKey,
        'productId': device.productId,
      }),
    );
  }

  /// App data (queue, history). It belongs with the robot: logging out keeps it.
  Object? readJson(String key) {
    final raw = _prefs.getString('data_$key');
    return raw == null ? null : jsonDecode(raw);
  }

  Future<void> writeJson(String key, Object value) => _prefs.setString('data_$key', jsonEncode(value));

  /// The app (UI) and the service run in different isolates, each with its own in-memory copy:
  /// reload from disk before acting on what the other one wrote.
  Future<void> reload() => _prefs.reload();

  static const _uiAliveKey = 'ui_alive_at';

  /// UI heartbeat: while it is recent the app is in charge; otherwise the service takes over.
  Future<void> markUiAlive() => _prefs.setInt(_uiAliveKey, DateTime.now().millisecondsSinceEpoch);

  Future<void> markUiGone() => _prefs.remove(_uiAliveKey);

  bool uiAlive({Duration within = const Duration(seconds: 12)}) {
    final t = _prefs.getInt(_uiAliveKey);
    return t != null && DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(t)) < within;
  }

  Future<void> clear() async {
    await _prefs.remove(_sessionKey);
    await _prefs.remove(_deviceKey);
  }
}
