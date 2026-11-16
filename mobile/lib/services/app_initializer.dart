import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/theme/app_theme.dart';

enum InitialRoute { login, onboarding, home }

class AppInitializer {
  static Future<InitialRoute> initialize() {
    final completer = Completer<InitialRoute>();

    final timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException(
            'Koneksi lambat. Gagal terhubung ke server dalam 15 detik.',
          ),
        );
      }
    });

    _performInitialization().then((result) {
      if (!completer.isCompleted) completer.complete(result);
    }).catchError((Object e) {
      if (!completer.isCompleted) completer.completeError(e);
    }).whenComplete(() {
      timeoutTimer.cancel();
    });

    return completer.future;
  }

  static Future<InitialRoute> _performInitialization() async {
    // Semua init dijalankan PARALEL, bukan berurutan, supaya total waktu
    // startup = waktu proses terlama, bukan jumlah semuanya.
    await Future.wait([
      _checkConnection(),
      initializeDateFormatting('id', null),
      appThemeController.load(),
      _initChatbot(),
    ]);

    final loggedIn = await AuthService.instance.isLoggedIn;

    if (!loggedIn) {
      return InitialRoute.login;
    }

    try {
      await AuthService.instance.syncUserFromApi().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Abaikan error sync, lanjut pakai data cache lokal
    }

    // Cek onboarding SETELAH sync selesai
    final onboardingDone = await AuthService.instance.isOnboardingDone;

    if (!onboardingDone) {
      return InitialRoute.onboarding;
    } else {
      return InitialRoute.home;
    }
  }

  static Future<void> _checkConnection() async {
    try {
      await http
          .get(Uri.parse('${ApiConfig.apiBaseUrl}/'))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server. Pastikan koneksi internet Anda stabil.');
    }
  }

  static Future<void> _initChatbot() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}