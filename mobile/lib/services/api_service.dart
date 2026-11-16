import 'dart:async';
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

  /// Sesi chat di server tempat pertukaran ini disimpan.
  final int? sessionId;

  /// True jika backend mendeteksi tanda bahaya dan menyertakan pesan darurat.
  final bool isEmergency;

  ChatResult({
    required this.reply,
    this.saved,
    this.saveError,
    this.quotaUsed,
    this.quotaLimit,
    this.sessionId,
    this.isEmergency = false,
  });
}

/// Ringkasan satu sesi chat untuk daftar riwayat.
class ChatSessionSummary {
  final int id;
  final String title;
  final DateTime? lastMessageAt;

  ChatSessionSummary({
    required this.id,
    required this.title,
    this.lastMessageAt,
  });

  factory ChatSessionSummary.fromJson(Map<String, dynamic> json) {
    return ChatSessionSummary(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? 'Percakapan',
      lastMessageAt:
          DateTime.tryParse(json['last_message_at']?.toString() ?? '')?.toLocal(),
    );
  }
}

/// Satu pesan yang tersimpan di sesi chat.
class ChatHistoryMessage {
  final String text;
  final bool isAi;
  final bool isEmergency;
  final DateTime timestamp;

  ChatHistoryMessage({
    required this.text,
    required this.isAi,
    required this.isEmergency,
    required this.timestamp,
  });

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) {
    final isAi = json['role'] == 'model';
    return ChatHistoryMessage(
      text: json['text']?.toString() ?? '',
      isAi: isAi,
      isEmergency: isAi && json['kind'] == 'emergency',
      timestamp:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}

/// Dilempar ketika chat ditolak server: data kesehatan belum lengkap (403),
/// batas harian/laju habis (429), atau sesi tidak ditemukan (404).
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
  static const _timeout = Duration(seconds: 30);

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.token;

    if (token == null || token.isEmpty) {
      throw Exception('Anda belum login. Silakan masuk kembali.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  /// Kirim pesan ke IbuSehat AI.
  ///
  /// Riwayat percakapan disimpan di server per sesi, jadi cukup kirim
  /// [sessionId] (null = mulai sesi baru). Id sesi dikembalikan di hasil.
  Future<ChatResult> sendChatMessage(String prompt, {int? sessionId}) async {
    final headers = await _authHeaders();
    final http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.apiBaseUrl}/gemini/chat'),
            headers: headers,
            body: jsonEncode({
              'prompt': prompt,
              'session_id': ?sessionId,
            }),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Server terlalu lama merespons. Coba lagi ya.');
    } catch (_) {
      throw Exception('Tidak dapat terhubung ke server.');
    }

    final body = _decode(response);

    if (response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 429) {
      final String code = body['code']?.toString() ??
          switch (response.statusCode) {
            429 => 'RATE_LIMITED',
            404 => 'SESSION_NOT_FOUND',
            _ => 'health_data_required',
          };

      final message = code == 'RATE_LIMITED'
          ? 'Terlalu banyak pesan dalam waktu singkat. Tunggu sebentar lalu coba lagi ya.'
          : body['message']?.toString() ??
              'Anda belum bisa mengakses fitur ini.';

      final meta = body['meta'];

      throw ChatAccessException(
        message,
        code,
        quotaUsed: meta is Map ? meta['used'] as int? : null,
        quotaLimit: meta is Map ? meta['quota'] as int? : null,
      );
    }

    if (response.statusCode == 200 && body['success'] == true) {
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final meta = body['meta'];
      final quota = meta is Map ? meta['quota'] : null;
      final safety = data['safety'];

      return ChatResult(
        reply: data['reply']?.toString() ?? 'Tidak ada jawaban.',
        saved: data['saved'] as Map<String, dynamic>?,
        saveError: data['save_error']?.toString(),
        quotaUsed: quota is Map ? quota['used'] as int? : null,
        quotaLimit: quota is Map ? quota['limit'] as int? : null,
        sessionId: (data['session_id'] as num?)?.toInt(),
        isEmergency: safety is Map && safety['level'] == 'emergency',
      );
    }

    throw Exception(
      body['message']?.toString() ?? 'Terjadi kesalahan server.',
    );
  }

  /// Daftar sesi chat milik pengguna, terbaru dulu.
  Future<List<ChatSessionSummary>> fetchChatSessions() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.apiBaseUrl}/gemini/sessions'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);

    final body = _decode(response);

    if (response.statusCode != 200 || body['data'] is! List) {
      throw Exception('Gagal memuat riwayat percakapan.');
    }

    return (body['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(ChatSessionSummary.fromJson)
        .toList();
  }

  /// Isi satu sesi chat, urut dari pesan terlama.
  Future<List<ChatHistoryMessage>> fetchChatMessages(int sessionId) async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.apiBaseUrl}/gemini/sessions/$sessionId/messages'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);

    final body = _decode(response);
    final data = body['data'];

    if (response.statusCode != 200 || data is! Map || data['messages'] is! List) {
      throw Exception('Gagal memuat percakapan.');
    }

    return (data['messages'] as List)
        .whereType<Map<String, dynamic>>()
        .map(ChatHistoryMessage.fromJson)
        .toList();
  }

  /// Hapus satu sesi chat beserta seluruh pesannya.
  Future<void> deleteChatSession(int sessionId) async {
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.apiBaseUrl}/gemini/sessions/$sessionId'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus percakapan.');
    }
  }
}
