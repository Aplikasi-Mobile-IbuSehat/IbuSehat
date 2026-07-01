import 'package:flutter/foundation.dart';
import 'package:mobile/models/sleep_weekly_summary_model.dart';
import 'package:mobile/services/sleep_service.dart';

/// Provider untuk mengelola state data tidur mingguan
/// Digunakan untuk sinkronisasi data antara halaman input dan Beranda
class SleepProvider with ChangeNotifier {
  final SleepService _sleepService;
  
  SleepProvider({SleepService? sleepService})
      : _sleepService = sleepService ?? SleepService();

  SleepWeeklySummaryModel? _weeklySummary;
  bool _isLoading = false;
  String? _errorMessage;

  SleepWeeklySummaryModel? get weeklySummary => _weeklySummary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _weeklySummary?.hasData ?? false;

  /// Mengambil data ringkasan tidur mingguan dari API
  Future<void> fetchWeeklySummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('=== SleepProvider: fetching weekly summary...');
      final summary = await _sleepService.fetchWeeklySummary();
      _weeklySummary = summary;
      _errorMessage = null;
      debugPrint('=== SleepProvider: fetched successfully, hasData=${summary.hasData}');
      debugPrint('=== SleepProvider: averageDuration=${summary.averageDuration}');
    } on SleepServiceException catch (e) {
      _errorMessage = e.message;
      debugPrint('=== SleepProvider: SleepServiceException: ${e.message}');
    } catch (e, st) {
      _errorMessage = 'Gagal memuat data tidur';
      debugPrint('=== SleepProvider: Error: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset data (untuk logout atau clear cache)
  void clear() {
    _weeklySummary = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Konversi durasi string (format "Xj Ym") ke total jam desimal
  /// Contoh: "7j 30m" -> 7.5 jam
  double getTotalHoursFromDuration(String? duration) {
    if (duration == null || duration.isEmpty || duration == '-') return 0.0;
    
    try {
      // Parse format "7j 30m"
      final parts = duration.split(' ');
      if (parts.length != 2) return 0.0;
      
      final hours = int.tryParse(parts[0].replaceAll('j', '')) ?? 0;
      final minutes = int.tryParse(parts[1].replaceAll('m', '')) ?? 0;
      
      return hours + (minutes / 60.0);
    } catch (e) {
      debugPrint('=== SleepProvider: Error parsing duration "$duration": $e');
      return 0.0;
    }
  }

  /// Mendapatkan total jam tidur mingguan
  /// Menggunakan total_hours langsung dari backend (SUM semua records)
  double get weeklyTotalHours {
    if (!hasData) return 0.0;
    
    // 🔥 GUNAKAN TOTAL_HOURS DARI BACKEND (SUDAH SUM SEMUA CATATAN)
    final totalHours = _weeklySummary?.totalHours;
    
    if (totalHours != null && totalHours > 0) {
      debugPrint('=== SleepProvider: using total_hours from backend=$totalHours');
      return totalHours;
    }
    
    // Fallback: hitung dari chart jika total_hours tidak tersedia
    final chart = _weeklySummary?.chart ?? [];
    double totalFromChart = 0.0;
    
    for (final day in chart) {
      if (day.durationMinutes > 0) {
        totalFromChart += day.durationMinutes / 60.0;
      }
    }
    
    debugPrint('=== SleepProvider: using fallback calculation from chart=$totalFromChart');
    return totalFromChart;
  }

  /// Mendapatkan persentase progress terhadap target 49 jam per minggu
  int get weeklyProgressPercent {
    const targetHours = 49.0;
    final total = weeklyTotalHours;
    
    if (total <= 0) return 0;
    
    final percent = (total / targetHours * 100).round();
    return percent.clamp(0, 100);
  }
}
