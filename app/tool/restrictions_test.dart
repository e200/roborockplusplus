// ignore_for_file: avoid_print
// Checks the save_map format on the real robot with a tiny no-go zone, and deletes it at the end.
import 'dart:convert';
import 'dart:io';

import 'package:aspira/cloud/roborock_cloud.dart';
import 'package:aspira/map/map_parser.dart';
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
  var map = MapParser.parse(await c.map());
  print('before: no-go=${map.noGoAreas.length} no-mop=${map.noMopAreas.length} walls=${map.virtualWalls.length}');
  if (map.noGoAreas.isNotEmpty || map.noMopAreas.isNotEmpty || map.virtualWalls.isNotEmpty) {
    print('restrictions already exist: leaving them alone');
    c.close();
    exit(0);
  }
  final k = map.rooms[7]!; // kitchen
  final x = k.x0 + 200, y = k.y0 + 200;
  final wall = [1, x, y, x + 300, y];
  final noMop = [2, x, y + 400, x + 200, y + 400, x + 200, y + 600, x, y + 600];
  print('save_map(wall+no-mop): ${await c.call('save_map', [wall, noMop])}');
  await Future<void>.delayed(const Duration(seconds: 3));
  map = MapParser.parse(await c.map());
  print('after: walls=${map.virtualWalls.length} no-mop=${map.noMopAreas.length} no-go=${map.noGoAreas.length}');
  print('save_map(vazio): ${await c.call('save_map', [])}');
  await Future<void>.delayed(const Duration(seconds: 3));
  map = MapParser.parse(await c.map());
  print('cleaned up: no-go=${map.noGoAreas.length} no-mop=${map.noMopAreas.length} walls=${map.virtualWalls.length}');
  c.close();
  exit(0);
}
