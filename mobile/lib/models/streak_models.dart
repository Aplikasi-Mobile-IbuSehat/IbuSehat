class StreakResult {
  final int streakActive;
  final int streakLongest;
  final bool isNewStreakDay;
  final String message;

  StreakResult({
    required this.streakActive,
    required this.streakLongest,
    required this.isNewStreakDay,
    required this.message,
  });

  factory StreakResult.fromJson(Map<String, dynamic> json) {
    return StreakResult(
      streakActive: json['streak_active'] as int? ?? 0,
      streakLongest: json['streak_longest'] as int? ?? 0,
      isNewStreakDay: json['is_new_streak_day'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}

class CalendarDay {
  final String date;
  final String status; // "completed", "missed", "today", "future"

  CalendarDay({
    required this.date,
    required this.status,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'future',
    );
  }
}

class StreakData {
  final int streakActive;
  final int streakLongest;
  final int totalAktivitas;
  final int hariAktifBulanIni;
  final List<CalendarDay> calendar;

  StreakData({
    required this.streakActive,
    required this.streakLongest,
    required this.totalAktivitas,
    required this.hariAktifBulanIni,
    required this.calendar,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      streakActive: json['streak_active'] as int? ?? 0,
      streakLongest: json['streak_longest'] as int? ?? 0,
      totalAktivitas: json['total_aktivitas'] as int? ?? 0,
      hariAktifBulanIni: json['hari_aktif_bulan_ini'] as int? ?? 0,
      calendar: (json['calendar'] as List<dynamic>?)
              ?.map((e) => CalendarDay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
