import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/models/water_intake.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/api_cache_manager.dart';

class WaterIntakeService {
  WaterIntakeService._();
  static final WaterIntakeService instance = WaterIntakeService._();

  static const _cacheKey = 'water_intake';

  // Gunakan getter agar tidak error compile jika ApiConfig.apiBaseUrl bukan const
  String get _getUrl => '${ApiConfig.apiBaseUrl}/user/water-intake';
  String get _addUrl => '${ApiConfig.apiBaseUrl}/user/water-intake/add';

  Future<WaterIntakeModel> getWaterIntake({bool forceRefresh = false}) async {
    final result = await ApiCacheManager.instance.getOrFetch(
      _cacheKey,
      () => _fetchFromApi(),
      forceRefresh: forceRefresh,
    );
    return result as WaterIntakeModel;
  }

  Future<WaterIntakeModel> addWaterIntake(int amount) async {
    final uri = Uri.parse(_addUrl);
    final headers = await AuthService.instance.jsonHeadersWithAuth();

    final response = await http
        .post(uri, headers: headers, body: jsonEncode({'amount': amount}))
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final updated = WaterIntakeModel.fromJson(body);
      ApiCacheManager.instance.set(_cacheKey, updated);
      return updated;
    }

    throw Exception(body['message'] ?? 'Gagal memperbarui asupan air');
  }

  String get _reduceUrl => '${ApiConfig.apiBaseUrl}/user/water-intake/reduce';

  Future<WaterIntakeModel> reduceWaterIntake(int amount) async {
    final uri = Uri.parse(_reduceUrl);
    final headers = await AuthService.instance.jsonHeadersWithAuth();

    final response = await http
        .post(uri, headers: headers, body: jsonEncode({'amount': amount}))
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final updated = WaterIntakeModel.fromJson(body);
      ApiCacheManager.instance.set(_cacheKey, updated);
      return updated;
    }

    throw Exception(body['message'] ?? 'Gagal mengurangi asupan air');
  }

  Future<WaterIntakeModel> _fetchFromApi() async {
    final uri = Uri.parse(_getUrl);
    final headers = await AuthService.instance.jsonHeadersWithAuth();

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return WaterIntakeModel.fromJson(body);
    }

    throw Exception(body['message'] ?? 'Gagal mengambil data asupan air');
  }

  void clearCache() => ApiCacheManager.instance.invalidate(_cacheKey);
}
