import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;
import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart';

/// A Roborock protocol message (local network and MQTT).
class RrMessage {
  static const helloRequest = 0;
  static const helloResponse = 1;
  static const pingRequest = 2;
  static const pingResponse = 3;
  static const generalRequest = 4;
  static const generalResponse = 5;
  static const rpcRequest = 101;
  static const rpcResponse = 102;

  /// "1.0" (ECB) or "L01" (GCM, used on the local network by recent models such as the Saros 20).
  final String version;
  final int protocol;
  final int seq;
  final int random;
  final int timestamp;
  final Uint8List? payload;

  const RrMessage({
    this.version = '1.0',
    required this.protocol,
    required this.seq,
    required this.random,
    required this.timestamp,
    this.payload,
  });
}

/// L01 nonces: ours (sent in the hello) and the robot's (returned in the reply).
class L01Nonces {
  final int connect;
  final int? ack;

  const L01Nonces(this.connect, [this.ack]);
}

class RrCrypto {
  static final _salt = utf8.encode(r'TXdfu$jyZ#TZHsg4');
  static const _timestampOrder = [5, 6, 3, 7, 1, 2, 0, 4];

  static Uint8List md5(List<int> data) => Uint8List.fromList(crypto.md5.convert(data).bytes);

  static String md5Hex(String text) => crypto.md5.convert(utf8.encode(text)).toString();

  /// The robot shuffles the timestamp's hex digits before deriving the key.
  static Uint8List encodeTimestamp(int timestamp) {
    final hex = timestamp.toRadixString(16).padLeft(8, '0');
    return ascii.encode(_timestampOrder.map((i) => hex[i]).join());
  }

  static Uint8List messageKey(String localKey, int timestamp) =>
      md5([...encodeTimestamp(timestamp), ...utf8.encode(localKey), ..._salt]);

  static Uint8List encryptEcb(Uint8List plain, Uint8List key) => _aes(true, key).process(plain);

  static Uint8List decryptEcb(Uint8List cipher, Uint8List key) => _aes(false, key).process(cipher);

  /// L01: AES-256-GCM. Key and IV are derived with SHA-256; the AAD binds the message to the hello nonces.
  static Uint8List l01Key(String localKey, int timestamp) => Uint8List.fromList(
    crypto.sha256.convert([...encodeTimestamp(timestamp), ...utf8.encode(localKey), ..._salt]).bytes,
  );

  static Uint8List l01Iv(int timestamp, int random, int seq) => Uint8List.fromList(
    crypto.sha256.convert([..._be32(seq), ..._be32(random), ..._be32(timestamp)]).bytes.sublist(0, 12),
  );

  static Uint8List l01Aad(int timestamp, int random, int seq, int connectNonce, int? ackNonce) => Uint8List.fromList([
    ..._be32(seq),
    ..._be32(connectNonce),
    if (ackNonce != null) ..._be32(ackNonce),
    ..._be32(random),
    ..._be32(timestamp),
  ]);

  static Uint8List gcm(bool encrypt, Uint8List data, RrMessage m, String localKey, L01Nonces n) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        encrypt,
        AEADParameters(
          KeyParameter(l01Key(localKey, m.timestamp)),
          128,
          l01Iv(m.timestamp, m.random, m.seq),
          l01Aad(m.timestamp, m.random, m.seq, n.connect, n.ack),
        ),
      );
    return cipher.process(data);
  }

  static List<int> _be32(int v) => [(v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff];

  static PaddedBlockCipher _aes(bool encrypt, Uint8List key) =>
      PaddedBlockCipherImpl(PKCS7Padding(), ECBBlockCipher(AESEngine()))
        ..init(encrypt, PaddedBlockCipherParameters(KeyParameter(key), null));
}

/// Wire format: [len u32]["1.0" seq u32 random u32 ts u32 protocol u16 [plen u16 payload]][crc32 u32].
/// The length prefix only exists on the local network; MQTT messages go without it.
class RrCodec {
  static const _header = 17;
  static const _versions = {'1.0', 'L01'};

  static Uint8List encode(RrMessage message, String localKey, {bool prefixed = true, L01Nonces? l01}) {
    final payload = message.payload;
    final encrypted = payload == null || payload.isEmpty
        ? payload
        : message.version == 'L01'
        ? RrCrypto.gcm(true, payload, message, localKey, l01 ?? (throw ArgumentError('L01 needs the nonces')))
        : RrCrypto.encryptEcb(payload, RrCrypto.messageKey(localKey, message.timestamp));
    final bodyLen = _header + (encrypted == null ? 0 : 2 + encrypted.length);
    final body = ByteData(bodyLen);
    final bytes = body.buffer.asUint8List();
    bytes.setRange(0, 3, ascii.encode(message.version));
    body
      ..setUint32(3, message.seq)
      ..setUint32(7, message.random)
      ..setUint32(11, message.timestamp)
      ..setUint16(15, message.protocol);
    if (encrypted != null) {
      body.setUint16(_header, encrypted.length);
      bytes.setRange(_header + 2, bodyLen, encrypted);
    }
    final prefix = prefixed ? 4 : 0;
    final out = ByteData(prefix + bodyLen + 4);
    if (prefixed) out.setUint32(0, bodyLen + 4);
    out.buffer.asUint8List().setRange(prefix, prefix + bodyLen, bytes);
    out.setUint32(prefix + bodyLen, getCrc32(bytes));
    return out.buffer.asUint8List();
  }

  /// Decodes a complete message, without the length prefix.
  static RrMessage decode(Uint8List frame, String localKey, {L01Nonces? l01}) {
    final version = frame.length < _header ? '' : ascii.decode(frame.sublist(0, 3), allowInvalid: true);
    if (!_versions.contains(version)) throw const FormatException('unknown protocol version');
    final data = ByteData.sublistView(frame);
    final seq = data.getUint32(3);
    final random = data.getUint32(7);
    final timestamp = data.getUint32(11);
    final protocol = data.getUint16(15);
    if (frame.length < _header + 2 + 4) {
      return RrMessage(version: version, protocol: protocol, seq: seq, random: random, timestamp: timestamp);
    }
    final len = data.getUint16(_header);
    final end = _header + 2 + len;
    if (data.getUint32(end) != getCrc32(frame.sublist(0, end))) {
      throw const FormatException('invalid CRC');
    }
    final encrypted = frame.sublist(_header + 2, end);
    final header = RrMessage(version: version, protocol: protocol, seq: seq, random: random, timestamp: timestamp);
    final Uint8List payload;
    if (len == 0) {
      payload = Uint8List(0);
    } else if (version == 'L01') {
      if (l01 == null) throw const FormatException('L01 message without negotiated nonces');
      try {
        payload = RrCrypto.gcm(false, encrypted, header, localKey, l01);
      } on InvalidCipherTextException {
        throw const FormatException('invalid GCM tag');
      }
    } else {
      payload = RrCrypto.decryptEcb(encrypted, RrCrypto.messageKey(localKey, timestamp));
    }
    return RrMessage(
      version: version,
      protocol: protocol,
      seq: seq,
      random: random,
      timestamp: timestamp,
      payload: payload,
    );
  }
}

/// Buffers socket bytes and returns complete messages (length-prefixed).
class RrFrameReader {
  final String localKey;

  /// Set after the L01 hello.
  L01Nonces? l01;
  final _buffer = BytesBuilder(copy: false);
  Uint8List _pending = Uint8List(0);

  RrFrameReader(this.localKey);

  List<RrMessage> feed(List<int> data) {
    _buffer
      ..add(_pending)
      ..add(data);
    _pending = _buffer.takeBytes();
    final out = <RrMessage>[];
    while (_pending.length >= 4) {
      final len = ByteData.sublistView(_pending).getUint32(0);
      if (len <= 0 || len > 1 << 20) {
        _resync();
        continue;
      }
      if (_pending.length < 4 + len) break;
      out.add(RrCodec.decode(Uint8List.sublistView(_pending, 4, 4 + len), localKey, l01: l01));
      _pending = Uint8List.sublistView(_pending, 4 + len);
    }
    return out;
  }

  /// Skips garbage up to the next plausible "1.0"/"L01" header.
  void _resync() {
    for (var i = 1; i + 6 < _pending.length; i++) {
      final v = String.fromCharCodes(_pending.sublist(i + 4, i + 7));
      if (RrCodec._versions.contains(v)) {
        _pending = Uint8List.sublistView(_pending, i);
        return;
      }
    }
    _pending = Uint8List(0);
  }
}
