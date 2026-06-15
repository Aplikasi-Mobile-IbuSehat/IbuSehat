import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/services/auth_service.dart';

/// Hasil dari satu kali pertukaran chat dengan AI.
class ChatResult {
  final String reply;
  final Map<String, dynamic>? saved;
  final String? saveError;
  final int? quotaUsed;
  final int? quotaLimit;

  ChatResult({
    required this.reply,
    this.saved,
    this.saveError,
    this.quotaUsed,
    this.quotaLimit,
  });
}

/// Dilempar ketika user belum premium atau kuota harian habis.
class ChatAccessException implements Exception {
  final String message;
  final String code; // 'PREMIUM_REQUIRED' | 'DAILY_QUOTA_EXCEEDED' | 'RATE_LIMITED'
  final int? quotaUsed;
  final int? quotaLimit;

  ChatAccessException(this.message, this.code, {this.quotaUsed, this.quotaLimit});

  @override
  String toString() => message;
}

class ApiService {
  /// Ambil token autentikasi yang tersimpan (hasil login Google + Sanctum).
  Future<String?> _getToken() async {
    return AuthService.instance.token;
  }

  /// Kirim pesan ke Gemini AI melalui backend Laravel.
  ///
  /// [history] adalah riwayat percakapan sebelumnya dalam format:
  /// [{"role": "user" | "model", "text": "..."}, ...]
  /// Hanya beberapa pasangan terakhir yang akan dipakai backend (sliding
  /// window), jadi Flutter boleh mengirim seluruh history sesi.
  ///
  /// Melempar [ChatAccessException] jika user tidak premium / kuota habis /
  /// terkena rate limit. Melempar [Exception] untuk error umum lainnya.
  Future<ChatResult> sendChatMessage(
    String prompt, {
    List<Map<String, String>> history = const [],
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}/gemini/chat');

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Anda belum login. Silakan masuk kembali.');
      }

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'prompt': prompt,
              'history': history,
            }),
          )
          .timeout(const Duration(seconds: 30));

      // 403 -> bukan premium, 429 -> kuota harian habis ATAU rate limit per menit
      if (response.statusCode == 403 || response.statusCode == 429) {
        Map<String, dynamic> body = {};
        try {
          body = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}

        final code = body['code'] as String? ??
            (response.statusCode == 429 ? 'RATE_LIMITED' : 'PREMIUM_REQUIRED');
        final message = body['message'] as String? ??
            'Anda belum bisa mengakses fitur ini saat ini.';
        final meta = body['meta'] as Map<String, dynamic>?;

        throw ChatAccessException(
          message,
          code,
          quotaUsed: meta?['used'] as int?,
          quotaLimit: meta?['quota'] as int?,
        );
      }

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final meta = body['meta'] as Map<String, dynamic>?;
        final quota = meta?['quota'] as Map<String, dynamic>?;

        return ChatResult(
          reply: data['reply'] as String? ?? 'Maaf, saya tidak mendapatkan jawaban.',
          saved: data['saved'] as Map<String, dynamic>?,
          saveError: data['save_error'] as String?,
          quotaUsed: quota?['used'] as int?,
          quotaLimit: quota?['limit'] as int?,
        );
      }

      // Server merespon tapi dengan error
      final message = body['message'] ?? 'Terjadi kesalahan pada server.';
      throw Exception(message);
    } on ChatAccessException {
      rethrow;
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    }
  }

  /// Buat transaksi pembayaran premium.
  /// [planType] harus '1M' (1 bulan) atau '11M' (11 bulan).
  Future<Map<String, dynamic>> createPremiumTransaction(String planType) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}/payment/create');

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Anda belum login. Silakan masuk kembali.');
    }

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'plan_type': planType}),
        )
        .timeout(const Duration(seconds: 30));

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body as Map<String, dynamic>;
    }

    throw Exception(body['message'] ?? 'Gagal membuat transaksi.');
  }
}