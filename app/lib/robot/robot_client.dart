import 'dart:async';
import 'dart:typed_data';

import '../cloud/roborock_cloud.dart';
import '../protocol/local_channel.dart';
import '../protocol/mqtt_channel.dart';
import '../protocol/rpc.dart';
import 'robot_status.dart';

enum LinkState { offline, cloud, local }

/// Talks to one robot: prefers the local link and falls back to the cloud when it fails.
/// Retries the local link on its own, with exponential backoff.
class RobotClient {
  final CloudSession session;
  final CloudDevice device;

  late final MqttChannel _mqtt = MqttChannel(rriot: session.rriot, duid: device.duid, localKey: device.localKey);
  LocalChannel? _local;
  String? _host;
  Timer? _retry;
  var _retryDelay = const Duration(seconds: 2);
  bool _closed = false;

  final _link = StreamController<LinkState>.broadcast();

  RobotClient(this.session, this.device);

  Stream<LinkState> get linkChanges => _link.stream;

  LinkState get link => _local?.isConnected == true
      ? LinkState.local
      : (_mqttReady && _mqtt.isConnected ? LinkState.cloud : LinkState.offline);

  bool _mqttReady = false;

  Timer? _mqttRetry;
  var _mqttRetryDelay = const Duration(seconds: 2);

  /// First attempt: if it fails it throws (the UI shows the error) but keeps retrying on its own with backoff.
  /// After one successful connection, MQTT auto-reconnect handles drops.
  Future<void> connect() async {
    _mqtt.onClosed = () => _link.add(link);
    try {
      await _mqtt.connect();
    } on RobotException {
      _scheduleMqttRetry();
      rethrow;
    }
    _onMqttUp();
  }

  void _onMqttUp() {
    _mqttReady = true;
    _link.add(link);
    unawaited(_connectLocal());
  }

  void _scheduleMqttRetry() {
    if (_closed) return;
    _mqttRetry?.cancel();
    _mqttRetry = Timer(_mqttRetryDelay, () async {
      try {
        await _mqtt.connect();
        _onMqttUp();
      } on RobotException {
        _scheduleMqttRetry();
      }
    });
    final next = _mqttRetryDelay * 2;
    _mqttRetryDelay = next > const Duration(minutes: 1) ? const Duration(minutes: 1) : next;
  }

  /// The robot's IP comes from the robot itself (`get_network_info`), asked via the cloud.
  Future<void> _connectLocal() async {
    if (_closed) return;
    try {
      _host ??= ((await _mqtt.call('get_network_info')) as Map)['ip'] as String;
      final local = LocalChannel(_host!, device.localKey)..onClosed = _onLocalLost;
      await local.connect();
      _local = local;
      _retryDelay = const Duration(seconds: 2);
      _link.add(link);
    } on Exception {
      _scheduleLocalRetry();
    }
  }

  void _onLocalLost() {
    _local = null;
    _link.add(link);
    _scheduleLocalRetry();
  }

  void _scheduleLocalRetry() {
    if (_closed) return;
    _retry?.cancel();
    _retry = Timer(_retryDelay, _connectLocal);
    final next = _retryDelay * 2;
    _retryDelay = next > const Duration(minutes: 2) ? const Duration(minutes: 2) : next;
  }

  Future<Object?> call(String method, [Object? params]) async {
    final local = _local;
    if (local != null && local.isConnected) {
      try {
        return await local.call(method, params);
      } on UnsupportedCommand {
        rethrow;
      } on RobotException {
        // fall back to the cloud
      }
    }
    if (!_mqttReady) throw const RobotException(RobotErrorKind.noLink, 'No connection to the robot');
    return _mqtt.call(method, params);
  }

  Future<RobotStatus> status() async {
    final res = await call('get_status');
    final first = res is List && res.isNotEmpty ? res.first : res;
    return RobotStatus.fromJson(Map<String, dynamic>.from(first as Map));
  }

  /// Segment id → room IoT id (to give it the name set in the official app).
  Future<Map<int, String>> roomMapping() async {
    final res = await call('get_room_mapping');
    final out = <int, String>{};
    if (res is List) {
      for (final e in res) {
        if (e is List && e.length >= 2) out[e[0] as int] = '${e[1]}';
      }
    }
    return out;
  }

  Future<Uint8List> map() => _mqtt.fetchMap();

  /// Map of a past clean (rooms, path and objects at that moment).
  Future<Uint8List> recordMap(int begin) =>
      _mqtt.fetchMap(method: 'get_clean_record_map_v2', params: {'start_time': begin});

  void close() {
    _closed = true;
    _retry?.cancel();
    _mqttRetry?.cancel();
    _local?.close();
    if (_mqttReady) _mqtt.close();
    _link.close();
  }
}
