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

  /// True jika data kesehatan (tinggi, berat, target berat, umur, tanggal
  /// melahirkan) sudah lengkap. Syarat akses Chatbot AI & program latihan.
  final bool healthDataComplete;

  const AuthUser({
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isOnboardingDone = false,
    this.healthDataComplete = false,
  });

  /// Pakai `health_data_complete` dari API; kalau tidak ada, hitung dari
  /// field kesehatan dengan rentang validasi yang sama seperti form.
  static bool parseHealthDataComplete(Map<String, dynamic> json) {
    final flag = json['health_data_complete'];
    if (flag is bool) return flag;
    return isHealthDataComplete(json);
  }

  static bool isHealthDataComplete(Map<String, dynamic> json) {
    bool inRange(dynamic v, num min, num max) {
      final n = v is num ? v : num.tryParse(v?.toString() ?? '');
      return n != null && n >= min && n <= max;
    }

    final date = json['delivery_date']?.toString() ?? '';
    return inRange(json['height'], 100, 220) &&
        inRange(json['weight'], 30, 200) &&
        inRange(json['target_weight'], 30, 200) &&
        inRange(json['age'], 12, 80) &&
        DateTime.tryParse(date) != null;
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
      healthDataComplete: parseHealthDataComplete(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'avatar': avatarUrl,
        'is_onboarding_done': isOnboardingDone,
        'health_data_complete': healthDataComplete,
      };

  AuthUser copyWith({bool? isOnboardingDone, bool? healthDataComplete}) =>
      AuthUser(
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        isOnboardingDone: isOnboardingDone ?? this.isOnboardingDone,
        healthDataComplete: healthDataComplete ?? this.healthDataComplete,
      );
}

/// Logger ringan: aman dipakai di production karena tidak akan pernah
/// mencetak isi token / data sensitif, dan tidak aktif di mode release.
void _log(String message) {
  if (kDebugMode) {
    debugPrint('[AuthService] $message');
  }
}

class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  /// Notifier yang dipancarkan setiap kali data user berubah.
  /// Widget bisa pakai [ValueListenableBuilder] atau [ListenableBuilder]
  /// untuk rebuild otomatis tanpa perlu polling manual.
  final ValueNotifier<AuthUser?> userNotifier = ValueNotifier<AuthUser?>(null);

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
  bool get healthDataCompleteSync => _cachedUser?.healthDataComplete ?? false;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleInitFuture;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitFuture != null) {
      return _googleInitFuture;
    }

    // ── WEB (aktif) ─────────────────────────────────────────────────────
    // Di browser plugin memakai Google Identity Services. Client ID dikirim
    // sebagai `clientId`; `serverClientId` tidak didukung di web.
    _googleInitFuture = _googleSignIn.initialize(
      clientId: ApiConfig.googleServerClientId.isEmpty
          ? null
          : ApiConfig.googleServerClientId,
    );

    // ── MOBILE (Android/iOS) — dinonaktifkan sementara, JANGAN DIHAPUS ──
    // Untuk mengaktifkan lagi login mobile: hapus blok WEB di atas dan
    // buka komentar blok ini.
    //
    // _googleInitFuture = _googleSignIn.initialize(
    //   serverClientId: ApiConfig.googleServerClientId.isEmpty
    //       ? null
    //       : ApiConfig.googleServerClientId,
    // );

    return _googleInitFuture;
  }

  // ================= TOKEN =================
  // Token disimpan di secure storage (Keystore/Keychain), bukan
  // SharedPreferences yang tersimpan plaintext — standar untuk credential.

  Future<String?> get token async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: _tokenKey);
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }

    // Migrasi token lama dari SharedPreferences (versi sebelum secure storage).
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_tokenKey);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _saveToken(legacyToken);
      await prefs.remove(_tokenKey);
    }

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

    // Beritahu semua listener (widget) bahwa user telah berubah.
    userNotifier.value = user;
    notifyListeners();

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
      // Sync ke notifier agar widget yang listen mendapat nilai awal yang benar.
      userNotifier.value = parsed;
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

  Future<void> syncOnboardingToBackend({Map<String, dynamic>? healthData}) async {
    final t = await token;
    if (t == null || t.isEmpty) return;

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.apiBaseUrl}/user/onboarding'),
            headers: await jsonHeadersWithAuth(),
            body: jsonEncode(healthData ?? {}),
          )
          .timeout(_timeout);
      if (await _handleAuthExpiry(response.statusCode)) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> &&
            decoded['health_data_complete'] is bool) {
          await _setHealthDataComplete(decoded['health_data_complete'] as bool);
        }
      }
    } catch (e) {
      _log('syncOnboarding error: $e');
    }
  }

  /// Perbarui flag kelengkapan data kesehatan di cache + beri tahu listener.
  Future<void> _setHealthDataComplete(bool value) async {
    final user = _cachedUser ?? await currentUser;
    if (user == null || user.healthDataComplete == value) return;
    await _saveUser(user.copyWith(healthDataComplete: value));
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
          .timeout(_timeout);

      if (await _handleAuthExpiry(response.statusCode)) return;

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
          healthDataComplete: AuthUser.parseHealthDataComplete(decoded),
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

  Future<Map<String, dynamic>> fetchProfile() async {
    final t = await token;
    if (t == null || t.isEmpty) {
      throw Exception('Anda belum login. Silakan masuk kembali.');
    }

    final response = await http
        .get(
          Uri.parse('${ApiConfig.apiBaseUrl}/profile'),
          headers: await jsonHeadersWithAuth(),
        )
        .timeout(_timeout);

    if (await _handleAuthExpiry(response.statusCode)) {
      throw Exception('Sesi habis, silakan login ulang.');
    }

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data kesehatan.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['data'] is! Map<String, dynamic>) {
      throw Exception('Data kesehatan tidak valid.');
    }

    return decoded['data'] as Map<String, dynamic>;
  }

  Future<void> updateHealthProfile({
    required double height,
    required double weight,
    required double targetWeight,
    required int age,
    required String deliveryDate,
  }) async {
    final t = await token;
    if (t == null || t.isEmpty) {
      throw Exception('Anda belum login. Silakan masuk kembali.');
    }

    final response = await http
        .put(
          Uri.parse('${ApiConfig.apiBaseUrl}/profile'),
          headers: await jsonHeadersWithAuth(),
          body: jsonEncode({
            'height': height,
            'weight': weight,
            'target_weight': targetWeight,
            'age': age,
            'delivery_date': deliveryDate,
          }),
        )
        .timeout(_timeout);

    if (await _handleAuthExpiry(response.statusCode)) {
      throw Exception('Sesi habis, silakan login ulang.');
    }

    if (response.statusCode != 200) {
      String message = 'Gagal menyimpan data kesehatan.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] is String) {
          message = decoded['message'] as String;
        }
      } catch (_) {}
      throw Exception(message);
    }

    var complete = true;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> &&
          decoded['data'] is Map<String, dynamic>) {
        complete = AuthUser.parseHealthDataComplete(
            decoded['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    await _setHealthDataComplete(complete);
  }

  // ================= GOOGLE LOGIN =================

  // ── WEB (aktif) ───────────────────────────────────────────────────────
  // Di browser, Google mewajibkan tombol resmi Google Identity Services
  // (lihat AuthPage): `authenticate()` tidak tersedia di web. Hasil login
  // datang lewat stream [googleAuthEvents], lalu id_token-nya ditukar ke
  // token Sanctum lewat [signInWithGoogleAccount].

  /// Siapkan Google Identity Services. Panggil sebelum tombol dirender.
  Future<void> initGoogleSignInWeb() => _ensureGoogleInitialized();

  /// Event login/logout dari tombol Google di web.
  Stream<GoogleSignInAuthenticationEvent> get googleAuthEvents =>
      _googleSignIn.authenticationEvents;

  /// Selesaikan login setelah user memilih akun di tombol Google (web).
  Future<AuthResult> signInWithGoogleAccount(GoogleSignInAccount account) {
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      return Future.value(
        const AuthFailure('Tidak mendapat id_token dari Google.'),
      );
    }
    return _loginWithGoogleIdToken(idToken);
  }

  /// Tukar id_token Google dengan token Sanctum di backend.
  Future<AuthResult> _loginWithGoogleIdToken(String idToken) async {
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
      return const AuthFailure('Tidak bisa terhubung ke server.');
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
    if (sanctumToken is! String || sanctumToken.isEmpty) {
      return const AuthFailure('Token tidak ditemukan.');
    }

    await _saveToken(sanctumToken);

    final userMap = body['user'];
    if (userMap is Map<String, dynamic>) {
      final user = AuthUser.fromJson(userMap);
      if (user != null) await _saveUser(user);
    }

    // Upload FCM token setelah login — tidak boleh menggagalkan login.
    unawaited(FcmNotificationService.instance.uploadTokenAfterLogin());

    return const AuthSuccess();
  }

  // ── MOBILE (Android/iOS) — dinonaktifkan sementara, JANGAN DIHAPUS ────
  // Kode asli login Google untuk mobile. Untuk mengaktifkan lagi: buka
  // komentar method di bawah, kembalikan blok MOBILE di
  // _ensureGoogleInitialized() dan tombol MOBILE di AuthPage.
  //
  // Future<AuthResult> signInWithGoogle() async {
  //   if (ApiConfig.googleServerClientId.isEmpty) {
  //     return const AuthFailure('GOOGLE_WEB_CLIENT_ID belum di-set di ApiConfig.');
  //   }
  //
  //   try {
  //     await _ensureGoogleInitialized();
  //   } catch (e) {
  //     return AuthFailure('Gagal inisialisasi Google Sign-In: $e');
  //   }
  //
  //   final GoogleSignInAccount account;
  //
  //   try {
  //     account = await _googleSignIn.authenticate();
  //   } on GoogleSignInException catch (e) {
  //     if (e.code == GoogleSignInExceptionCode.canceled) {
  //       return const AuthCancelled();
  //     }
  //     return AuthFailure('Google Sign-In gagal: ${e.description ?? e.code}');
  //   } catch (e) {
  //     return AuthFailure('Kesalahan Google Sign-In: $e');
  //   }
  //
  //   final idToken = account.authentication.idToken;
  //   if (idToken == null || idToken.isEmpty) {
  //     return const AuthFailure('Tidak mendapat id_token dari Google.');
  //   }
  //
  //   // ================= KIRIM KE BACKEND =================
  //
  //   http.Response response;
  //
  //   try {
  //     response = await http
  //         .post(
  //           Uri.parse('${ApiConfig.apiBaseUrl}/auth/google'),
  //           headers: const {
  //             'Content-Type': 'application/json',
  //             'Accept': 'application/json',
  //           },
  //           body: jsonEncode({'id_token': idToken}),
  //         )
  //         .timeout(const Duration(seconds: 30));
  //   } on SocketException {
  //     return const AuthFailure('Tidak bisa terhubung ke server.');
  //   } on TimeoutException {
  //     return const AuthFailure('Server tidak merespons. Coba lagi.');
  //   } catch (e) {
  //     return AuthFailure('Kesalahan jaringan: $e');
  //   }
  //
  //   Map<String, dynamic> body;
  //
  //   try {
  //     final decoded = jsonDecode(response.body);
  //     if (decoded is! Map<String, dynamic>) {
  //       return const AuthFailure('Response server tidak valid.');
  //     }
  //     body = decoded;
  //   } catch (_) {
  //     return const AuthFailure('Response server bukan JSON.');
  //   }
  //
  //   if (response.statusCode != 200) {
  //     return AuthFailure(body['message']?.toString() ?? 'Login gagal.');
  //   }
  //
  //   final sanctumToken = body['token'];
  //   if (sanctumToken == null || (sanctumToken as String).isEmpty) {
  //     return const AuthFailure('Token tidak ditemukan.');
  //   }
  //
  //   await _saveToken(sanctumToken);
  //
  //   final userMap = body['user'];
  //   if (userMap is Map<String, dynamic>) {
  //     final user = AuthUser.fromJson(userMap);
  //     if (user != null) await _saveUser(user);
  //   }
  //
  //   // Upload FCM token setelah login — tidak boleh menggagalkan login
  //   // kalau gagal, jadi tidak di-await blocking & dibungkus try/catch
  //   // (uploadTokenAfterLogin sendiri sudah aman terhadap error).
  //   unawaited(FcmNotificationService.instance.uploadTokenAfterLogin());
  //
  //   return const AuthSuccess();
  // }

  // ================= LOGOUT =================

  Future<void> signOut() async {
    // clear cache aplikasi
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