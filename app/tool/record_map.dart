// ignore_for_file: avoid_print
// Tests a past clean's map against the real robot. Read-only.
import 'dart:convert';
import 'dart:io';

import 'package:aspira/cloud/roborock_cloud.dart';
import 'package:aspira/map/map_parser.dart';
import 'package:aspira/robot/robot_client.dart';
import 'package:aspira/robot/robot_commands.dart';

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
  final sum = await c.cleanSummary();
  for (final id in sum.recordIds.skip(8).take(5)) {
    final sw = Stopwatch()..start();
    try {
      final raw = await c.recordMap(id);
      final m = MapParser.parse(raw);
      print('$id: ${sw.elapsedMilliseconds} ms, ${raw.length} bytes, percurso=${m.path.length}');
    } catch (e) {
      print('$id: falhou em ${sw.elapsedMilliseconds} ms: $e');
    }
  }
  c.close();
  exit(0);
}
