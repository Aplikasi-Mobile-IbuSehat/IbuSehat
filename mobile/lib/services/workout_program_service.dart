import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/api_config.dart';
import 'package:mobile/models/workout_program_model.dart';

/// Base URL: [ApiConfig.baseUrl] (default `http://127.0.0.1:8000`,
import 'package:mobile/config/api_config.dart';
import 'package:mobile/models/workout_program_model.dart';

/// Base URL: [ApiConfig.baseUrl] (default `http://192.168.1.9:8000`,
/// override with `--dart-define=API_BASE_URL=...`).
class WorkoutProgramService {
  WorkoutProgramService._();

  static const Duration _httpTimeout = Duration(seconds: 10);

  static Future<List<WorkoutProgramModel>> fetchPrograms() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/workout-programs');
    debugPrint('WorkoutProgramService.fetchPrograms: GET $uri');

    try {
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_httpTimeout);

      debugPrint(
        'WorkoutProgramService.fetchPrograms: status=${res.statusCode}',
      );

      if (res.statusCode != 200) {
        debugPrint('WorkoutProgramService.fetchPrograms: body=${res.body}');
        throw Exception('Gagal memuat program latihan (${res.statusCode})');
      }

      final dynamic decodedRaw = jsonDecode(res.body);
      if (decodedRaw is! Map<String, dynamic>) {
        debugPrint(
          'WorkoutProgramService.fetchPrograms: root is not object, '
          'type=${decodedRaw.runtimeType}',
        );
        throw Exception('Format respons tidak valid');
      }

      final decoded = decodedRaw;
      final dynamic dataRaw = decoded['data'];
      if (dataRaw == null) {
        debugPrint('WorkoutProgramService.fetchPrograms: missing key "data"');
        throw Exception('Format respons tidak valid (data kosong)');
      }
      if (dataRaw is! List<dynamic>) {
        debugPrint(
          'WorkoutProgramService.fetchPrograms: "data" is not a list, '
          'type=${dataRaw.runtimeType}',
        );
        throw Exception('Format respons tidak valid');
      }

      final list = dataRaw
          .map((e) => WorkoutProgramModel.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint(
        'WorkoutProgramService.fetchPrograms: parsed ${list.length} programs',
      );
      return list;
    } on TimeoutException catch (e, st) {
      debugPrint('WorkoutProgramService.fetchPrograms: timeout $e\n$st');
      throw Exception('Koneksi timeout. Coba lagi.');
    } on http.ClientException catch (e, st) {
      debugPrint('WorkoutProgramService.fetchPrograms: client $e\n$st');
      throw Exception('Gagal terhubung ke server.');
    } on FormatException catch (e, st) {
      debugPrint('WorkoutProgramService.fetchPrograms: json $e\n$st');
      throw Exception('Gagal membaca respons server.');
    } catch (e, st) {
      debugPrint('WorkoutProgramService.fetchPrograms: error $e\n$st');
      rethrow;
    }
  }

  static Future<WorkoutProgramModel> fetchProgramDetail(
    int id, {
    String? difficulty,
  }) async {
    final query = <String, String>{};
    if (difficulty != null && difficulty.isNotEmpty) {
      query['difficulty'] = difficulty;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/workout-programs/$id',
    ).replace(queryParameters: query.isEmpty ? null : query);

    debugPrint('WorkoutProgramService.fetchProgramDetail: GET $uri');

    try {
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_httpTimeout);

      debugPrint(
        'WorkoutProgramService.fetchProgramDetail: status=${res.statusCode}',
      );

      if (res.statusCode != 200) {
        debugPrint(
          'WorkoutProgramService.fetchProgramDetail: body=${res.body}',
        );
        throw Exception('Gagal memuat detail program (${res.statusCode})');
      }

      final dynamic decodedRaw = jsonDecode(res.body);
      if (decodedRaw is! Map<String, dynamic>) {
        debugPrint(
          'WorkoutProgramService.fetchProgramDetail: root is not object',
        );
        throw Exception('Format respons tidak valid');
      }

      final dataRaw = decodedRaw['data'];
      if (dataRaw is! Map<String, dynamic>) {
        debugPrint(
          'WorkoutProgramService.fetchProgramDetail: "data" is not object, '
          'type=${dataRaw.runtimeType}',
        );
        throw Exception('Format respons tidak valid');
      }

      return WorkoutProgramModel.fromJson(dataRaw);
    } on TimeoutException catch (e, st) {
      debugPrint('WorkoutProgramService.fetchProgramDetail: timeout $e\n$st');
      throw Exception('Koneksi timeout. Coba lagi.');
    } on http.ClientException catch (e, st) {
      debugPrint('WorkoutProgramService.fetchProgramDetail: client $e\n$st');
      throw Exception('Gagal terhubung ke server.');
    } on FormatException catch (e, st) {
      debugPrint('WorkoutProgramService.fetchProgramDetail: json $e\n$st');
      throw Exception('Gagal membaca respons server.');
    } catch (e, st) {
      debugPrint('WorkoutProgramService.fetchProgramDetail: error $e\n$st');
      rethrow;
    }
  }
}
