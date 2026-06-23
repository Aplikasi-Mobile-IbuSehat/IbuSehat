import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/models/food.dart';
import 'package:mobile/pages/diet/add_food_page.dart';
import 'package:mobile/pages/diet/food_detail_page.dart';
import 'package:mobile/services/api_cache_manager.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/theme/app_colors.dart';
// import 'package:skeletonizer/skeletonizer.dart'; // Removed - using custom loading placeholder

class DietFoodLogSection extends StatefulWidget {
  const DietFoodLogSection({
    super.key,
    this.maxItems = 10,
    this.onTotalKcalChanged,
  });

  final int maxItems;
  final ValueChanged<double>? onTotalKcalChanged;

  @override
  State<DietFoodLogSection> createState() => DietFoodLogSectionState();
}

class DietFoodLogSectionState extends State<DietFoodLogSection> {
  bool _isLoading = true;
  bool _hasError = false;
  bool _retryScheduled = false;
  final List<Food> _foodLog = [];

  @override
  void initState() {
    super.initState();
    _fetchFoodLogs();
  }

  @override
  void dispose() {
    _retryScheduled = false;
    super.dispose();
  }

  Future<void> refresh({bool forceRefresh = false}) => _fetchFoodLogs(forceRefresh: forceRefresh);

  void _scheduleAutoRetry() {
    if (_retryScheduled || !mounted) return;
    _retryScheduled = true;
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || !_hasError) return;
      _retryScheduled = false;
      _fetchFoodLogs(forceRefresh: true);
    });
  }

  Future<Map<String, String>> _jsonHeaders() async {
    return AuthService.instance.jsonHeadersWithAuth();
  }

  Future<void> _fetchFoodLogs({bool forceRefresh = false}) async {
    if (forceRefresh) {
      ApiCacheManager.instance.invalidate('${ApiConfig.apiBaseUrl}/food-logs');
    }

    if (mounted) {
      setState(() {
        _isLoading = _foodLog.isEmpty;
        _hasError = false;
        _retryScheduled = false;
      });
    }

    try {
      final cacheKey = '${ApiConfig.apiBaseUrl}/food-logs';
      final data = await ApiCacheManager.instance.getOrFetch(cacheKey, () async {
        final response = await http.get(
          Uri.parse(cacheKey),
          headers: await _jsonHeaders(),
        );
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['data'] as List<dynamic>;
        }
        throw Exception('Gagal memuat log makanan');
      });

      if (!mounted) return;
      setState(() {
        _foodLog
          ..clear()
          ..addAll((data as List<dynamic>).map((e) => Food.fromLogJson(e)));
        _isLoading = false;
        _hasError = false;
      });
      _notifyTotalKcal();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _scheduleAutoRetry();
    }
  }

  Future<void> _handleAddFood() async {
    if (_foodLog.length >= widget.maxItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maksimal ${widget.maxItems} makanan per hari. Hapus salah satu dulu.'),
        ),
      );
      return;
    }

    final result = await Navigator.push<Food>(
      context,
      MaterialPageRoute(builder: (context) => const AddFoodPage()),
    );
    if (result == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/food-logs'),
        headers: await _jsonHeaders(),
        body: jsonEncode({
          'makanan_id': result.id,
          'nama_makanan': result.name,
          'weight': result.weight,
          'kcal': result.kcal,
          'protein': result.protein,
          'carbs': result.carbs,
          'fat': result.fat,
          'category': result.category,
        }),
      );
      if (response.statusCode == 201 && mounted) {
        ApiCacheManager.instance.invalidate('${ApiConfig.apiBaseUrl}/food-logs');
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _foodLog.add(Food.fromLogJson(data));
        });
        _notifyTotalKcal();
      }
    } catch (_) {}
  }

  void _notifyTotalKcal() {
    final total = _foodLog.fold<double>(0, (sum, item) => sum + item.kcal);
    widget.onTotalKcalChanged?.call(total);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Daftar Makanan', _handleAddFood),
        const SizedBox(height: 20),
        _buildFoodList(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAction) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final cardColor = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: border),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final cardColor = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;
    if (_isLoading) {
      return _buildFoodSkeleton(isDark: isDark, cardColor: cardColor, border: border);
    }
    if (_hasError) {
      return _buildErrorState('Gagal memuat log makanan', () => refresh(forceRefresh: true));
    }
    if (_foodLog.isEmpty) {
      return _buildEmptyState(Icons.restaurant_menu_rounded, 'Belum ada makanan dicatat');
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _foodLog.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final Food food = _foodLog[index];
          return GestureDetector(
            onTap: () => _showItemOptionsSheet(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getFoodColor(food),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getFoodIcon(food),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${food.weight.toStringAsFixed(0)} g',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${food.kcal.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.chevron_right_rounded, color: textSecondary, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodSkeleton({
    required bool isDark,
    required Color cardColor,
    required Color border,
  }) {
    // Simple loading placeholder (skeletonizer removed for compatibility)
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    /* Old skeleton code - removed for compatibility
    final shimmerBase = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);
    final shimmerHighlight = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFFFFFFF);
    return Container(
      enabled: true,
      effect: // ShimmerEffect(
        baseColor: shimmerBase,
        highlightColor: shimmerHighlight,
        duration: const Duration(milliseconds: 1200),
      ),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 11,
                        width: 80,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 13,
                  width: 60,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    */
  }

  void _showItemOptionsSheet(int index) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Opsi Makanan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? darkTextPrimary : const Color(0xFF1F1235),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildBottomSheetOption(
                    icon: Icons.edit_rounded,
                    title: 'Edit',
                    color: isDark ? darkTextPrimary : const Color(0xFF1F1235),
                    onTap: () async {
                      Navigator.pop(context);
                      final original = _foodLog[index];
                      final updated = await Navigator.push<Food>(
                        context,
                        MaterialPageRoute(builder: (context) => FoodDetailPage(food: original)),
                      );
                      if (updated == null) return;
                      try {
                        final response = await http.put(
                          Uri.parse('${ApiConfig.apiBaseUrl}/food-logs/${original.id}'),
                          headers: await _jsonHeaders(),
                          body: jsonEncode({
                            'makanan_id': updated.id,
                            'nama_makanan': updated.name,
                            'weight': updated.weight,
                            'kcal': updated.kcal,
                            'protein': updated.protein,
                            'carbs': updated.carbs,
                            'fat': updated.fat,
                            'category': updated.category,
                          }),
                        );
                        if (response.statusCode == 200 && mounted) {
                          ApiCacheManager.instance.invalidate('${ApiConfig.apiBaseUrl}/food-logs');
                          final data = jsonDecode(response.body)['data'];
                          setState(() {
                            _foodLog[index] = Food.fromLogJson(data);
                          });
                          _notifyTotalKcal();
                        }
                      } catch (_) {}
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBottomSheetOption(
                    icon: Icons.delete_outline_rounded,
                    title: 'Hapus',
                    color: Colors.red,
                    onTap: () async {
                      Navigator.pop(context);
                      final foodId = _foodLog[index].id;
                      try {
                        final response = await http.delete(
                          Uri.parse('${ApiConfig.apiBaseUrl}/food-logs/$foodId'),
                          headers: await _jsonHeaders(),
                        );
                        if (response.statusCode == 200 && mounted) {
                          ApiCacheManager.instance.invalidate('${ApiConfig.apiBaseUrl}/food-logs');
                          setState(() {
                            _foodLog.removeAt(index);
                          });
                          _notifyTotalKcal();
                        }
                      } catch (_) {}
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? darkSurface : lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? darkBorder : lightBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? darkSurface : lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? darkBorder : lightBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  IconData _getFoodIcon(Food food) {
    final category = (food.category ?? '').toLowerCase();
    if (category.contains('buah')) return Icons.apple_rounded;
    if (category.contains('sayur')) return Icons.eco_rounded;
    if (category.contains('kacang')) return Icons.spa_rounded;
    if (category.contains('susu')) return Icons.local_drink_rounded;
    if (category.contains('olahan')) return Icons.restaurant_rounded;
    return Icons.restaurant;
  }

  Color _getFoodColor(Food food) {
    final category = (food.category ?? '').toLowerCase();
    if (category.contains('buah')) return const Color(0xFFEF4444);
    if (category.contains('sayur')) return const Color(0xFF22C55E);
    if (category.contains('kacang')) return const Color(0xFFF59E0B);
    if (category.contains('susu')) return const Color(0xFF3B82F6);
    if (category.contains('olahan')) return const Color(0xFF8B5CF6);
    return const Color(0xFF8B5CF6);
  }
}
