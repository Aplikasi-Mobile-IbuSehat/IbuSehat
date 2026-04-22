import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isOnboardingDone;

  const AuthUser({
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isOnboardingDone = false,
  });

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

  // Singleton GoogleSignIn v7.2+
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _initFuture;

  Future<void> _ensureGoogleInitialized() async {
    if (_initFuture != null) return _initFuture;
    _initFuture = _googleSignIn.initialize(
      serverClientId: ApiConfig.googleServerClientId.isEmpty 
          ? null 
          : ApiConfig.googleServerClientId,
    );
    return _initFuture;
  }

  // ─── Token ───────────────────────────────────────────────────────────────

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

  // ─── User ─────────────────────────────────────────────────────────────────

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
      }),
    );

    // Sync juga ke flag onboarding lokal jika TRUE dari backend
    if (user.isOnboardingDone) {
      await setOnboardingDone(isLocalOnly: true);
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

  // ─── Status ───────────────────────────────────────────────────────────────

  Future<bool> get isLoggedIn async {
    final t = await token;
    return t != null && t.isNotEmpty;
  }

  Future<bool> get isOnboardingDone async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingDoneKey) ?? false;
  }

  Future<void> setOnboardingDone({bool isLocalOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, true);

    if (!isLocalOnly) {
      await syncOnboardingToBackend();
    }
  }

  Future<void> syncOnboardingToBackend() async {
    final t = await token;
    if (t == null || t.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/user/onboarding'),
        headers: await jsonHeadersWithAuth(),
      );
      debugPrint('syncOnboardingToBackend: ${response.statusCode}');
    } catch (e) {
      debugPrint('syncOnboardingToBackend error: $e');
    }
  }

  // ─── Sync dari API ────────────────────────────────────────────────────────

  Future<void> syncUserFromApi() async {
    final t = await token;
    if (t == null || t.isEmpty) return;
    try {
      final r = await http
          .get(
            Uri.parse('${ApiConfig.apiBaseUrl}/user'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $t',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (r.statusCode != 200) return;

      final decoded = jsonDecode(r.body);
      if (decoded is! Map<String, dynamic>) return;

      await _saveUser(AuthUser(
        name: decoded['name'] as String? ?? 'Pengguna',
        email: decoded['email'] as String? ?? '',
        avatarUrl: decoded['avatar'] as String?,
        isOnboardingDone: decoded['is_onboarding_done'] == true,
      ));
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

  // ─── Sign In ──────────────────────────────────────────────────────────────

  /// Return value:
  /// - `null`  → sukses
  /// - `''`    → user membatalkan (tidak tampilkan SnackBar)
  /// - string  → pesan error untuk ditampilkan ke user
  Future<String?> signInWithGoogle() async {
    // Pastikan Web Client ID sudah di-set
    if (ApiConfig.googleServerClientId.isEmpty) {
      return 'GOOGLE_WEB_CLIENT_ID belum di-set di ApiConfig.';
    }

    // Inisialisasi Google Sign-In
    try {
      await _ensureGoogleInitialized();
    } catch (e) {
      debugPrint('GoogleSignIn init error: $e');
      return 'Gagal inisialisasi Google Sign-In: $e';
    }

    // Tampilkan picker Google
    final GoogleSignInAccount account;
    try {
      // Pastikan session lama benar-benar bersih agar picker muncul
      await _googleSignIn.signOut();
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return ''; // user batal
      }
      debugPrint('GoogleSignIn.authenticate error: $e');
      return 'Terjadi kesalahan saat membuka Google Sign-In: $e';
    } catch (e) {
      debugPrint('GoogleSignIn.authenticate error: $e');
      return 'Terjadi kesalahan saat membuka Google Sign-In: $e';
    }

    // Ambil id_token
    final auth = account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      return 'Tidak mendapat id_token dari Google.\n'
          'Pastikan googleServerClientId di ApiConfig menggunakan '
          'Web Client ID (client_type: 3), bukan Android Client ID.';
    }

    // Kirim id_token ke backend Laravel
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
    } on SocketException catch (e) {
      debugPrint('auth/google SocketException: $e');
      return 'Tidak bisa terhubung ke server.\n'
          'Pastikan Laravel jalan dengan:\n'
          'php artisan serve --host=0.0.0.0\n'
          'dan IP di ApiConfig sudah benar.';
    } on http.ClientException catch (e) {
      debugPrint('auth/google ClientException: $e');
      return 'Gagal menghubungi server. Periksa URL di ApiConfig.';
    } catch (e) {
      debugPrint('auth/google error: $e');
      return 'Kesalahan jaringan: $e';
    }

    // Parse response
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return 'Respons server tidak valid (${response.statusCode}).';
      }
      body = decoded;
    } catch (_) {
      debugPrint('auth/google response body: ${response.body}');
      return 'Respons server bukan JSON (${response.statusCode}).\n'
          'Pastikan backend berjalan di ${ApiConfig.apiBaseUrl}.';
    }

    if (response.statusCode != 200) {
      return body['message']?.toString() ??
          'Login gagal (${response.statusCode}).';
    }

    final sanctumToken = body['token'] as String?;
    if (sanctumToken == null || sanctumToken.isEmpty) {
      return 'Respons server tidak berisi token.';
    }

    // Simpan token & data user
    await _saveToken(sanctumToken);

    final userMap = body['user'];
    if (userMap is Map<String, dynamic>) {
      final u = AuthUser.fromJson(userMap);
      if (u != null) await _saveUser(u);
    }

    return null; // sukses
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    // Hapus token di server
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
        debugPrint('signOut server error: $e');
        // Tetap lanjut bersihkan lokal meskipun server tidak terjangkau
      }
    }

    // Bersihkan lokal
    await _saveToken(null);
    await _saveUser(null);

    // Sign out dari Google
    try {
      await _googleSignIn.signOut();
      // Jangan gunakan disconnect() kecuali benar-benar ingin revoke akses permanen
      // (Bisa menyebabkan user harus klik "Allow" lagi setiap login)
      // await _googleSignIn.disconnect(); 
    } catch (e) {
      debugPrint('Google signOut error: $e');
    }
  }
}