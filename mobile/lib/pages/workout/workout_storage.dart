import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WorkoutSession {
  final String mode; // run / walk / bike
  final DateTime startTime;
  final Duration duration;
  final double distanceKm;
  final double avgSpeedKmh;

  WorkoutSession({
    required this.mode,
    required this.startTime,
    required this.duration,
    required this.distanceKm,
    required this.avgSpeedKmh,
  });

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'startTime': startTime.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'distanceKm': distanceKm,
      'avgSpeedKmh': avgSpeedKmh,
    };
  }

  static WorkoutSession fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      mode: (json['mode'] as String?) ?? 'run',
      startTime: DateTime.parse(json['startTime'] as String),
      duration: Duration(seconds: json['durationSeconds'] as int),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      avgSpeedKmh: (json['avgSpeedKmh'] as num).toDouble(),
    );
  }
}

class WorkoutStorage {
  static const _keySessions = 'workout_sessions';

  static Future<void> saveSession(WorkoutSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_keySessions) ?? [];
    final encoded = jsonEncode(session.toJson());
    existing.add(encoded);
    await prefs.setStringList(_keySessions, existing);
  }

  static Future<List<WorkoutSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_keySessions) ?? [];
    return existing
        .map(
          (e) => WorkoutSession.fromJson(jsonDecode(e) as Map<String, dynamic>),
        )
        .toList();
  }
}
