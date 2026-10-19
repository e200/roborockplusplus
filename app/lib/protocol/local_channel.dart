import 'dart:async';
import 'dart:io';

import 'rpc.dart';
import 'rr_message.dart';

/// Direct TCP connection to the robot (port 58867, V1 protocol).
class LocalChannel {
  static const port = 58867;

  /// Short: if the local link stalls, the request falls back to the cloud instead of keeping the user waiting.
  static const _timeout = Duration(seconds: 3);
  static const _pingInterval = Duration(seconds: 10);

  final String host;
  final String localKey;

  /// Version negotiated in the hello. The Saros 20 only answers L01; older models use "1.0".
  String version = 'L01';
  L01Nonces? _nonces;
  final _counter = MessageCounter();

  Socket? _socket;
  Timer? _ping;
  late final RrFrameReader _reader = RrFrameReader(localKey);
  final _pending = <int, Completer<RrMessage>>{};
  final _pendingRpc = <int, Completer<RpcResponse>>{};
  void Function()? onClosed;

  LocalChannel(this.host, this.localKey);

  bool get isConnected => _socket != null;

  Future<void> connect() async {
    final socket = await Socket.connect(host, port, timeout: _timeout);
    socket.setOption(SocketOption.tcpNoDelay, true);
    _socket = socket;
    socket.listen(_onData, onError: (_) => _closed(), onDone: _closed, cancelOnError: true);
    // Write errors after the link drops arrive here; without this they become unhandled exceptions.
    unawaited(socket.done.then<void>((_) {}, onError: (_) => _closed()));
    try {
      await _hello();
    } catch (_) {
      close();
      rethrow;
    }
    _ping = Timer.periodic(_pingInterval, (_) {
      _request(
        RrMessage(
          version: version,
          protocol: RrMessage.pingRequest,
          seq: _counter.nextSeq(),
          random: _counter.nextRandom(),
          timestamp: nowSeconds(),
        ),
        RrMessage.pingResponse,
      ).catchError((_) => RrMessage(protocol: 0, seq: 0, random: 0, timestamp: 0));
    });
  }

  /// Hello with seq 1 and our nonce in `random`; the robot returns its own, which goes into the L01 AAD.
  Future<void> _hello() async {
    for (final v in [version, if (version == 'L01') '1.0' else 'L01']) {
      final connect = nextRequestId();
      _nonces = L01Nonces(connect);
      try {
        final res = await _request(
          RrMessage(version: v, protocol: RrMessage.helloRequest, seq: 1, random: connect, timestamp: nowSeconds()),
          RrMessage.helloResponse,
        );
        version = v;
        _nonces = L01Nonces(connect, res.random);
        _reader.l01 = _nonces;
        return;
      } on RobotException {
        // try the other version
      }
    }
    throw const RobotException(RobotErrorKind.timeout, 'Robot did not answer on the local network');
  }

  Future<Object?> call(String method, [Object? params]) async {
    final socket = _socket;
    if (socket == null) throw const RobotException(RobotErrorKind.noLink, 'No local connection');
    final id = nextRequestId(), ts = nowSeconds();
    final done = Completer<RpcResponse>();
    _pendingRpc[id] = done;
    _send(
      RrCodec.encode(
        RrMessage(
          version: version,
          protocol: RrMessage.generalRequest,
          seq: _counter.nextSeq(),
          random: _counter.nextRandom(),
          timestamp: ts,
          payload: encodeRpc(id, method, params, ts),
        ),
        localKey,
        l01: _nonces,
      ),
    );
    try {
      return unwrapRpc(method, await done.future.timeout(_timeout));
    } on TimeoutException {
      throw RobotException(RobotErrorKind.timeout, 'Robot did not answer "$method" locally');
    } finally {
      _pendingRpc.remove(id);
    }
  }

  Future<RrMessage> _request(RrMessage message, int responseProtocol) async {
    final socket = _socket;
    if (socket == null) throw const RobotException(RobotErrorKind.noLink, 'No local connection');
    final done = Completer<RrMessage>();
    _pending[message.seq << 8 | responseProtocol] = done;
    _send(RrCodec.encode(message, localKey, l01: _nonces));
    try {
      return await done.future.timeout(_timeout);
    } on TimeoutException {
      throw const RobotException(RobotErrorKind.timeout, 'Robot did not answer on the local network');
    } finally {
      _pending.remove(message.seq << 8 | responseProtocol);
    }
  }

  void _send(List<int> frame) {
    try {
      _socket?.add(frame);
    } on Object {
      _closed();
      throw const RobotException(RobotErrorKind.closed, 'Local connection closed');
    }
  }

  void _onData(List<int> data) {
    final List<RrMessage> messages;
    try {
      messages = _reader.feed(data);
    } on FormatException {
      return; // corrupt frame: the reader resyncs on the next header
    }
    for (final m in messages) {
      _pending[m.seq << 8 | m.protocol]?.complete(m);
      final rpc = decodeRpc(m);
      if (rpc != null) _pendingRpc[rpc.id]?.complete(rpc);
    }
  }

  void _closed() {
    if (_socket == null) return;
    close();
    onClosed?.call();
  }

  void close() {
    _ping?.cancel();
    _ping = null;
    _socket?.destroy();
    _socket = null;
    for (final c in [..._pending.values, ..._pendingRpc.values]) {
      if (!c.isCompleted) c.completeError(const RobotException(RobotErrorKind.closed, 'Local connection closed'));
    }
  }
}
