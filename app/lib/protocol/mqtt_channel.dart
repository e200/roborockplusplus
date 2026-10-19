import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_buffers.dart';

import '../cloud/roborock_cloud.dart';
import 'rpc.dart';
import 'rr_message.dart';

/// Connection to the robot through the cloud (MQTT over TLS). Slower than local, but works away from home and
/// is the only path the robot sends maps on.
class MqttChannel {
  static const _timeout = Duration(seconds: 10);
  static const _mapResponse = 301;

  final Rriot rriot;
  final String duid;
  final String localKey;
  final SecurityData security;

  late MqttServerClient _client;
  final _pendingRpc = <int, Completer<RpcResponse>>{};
  final _pendingMap = <int, Completer<Uint8List>>{};
  final _counter = MessageCounter();
  void Function()? onClosed;

  MqttChannel({required this.rriot, required this.duid, required this.localKey})
    : security = SecurityData.create(rriot.k);

  String get _user => RrCrypto.md5Hex('${rriot.u}:${rriot.k}').substring(2, 10);

  String get _password => RrCrypto.md5Hex('${rriot.s}:${rriot.k}').substring(16);

  String get _publishTopic => 'rr/m/i/${rriot.u}/$_user/$duid';

  String get _subscribeTopic => 'rr/m/o/${rriot.u}/$_user/$duid';

  bool _created = false;

  bool get isConnected => _created && _client.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect() async {
    final url = Uri.parse(rriot.mqttUrl.replaceFirst('ssl://', 'https://').replaceFirst('tcp://', 'http://'));
    // Every attempt (the first and each retry) uses a fresh client.
    if (_created) _client.disconnect();
    _created = true;
    _client = MqttServerClient.withPort(url.host, 'aspira_${nextRequestId()}${nextRequestId()}', url.port)
      ..secure = rriot.mqttUrl.startsWith('ssl://')
      ..keepAlivePeriod = 45
      ..autoReconnect = true
      ..logging(on: false)
      ..onDisconnected = (() => onClosed?.call());
    // mqtt_client listens to the socket without an error handler: a network drop (e.g. errno 103) surfaced as an
    // unhandled error. In a guarded zone those errors are logged and auto-reconnect takes care of the rest.
    final connected = Completer<MqttClientConnectionStatus?>();
    runZonedGuarded(
      () => _client
          .connect(_user, _password)
          .then(
            connected.complete,
            onError: (Object e, StackTrace st) {
              if (!connected.isCompleted) connected.completeError(e, st);
            },
          ),
      (e, _) {
        if (!connected.isCompleted) {
          connected.completeError(RobotException(RobotErrorKind.noLink, 'Cloud connection failed: $e'));
        } else {
          debugPrint('MQTT: $e');
        }
      },
    );
    final MqttClientConnectionStatus? status;
    try {
      status = await connected.future;
    } on RobotException {
      rethrow;
    } on Exception catch (e) {
      throw RobotException(RobotErrorKind.noLink, 'Cloud connection failed: $e');
    }
    if (status?.state != MqttConnectionState.connected) {
      throw RobotException(RobotErrorKind.refused, 'MQTT refused the connection: ${status?.returnCode}');
    }
    _client.subscribe(_subscribeTopic, MqttQos.atMostOnce);
    _client.updates?.listen((events) {
      for (final e in events) {
        final msg = e.payload as MqttPublishMessage;
        _onPayload(Uint8List.fromList(msg.payload.message.toList()));
      }
    });
  }

  Future<Object?> call(String method, [Object? params]) async {
    final id = nextRequestId();
    final done = Completer<RpcResponse>();
    _pendingRpc[id] = done;
    _publish(id, method, params);
    try {
      return unwrapRpc(method, await done.future.timeout(_timeout));
    } on TimeoutException {
      throw RobotException(RobotErrorKind.timeout, 'Robot did not answer "$method" via the cloud');
    } finally {
      _pendingRpc.remove(id);
    }
  }

  /// Requests a map (the current one or a past clean's). The RPC reply is just "ok"; the map arrives
  /// separately, encrypted with the [security] nonce.
  Future<Uint8List> fetchMap({String method = 'get_map_v1', Object params = const []}) async {
    final id = nextRequestId();
    final done = Completer<Uint8List>();
    _pendingMap[id] = done;
    _publish(id, method, params, withSecurity: true);
    try {
      return await done.future.timeout(_timeout);
    } on TimeoutException {
      throw const RobotException(RobotErrorKind.timeout, 'Map did not arrive in time');
    } finally {
      _pendingMap.remove(id);
    }
  }

  void _publish(int id, String method, Object? params, {bool withSecurity = false}) {
    if (!isConnected) throw const RobotException(RobotErrorKind.noLink, 'No cloud connection');
    final ts = nowSeconds();
    final frame = RrCodec.encode(
      RrMessage(
        protocol: RrMessage.rpcRequest,
        seq: _counter.nextSeq(),
        random: _counter.nextRandom(),
        timestamp: ts,
        payload: encodeRpc(id, method, params, ts, security: withSecurity ? security : null),
      ),
      localKey,
      prefixed: false,
    );
    _client.publishMessage(_publishTopic, MqttQos.atMostOnce, Uint8Buffer()..addAll(frame));
  }

  void _onPayload(Uint8List data) {
    final RrMessage m;
    try {
      m = RrCodec.decode(data, localKey);
    } on FormatException {
      return;
    } on ArgumentError {
      return; // bad AES/padding: a message for another device, or corrupt
    }
    if (m.protocol == _mapResponse && m.payload != null) {
      final map = decodeMapResponse(m.payload!, security);
      if (map != null) _pendingMap[map.requestId]?.complete(map.data);
      return;
    }
    final rpc = decodeRpc(m);
    if (rpc != null) _pendingRpc[rpc.id]?.complete(rpc);
  }

  void close() {
    if (_created) _client.disconnect();
    for (final c in [..._pendingRpc.values, ..._pendingMap.values]) {
      if (!c.isCompleted) c.completeError(const RobotException(RobotErrorKind.closed, 'Cloud connection closed'));
    }
  }
}
