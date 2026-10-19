import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart' show GZipDecoder;
import 'package:pointycastle/export.dart';

import 'rr_message.dart';

/// What went wrong talking to the robot. The UI shows a localized text per kind; [RobotException.message]
/// is the English detail for logs.
enum RobotErrorKind { noLink, timeout, closed, refused, robot, unexpected, unsupported }

class RobotException implements Exception {
  final RobotErrorKind kind;
  final String message;

  const RobotException(this.kind, this.message);

  @override
  String toString() => message;
}

/// The robot does not know the method (firmware without that feature).
class UnsupportedCommand extends RobotException {
  const UnsupportedCommand(String method) : super(RobotErrorKind.unsupported, 'Robot does not support "$method"');
}

final _rnd = Random.secure();

int nextRequestId() => 10000 + _rnd.nextInt(22767);

/// Sequence numbers and message nonces that only ever grow, per connection.
/// The robot (L01) drops messages with a lower sequence than the last one it accepted: with random values,
/// half the requests were silently lost and fell back to the cloud after timing out.
class MessageCounter {
  int _seq;
  int _random;

  MessageCounter({int seq = 100000, int random = 10000})
    : _seq = seq + _rnd.nextInt(1000),
      _random = random + _rnd.nextInt(1000);

  int nextSeq() => ++_seq;

  int nextRandom() => ++_random;
}

int nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

/// Nonce and endpoint the robot uses to encrypt large responses (maps).
class SecurityData {
  final Uint8List nonce;
  final String endpoint;

  SecurityData._(this.nonce, this.endpoint);

  factory SecurityData.create(String rriotK) => SecurityData._(
    Uint8List.fromList(List.generate(16, (_) => _rnd.nextInt(256))),
    base64.encode(RrCrypto.md5(utf8.encode(rriotK)).sublist(8, 14)),
  );

  String get nonceHex => nonce.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// V1 RPC request: `{"dps":{"101":"{id,method,params}"},"t":ts}`.
Uint8List encodeRpc(int id, String method, Object? params, int timestamp, {SecurityData? security}) {
  final inner = {
    'id': id,
    'method': method,
    'params': params ?? const [],
    if (security != null) 'security': {'endpoint': security.endpoint, 'nonce': security.nonceHex},
  };
  return Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'dps': {'101': jsonEncode(inner)},
        't': timestamp,
      }),
    ),
  );
}

class RpcResponse {
  final int id;
  final Object? result;
  final Object? error;

  const RpcResponse(this.id, this.result, this.error);
}

/// V1 RPC response (dps 102). Returns null if the message is not an RPC response.
RpcResponse? decodeRpc(RrMessage message) {
  final payload = message.payload;
  if (payload == null || payload.isEmpty) return null;
  final Object? json;
  try {
    json = jsonDecode(utf8.decode(payload));
  } on FormatException {
    return null;
  }
  final dps = json is Map ? json['dps'] : null;
  final raw = dps is Map ? dps['102'] : null;
  if (raw is! String) return null;
  final inner = jsonDecode(raw) as Map<String, dynamic>;
  final id = inner['id'];
  if (id is! int) return null;
  return RpcResponse(id, inner['result'], inner['error']);
}

/// Turns the response into a result or an exception, like python-roborock.
Object? unwrapRpc(String method, RpcResponse r) {
  if (r.error != null) throw RobotException(RobotErrorKind.robot, 'Robot error on "$method": ${r.error}');
  final result = r.result;
  if (result == 'unknown_method') throw UnsupportedCommand(method);
  if (result is String && result != 'ok') {
    throw RobotException(RobotErrorKind.unexpected, 'Unexpected reply to "$method": $result');
  }
  return result;
}

/// Map response (protocol 301): 24-byte header + AES-CBC body (zero IV, key = nonce), gzipped.
({int requestId, Uint8List data})? decodeMapResponse(Uint8List payload, SecurityData security) {
  if (payload.length < 24) return null;
  final endpoint = ascii.decode(payload.sublist(0, 8), allowInvalid: true);
  if (!endpoint.startsWith(security.endpoint)) return null;
  final requestId = ByteData.sublistView(payload, 16, 18).getUint16(0, Endian.little);
  final cipher = PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()))
    ..init(false, PaddedBlockCipherParameters(ParametersWithIV(KeyParameter(security.nonce), Uint8List(16)), null));
  final plain = cipher.process(Uint8List.sublistView(payload, 24));
  return (requestId: requestId, data: Uint8List.fromList(GZipDecoder().decodeBytes(plain)));
}
