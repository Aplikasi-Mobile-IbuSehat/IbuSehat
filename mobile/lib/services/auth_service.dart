import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/services/api_cache_manager.dart';
import 'package:mobile/services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hasil login — eksplisit, tidak pakai sentinel string kosong yang rawan
/// salah baca ('' = cancel itu bug menunggu waktu).
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess();
}

class AuthCancelled extends AuthResult {
  const AuthCancelled();
}

class AuthFailure extends AuthResult {
  final String message;
  const AuthFailure(this.message);
}

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

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'avatar': avatarUrl,
        'is_onboarding_done': isOnboardingDone,
        'is_premium': isPremium,
      };

  AuthUser copyWith({bool? isOnboardingDone, bool? isPremium}) => AuthUser(
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        isOnboardingDone: isOnboardingDone ?? this.isOnboardingDone,
        isPremium: isPremium ?? this.isPremium,
      );
}

/// Logger ringan: aman dipakai di production karena tidak akan pernah
/// mencetak isi token / data sensitif, dan tidak aktif di mode release.
void _log(String message) {
  if (kDebugMode) {
    debugPrint('[AuthService] $message');
  }
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'sanctum_token';
  static const _userJsonKey = 'auth_user_json';
  static const _onboardingDoneKey = 'onboarding_done';

  static const _timeout = Duration(seconds: 15);

  AuthUser? _cachedUser;
  String? _cachedToken;

  /// Dedupe: kalau beberapa widget memanggil syncUserFromApi() bersamaan
  /// (misal splash + halaman lain), cukup 1 request yang jalan.
  Future<void>? _syncInFlight;

  AuthUser? get cachedUserSync => _cachedUser;
  bool get isPremiumSync => _cachedUser?.isPremium ?? false;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleInitFuture;

  Future<void> _ensureGoogleInitialized() {
    return _googleInitFuture ??= _googleSignIn.initialize(
      serverClientId: ApiConfig.googleServerClientId.isEmpty
          ? null
          : ApiConfig.googleServerClientId,
    );
  }

  // ================= TOKEN =================
  // Token disimpan di secure storage (Keystore/Keychain), bukan
  // SharedPreferences yang tersimpan plaintext — standar untuk credential.

  Future<String?> get token async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  Future<void> _saveToken(String? value) async {
    _cachedToken = (value == null || value.isEmpty) ? null : value;

    if (_cachedToken == null) {
      await _storage.delete(key: _tokenKey);
    } else {
      await _storage.write(key: _tokenKey, value: _cachedToken);
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

    await prefs.setString(_userJsonKey, jsonEncode(user.toJson()));

    if (user.isOnboardingDone) {
      await prefs.setBool(_onboardingDoneKey, true);
    }
  }

  Future<AuthUser?> get currentUser async {
    if (_cachedUser != null) return _cachedUser;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userJsonKey);
    if (raw == null || raw.isEmpty) return null;

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
      _cachedUser = _cachedUser!.copyWith(isOnboardingDone: true);
    }

    if (!isLocalOnly) {
      await syncOnboardingToBackend();
    }
  }

  Future<void> syncOnboardingToBackend() async {
    final t = await token;
    if (t == null || t.isEmpty) return;

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.apiBaseUrl}/user/onboarding'),
            headers: await jsonHeadersWithAuth(),
          )
          .timeout(_timeout);
      await _handleAuthExpiry(response.statusCode);
    } catch (e) {
      _log('syncOnboarding error: $e');
    }
  }

  // ================= SYNC USER =================

  Future<void> syncUserFromApi() {
    // Kalau sudah ada request yang sedang berjalan, ikut nunggu yang itu
    // saja — jangan tembak request baru.
    return _syncInFlight ??= _doSyncUserFromApi().whenComplete(() {
      _syncInFlight = null;
    });
  }

  Future<void> _doSyncUserFromApi() async {
    final t = await token;
    if (t == null || t.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/user'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $t',
        },
      ).timeout(_timeout);

      if (await _handleAuthExpiry(response.statusCode)) return;
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;

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
      _log('syncUserFromApi error: $e');
    }
  }

  /// Kalau backend bilang token sudah tidak valid (401), langsung bersihkan
  /// sesi lokal supaya user tidak terjebak di state "logged in" palsu.
  /// Return true kalau token memang expired & sudah ditangani.
  Future<bool> _handleAuthExpiry(int statusCode) async {
    if (statusCode == 401) {
      _log('Token expired/invalid — clearing local session');
      await _saveToken(null);
      await _saveUser(null);
      return true;
    }
    return false;
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

  Future<AuthResult> signInWithGoogle() async {
    if (ApiConfig.googleServerClientId.isEmpty) {
      return const AuthFailure('GOOGLE_WEB_CLIENT_ID belum di-set di ApiConfig.');
    }

    try {
      await _ensureGoogleInitialized();
    } catch (e) {
      return AuthFailure('Gagal inisialisasi Google Sign-In: $e');
    }

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const AuthCancelled();
      }
      return AuthFailure('Google Sign-In gagal: ${e.description ?? e.code}');
    } catch (e) {
      return AuthFailure('Kesalahan Google Sign-In: $e');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      return const AuthFailure('Tidak mendapat id_token dari Google.');
    }

    // ================= KIRIM KE BACKEND =================
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.apiBaseUrl}/auth/google'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'id_token': idToken}),
          )
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      return const AuthFailure('Tidak bisa terhubung ke server.');
    } on TimeoutException {
      return const AuthFailure('Server tidak merespons. Coba lagi.');
    } catch (e) {
      return AuthFailure('Kesalahan jaringan: $e');
    }

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const AuthFailure('Response server tidak valid.');
      }
      body = decoded;
    } catch (_) {
      return const AuthFailure('Response server bukan JSON.');
    }

    if (response.statusCode != 200) {
      return AuthFailure(body['message']?.toString() ?? 'Login gagal.');
    }

    final sanctumToken = body['token'];
    if (sanctumToken == null || (sanctumToken as String).isEmpty) {
      return const AuthFailure('Token tidak ditemukan.');
    }

    await _saveToken(sanctumToken);

    final userMap = body['user'];
    if (userMap is Map<String, dynamic>) {
      final user = AuthUser.fromJson(userMap);
      if (user != null) await _saveUser(user);
    }

    // Upload FCM token setelah login — tidak boleh menggagalkan login
    // kalau gagal, jadi tidak di-await blocking & dibungkus try/catch
    // (uploadTokenAfterLogin sendiri sudah aman terhadap error).
    unawaited(FcmNotificationService.instance.uploadTokenAfterLogin());

    return const AuthSuccess();
  }

  // ================= LOGOUT =================

  Future<void> signOut() async {
    ApiCacheManager.instance.clearAll();

    final t = await token;
    if (t != null && t.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('${ApiConfig.apiBaseUrl}/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $t',
          },
        ).timeout(_timeout);
      } catch (e) {
        _log('logout server error: $e');
      }
    }

    await _saveToken(null);
    await _saveUser(null);

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      _log('Google logout error: $e');
    }
  }
}