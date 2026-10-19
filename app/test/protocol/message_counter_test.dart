import 'package:aspira/protocol/rpc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression: the Saros 20 (L01) ignores messages whose sequence is not higher than the previous one.
void main() {
  test('sequence and message nonce always grow within a connection', () {
    final c = MessageCounter();
    var seq = c.nextSeq(), random = c.nextRandom();
    for (var i = 0; i < 1000; i++) {
      final s = c.nextSeq(), r = c.nextRandom();
      expect(s, greaterThan(seq));
      expect(r, greaterThan(random));
      seq = s;
      random = r;
    }
  });

  test('the first sequence is above the hello (seq 1)', () {
    expect(MessageCounter().nextSeq(), greaterThan(1));
  });
}
