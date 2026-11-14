import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/models/progress_summary_model.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/api_cache_manager.dart';

class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  static const _cacheKey = 'progress_summary';

  String get _summaryUrl => '${ApiConfig.apiBaseUrl}/progress/summary';

  Future<ProgressSummaryModel> getProgressSummary({bool forceRefresh = false}) async {
    final result = await ApiCacheManager.instance.getOrFetch(
      _cacheKey,
      () => _fetchFromApi(),
      forceRefresh: forceRefresh,
    );
    return result as ProgressSummaryModel;
  }

  Future<ProgressSummaryModel> _fetchFromApi() async {
    final uri = Uri.parse(_summaryUrl);
    final headers = await AuthService.instance.jsonHeadersWithAuth();

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && body['status'] == 'success') {
      return ProgressSummaryModel.fromJson(body['data'] as Map<String, dynamic>);
    }

    throw Exception(body['message'] ?? 'Gagal mengambil ringkasan progress');
  }

  void clearCache() => ApiCacheManager.instance.invalidate(_cacheKey);
}
