class SleepDashboardModel {
  const SleepDashboardModel({
    required this.hasData,
    required this.sleepScore,
    required this.sleepCategory,
    required this.sleepMessage,
    required this.sleepDuration,
    required this.sleepTime,
    required this.wakeTime,
    required this.averageSleep,
    required this.sleepDebt,
    required this.sleepQuality,
    required this.weeklySleepScores,
  });

  final int sleepScore;
  final String sleepCategory;
  final String sleepMessage;
  final String sleepDuration;
  final String sleepTime;
  final String wakeTime;
  final String averageSleep;
  final String sleepDebt;
  final String sleepQuality;
  final List<int> weeklySleepScores;
  final bool hasData;

  factory SleepDashboardModel.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final scoresRaw = root['weekly_sleep_scores'] as List<dynamic>? ?? [];
    final scores = scoresRaw
        .map((e) => (e as num?)?.toInt() ?? 0)
        .toList(growable: false);

    return SleepDashboardModel(
      hasData: root['has_data'] as bool? ?? true,
      sleepScore: (root['sleep_score'] as num?)?.toInt() ?? 0,
      sleepCategory: root['sleep_category'] as String? ?? '-',
      sleepMessage: root['sleep_message'] as String? ?? '',
      sleepDuration: root['sleep_duration'] as String? ?? '-',
      sleepTime: root['sleep_time'] as String? ?? '-',
      wakeTime: root['wake_time'] as String? ?? '-',
      averageSleep: root['average_sleep'] as String? ?? '-',
      sleepDebt: root['sleep_debt'] as String? ?? '-',
      sleepQuality: root['sleep_quality'] as String? ?? '-',
      weeklySleepScores: scores,
    );
  }
}
