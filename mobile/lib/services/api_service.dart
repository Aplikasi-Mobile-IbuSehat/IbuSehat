import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';

class ApiService {
  /// Kirim pesan ke Gemini AI melalui backend Laravel.
  /// Melempar [Exception] jika terjadi error jaringan atau server.
  Future<String> sendChatMessage(String prompt) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}/gemini/chat');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        return body['data'] as String;
      }

      // Server merespon tapi dengan error
      final message = body['message'] ?? 'Terjadi kesalahan pada server.';
      throw Exception(message);
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    }
  }
}
