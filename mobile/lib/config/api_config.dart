import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '502499232288-nla05vkd7ub40ll14ii567dugogmp9kb.apps.googleusercontent.com',
  );

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;

    const devIp = '10.250.212.134';

    assert(
      devIp != '127.0.0.1' || !kReleaseMode,
      'Ganti devIp dengan IP server production sebelum release!',
    );

    return 'http://$devIp:8000';
  }

  static String get apiBaseUrl => '$baseUrl/api';
}