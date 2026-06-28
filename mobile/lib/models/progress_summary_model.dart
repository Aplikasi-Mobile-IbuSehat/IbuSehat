class ProgressSummaryModel {
  final WeeklySummary weekly;

  const ProgressSummaryModel({required this.weekly});

  factory ProgressSummaryModel.fromJson(Map<String, dynamic> json) {
    return ProgressSummaryModel(
      weekly: WeeklySummary.fromJson(json['weekly'] as Map<String, dynamic>),
    );
  }
}

class WeeklySummary {
  final WaterSummary water;
  final NutritionSummary nutrition;
  final WorkoutSummary workout;

  const WeeklySummary({
    required this.water,
    required this.nutrition,
    required this.workout,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      water: WaterSummary.fromJson(json['water'] as Map<String, dynamic>),
      nutrition: NutritionSummary.fromJson(json['nutrition'] as Map<String, dynamic>),
      workout: WorkoutSummary.fromJson(json['workout'] as Map<String, dynamic>),
    );
  }
}

class WaterSummary {
  final int totalMl;
  final int targetMl;
  final int percent;
  final List<DailyIntake> daily;
  final int average;
  final int today;
  final int targetDailyMl;

  const WaterSummary({
    required this.totalMl,
    required this.targetMl,
    required this.percent,
    required this.daily,
    required this.average,
    required this.today,
    required this.targetDailyMl,
  });

  factory WaterSummary.fromJson(Map<String, dynamic> json) {
    return WaterSummary(
      totalMl: (json['total_ml'] as num).toInt(),
      targetMl: (json['target_ml'] as num).toInt(),
      percent: (json['percent'] as num).toInt(),
      daily: (json['daily'] as List)
          .map((e) => DailyIntake.fromJson(e as Map<String, dynamic>))
          .toList(),
      average: (json['average'] as num).toInt(),
      today: (json['today'] as num).toInt(),
      targetDailyMl: (json['target_daily_ml'] as num?)?.toInt() ?? 2000,
    );
  }
}

class NutritionSummary {
  final int totalKkal;
  final int targetKkal;
  final int percent;
  final List<DailyIntake> daily;
  final int average;
  final int today;
  final int targetDailyKkal;

  const NutritionSummary({
    required this.totalKkal,
    required this.targetKkal,
    required this.percent,
    required this.daily,
    required this.average,
    required this.today,
    required this.targetDailyKkal,
  });

  factory NutritionSummary.fromJson(Map<String, dynamic> json) {
    return NutritionSummary(
      totalKkal: (json['total_kkal'] as num).toInt(),
      targetKkal: (json['target_kkal'] as num).toInt(),
      percent: (json['percent'] as num).toInt(),
      daily: (json['daily'] as List)
          .map((e) => DailyIntake.fromJson(e as Map<String, dynamic>))
          .toList(),
      average: (json['average'] as num).toInt(),
      today: (json['today'] as num).toInt(),
      targetDailyKkal: (json['target_daily_kkal'] as num?)?.toInt() ?? 2067,
    );
  }
}

class DailyIntake {
  final String day;
  final int amount;

  const DailyIntake({required this.day, required this.amount});

  factory DailyIntake.fromJson(Map<String, dynamic> json) {
    return DailyIntake(
      day: json['day'] as String,
      amount: (json['amount'] as num).toInt(),
    );
  }
}

class WorkoutSummary {
  final int totalMinutes;
  final int targetMinutes;
  final int percent;
  final List<DailyIntake> daily;
  final int average;
  final int today;
  final int targetDailyMinutes;

  const WorkoutSummary({
    required this.totalMinutes,
    required this.targetMinutes,
    required this.percent,
    required this.daily,
    required this.average,
    required this.today,
    required this.targetDailyMinutes,
  });

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) {
    return WorkoutSummary(
      totalMinutes: (json['total_minutes'] as num).toInt(),
      targetMinutes: (json['target_minutes'] as num).toInt(),
      percent: (json['percent'] as num).toInt(),
      daily: (json['daily'] as List)
          .map((e) => DailyIntake.fromJson(e as Map<String, dynamic>))
          .toList(),
      average: (json['average'] as num).toInt(),
      today: (json['today'] as num).toInt(),
      targetDailyMinutes: (json['target_daily_minutes'] as num?)?.toInt() ?? 25,
    );
  }
}
