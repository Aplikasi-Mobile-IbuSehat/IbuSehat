class SleepHistoryItem {
  const SleepHistoryItem({
    required this.id,
    required this.date,
    required this.dateIso,
    required this.sleepDuration,
    required this.score,
    required this.statusLabel,
    required this.emoji,
  });

  final int id;
  final String date;
  final String dateIso;
  final String sleepDuration;
  final int score;
  final String statusLabel;
  final String emoji;

  factory SleepHistoryItem.fromJson(Map<String, dynamic> json) {
    return SleepHistoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      date: json['date'] as String? ?? '-',
      dateIso: json['date_iso'] as String? ?? '',
      sleepDuration: json['sleep_duration'] as String? ?? '-',
      score: (json['score'] as num?)?.toInt() ?? 0,
      statusLabel: json['status_label'] as String? ?? '-',
      emoji: json['emoji'] as String? ?? '😐',
    );
  }
}
