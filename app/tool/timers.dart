// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:aspira/cloud/roborock_cloud.dart';
import 'package:aspira/robot/robot_client.dart';
import 'package:http/http.dart' as http;

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
  final path = '/user/devices/${dev.duid}/jobs';
  final res = await http.get(
    Uri.parse('${session.rriot.apiUrl}$path'),
    headers: {'Authorization': RoborockCloud.hawk(session.rriot, path)},
  );
  print('cloud jobs: ${res.body.substring(0, res.body.length.clamp(0, 300))}');
  final c = RobotClient(session, dev);
  await c.connect();
  for (final m in ['get_timer', 'get_timer_summary', 'get_timer_detail']) {
    try {
      print('$m: ${jsonEncode(await c.call(m))}');
    } catch (e) {
      print('$m: ERRO $e');
    }
  }
  c.close();
  exit(0);
}
