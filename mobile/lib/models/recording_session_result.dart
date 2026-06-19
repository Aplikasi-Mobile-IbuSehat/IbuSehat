import 'package:latlong2/latlong.dart';

/// Data passed from [TrackingScreen] to [ActivitySummaryScreen].
class RecordingSessionResult {
  RecordingSessionResult({
    required this.apiType,
    required this.route,
    required this.durationSeconds,
    required this.distanceKm,
    required this.calories,
    required this.startedAt,
    required this.endedAt,
    required this.paceDisplay,
  });

  /// `running` | `walking` | `cycling`
  final String apiType;
  final List<LatLng> route;
  final int durationSeconds;
  final double distanceKm;
  final int calories;
  final DateTime startedAt;
  final DateTime endedAt;

  /// Pace string for API, e.g. `7:56` or `0:00` if unknown.
  final String paceDisplay;

  Map<String, dynamic> toApiJson({
    required String title,
  }) {
    return {
      'type': apiType,
      'title': title,
      'distance_km': distanceKm,
      'duration_seconds': durationSeconds,
      'pace': paceDisplay,
      'calories': calories,
      'coordinates': route
          .map((e) => {'lat': e.latitude, 'lng': e.longitude})
          .toList(),
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
    };
  }
}
