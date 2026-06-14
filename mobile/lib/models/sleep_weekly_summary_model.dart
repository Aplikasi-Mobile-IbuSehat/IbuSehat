class SleepChartDay {
  const SleepChartDay({required this.day, this.score});

  final String day;
  final int? score;

  factory SleepChartDay.fromJson(Map<String, dynamic> json) {
    final rawScore = json['score'];
    return SleepChartDay(
      day: json['day'] as String? ?? '',
      score: rawScore == null ? null : (rawScore as num).toInt(),
    );
  }
}

class SleepWeeklySummaryModel {
  const SleepWeeklySummaryModel({
    required this.hasData,
    this.averageScore,
    this.averageCategory,
    this.averageCategoryMessage,
    this.averageDuration,
    this.averageSleepTime,
    this.averageWakeTime,
    required this.totalDebt,
    required this.qualityLabel,
    required this.qualityColor,
    required this.chart,
  });

  final bool hasData;
  final int? averageScore;
  final String? averageCategory;
  final String? averageCategoryMessage;
  final String? averageDuration;
  final String? averageSleepTime;
  final String? averageWakeTime;
  final String totalDebt;
  final String qualityLabel;
  final String qualityColor;
  final List<SleepChartDay> chart;

  List<int> get scoresWithData =>
      chart.where((e) => e.score != null).map((e) => e.score!).toList();

  factory SleepWeeklySummaryModel.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final hasData = root['has_data'] as bool? ?? true;
    final chartRaw = root['chart'] as List<dynamic>? ?? [];
    final chart = chartRaw
        .whereType<Map<String, dynamic>>()
        .map(SleepChartDay.fromJson)
        .toList();

    return SleepWeeklySummaryModel(
      hasData: hasData,
      averageScore: (root['average_score'] as num?)?.toInt(),
      averageCategory: root['average_category'] as String?,
      averageCategoryMessage: root['average_category_message'] as String?,
      averageDuration: root['average_duration'] as String?,
      averageSleepTime: root['average_sleep_time'] as String?,
      averageWakeTime: root['average_wake_time'] as String?,
      totalDebt: root['total_debt'] as String? ?? '-',
      qualityLabel: root['quality_label'] as String? ?? '-',
      qualityColor: root['quality_color'] as String? ?? 'green',
      chart: chart,
    );
  }

  static SleepWeeklySummaryModel empty() {
    return const SleepWeeklySummaryModel(
      hasData: false,
      totalDebt: '-',
      qualityLabel: '-',
      qualityColor: 'grey',
      chart: [],
    );
  }
}
