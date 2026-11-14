class SleepTodayModel {
  const SleepTodayModel({
    required this.hasData,
    this.sleepLogId,
    this.score,
    this.category,
    this.categoryMessage,
    this.sleepDuration,
    this.sleepTime,
    this.wakeTime,
  });

  final bool hasData;
  final int? sleepLogId;
  final int? score;
  final String? category;
  final String? categoryMessage;
  final String? sleepDuration;
  final String? sleepTime;
  final String? wakeTime;

  factory SleepTodayModel.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return SleepTodayModel(
      hasData: root['has_data'] as bool? ?? false,
      sleepLogId: (root['sleep_log_id'] as num?)?.toInt(),
      score: (root['score'] as num?)?.toInt(),
      category: root['category'] as String?,
      categoryMessage: root['category_message'] as String?,
      sleepDuration: root['sleep_duration'] as String?,
      sleepTime: root['sleep_time'] as String?,
      wakeTime: root['wake_time'] as String?,
    );
  }
}
