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

  /// Credential Manager often maps config/SDK failures to [canceled].
  /// See google_sign_in_android troubleshooting docs.
  bool _isLikelyUserCancellation(GoogleSignInException e) {
    if (e.code != GoogleSignInExceptionCode.canceled) {
      return false;
    }
    final desc = (e.description ?? '').toLowerCase();
    final details = e.details?.toString().toLowerCase() ?? '';

    const frameworkHints = <String>[
      'getcredential',
      'credential manager',
      'credentialmanager',
      'framework',
      'provider',
      'configuration',
      'developer.android.com',
      'unexpected',
      'no credential',
      'nocredential',
      'serverclientid',
      'sha',
      'package',
      'misconfigured',
      'play services',
    ];

    for (final hint in frameworkHints) {
      if (desc.contains(hint) || details.contains(hint)) {
        return false;
      }
    }

    // Empty description on Android often means a false cancel after account pick.
    if (desc.trim().isEmpty && details.trim().isEmpty) {
      return false;
    }

    return true;
  }

  void _logGoogleSignInException(
    String phase,
    GoogleSignInException e,
    StackTrace st,
  ) {
    debugPrint(
      '🔴 [AUTH] $phase GoogleSignInException:\n'
      '  code=${e.code}\n'
      '  description=${e.description}\n'
      '  details=${e.details}\n'
      '  likelyUserCancel=${_isLikelyUserCancellation(e)}\n'
      '$st',
    );
  }

  String _googleSignInErrorMessage(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Konfigurasi Google Sign-In salah.\n'
            'Pastikan package name (com.ibusehat.app), SHA-1 debug/release, '
            'dan Web Client ID sudah benar di Firebase/Google Cloud.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google Play Services / Credential Manager tidak siap.\n'
            '${e.description ?? ''}';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'UI login Google tidak dapat ditampilkan. Coba lagi dari layar utama.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Login Google terputus. Silakan coba lagi.';
      case GoogleSignInExceptionCode.canceled:
        return '';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Akun Google tidak cocok dengan sesi sebelumnya.';
      case GoogleSignInExceptionCode.unknownError:
        return e.description?.isNotEmpty == true
            ? e.description!
            : 'Login Google gagal (kesalahan tidak diketahui).';
    }
  }

  /// v7: [authenticate] = Credential Manager button flow.
  /// Fallback: [attemptLightweightAuthentication] (replaces legacy signIn/signInSilently).
  Future<GoogleSignInAccount> _obtainGoogleAccount() async {
    GoogleSignInException? authenticateError;

    try {
      debugPrint(
        '🔵 [AUTH] Step 5a: authenticate() — Credential Manager button flow...',
      );
      final account = await _googleSignIn.authenticate();
      debugPrint(
        '🟢 [AUTH] Step 5a: authenticate() OK — email=${account.email}',
      );
      return account;
    } on GoogleSignInException catch (e, st) {
      authenticateError = e;
      _logGoogleSignInException('authenticate', e, st);

      if (e.code != GoogleSignInExceptionCode.canceled) {
        rethrow;
      }
      if (_isLikelyUserCancellation(e)) {
        rethrow;
      }
      debugPrint(
        '🟡 [AUTH] Step 5a: canceled looks like Credential Manager/framework '
        'failure — will try signIn fallback',
      );
    }

    debugPrint(
      '🔵 [AUTH] Step 5b: signIn fallback via attemptLightweightAuthentication()...',
    );
    try {
      final Future<GoogleSignInAccount?>? lightweightFuture =
          _googleSignIn.attemptLightweightAuthentication(
        reportAllExceptions: true,
      );

      if (lightweightFuture == null) {
        debugPrint('🔴 [AUTH] Step 5b: lightweight auth returned null Future');
        throw GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description:
              'Fallback sign-in tidak didukung di platform ini. ${authenticateError.description ?? ''}',
          details: authenticateError.details,
        );
      }

      final account = await lightweightFuture;
      if (account != null) {
        debugPrint(
          '🟢 [AUTH] Step 5b: signIn fallback OK — email=${account.email}',
        );
        return account;
      }

      debugPrint('🔴 [AUTH] Step 5b: signIn fallback returned null account');
      throw GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'Tidak ada akun Google yang dipilih.',
      );
    } on GoogleSignInException catch (e, st) {
      _logGoogleSignInException('signIn/lightweight', e, st);
      rethrow;
    }
  }

  // ΓöÇΓöÇΓöÇ Token ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

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

  // ΓöÇΓöÇΓöÇ User ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

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

  // ΓöÇΓöÇΓöÇ Status ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

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

  // ΓöÇΓöÇΓöÇ Sync dari API ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

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

  // ΓöÇΓöÇΓöÇ Sign In ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  /// Return value:
  /// - `null`  ΓåÆ sukses
  /// - `''`    ΓåÆ user membatalkan (tidak tampilkan SnackBar)
  /// - string  ΓåÆ pesan error untuk ditampilkan ke user
  Future<String?> signInWithGoogle() async {
    debugPrint('🔵 [AUTH] Step 1: signInWithGoogle() STARTED');
    debugPrint('🔵 [AUTH] Backend URL: ${ApiConfig.apiBaseUrl}/auth/google');

    // Pastikan Web Client ID sudah di-set
    if (ApiConfig.googleServerClientId.isEmpty) {
      debugPrint('🔴 [AUTH] ABORT: googleServerClientId is empty');
      return 'GOOGLE_WEB_CLIENT_ID belum di-set di ApiConfig.';
    }
    debugPrint('🔵 [AUTH] Step 2: googleServerClientId OK (${ApiConfig.googleServerClientId.substring(0, 20)}...)');

    // Inisialisasi Google Sign-In
    try {
      debugPrint('🔵 [AUTH] Step 3: Initializing GoogleSignIn...');
      await _ensureGoogleInitialized();
      debugPrint('🟢 [AUTH] Step 3: GoogleSignIn initialized OK');
    } catch (e) {
      debugPrint('🔴 [AUTH] Step 3 FAILED: GoogleSignIn init error: $e');
      return 'Gagal inisialisasi Google Sign-In: $e';
    }

    // Jangan signOut() sebelum login — clearCredentialState bisa memicu
    // GetCredentialResponse "canceled" palsu di Credential Manager.
    final GoogleSignInAccount account;
    try {
      debugPrint('🔵 [AUTH] Step 4: Obtaining Google account (authenticate → signIn fallback)...');
      account = await _obtainGoogleAccount();
      debugPrint(
        '🟢 [AUTH] Step 4: Account obtained — email=${account.email}, id=${account.id}',
      );
    } on GoogleSignInException catch (e, st) {
      final msg = _googleSignInErrorMessage(e);
      if (msg.isEmpty) {
        debugPrint('🟡 [AUTH] Step 4: User canceled sign-in (confirmed)');
        return '';
      }
      _logGoogleSignInException('signInWithGoogle', e, st);
      return msg;
    } catch (e, st) {
      debugPrint('🔴 [AUTH] Step 4 FAILED: $e\n$st');
      return 'Terjadi kesalahan saat membuka Google Sign-In: $e';
    }

    // Ambil id_token
    debugPrint('🔵 [AUTH] Step 6: Getting id_token from authentication...');
    final auth = account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      debugPrint('🔴 [AUTH] Step 6 FAILED: idToken is null or empty');
      return 'Tidak mendapat id_token dari Google.\n'
          'Pastikan googleServerClientId di ApiConfig menggunakan '
          'Web Client ID (client_type: 3), bukan Android Client ID.';
    }
    debugPrint('🟢 [AUTH] Step 6: Got idToken (${idToken.length} chars): ${idToken.substring(0, 20)}...');

    // Kirim id_token ke backend Laravel
    final url = '${ApiConfig.apiBaseUrl}/auth/google';
    debugPrint('🔵 [AUTH] Step 7: POSTing id_token to $url ...');
    http.Response response;
    try {
      final stopwatch = Stopwatch()..start();
      response = await http
          .post(
            Uri.parse(url),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'id_token': idToken}),
          )
          .timeout(const Duration(seconds: 30));
      stopwatch.stop();
      debugPrint('🟢 [AUTH] Step 7: Backend responded in ${stopwatch.elapsedMilliseconds}ms — status=${response.statusCode}');
      debugPrint('🟢 [AUTH] Step 7: Response body: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
    } on SocketException catch (e) {
      debugPrint('🔴 [AUTH] Step 7 FAILED: SocketException: $e');
      return 'Tidak bisa terhubung ke server.\n'
          'Pastikan Laravel jalan dengan:\n'
          'php artisan serve --host=0.0.0.0\n'
          'dan IP di ApiConfig sudah benar.';
    } on http.ClientException catch (e) {
      debugPrint('🔴 [AUTH] Step 7 FAILED: ClientException: $e');
      return 'Gagal menghubungi server. Periksa URL di ApiConfig.';
    } catch (e) {
      debugPrint('🔴 [AUTH] Step 7 FAILED: $e');
      return 'Kesalahan jaringan: $e';
    }

    // Parse response
    debugPrint('🔵 [AUTH] Step 8: Parsing JSON response...');
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('🔴 [AUTH] Step 8 FAILED: Response is not a Map');
        return 'Respons server tidak valid (${response.statusCode}).';
      }
      body = decoded;
      debugPrint('🟢 [AUTH] Step 8: JSON parsed OK — keys=${body.keys.toList()}');
    } catch (_) {
      debugPrint('🔴 [AUTH] Step 8 FAILED: JSON decode error');
      debugPrint('🔴 [AUTH] Raw body: ${response.body}');
      return 'Respons server bukan JSON (${response.statusCode}).\n'
          'Pastikan backend berjalan di ${ApiConfig.apiBaseUrl}.';
    }

    if (response.statusCode != 200) {
      final msg = body['message']?.toString() ??
          'Login gagal (${response.statusCode}).';
      debugPrint('🔴 [AUTH] Step 9 FAILED: Server returned ${response.statusCode}: $msg');
      return msg;
    }

    final sanctumToken = body['token'] as String?;
    if (sanctumToken == null || sanctumToken.isEmpty) {
      debugPrint('🔴 [AUTH] Step 9 FAILED: No token in response');
      return 'Respons server tidak berisi token.';
    }
    debugPrint('🟢 [AUTH] Step 9: Got Sanctum token (${sanctumToken.length} chars)');

    // Simpan token & data user
    debugPrint('🔵 [AUTH] Step 10: Saving token & user...');
    await _saveToken(sanctumToken);

    final userMap = body['user'];
    if (userMap is Map<String, dynamic>) {
      final u = AuthUser.fromJson(userMap);
      if (u != null) {
        await _saveUser(u);
        debugPrint('🟢 [AUTH] Step 10: Saved user: ${u.name} (${u.email})');
      }
    }

    debugPrint('🟢 [AUTH] ✅ signInWithGoogle() COMPLETED SUCCESSFULLY');
    return null; // sukses
  }

  // ΓöÇΓöÇΓöÇ Sign Out ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

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
