import 'dart:convert';
import 'dart:typed_data';

import 'package:aspira/protocol/rr_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vectors generated with python-roborock (MessageParser.build) and a fake key.
void main() {
  const key = '0123456789abcdef';
  final payload = Uint8List.fromList(
    utf8.encode(r'{"dps":{"101":"{\"id\":12345,\"method\":\"get_status\",\"params\":[]}"},"t":1792354942}'),
  );
  final request = RrMessage(
    protocol: RrMessage.generalRequest,
    seq: 123456,
    random: 54321,
    timestamp: 1792354942,
    payload: payload,
  );

  const reqHex =
      '00000077312e300001e2400000d4316ad52a7e000400605601c525ac16d8daf7e37dc621ab08205de304cada039b'
      '69f99db4985b57403053c97c8fff8df7f82e73c96c02b6c80451db8c85dee8e0d93a09abef39fabb1eacac2a86d82f7c4db75fb418'
      '1f459b9de783b6e7ec6ecc594c77dd46a002b3b1895a95af';
  const helloHex = '00000015312e300000000100004e206ad52a7e0000c71f5de8';

  String hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  Uint8List bytes(String h) =>
      Uint8List.fromList([for (var i = 0; i < h.length; i += 2) int.parse(h.substring(i, i + 2), radix: 16)]);

  test('encodes requests like the reference implementation', () {
    expect(hex(RrCodec.encode(request, key)), reqHex);
  });

  test('encodes without a length prefix for MQTT', () {
    expect(hex(RrCodec.encode(request, key, prefixed: false)), reqHex.substring(8));
  });

  test('encodes a hello without payload', () {
    const hello = RrMessage(protocol: RrMessage.helloRequest, seq: 1, random: 20000, timestamp: 1792354942);
    expect(hex(RrCodec.encode(hello, key)), helloHex);
  });

  test('leitor junta frames partidos e separa frames concatenados', () {
    final reader = RrFrameReader(key);
    final all = bytes(helloHex + reqHex);
    final messages = [...reader.feed(all.sublist(0, 30)), ...reader.feed(all.sublist(30))];
    expect(messages, hasLength(2));
    expect(messages[0].protocol, RrMessage.helloRequest);
    expect(messages[0].payload, isNull);
    expect(messages[1].seq, 123456);
    expect(messages[1].timestamp, 1792354942);
    expect(messages[1].payload, payload);
  });

  const l01ReqHex =
      '0000007e4c30310001e2400000d4316ad52a7e00040067228a715a12781a0222a2fc75effeddc5d48e2c1907799818f713c813b0b'
      '481ce4ec80411107623535e6fce59c344a16e2cd31c4b18de5e4a966299043da74903bbea6a1c34c6d64cc06cd7fd5db40be5250053247d44'
      'd21053ddbb1ed7cd0497a49ce4ee3117b4eff293fd';
  const l01HelloHex = '000000154c30310000000100004e206ad52a7e0000ce4b2354';
  const nonces = L01Nonces(20000, 30000);

  test('L01: encodes a request like the reference (AES-256-GCM)', () {
    final m = RrMessage(
      version: 'L01',
      protocol: RrMessage.generalRequest,
      seq: 123456,
      random: 54321,
      timestamp: 1792354942,
      payload: payload,
    );
    expect(hex(RrCodec.encode(m, key, l01: nonces)), l01ReqHex);
  });

  test('L01: hello without payload', () {
    const hello = RrMessage(
      version: 'L01',
      protocol: RrMessage.helloRequest,
      seq: 1,
      random: 20000,
      timestamp: 1792354942,
    );
    expect(hex(RrCodec.encode(hello, key, l01: const L01Nonces(20000))), l01HelloHex);
  });

  test('L01: descodifica e rejeita nonces errados', () {
    final reader = RrFrameReader(key)..l01 = nonces;
    final m = reader.feed(bytes(l01ReqHex)).single;
    expect(m.version, 'L01');
    expect(m.payload, payload);
    expect(
      () => RrCodec.decode(bytes(l01ReqHex).sublist(4), key, l01: const L01Nonces(20000, 1)),
      throwsFormatException,
    );
  });
}
