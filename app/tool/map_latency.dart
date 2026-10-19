// ignore_for_file: avoid_print
// Measures how long a live map fetch takes (it only comes through the cloud). Read-only.
import 'dart:convert';
import 'dart:io';

import 'package:aspira/cloud/roborock_cloud.dart';
import 'package:aspira/robot/robot_client.dart';

Future<void> main() async {
  final py = jsonDecode(File('../secrets/session.json').readAsStringSync()) as Map<String, dynamic>;
  final ud = py['user_data'] as Map<String, dynamic>;
  final session = CloudSession(
    email: py['email'],
    baseUrl: 'https://euiot.roborock.com',
    token: ud['token'],
    rriot: Rriot.fromJson(Map<String, dynamic>.from(ud['rriot'])),
  );
  final c = RobotClient(session, (await RoborockCloud.home(session)).devices.first);
  await c.connect();
  final times = <int>[];
  for (var i = 0; i < 8; i++) {
    final sw = Stopwatch()..start();
    final raw = await c.map();
    times.add(sw.elapsedMilliseconds);
    print('map ${raw.length} bytes in ${sw.elapsedMilliseconds} ms');
  }
  times.sort();
  print('median ${times[times.length ~/ 2]} ms, max ${times.last} ms');
  exit(0);
}
