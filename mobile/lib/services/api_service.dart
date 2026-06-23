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

/// Dilempar ketika user belum premium atau kuota habis.
class ChatAccessException implements Exception {
  final String message;

  final String code;

  final int? quotaUsed;

  final int? quotaLimit;

  ChatAccessException(
    this.message,
    this.code, {
    this.quotaUsed,
    this.quotaLimit,
  });

  @override
  String toString() => message;
}

class ApiService {
  /// Ambil token login Google Sanctum
  Future<String?> _getToken() async {
    return AuthService.instance.token;
  }

  /// Gemini Chat
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

            body: jsonEncode({'prompt': prompt, 'history': history}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 403 || response.statusCode == 429) {
        Map<String, dynamic> body = {};

        try {
          body = jsonDecode(response.body);
        } catch (_) {}

        final code =
            body['code'] ??
            (response.statusCode == 429 ? 'RATE_LIMITED' : 'PREMIUM_REQUIRED');

        final message =
            body['message'] ?? 'Anda belum bisa mengakses fitur ini.';

        final meta = body['meta'];

        throw ChatAccessException(
          message,
          code,

          quotaUsed: meta?['used'],

          quotaLimit: meta?['quota'],
        );
      }

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'];

        final meta = body['meta'];

        final quota = meta?['quota'];

        return ChatResult(
          reply: data['reply'] ?? 'Tidak ada jawaban.',

          saved: data['saved'],

          saveError: data['save_error'],

          quotaUsed: quota?['used'],

          quotaLimit: quota?['limit'],
        );
      }

      throw Exception(body['message'] ?? 'Terjadi kesalahan server.');
    } on ChatAccessException {
      rethrow;
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  /// Buat pembayaran Premium Midtrans
  Future<Map<String, dynamic>> createPremiumTransaction(String planType) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}/payment/create');

    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Anda belum login.');
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
      return body;
    }

    throw Exception(body['message'] ?? 'Gagal membuat transaksi.');
  }
}
