import 'package:flutter/foundation.dart';
import 'package:mobile/models/sleep_dashboard_model.dart';
import 'package:mobile/models/sleep_weekly_summary_model.dart';
import 'package:mobile/services/sleep_service.dart';

enum SleepLoadState { initial, loading, success, error }

class SleepProvider extends ChangeNotifier {
  SleepProvider({SleepService? service})
      : _service = service ?? SleepService();

  final SleepService _service;

  SleepLoadState state = SleepLoadState.initial;
  SleepDashboardModel? dashboard;
  SleepWeeklySummaryModel? weeklySummary;
  String? errorMessage;

  bool get isLoading => state == SleepLoadState.loading;
  bool get hasError => state == SleepLoadState.error;
  bool get hasData =>
      state == SleepLoadState.success &&
      dashboard != null &&
      (dashboard!.hasData);

  Future<void> loadDashboard() async {
    state = SleepLoadState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.fetchDashboard(),
        _service.fetchWeeklySummary(),
      ]);

      dashboard = results[0] as SleepDashboardModel;
      weeklySummary = results[1] as SleepWeeklySummaryModel;

      if (!dashboard!.hasData) {
        state = SleepLoadState.error;
        errorMessage = 'Belum ada data tidur';
      } else {
        state = SleepLoadState.success;
      }
    } on SleepServiceException catch (e) {
      errorMessage = e.message;
      state = SleepLoadState.error;
    } catch (e) {
      debugPrint('SleepProvider.loadDashboard: $e');
      errorMessage = 'Gagal memuat data tidur';
      state = SleepLoadState.error;
    }

    notifyListeners();
  }
}
