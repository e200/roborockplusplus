// ignore_for_file: avoid_print
import 'dart:io';
import 'package:aspira/protocol/local_channel.dart';

Future<void> main(List<String> a) async {
  final ch = LocalChannel(a[0], a[1]);
  await ch.connect();
  for (var i = 0; i < 4; i++) {
    final sw = Stopwatch()..start();
    try {
      await ch.call('get_status');
      print('get_status: ${sw.elapsedMilliseconds} ms');
    } catch (e) {
      print('falhou em ${sw.elapsedMilliseconds} ms: $e');
    }
  }
  ch.close();
  exit(0);
}
