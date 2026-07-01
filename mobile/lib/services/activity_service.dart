import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/models/activity_model.dart';
import 'package:mobile/services/auth_service.dart';

/// User-facing error for Langkah / summary API failures.
class LangkahSummaryError implements Exception {
  LangkahSummaryError(this.userMessage);
  final String userMessage;

  @override
  String toString() => userMessage;
}

class ActivityService {
  ActivityService._();

  static const Duration _httpTimeout = Duration(seconds: 10);

  static Future<String?> _bearerToken() => AuthService.instance.token;

  static Map<String, String> _jsonHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static void _logSummaryFailure(
    String phase, {
    int? statusCode,
    String? body,
    Map<String, String>? headers,
    Object? error,
  }) {
    debugPrint(
      'LANGKAH SUMMARY [$phase] status=$statusCode error=$error\n'
      'headers=$headers\nbody=$body',
    );
  }

  /// GET `${ApiConfig.baseUrl}/api/activities/summary` with Bearer token.
  ///
  /// Throws [LangkahSummaryError] with an Indonesian user message for known cases.
  static Future<ActivitySummaryResponse> fetchSummary() async {
    final token = await _bearerToken();
    final tokenPreview = token == null || token.isEmpty
        ? '(empty)'
        : (token.length <= 10
              ? '(len=${token.length})'
              : '(len=${token.length}, head=${token.substring(0, 8)}…)');
    debugPrint('LANGKAH TOKEN: $tokenPreview');

    if (token == null || token.isEmpty) {
      throw LangkahSummaryError('Belum login');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/activities/summary');
    debugPrint('LANGKAH URL: $uri');

    try {
      final res = await http
          .get(uri, headers: _jsonHeaders(token))
          .timeout(_httpTimeout);

      final hdrs = Map<String, String>.from(res.headers);
      debugPrint('LANGKAH RESPONSE status=${res.statusCode} headers=$hdrs');
      debugPrint('LANGKAH API RESPONSE BODY: ${res.body}');

      switch (res.statusCode) {
        case 200:
          try {
            final decoded = jsonDecode(res.body);
            if (decoded is! Map<String, dynamic>) {
              _logSummaryFailure('parse', statusCode: 200, body: res.body);
              throw LangkahSummaryError('Server error, coba lagi');
            }
            return ActivitySummaryResponse.fromJson(decoded);
          } catch (e, st) {
            _logSummaryFailure(
              'json',
              statusCode: 200,
              body: res.body,
              error: e,
            );
            debugPrint('$st');
            throw LangkahSummaryError('Server error, coba lagi');
          }
        case 401:
          _logSummaryFailure(
            '401',
            statusCode: 401,
            body: res.body,
            headers: hdrs,
          );
          throw LangkahSummaryError('Sesi habis, silakan login ulang');
        case 404:
          _logSummaryFailure('404', statusCode: 404, body: res.body);
          throw LangkahSummaryError('0 langkah hari ini');
        case 500:
        default:
          if (res.statusCode >= 500) {
            _logSummaryFailure(
              '5xx',
              statusCode: res.statusCode,
              body: res.body,
              headers: hdrs,
            );
            throw LangkahSummaryError('Server error, coba lagi');
          }
          _logSummaryFailure(
            'other',
            statusCode: res.statusCode,
            body: res.body,
            headers: hdrs,
          );
          throw LangkahSummaryError('Server error, coba lagi');
      }
    } on LangkahSummaryError {
      rethrow;
    } on TimeoutException catch (e, st) {
      _logSummaryFailure('timeout', error: e);
      debugPrint('$st');
      throw LangkahSummaryError('Tidak ada koneksi');
    } on SocketException catch (e, st) {
      _logSummaryFailure('socket', error: e);
      debugPrint('$st');
      throw LangkahSummaryError('Tidak ada koneksi');
    } catch (e, st) {
      debugPrint('ActivityService.fetchSummary: $e\n$st');
      throw LangkahSummaryError('Tidak ada koneksi');
    }
  }

  static Future<void> saveActivity(Map<String, dynamic> payload) async {
    final token = await _bearerToken();
    if (token == null || token.isEmpty) {
      throw Exception('Belum login: token tidak ditemukan.');
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/activities');
    try {
      final res = await http
          .post(uri, headers: _jsonHeaders(token), body: jsonEncode(payload))
          .timeout(_httpTimeout);
      final body = jsonDecode(res.body);
      if (res.statusCode != 201) {
        final msg = body is Map && body['message'] != null
            ? body['message'].toString()
            : 'Gagal menyimpan (${res.statusCode})';
        throw Exception(msg);
      }
    } catch (e, st) {
      debugPrint('ActivityService.saveActivity: $e\n$st');
      rethrow;
    }
  }

  static Future<List<ActivityModel>> fetchActivities() async {
    final token = await _bearerToken();
    if (token == null || token.isEmpty) {
      throw LangkahSummaryError('Belum login');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/activities');
    try {
      final res = await http
          .get(uri, headers: _jsonHeaders(token))
          .timeout(_httpTimeout);

      if (res.statusCode == 401) {
        throw LangkahSummaryError('Sesi habis, silakan login ulang');
      }

      if (res.statusCode != 200) {
        throw LangkahSummaryError('Tidak ada koneksi');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw LangkahSummaryError('Tidak ada koneksi');
      }

      final rawList = decoded['data'] as List<dynamic>? ?? const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(ActivityModel.fromJson)
          .toList();
    } on LangkahSummaryError {
      rethrow;
    } on TimeoutException catch (e, st) {
      debugPrint('ActivityService.fetchActivities timeout: $e\n$st');
      throw LangkahSummaryError('Tidak ada koneksi');
    } on SocketException catch (e, st) {
      debugPrint('ActivityService.fetchActivities socket: $e\n$st');
      throw LangkahSummaryError('Tidak ada koneksi');
    } catch (e, st) {
      debugPrint('ActivityService.fetchActivities: $e\n$st');
      throw LangkahSummaryError('Tidak ada koneksi');
    }
  }
}
