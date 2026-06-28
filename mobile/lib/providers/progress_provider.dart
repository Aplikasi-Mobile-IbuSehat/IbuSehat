import 'package:flutter/foundation.dart';
import 'package:mobile/models/progress_summary_model.dart';
import 'package:mobile/services/progress_service.dart';

class ProgressProvider with ChangeNotifier {
  final ProgressService _progressService;

  ProgressProvider({ProgressService? progressService})
      : _progressService = progressService ?? ProgressService.instance;

  ProgressSummaryModel? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  ProgressSummaryModel? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _summary != null;

  Future<void> fetchSummary({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('=== ProgressProvider: fetching summary...');
      final summary = await _progressService.getProgressSummary(forceRefresh: forceRefresh);
      _summary = summary;
      _errorMessage = null;
      debugPrint('=== ProgressProvider: fetched successfully, hasData=${_summary != null}');
    } catch (e, st) {
      _errorMessage = 'Gagal memuat data progress';
      debugPrint('=== ProgressProvider: Error: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _summary = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
