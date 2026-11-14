class SleepLogResult {
  const SleepLogResult({
    required this.sleepLogId,
    required this.isSaved,
    required this.score,
    required this.category,
    required this.categoryMessage,
    required this.sleepDuration,
    required this.sleepDurationRange,
    required this.consistencyPercent,
    required this.consistencyLabel,
    required this.nightWakings,
    required this.nightWakingsLabel,
    required this.sleepDebt,
    required this.sleepDebtLabel,
    required this.analysis,
    this.mood,
    this.moodLabel,
    this.moodEmoji,
    this.sleepTime,
    this.wakeTime,
  });

  final int sleepLogId;
  final bool isSaved;
  final int score;
  final String category;
  final String categoryMessage;
  final String sleepDuration;
  final String sleepDurationRange;
  final int consistencyPercent;
  final String consistencyLabel;
  final int nightWakings;
  final String nightWakingsLabel;
  final String sleepDebt;
  final String sleepDebtLabel;
  final String analysis;
  final String? mood;
  final String? moodLabel;
  final String? moodEmoji;
  final String? sleepTime;
  final String? wakeTime;

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  static String _parseString(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    return value.toString();
  }

  factory SleepLogResult.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return SleepLogResult(
      sleepLogId: (root['sleep_log_id'] as num?)?.toInt() ?? 0,
      isSaved: _parseBool(root['is_saved']),
      score: (root['score'] as num?)?.toInt() ?? 0,
      category: _parseString(root['category']),
      categoryMessage: _parseString(root['category_message'], ''),
      sleepDuration: _parseString(root['sleep_duration']),
      sleepDurationRange: _parseString(root['sleep_duration_range']),
      consistencyPercent: (root['consistency_percent'] as num?)?.toInt() ?? 0,
      consistencyLabel: _parseString(root['consistency_label']),
      nightWakings: (root['night_wakings'] as num?)?.toInt() ?? 0,
      nightWakingsLabel: _parseString(root['night_wakings_label']),
      sleepDebt: _parseString(root['sleep_debt']),
      sleepDebtLabel: _parseString(root['sleep_debt_label']),
      analysis: _parseString(root['analysis'], ''),
      mood: root['mood']?.toString(),
      moodLabel: root['mood_label']?.toString(),
      moodEmoji: root['mood_emoji']?.toString(),
      sleepTime: root['sleep_time']?.toString(),
      wakeTime: root['wake_time']?.toString(),
    );
  }

  Map<String, dynamic> toDataMap() => {
        'sleep_log_id': sleepLogId,
        'is_saved': isSaved,
        'score': score,
        'category': category,
        'category_message': categoryMessage,
        'sleep_duration': sleepDuration,
        'sleep_duration_range': sleepDurationRange,
        'consistency_percent': consistencyPercent,
        'consistency_label': consistencyLabel,
        'night_wakings': nightWakings,
        'night_wakings_label': nightWakingsLabel,
        'sleep_debt': sleepDebt,
        'sleep_debt_label': sleepDebtLabel,
        'analysis': analysis,
        if (mood != null) 'mood': mood,
        if (moodLabel != null) 'mood_label': moodLabel,
        if (moodEmoji != null) 'mood_emoji': moodEmoji,
        if (sleepTime != null) 'sleep_time': sleepTime,
        if (wakeTime != null) 'wake_time': wakeTime,
      };
}

class SleepLogRequest {
  const SleepLogRequest({
    required this.sleepTime,
    required this.wakeTime,
    required this.nightWakings,
    required this.awakeDuration,
    required this.mood,
    this.notes,
  });

  final String sleepTime;
  final String wakeTime;
  final int nightWakings;
  final int awakeDuration;
  final String mood;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'sleep_time': sleepTime,
        'wake_time': wakeTime,
        'night_wakings': nightWakings,
        'awake_duration': awakeDuration,
        'mood': mood,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };
}
