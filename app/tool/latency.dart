// ignore_for_file: avoid_print
// Measures get_status round trip over the local network and the cloud. Read-only.
import 'dart:convert';
import 'dart:io';

import 'package:aspira/cloud/roborock_cloud.dart';
import 'package:aspira/protocol/local_channel.dart';
import 'package:aspira/protocol/mqtt_channel.dart';

Future<void> main() async {
  final py = jsonDecode(File('../secrets/session.json').readAsStringSync()) as Map<String, dynamic>;
  final ud = py['user_data'] as Map<String, dynamic>;
  final session = CloudSession(
    email: py['email'],
    baseUrl: 'https://euiot.roborock.com',
    token: ud['token'],
    rriot: Rriot.fromJson(Map<String, dynamic>.from(ud['rriot'])),
  );
  final dev = (await RoborockCloud.home(session)).devices.first;

  Future<void> bench(String name, Future<Object?> Function() call) async {
    final times = <int>[];
    for (var i = 0; i < 8; i++) {
      final sw = Stopwatch()..start();
      await call();
      times.add(sw.elapsedMilliseconds);
    }
    times.sort();
    print('$name: median ${times[times.length ~/ 2]} ms, min ${times.first}, max ${times.last}');
  }

  final mqtt = MqttChannel(rriot: session.rriot, duid: dev.duid, localKey: dev.localKey);
  await mqtt.connect();
  final ip = ((await mqtt.call('get_network_info')) as Map)['ip'] as String;
  final local = LocalChannel(ip, dev.localKey);
  final sw = Stopwatch()..start();
  await local.connect();
  print('local link (${local.version}): ${sw.elapsedMilliseconds} ms');
  await bench('get_status local', () => local.call('get_status'));
  await bench('get_status cloud', () => mqtt.call('get_status'));
  local.close();
  mqtt.close();
  exit(0);
}
