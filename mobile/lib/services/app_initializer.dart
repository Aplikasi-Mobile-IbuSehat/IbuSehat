import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/theme/app_theme.dart';

enum InitialRoute { login, onboarding, home }

class AppInitializer {
  static Future<InitialRoute> initialize() async {
    return await Future.any([
      _performInitialization(),
      Future.delayed(const Duration(seconds: 15), () {
        throw TimeoutException('Koneksi lambat. Gagal terhubung ke server dalam 15 detik.');
      }),
    ]);
  }

  static Future<InitialRoute> _performInitialization() async {
    try {
      await http.get(Uri.parse('${ApiConfig.apiBaseUrl}/')).timeout(const Duration(seconds: 5));
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server. Pastikan koneksi internet Anda stabil.');
    }

    await Future.wait([
      _initFirebase(),
      initializeDateFormatting('id', null),
      appThemeController.load(),
      _initChatbot(),
      _initPaymentGateway(),
    ]);

    final loggedIn = await AuthService.instance.isLoggedIn;

    if (!loggedIn) {
      return InitialRoute.login;
    }

    // ✅ FIX 1: Sync dulu dari backend SEBELUM cek onboarding,
    // supaya isOnboardingDone selalu pakai data terbaru dari server.
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

  static Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }

  static Future<void> _initChatbot() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<void> _initPaymentGateway() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}