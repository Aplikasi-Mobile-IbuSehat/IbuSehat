class SleepLatestModel {
  const SleepLatestModel({
    required this.hasData,
    this.score,
    this.category,
    this.categoryMessage,
    this.sleepDuration,
    this.sleepTime,
    this.wakeTime,
    this.loggedAt,
  });

  final bool hasData;
  final int? score;
  final String? category;
  final String? categoryMessage;
  final String? sleepDuration;
  final String? sleepTime;
  final String? wakeTime;
  final String? loggedAt;

  factory SleepLatestModel.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return SleepLatestModel(
      hasData: root['has_data'] as bool? ?? false,
      score: (root['score'] as num?)?.toInt(),
      category: root['category'] as String?,
      categoryMessage: root['category_message'] as String?,
      sleepDuration: root['sleep_duration'] as String?,
      sleepTime: root['sleep_time'] as String?,
      wakeTime: root['wake_time'] as String?,
      loggedAt: root['logged_at'] as String?,
    );
  }
}
