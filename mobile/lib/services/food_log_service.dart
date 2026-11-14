import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile/models/food.dart'; // model Food kamu

class FoodService {
  static const String _baseUrl = 'https://your-api.com/api';
  final String token;

  FoodService({required this.token});

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ─── FOOD DATABASE ────────────────────────────────────────────

  /// Cari makanan dari database
  Future<List<Food>> searchFoods({
    String? search,
    String? kategori,
    int perPage = 20,
  }) async {
    final params = <String, String>{'per_page': perPage.toString()};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (kategori != null && kategori.isNotEmpty) params['kategori'] = kategori;

    final uri = Uri.parse('$_baseUrl/foods').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    final body = jsonDecode(res.body);

    if (res.statusCode == 200 && body['success'] == true) {
      return (body['data'] as List)
          .map((e) => Food.fromJson(e))
          .toList();
    }
    throw Exception(body['message'] ?? 'Gagal mengambil data makanan');
  }

  /// Ambil semua kategori makanan
  Future<List<String>> getCategories() async {
    final uri = Uri.parse('$_baseUrl/foods/categories');
    final res = await http.get(uri, headers: _headers);
    final body = jsonDecode(res.body);

    if (res.statusCode == 200 && body['success'] == true) {
      return List<String>.from(body['data']);
    }
    throw Exception('Gagal mengambil kategori');
  }

  // ─── FOOD LOG ─────────────────────────────────────────────────

  /// Ambil log makanan (default: hari ini)
  Future<Map<String, dynamic>> getFoodLogs({DateTime? date}) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date ?? DateTime.now());
    final uri = Uri.parse('$_baseUrl/food-logs?date=$dateStr');
    final res = await http.get(uri, headers: _headers);
    final body = jsonDecode(res.body);

    if (res.statusCode == 200 && body['success'] == true) {
      return {
        'date'    : body['date'],
        'logs'    : (body['data'] as List).map((e) => Food.fromLogJson(e)).toList(),
        'summary' : body['summary'],
        'meta'    : body['meta'],
      };
    }
    throw Exception('Gagal mengambil food log');
  }

  /// Tambah makanan ke log
  Future<Food> addFoodLog({
    required Food food,
    required double weight,
    String? category,
    int? makananId,
  }) async {
    // Hitung ulang nutrisi berdasarkan weight aktual (per 100g)
    final ratio = weight / 100;

    final uri = Uri.parse('$_baseUrl/food-logs');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'nama_makanan' : food.name,
        'weight'       : weight,
        'kcal'         : food.kcal * ratio,
        'protein'      : food.protein * ratio,
        'carbs'        : food.carbs * ratio,
        'fat'          : food.fat * ratio,
        'category'     : category ?? food.category ?? '',
        if (makananId != null) 'makanan_id': makananId,
      }),
    );
    final body = jsonDecode(res.body);

    if (res.statusCode == 201 && body['success'] == true) {
      return Food.fromLogJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Gagal menambah food log');
  }

  /// Update log makanan
  Future<Food> updateFoodLog({
    required int logId,
    double? weight,
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
    String? category,
  }) async {
    final uri = Uri.parse('$_baseUrl/food-logs/$logId');
    final payload = <String, dynamic>{};
    if (weight != null)   payload['weight']   = weight;
    if (kcal != null)     payload['kcal']     = kcal;
    if (protein != null)  payload['protein']  = protein;
    if (carbs != null)    payload['carbs']    = carbs;
    if (fat != null)      payload['fat']      = fat;
    if (category != null) payload['category'] = category;

    final res = await http.patch(uri, headers: _headers, body: jsonEncode(payload));
    final body = jsonDecode(res.body);

    if (res.statusCode == 200 && body['success'] == true) {
      return Food.fromLogJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Gagal update food log');
  }

  /// Hapus log makanan
  Future<void> deleteFoodLog(int logId) async {
    final uri = Uri.parse('$_baseUrl/food-logs/$logId');
    final res = await http.delete(uri, headers: _headers);
    final body = jsonDecode(res.body);

    if (res.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Gagal menghapus food log');
    }
  }

  /// Ringkasan mingguan
  Future<List<Map<String, dynamic>>> getWeeklySummary() async {
    final from = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 6)));
    final to = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final uri = Uri.parse('$_baseUrl/food-logs/summary?from=$from&to=$to');
    final res = await http.get(uri, headers: _headers);
    final body = jsonDecode(res.body);

    if (res.statusCode == 200 && body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    throw Exception('Gagal mengambil ringkasan mingguan');
  }
}