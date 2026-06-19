import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  // Bisa di-override saat build:
  // flutter run --dart-define=API_BASE_URL=https://xxx.ngrok-free.app
  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '502499232288-nla05vkd7ub40ll14ii567dugogmp9kb.apps.googleusercontent.com',
  );

  static String get baseUrl {
    // Prioritas 1: jika ada --dart-define=API_BASE_URL, pakai itu
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;

    // Prioritas 2: sesuai mode
    if (kReleaseMode) {
      return 'https://ibusehat123.com';
    }

    // Pakai ngrok  → 'https://shingle-immodest-styling.ngrok-free.dev'
    // Pakai emulator → 'http://10.0.2.2:8000'
    // Pakai HP fisik → 'http://192.168.88.10:8000'
    return 'https://shingle-immodest-styling.ngrok-free.dev';
  }

  static String get apiBaseUrl => '$baseUrl/api';
}
