import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/models/streak_models.dart';
import 'package:mobile/services/auth_service.dart';

class StreakService {
  static String get _baseUrl => ApiConfig.apiBaseUrl;

  /// Complete a workout and update streak
  /// Returns StreakResult with streak information
  Future<StreakResult> completeWorkout(int? workoutId) async {
    try {
      final token = await AuthService.instance.token;
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('$_baseUrl/workout/complete');
      
      final requestBody = {
        'workout_id': workoutId,
      };
      
      print('=== SERVICE URL: ${uri.toString()}');
      print('=== SERVICE token: ${token.substring(0, 20)}...');
      print('=== SERVICE workoutId: $workoutId');
      debugPrint('🔵 DEBUG completeWorkout - workoutId: $workoutId');
      debugPrint('🔵 DEBUG token: ${token.substring(0, 20)}...');
      debugPrint('🔵 DEBUG request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('=== SERVICE response code: ${response.statusCode}');
      print('=== SERVICE response body: ${response.body}');
      debugPrint('🔵 DEBUG response status: ${response.statusCode}');
      debugPrint('🔵 DEBUG response body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>;
          final result = StreakResult.fromJson(data);
          debugPrint('🟢 [STREAK] Workout completed: streak=${result.streakActive}, isNew=${result.isNewStreakDay}');
          return result;
        }
      }

      // Server responded with error
      debugPrint('🔴 DEBUG Laravel error: ${response.body}');
      
      // Parse error message from Laravel response
      final errorMessage = body['message'] as String? ?? 
                          body['error'] as String? ?? 
                          'Validasi gagal';
      
      // Include validation errors if present
      if (body.containsKey('errors')) {
        debugPrint('🔴 DEBUG Validation errors: ${body['errors']}');
      }
      
      throw Exception(errorMessage);
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('🔴 [STREAK] Error completing workout: $e');
      throw Exception('Failed to connect to server. Please check your internet connection.');
    }
  }

  /// Get streak data with calendar
  Future<StreakData> getStreakData({int? year, int? month}) async {
    try {
      final token = await AuthService.instance.token;
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final queryParams = <String, String>{};
      if (year != null) queryParams['year'] = year.toString();
      if (month != null) queryParams['month'] = month.toString();

      final uri = Uri.parse('$_baseUrl/streak').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      debugPrint('🔵 [STREAK] Fetching streak data: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('🔵 [STREAK] Response status: ${response.statusCode}');

      if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final streakData = StreakData.fromJson(data);
        debugPrint('🟢 [STREAK] Data fetched: streak=${streakData.streakActive}, calendar=${streakData.calendar.length} days');
        return streakData;
      }

      // Server responded with error
      final message = body['message'] as String? ?? 'Failed to get streak data';
      throw Exception(message);
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('🔴 [STREAK] Error fetching streak data: $e');
      throw Exception('Failed to connect to server. Please check your internet connection.');
    }
  }
}
