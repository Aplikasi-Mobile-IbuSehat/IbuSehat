import 'package:flutter/foundation.dart';

/// A simple in-memory cache manager to prevent redundant API fetches 
/// and allow pages to reload instantly.
class ApiCacheManager {
  ApiCacheManager._();

  static final ApiCacheManager instance = ApiCacheManager._();

  final Map<String, dynamic> _cache = {};

  /// Retrieves data from cache if it exists, or fetches from Network and caches it.
  Future<dynamic> getOrFetch(
    String key,
    Future<dynamic> Function() fetchCallback, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(key)) {
      debugPrint('ApiCacheManager: Cache HIT for $key');
      return _cache[key];
    }

    try {
      debugPrint('ApiCacheManager: Cache MISS (or refresh) for $key');
      final data = await fetchCallback();
      _cache[key] = data;
      return data;
    } catch (e) {
      debugPrint('ApiCacheManager: Error fetching data for $key - $e');
      rethrow;
    }
  }

  void invalidate(String key) {
    _cache.remove(key);
  }

  void clearAll() {
    _cache.clear();
  }
}
