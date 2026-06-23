import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
// import 'package:mobile/services/api_cache_manager.dart';
// import 'package:mobile/services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isOnboardingDone;
  final bool isPremium;

  const AuthUser({
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isOnboardingDone = false,
    this.isPremium = false,
  });

  static bool _parsePremium(Map<String, dynamic> json) {
    if (json['is_premium'] != true) return false;

    final until = json['premium_until'];

    if (until == null) return true;

    try {
      return DateTime.parse(until.toString()).isAfter(DateTime.now());
    } catch (_) {
      return true;
    }
  }

  static AuthUser? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final name = json['name'] as String?;
    final email = json['email'] as String?;

    if (name == null || email == null) return null;

    return AuthUser(
      name: name,
      email: email,
      avatarUrl: json['avatar'] as String?,
      isOnboardingDone: json['is_onboarding_done'] == true,
      isPremium: _parsePremium(json),
    );
  }
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _tokenKey = 'sanctum_token';
  static const _userJsonKey = 'auth_user_json';
  static const _onboardingDoneKey = 'onboarding_done';

  AuthUser? _cachedUser;

  AuthUser? get cachedUserSync => _cachedUser;

  bool get isPremiumSync => _cachedUser?.isPremium ?? false;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static Future<void>? _initFuture;

  Future<void> _ensureGoogleInitialized() async {
    if (_initFuture != null) {
      return _initFuture;
    }

    _initFuture = _googleSignIn.initialize(
      serverClientId: ApiConfig.googleServerClientId.isEmpty
          ? null
          : ApiConfig.googleServerClientId,
    );

    return _initFuture;
  }

  // ================= TOKEN =================

  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String? value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value == null || value.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, value);
    }
  }

  // ================= USER =================

  Future<void> _saveUser(AuthUser? user) async {
    _cachedUser = user;

    final prefs = await SharedPreferences.getInstance();

    if (user == null) {
      await prefs.remove(_userJsonKey);

      return;
    }

    await prefs.setString(
      _userJsonKey,

      jsonEncode({
        'name': user.name,

        'email': user.email,

        'avatar': user.avatarUrl,

        'is_onboarding_done': user.isOnboardingDone,

        'is_premium': user.isPremium,
      }),
    );

    if (user.isOnboardingDone) {
      await prefs.setBool(_onboardingDoneKey, true);
    }
  }

  Future<AuthUser?> get currentUser async {
    if (_cachedUser != null) {
      return _cachedUser;
    }

    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_userJsonKey);

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final parsed = AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);

      _cachedUser = parsed;

      return parsed;
    } catch (_) {
      return null;
    }
  }
  // ================= STATUS =================

  Future<bool> get isLoggedIn async {
    final t = await token;

    return t != null && t.isNotEmpty;
  }

  Future<bool> get isOnboardingDone async {
    final prefs = await SharedPreferences.getInstance();

    final local = prefs.getBool(_onboardingDoneKey) ?? false;

    final user = await currentUser;

    final remote = user?.isOnboardingDone ?? false;

    return local || remote;
  }

  Future<void> setOnboardingDone({bool isLocalOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_onboardingDoneKey, true);

    if (_cachedUser != null) {
      _cachedUser = AuthUser(
        name: _cachedUser!.name,

        email: _cachedUser!.email,

        avatarUrl: _cachedUser!.avatarUrl,

        isOnboardingDone: true,

        isPremium: _cachedUser!.isPremium,
      );
    }

    if (!isLocalOnly) {
      await syncOnboardingToBackend();
    }
  }

  Future<void> syncOnboardingToBackend() async {
    final t = await token;

    if (t == null || t.isEmpty) {
      return;
    }

    try {
      await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/user/onboarding'),

        headers: await jsonHeadersWithAuth(),
      );
    } catch (e) {
      debugPrint('syncOnboarding error: $e');
    }
  }

  // ================= SYNC USER =================

  Future<void> syncUserFromApi() async {
    final t = await token;

    if (t == null || t.isEmpty) {
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.apiBaseUrl}/user'),

            headers: {
              'Accept': 'application/json',

              'Authorization': 'Bearer $t',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return;
      }

      await _saveUser(
        AuthUser(
          name: decoded['name'] ?? 'Pengguna',

          email: decoded['email'] ?? '',

          avatarUrl: decoded['avatar'],

          isOnboardingDone: decoded['is_onboarding_done'] == true,

          isPremium: AuthUser._parsePremium(decoded),
        ),
      );
    } catch (e) {
      debugPrint('syncUserFromApi error: $e');
    }
  }

  Future<Map<String, String>> jsonHeadersWithAuth() async {
    final t = await token;

    return {
      'Content-Type': 'application/json',

      'Accept': 'application/json',

      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  // ================= GOOGLE LOGIN =================

  Future<String?> signInWithGoogle() async {
    if (ApiConfig.googleServerClientId.isEmpty) {
      return 'GOOGLE_WEB_CLIENT_ID belum di-set di ApiConfig.';
    }

    try {
      await _ensureGoogleInitialized();
    } catch (e) {
      return 'Gagal inisialisasi Google Sign-In: $e';
    }

    final GoogleSignInAccount account;

    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return '';
      }

      return 'Google Sign-In gagal: $e';
    } catch (e) {
      return 'Kesalahan Google Sign-In: $e';
    }

    final auth = account.authentication;

    final idToken = auth.idToken;

    if (idToken == null || idToken.isEmpty) {
      return 'Tidak mendapat id_token dari Google.';
    }
    // ================= KIRIM KE LARAVEL =================

    http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.apiBaseUrl}/auth/google'),

            headers: {
              'Content-Type': 'application/json',

              'Accept': 'application/json',
            },

            body: jsonEncode({'id_token': idToken}),
          )
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      return 'Tidak bisa terhubung ke server.';
    } catch (e) {
      return 'Kesalahan jaringan: $e';
    }

    Map<String, dynamic> body;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return 'Response server tidak valid.';
      }

      body = decoded;
    } catch (_) {
      return 'Response server bukan JSON.';
    }

    if (response.statusCode != 200) {
      return body['message'] ?? 'Login gagal.';
    }

    final sanctumToken = body['token'];

    if (sanctumToken == null || sanctumToken.isEmpty) {
      return 'Token tidak ditemukan.';
    }

    await _saveToken(sanctumToken);

    // upload FCM token setelah login
    // TODO: Implement FCM notification service
    // await FcmNotificationService.instance.uploadTokenAfterLogin();

    final userMap = body['user'];

    if (userMap is Map<String, dynamic>) {
      final user = AuthUser.fromJson(userMap);

      if (user != null) {
        await _saveUser(user);
      }
    }

    return null;
  }

  // ================= LOGOUT =================

  Future<void> signOut() async {
    // clear cache aplikasi
    // TODO: Implement API cache manager
    // ApiCacheManager.instance.clearAll();

    final t = await token;

    if (t != null && t.isNotEmpty) {
      try {
        await http
            .post(
              Uri.parse('${ApiConfig.apiBaseUrl}/logout'),

              headers: {
                'Accept': 'application/json',

                'Authorization': 'Bearer $t',
              },
            )
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('logout server error: $e');
      }
    }

    await _saveToken(null);

    await _saveUser(null);

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google logout error: $e');
    }
  }
}
