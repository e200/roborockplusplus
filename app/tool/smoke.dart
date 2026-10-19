import 'dart:ui';
// ignore_for_file: avoid_print
// Test against the real robot, read-only. Reuses the Python session in ../secrets/session.json.
//   dart run tool/smoke.dart
import 'dart:convert';
import 'dart:io';

import 'package:aspira/l10n/l10n.dart';
import 'package:aspira/cloud/roborock_cloud.dart';
import 'package:aspira/map/map_parser.dart';
import 'package:aspira/robot/robot_client.dart';

Future<void> main() async {
  final l = lookupL10n(const Locale('en'));
  final py = jsonDecode(File('../secrets/session.json').readAsStringSync()) as Map<String, dynamic>;
  final ud = py['user_data'] as Map<String, dynamic>;
  final session = CloudSession(
    email: py['email'],
    baseUrl: 'https://euiot.roborock.com',
    token: ud['token'],
    rriot: Rriot.fromJson(Map<String, dynamic>.from(ud['rriot'])),
  );

  final sw = Stopwatch()..start();
  final home = await RoborockCloud.home(session);
  print('home: ${home.devices.map((d) => d.name).toList()} rooms=${home.rooms.length} (${sw.elapsedMilliseconds} ms)');

  final client = RobotClient(session, home.devices.first);
  client.linkChanges.listen((l) => print('link: $l (${sw.elapsedMilliseconds} ms)'));
  await client.connect();
  for (var i = 0; i < 20 && client.link != LinkState.local; i++) {
    await Future.delayed(const Duration(milliseconds: 250));
  }

  final s = await client.status();
  print(
    'status: ${s.stateLabel(l)} · battery ${s.battery}% · suction ${s.fanLabel(l)} · water ${s.waterLabel(l)} · via ${client.link}',
  );

  final mapping = await client.roomMapping();
  print('rooms: ${{for (final e in mapping.entries) e.key: home.rooms[e.value] ?? e.value}}');

  final raw = await client.map();
  final map = MapParser.parse(raw);
  print(
    'map: ${raw.length} bytes · rooms=${map.rooms.length} · robot=(${map.robot?.x},${map.robot?.y}) '
    'dock=(${map.charger?.x},${map.charger?.y}) · robot room=${map.robotRoom} (${sw.elapsedMilliseconds} ms)',
  );

  client.close();
  exit(0);
}
