import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String _baseUrl = 'http://127.0.0.1:8000';

  /// Kirim pesan ke Gemini AI melalui backend Laravel.
  /// Melempar [Exception] jika terjadi error jaringan atau server.
  Future<String> sendChatMessage(String prompt) async {
    final uri = Uri.parse('$_baseUrl/api/gemini/chat');

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
