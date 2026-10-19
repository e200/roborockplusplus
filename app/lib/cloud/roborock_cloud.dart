import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Cloud failures the user can act on; the UI shows a localized text per kind.
enum CloudErrorKind {
  accountNotFound,
  tooManyCodes,
  invalidCode,
  acceptTerms,
  sessionExpired,
  noHome,
  noRobots,
  network,
  other,
}

class CloudException implements Exception {
  final CloudErrorKind kind;

  /// English detail for logs (for [CloudErrorKind.other], the server's own message).
  final String message;
  final int? code;

  const CloudException(this.kind, this.message, [this.code]);

  @override
  String toString() => code == null ? message : '$message (code $code)';
}

/// IoT credentials returned at login; they sign home API requests (Hawk) and MQTT.
class Rriot {
  final String u, s, h, k;

  /// URLs: `a` home API, `m` MQTT broker.
  final String apiUrl, mqttUrl;

  const Rriot({
    required this.u,
    required this.s,
    required this.h,
    required this.k,
    required this.apiUrl,
    required this.mqttUrl,
  });

  factory Rriot.fromJson(Map<String, dynamic> j) {
    final r = j['r'] as Map<String, dynamic>;
    return Rriot(u: j['u'], s: j['s'], h: j['h'], k: j['k'], apiUrl: r['a'], mqttUrl: r['m']);
  }

  Map<String, dynamic> toJson() => {
    'u': u,
    's': s,
    'h': h,
    'k': k,
    'r': {'a': apiUrl, 'm': mqttUrl},
  };
}

class CloudSession {
  final String email;
  final String baseUrl;
  final String token;
  final Rriot rriot;

  const CloudSession({required this.email, required this.baseUrl, required this.token, required this.rriot});

  factory CloudSession.fromJson(Map<String, dynamic> j) =>
      CloudSession(email: j['email'], baseUrl: j['baseUrl'], token: j['token'], rriot: Rriot.fromJson(j['rriot']));

  Map<String, dynamic> toJson() => {'email': email, 'baseUrl': baseUrl, 'token': token, 'rriot': rriot.toJson()};
}

class CloudDevice {
  final String duid;
  final String name;
  final String localKey;
  final String productId;
  final bool online;

  const CloudDevice({
    required this.duid,
    required this.name,
    required this.localKey,
    required this.productId,
    required this.online,
  });
}

class CloudHome {
  final List<CloudDevice> devices;

  /// Home rooms: IoT id → name. The robot uses segment ids; `get_room_mapping` links the two.
  final Map<String, String> rooms;

  const CloudHome(this.devices, this.rooms);
}

/// Roborock cloud API client (ported from python-roborock `web_api.py`).
class RoborockCloud {
  static const _regions = [
    'https://euiot.roborock.com',
    'https://usiot.roborock.com',
    'https://cniot.roborock.com',
    'https://ruiot.roborock.com',
  ];

  final String email;

  /// Stable id of this install. The login code is bound to it: it must be the same when requesting the code
  /// and when logging in.
  final String deviceId;
  final http.Client _http;

  String? _baseUrl, _country;
  int? _countryCode;

  RoborockCloud({required this.email, required this.deviceId, http.Client? client}) : _http = client ?? http.Client();

  String get _clientId => base64.encode(md5.convert(utf8.encode(email + deviceId)).bytes);

  Future<void> _resolveRegion() async {
    if (_baseUrl != null) return;
    for (final region in _regions) {
      final res = await _json(
        _http.post(
          Uri.parse(
            '$region/api/v1/getUrlByEmail',
          ).replace(queryParameters: {'email': email, 'needtwostepauth': 'false'}),
        ),
      );
      if (res['code'] != 200) continue;
      final data = res['data'] as Map<String, dynamic>;
      if (data['country'] == null && data['countrycode'] == null) continue;
      _baseUrl = data['url'];
      _country = data['country'];
      _countryCode = int.tryParse('${data['countrycode']}');
      return;
    }
    throw const CloudException(CloudErrorKind.accountNotFound, 'No Roborock account for this email');
  }

  Future<void> requestCode() async {
    await _resolveRegion();
    final res = await _json(
      _http.post(
        Uri.parse('$_baseUrl/api/v4/email/code/send'),
        headers: {'header_clientid': _clientId, 'header_clientlang': 'en'},
        body: {'email': email, 'type': 'login', 'platform': ''},
      ),
    );
    switch (res['code']) {
      case 200:
        return;
      case 2008:
        throw const CloudException(CloudErrorKind.accountNotFound, 'Account does not exist', 2008);
      case 9002:
        throw const CloudException(CloudErrorKind.tooManyCodes, 'Too many code requests', 9002);
    }
    throw CloudException(CloudErrorKind.other, '${res['msg']}', res['code']);
  }

  Future<CloudSession> login(String code) async {
    await _resolveRegion();
    final ks = _randomString(16);
    final sign = await _json(
      _http.post(
        Uri.parse('$_baseUrl/api/v3/key/sign').replace(queryParameters: {'s': ks}),
        headers: {'header_clientid': _clientId},
      ),
    );
    final k = (sign['data'] as Map?)?['k'];
    if (k == null) throw CloudException(CloudErrorKind.other, 'Could not sign the login request', sign['code']);

    final res = await _json(
      _http.post(
        Uri.parse('$_baseUrl/api/v4/auth/email/login/code'),
        headers: {
          'header_clientid': _clientId,
          'x-mercy-ks': ks,
          'x-mercy-k': k,
          'header_clientlang': 'en',
          'header_appversion': '4.54.02',
          'header_phonesystem': 'iOS',
          'header_phonemodel': 'iPhone16,1',
        },
        body: {
          'country': '$_country',
          'countryCode': '$_countryCode',
          'email': email,
          'code': code,
          ...await _agreementVersion(),
        },
      ),
    );
    switch (res['code']) {
      case 200:
        final data = res['data'] as Map<String, dynamic>;
        return CloudSession(
          email: email,
          baseUrl: _baseUrl!,
          token: data['token'],
          rriot: Rriot.fromJson(data['rriot']),
        );
      case 2018:
        throw const CloudException(CloudErrorKind.invalidCode, 'Invalid code', 2018);
      case 3009:
      case 3006:
        throw CloudException(CloudErrorKind.acceptTerms, 'Terms must be accepted in the Roborock app', res['code']);
    }
    throw CloudException(CloudErrorKind.other, '${res['msg']}', res['code']);
  }

  /// Login rejects outdated agreement versions; the fallback is the one the reference library uses.
  Future<Map<String, String>> _agreementVersion() async {
    try {
      final res = await _json(
        _http.get(
          Uri.parse('$_baseUrl/api/v3/app/agreement/latest').replace(queryParameters: {'country': '$_country'}),
          headers: {'header_clientlang': 'en'},
        ),
      );
      final d = res['data'] as Map?;
      if (res['code'] == 200 && d?['majorVersion'] is int && d?['minorVersion'] is int) {
        return {'majorVersion': '${d!['majorVersion']}', 'minorVersion': '${d['minorVersion']}'};
      }
    } on Exception {
      // never blocks login
    }
    return {'majorVersion': '14', 'minorVersion': '0'};
  }

  static Future<CloudHome> home(CloudSession s, {http.Client? client}) async {
    final c = client ?? http.Client();
    final detail = await _json(
      c.get(Uri.parse('${s.baseUrl}/api/v1/getHomeDetail'), headers: {'Authorization': s.token}),
    );
    if (detail['code'] == 2010) throw const CloudException(CloudErrorKind.sessionExpired, 'Session expired', 2010);
    final homeId = (detail['data'] as Map?)?['rrHomeId'];
    if (homeId == null) throw CloudException(CloudErrorKind.noHome, 'No home on this account', detail['code']);

    final path = '/v3/user/homes/$homeId';
    final res = await _json(
      c.get(Uri.parse('${s.rriot.apiUrl}$path'), headers: {'Authorization': hawk(s.rriot, path)}),
    );
    if (res['success'] != true) {
      throw CloudException(CloudErrorKind.other, 'Could not read the home: ${res['msg'] ?? res}');
    }
    final result = res['result'] as Map<String, dynamic>;
    final devices = [
      for (final d in [...?result['devices'] as List?, ...?result['receivedDevices'] as List?])
        CloudDevice(
          duid: d['duid'],
          name: d['name'] ?? 'Roborock',
          localKey: d['localKey'],
          productId: '${d['productId']}',
          online: d['online'] == true,
        ),
    ];
    final rooms = {for (final r in (result['rooms'] as List? ?? const [])) '${r['id']}': '${r['name']}'};
    return CloudHome(devices, rooms);
  }

  /// Hawk authentication for home API requests.
  static String hawk(Rriot r, String path, {DateTime? now, String? nonce}) {
    final ts = ((now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000).toString();
    final n = nonce ?? _randomString(8);
    final pre = [r.u, r.s, n, ts, md5.convert(utf8.encode(path)).toString(), '', ''].join(':');
    final mac = base64.encode(Hmac(sha256, utf8.encode(r.h)).convert(utf8.encode(pre)).bytes);
    return 'Hawk id="${r.u}",s="${r.s}",ts="$ts",nonce="$n",mac="$mac"';
  }

  static Future<Map<String, dynamic>> _json(Future<http.Response> request) async {
    final http.Response res;
    try {
      res = await request;
    } on Exception catch (e) {
      throw CloudException(CloudErrorKind.network, 'No connection to the Roborock cloud: $e');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw CloudException(CloudErrorKind.other, 'Unexpected response (${res.statusCode})');
    }
    return body;
  }

  static String _randomString(int n) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    return String.fromCharCodes(List.generate(n, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
}
