import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _defaultBaseUrl = 'http://192.168.0.36:8000';
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '502499232288-nla05vkd7ub40ll14ii567dugogmp9kb.apps.googleusercontent.com',
  );

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    assert(
      _defaultBaseUrl.startsWith('http://') ||
          _defaultBaseUrl.startsWith('https://') ||
          !kReleaseMode,
      'Ganti base URL dengan host server yang valid sebelum release!',
    );

    return _defaultBaseUrl;
  }

  static String get apiBaseUrl => '${baseUrl}/api';
}
