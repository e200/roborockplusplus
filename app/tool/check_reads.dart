// ignore_for_file: avoid_print
// Checks the read commands the app uses against the real robot. Changes nothing.
import 'dart:convert';
import 'dart:io';

import 'package:aspira/cloud/roborock_cloud.dart';
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
  final home = await RoborockCloud.home(session);
  final c = RobotClient(session, home.devices.first);
  await c.connect();
  Future<void> check(String name, Future<Object?> Function() f) async {
    try {
      print('$name: ${await f()}');
    } catch (e) {
      print('$name: ERRO $e');
    }
  }

  await check('volume', c.volume);
  await check('bloqueio', c.childLock);
  await check('consumables', c.consumables);
  await check('resumo', () async => (await c.cleanSummary()).count);
  await check('last record', () async {
    final s = await c.cleanSummary();
    final r = await c.cleanRecord(s.recordIds.first);
    return '${r?.startedAt} ${r?.durationSeconds}s ${r?.outcome} ${r?.source}';
  });
  c.close();
  exit(0);
}
