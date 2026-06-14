import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/config/api_config.dart';
import 'package:mobile/models/sleep_dashboard_model.dart';
import 'package:mobile/models/sleep_history_item.dart';
import 'package:mobile/models/sleep_latest_model.dart';
import 'package:mobile/models/sleep_log_result.dart';
import 'package:mobile/models/sleep_today_model.dart';
import 'package:mobile/models/sleep_weekly_summary_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SleepServiceException implements Exception {
  SleepServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class SleepService {
  SleepService({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  Future<String?> _bearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sanctum_token');
  }

  Map<String, dynamic> _asJsonMap(dynamic data, String errorMessage) {
    if (data is! Map<String, dynamic>) {
      debugPrint('SleepService: respons bukan JSON — $data');
      throw SleepServiceException(errorMessage);
    }
    return data;
  }

  void _ensureSuccess(Map<String, dynamic> json) {
    final status = json['status'];
    if (status != null && status.toString() != 'success') {
      throw SleepServiceException(
        json['message']?.toString() ?? 'Permintaan gagal',
      );
    }
  }

  /// GET /api/sleep/dashboard
  Future<SleepDashboardModel> fetchDashboard() async {
    final token = await _bearerToken();
    if (token == null || token.isEmpty) {
      throw SleepServiceException('Belum login');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/sleep/dashboard',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data;
      if (data == null) {
        throw SleepServiceException('Gagal memuat data tidur');
      }

      return SleepDashboardModel.fromJson(data);
    } on DioException catch (e, st) {
      debugPrint('SleepService.fetchDashboard DioException: $e\n$st');
      final status = e.response?.statusCode;
      if (status == 401) {
        throw SleepServiceException('Sesi habis, silakan login ulang');
      }
      throw SleepServiceException('Gagal memuat data tidur');
    } catch (e, st) {
      if (e is SleepServiceException) rethrow;
      debugPrint('SleepService.fetchDashboard: $e\n$st');
      throw SleepServiceException('Gagal memuat data tidur');
    }
  }

  /// GET /api/sleep/log/latest
  Future<SleepLatestModel> fetchLatestLog() async {
    final token = await _bearerToken();
    if (token == null || token.isEmpty) {
      throw SleepServiceException('Belum login');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/sleep/log/latest',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data;
      if (data == null) {
        throw SleepServiceException('Gagal memuat skor tidur');
      }

      return SleepLatestModel.fromJson(data);
    } on DioException catch (e, st) {
      debugPrint('SleepService.fetchLatestLog DioException: $e\n$st');
      if (e.response?.statusCode == 401) {
        throw SleepServiceException('Sesi habis, silakan login ulang');
      }
      throw SleepServiceException('Gagal memuat skor tidur');
    } catch (e, st) {
      if (e is SleepServiceException) rethrow;
      debugPrint('SleepService.fetchLatestLog: $e\n$st');
      throw SleepServiceException('Gagal memuat skor tidur');
    }
  }

  /// GET /api/sleep/log/today
  Future<SleepTodayModel> fetchToday() async {
    final token = await _bearerToken();
    if (token == null || token.isEmpty) {
      throw SleepServiceException('Belum login');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/sleep/log/today',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data;
      if (data == null) {
        throw SleepServiceException('Gagal memuat data tidur hari ini');
      }

      return SleepTodayModel.fromJson(data);
    } on DioException catch (e, st) {
      debugPrint('SleepService.fetchToday DioException: $e\n$st');
      if (e.response?.statusCode == 401) {
        throw SleepServiceException('Sesi habis, silakan login ulang');
      }
      throw SleepServiceException('Gagal memuat data tidur hari ini');
    } catch (e, st) {
      if (e is SleepServiceException) rethrow;
      debugPrint('SleepService.fetchToday: $e\n$st');
      throw SleepServiceException('Gagal memuat data tidur hari ini');
    }
  }

  /// GET /api/sleep/log/weekly-summary
  Future<SleepWeeklySummaryModel> fetchWeeklySummary() async {
    final token = await _bearerToken();
    if (token == null || token.isEmpty) {
      throw SleepServiceException('Belum login');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/sleep/log/weekly-summary',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data;
      if (data == null) {
        throw SleepServiceException('Gagal memuat ringkasan mingguan');
      }

      return SleepWeeklySummaryModel.fromJson(data);
    } on DioException catch (e, st) {
      debugPrint('SleepService.fetchWeeklySummary DioException: $e\n$st');
      if (e.response?.statusCode == 401) {
        throw SleepServiceException('Sesi habis, silakan login ulang');
      }
      throw SleepServiceException('Gagal memuat ringkasan mingguan');
    } catch (e, st) {
      if (e is SleepServiceException) rethrow;
      debugPrint('SleepService.fetchWeeklySummary: $e\n$st');
      throw SleepServiceException('Gagal memuat ringkasan mingguan');
    }
  }

  /// POST /api/sleep/log
  Future<SleepLogResult> submitSleepLog(SleepLogRequest request) async {
    final token = await _bearerToken();
    if (token == null || token.isEmpty) {
      throw SleepServiceException('Belum login');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sleep/log',
        data: request.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = _asJsonMap(
        response.data,
        'Gagal menyimpan data tidur',
      );
      _ensureSuccess(data);

      return SleepLogResult.fromJson(data);
    } on DioException catch (e, st) {
      debugPrint('SleepService.submitSleepLog DioException: $e\n$st');
      debugPrint('SleepService.submitSleepLog body: ${e.response?.data}');
      final status = e.response?.statusCode;
      final body = e.response?.data;

      if (status == 401) {
        throw SleepServiceException('Sesi habis, silakan login ulang');
      }

      if (status == 422 && body is Map<String, dynamic>) {
        final message = body['message'] as String? ??
            _firstValidationError(body['errors']);
        throw SleepServiceException(message ?? 'Data tidak valid');
      }

      if (body is Map<String, dynamic>) {
        final message = body['message'] as String?;
        if (message != null && message.isNotEmpty) {
          throw SleepServiceException(message);
        }
      }

      throw SleepServiceException('Gagal menyimpan data tidur');
    } catch (e, st) {
      if (e is SleepServiceException) rethrow;
      debugPrint('SleepService.submitSleepLog: $e\n$st');
      throw SleepServiceException('Gagal menyimpan data tidur');
    }
  }

  /// GET /api/sleep/log/{id}
  Future<SleepLogResult> fetchSleepLogDetail(int id) async {
    final token = await _bearerToken();
    if (token == null || token.isEmpty) {
      throw SleepServiceException('Belum login');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/sleep/log/detail/$id',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = _asJsonMap(
        response.data,
        'Gagal memuat detail tidur',
      );
      _ensureSuccess(data);

      return SleepLogResult.fromJson(data);
    } on DioException catch (e, st) {
      debugPrint('SleepService.fetchSleepLogDetail DioException: $e\n$st');
      debugPrint('SleepService.fetchSleepLogDetail body: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw SleepServiceException('Sesi habis, silakan login ulang');
      }
      if (e.response?.statusCode == 404) {
        throw SleepServiceException('Data tidur tidak ditemukan');
      }
      throw SleepServiceException('Gagal memuat detail tidur');
    } catch (e, st) {
      if (e is SleepServiceException) rethrow;
      debugPrint('SleepService.fetchSleepLogDetail: $e\n$st');
      throw SleepServiceException('Gagal memuat detail tidur');
    }
  }

  /// GET /api/sleep/log/history
  Future<List<SleepHistoryItem>> fetchHistory({
    String period = 'weekly',
    String search = '',
  }) async {
    final token = await _bearerToken();
    if (token == null || token.isEmpty) {
      throw SleepServiceException('Belum login');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/sleep/log/history',
        queryParameters: {
          'period': period,
          if (search.isNotEmpty) 'search': search,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data;
      if (data == null) {
        throw SleepServiceException('Gagal memuat riwayat tidur');
      }

      final list = data['data'] as List<dynamic>? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(SleepHistoryItem.fromJson)
          .toList();
    } on DioException catch (e, st) {
      debugPrint('SleepService.fetchHistory DioException: $e\n$st');
      if (e.response?.statusCode == 401) {
        throw SleepServiceException('Sesi habis, silakan login ulang');
      }
      throw SleepServiceException('Gagal memuat riwayat tidur');
    } catch (e, st) {
      if (e is SleepServiceException) rethrow;
      debugPrint('SleepService.fetchHistory: $e\n$st');
      throw SleepServiceException('Gagal memuat riwayat tidur');
    }
  }

  /// DELETE /api/sleep/log/{id}
  Future<void> deleteSleepLog(int id) async {
    final token = await _bearerToken();
    if (token == null || token.isEmpty) {
      throw SleepServiceException('Belum login');
    }

    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/sleep/log/$id',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data;
      if (data == null) {
        throw SleepServiceException('Gagal menghapus riwayat tidur');
      }
      _ensureSuccess(data);
    } on DioException catch (e, st) {
      debugPrint('SleepService.deleteSleepLog DioException: $e\n$st');
      if (e.response?.statusCode == 401) {
        throw SleepServiceException('Sesi habis, silakan login ulang');
      }
      if (e.response?.statusCode == 404) {
        throw SleepServiceException('Data tidur tidak ditemukan');
      }
      throw SleepServiceException('Gagal menghapus riwayat tidur');
    } catch (e, st) {
      if (e is SleepServiceException) rethrow;
      debugPrint('SleepService.deleteSleepLog: $e\n$st');
      throw SleepServiceException('Gagal menghapus riwayat tidur');
    }
  }

  /// POST /api/sleep/log/save
  Future<void> saveSleepLog(int sleepLogId) async {
    final token = await _bearerToken();
    if (token == null || token.isEmpty) {
      throw SleepServiceException('Belum login');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sleep/log/save',
        data: {'sleep_log_id': sleepLogId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data;
      if (data == null || data['status'] != 'success') {
        throw SleepServiceException('Gagal menyimpan hasil');
      }
    } on DioException catch (e, st) {
      debugPrint('SleepService.saveSleepLog DioException: $e\n$st');
      final status = e.response?.statusCode;
      final body = e.response?.data;

      if (status == 401) {
        throw SleepServiceException('Sesi habis, silakan login ulang');
      }

      if (body is Map<String, dynamic>) {
        final message = body['message'] as String?;
        if (message != null && message.isNotEmpty) {
          throw SleepServiceException(message);
        }
      }

      throw SleepServiceException('Gagal menyimpan hasil');
    } catch (e, st) {
      if (e is SleepServiceException) rethrow;
      debugPrint('SleepService.saveSleepLog: $e\n$st');
      throw SleepServiceException('Gagal menyimpan hasil');
    }
  }

  String? _firstValidationError(dynamic errors) {
    if (errors is! Map) return null;
    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
    }
    return null;
  }
}
