// ignore_for_file: avoid_print
// Reads each setting's format from the real robot. Read-only.
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
  for (final m in [
    'get_carpet_mode',
    'get_carpet_clean_mode',
    'app_get_carpet_deep_clean_status',
    'get_dust_collection_mode',
    'get_dust_collection_switch_status',
    'app_get_dryer_setting',
    'get_smart_wash_params',
    'get_wash_towel_mode',
    'get_wash_water_temperature',
    'get_dnd_timer',
    'get_timer',
    'get_server_timer',
    'get_led_status',
    'get_flow_led_status',
    'get_clean_motor_mode',
    'get_identify_furniture_status',
    'get_avoid_collision_status',
    'get_corner_clean_mode',
    'get_stretch_tag_status',
    'get_fw_features',
    'get_clean_sequence',
  ]) {
    try {
      print('$m => ${jsonEncode(await c.call(m))}');
    } catch (e) {
      print('$m => ERRO $e');
    }
  }
  c.close();
  exit(0);
}
