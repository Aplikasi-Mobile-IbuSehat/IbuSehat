class ActivityCoordinate {
  ActivityCoordinate({required this.lat, required this.lng});

  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  factory ActivityCoordinate.fromJson(Map<String, dynamic> json) {
    return ActivityCoordinate(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class ActivityModel {
  ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.distanceKm,
    required this.durationSeconds,
    this.pace,
    required this.calories,
    required this.coordinates,
    required this.startedAt,
    required this.endedAt,
  });

  final int id;
  final String type;
  final String title;
  final double distanceKm;
  final int durationSeconds;
  final String? pace;
  final int calories;
  final List<ActivityCoordinate> coordinates;
  final DateTime startedAt;
  final DateTime endedAt;

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final coords = (json['coordinates'] as List<dynamic>? ?? [])
        .map((e) => ActivityCoordinate.fromJson(e as Map<String, dynamic>))
        .toList();
    return ActivityModel(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      title: json['title'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
      durationSeconds: (json['duration_seconds'] as num).toInt(),
      pace: json['pace'] as String?,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      coordinates: coords,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: DateTime.parse(json['ended_at'] as String),
    );
  }
}

class ActivitySummaryResponse {
  ActivitySummaryResponse({
    required this.todayDistanceKm,
    required this.todayStepsEstimate,
    required this.monthDistanceKm,
    this.latestActivity,
    required this.weeklyChart,
  });

  final double todayDistanceKm;
  final int todayStepsEstimate;
  final double monthDistanceKm;
  final ActivityModel? latestActivity;
  final List<WeeklyChartDay> weeklyChart;

  static List<WeeklyChartDay> _parseWeekly(Map<String, dynamic> json) {
    final weeklyData = json['weekly_data'] as List<dynamic>?;
    if (weeklyData != null && weeklyData.isNotEmpty) {
      return weeklyData
          .map((e) => WeeklyChartDay.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final legacy = json['weekly_chart'] as List<dynamic>? ?? [];
    return legacy
        .map((e) => WeeklyChartDay.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  factory ActivitySummaryResponse.fromJson(Map<String, dynamic> json) {
    final stepsRaw = json['today_steps'] ?? json['today_steps_estimate'];
    final steps = switch (stepsRaw) {
      int v => v,
      num v => v.toInt(),
      _ => 0,
    };

    return ActivitySummaryResponse(
      todayDistanceKm: (json['today_distance_km'] as num?)?.toDouble() ?? 0,
      todayStepsEstimate: steps,
      monthDistanceKm: (json['month_distance_km'] as num?)?.toDouble() ?? 0,
      latestActivity: json['latest_activity'] != null
          ? ActivityModel.fromJson(
              json['latest_activity'] as Map<String, dynamic>,
            )
          : null,
      weeklyChart: _parseWeekly(json),
    );
  }
}

class WeeklyChartDay {
  WeeklyChartDay({required this.label, required this.distanceKm});

  /// Short label, e.g. `Sen` or day-of-month from legacy `date`.
  final String label;
  final double distanceKm;

  factory WeeklyChartDay.fromJson(Map<String, dynamic> json) {
    final day = json['day'] as String?;
    final date = json['date'] as String?;
    final label = day ??
        (date != null && date.length >= 10 ? date.substring(8) : '?');
    return WeeklyChartDay(
      label: label,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
    );
  }
}
