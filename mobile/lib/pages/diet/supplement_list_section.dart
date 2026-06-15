import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/models/supplement.dart';
import 'package:mobile/pages/diet/supplement_detail_page.dart';
import 'package:mobile/pages/diet/add_supplement_page.dart';
import 'package:mobile/services/api_cache_manager.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DietSupplementListSection extends StatefulWidget {
  const DietSupplementListSection({
    super.key,
    this.maxItems = 5,
  });

  final int maxItems;

  @override
  State<DietSupplementListSection> createState() => DietSupplementListSectionState();
}

class DietSupplementListSectionState extends State<DietSupplementListSection> {
  bool _isLoading = true;
  bool _hasError = false;
  bool _retryScheduled = false;
  final List<Supplement> _supplements = [];

  @override
  void initState() {
    super.initState();
    _fetchSupplementLogs();
  }

  @override
  void dispose() {
    _retryScheduled = false;
    super.dispose();
  }

  Future<void> refresh({bool forceRefresh = false}) =>
      _fetchSupplementLogs(forceRefresh: forceRefresh);

  void _scheduleAutoRetry() {
    if (_retryScheduled || !mounted) return;
    _retryScheduled = true;
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || !_hasError) return;
      _retryScheduled = false;
      _fetchSupplementLogs(forceRefresh: true);
    });
  }

  Future<Map<String, String>> _jsonHeaders() async {
    return AuthService.instance.jsonHeadersWithAuth();
  }

  String? _formatTimeForApi(TimeOfDay? value) {
    if (value == null) return null;
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String? _normalizeImageForLog(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;
    final raw = imageUrl.trim();
    if (raw.length <= 255) return raw;
    final uri = Uri.tryParse(raw);
    final segments = uri?.pathSegments ?? const <String>[];
    if (segments.isNotEmpty) {
      final filename = segments.last;
      if (filename.length <= 255) return filename;
    }
    return raw.substring(raw.length - 255);
  }

  Future<void> _fetchSupplementLogs({bool forceRefresh = false}) async {
    if (forceRefresh) {
      ApiCacheManager.instance.invalidate('${ApiConfig.apiBaseUrl}/supplement-logs');
    }

    if (mounted) {
      setState(() {
        _isLoading = _supplements.isEmpty;
        _hasError = false;
        _retryScheduled = false;
      });
    }

    try {
      final cacheKey = '${ApiConfig.apiBaseUrl}/supplement-logs';
      final data = await ApiCacheManager.instance.getOrFetch(cacheKey, () async {
        final response = await http.get(
          Uri.parse(cacheKey),
          headers: await _jsonHeaders(),
        );
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['data'] as List<dynamic>;
        }
        throw Exception('Gagal memuat log suplemen');
      });

      if (!mounted) return;
      setState(() {
        _supplements
          ..clear()
          ..addAll((data as List<dynamic>).map((e) => Supplement.fromLogJson(
                e as Map<String, dynamic>,
                baseUrl: ApiConfig.baseUrl,
              )));
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _scheduleAutoRetry();
    }
  }

  Future<Supplement?> _addSupplementLog(Supplement supplement) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/supplement-logs'),
        headers: await _jsonHeaders(),
        body: jsonEncode({
          'supplement_id': int.tryParse(supplement.id),
          'nama_suplemen': supplement.name,
          'komposisi': supplement.composition,
          'kemasan': supplement.packaging,
          'aturan_pakai': supplement.rules,
          'gambar': _normalizeImageForLog(supplement.imageUrl),
          'source': supplement.source,
          'reminder_time': _formatTimeForApi(supplement.reminderTime),
          'is_taken': supplement.isTaken,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          ApiCacheManager.instance.invalidate('${ApiConfig.apiBaseUrl}/supplement-logs');
          final data = decoded['data'] as Map<String, dynamic>;
          return Supplement.fromLogJson(data, baseUrl: ApiConfig.baseUrl);
        }
        ApiCacheManager.instance.invalidate('${ApiConfig.apiBaseUrl}/supplement-logs');
        await _fetchSupplementLogs();
      }
    } catch (_) {}
    return null;
  }

  Future<Supplement?> _updateSupplementLog(Supplement supplement) async {
    if (supplement.logId == null || supplement.logId!.isEmpty) return null;
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.apiBaseUrl}/supplement-logs/${supplement.logId}'),
        headers: await _jsonHeaders(),
        body: jsonEncode({
          'supplement_id': int.tryParse(supplement.id),
          'nama_suplemen': supplement.name,
          'komposisi': supplement.composition,
          'kemasan': supplement.packaging,
          'aturan_pakai': supplement.rules,
          'gambar': supplement.imageUrl,
          'source': supplement.source,
          'reminder_time': _formatTimeForApi(supplement.reminderTime),
          'is_taken': supplement.isTaken,
        }),
      );
      if (response.statusCode == 200) {
        ApiCacheManager.instance.invalidate('${ApiConfig.apiBaseUrl}/supplement-logs');
        final data = jsonDecode(response.body)['data'];
        return Supplement.fromLogJson(
          data as Map<String, dynamic>,
          baseUrl: ApiConfig.baseUrl,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _deleteSupplementLog(Supplement supplement) async {
    if (supplement.logId == null || supplement.logId!.isEmpty) return false;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.apiBaseUrl}/supplement-logs/${supplement.logId}'),
        headers: await _jsonHeaders(),
      );
      if (response.statusCode == 200) {
        ApiCacheManager.instance.invalidate('${ApiConfig.apiBaseUrl}/supplement-logs');
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _updateSupplementAt(int index, Supplement next) async {
    final updated = await _updateSupplementLog(next);
    if (updated == null || !mounted) return;
    setState(() {
      _supplements[index] = updated;
    });
  }

  Future<void> _handleAddSupplement() async {
    if (_supplements.length >= widget.maxItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maksimal ${widget.maxItems} suplemen. Hapus salah satu dulu.')),
      );
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSupplementPage()),
    );
    if (result != null && result is Supplement) {
      final beforeCount = _supplements.length;
      final saved = await _addSupplementLog(result);
      if (saved != null && mounted) {
        setState(() {
          _supplements.add(saved);
        });
      } else if (mounted) {
        await _fetchSupplementLogs();
        if (!mounted) return;
        final insertedAfterRefresh = _supplements.length > beforeCount;
        if (!insertedAfterRefresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menambahkan suplemen. Coba lagi.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Suplemen Saya', _handleAddSupplement),
        const SizedBox(height: 20),
        _buildSupplementList(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAction) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final cardColor = isDark ? darkSurface : lightSurface;
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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

  Widget _buildSupplementList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final cardColor = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;
    if (_isLoading) {
      return _buildSupplementSkeleton(isDark: isDark, cardColor: cardColor, border: border);
    }
    if (_hasError) {
      return _buildErrorState('Gagal memuat log suplemen', () => refresh(forceRefresh: true));
    }

    if (_supplements.isEmpty) {
      return _buildEmptyState(Icons.medication_outlined, 'Belum ada suplemen');
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
        itemCount: _supplements.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final supplement = _supplements[index];
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.12)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildSupplementImage(supplement),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplement.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          supplement.isTaken ? 'Sudah diminum' : 'Belum diminum',
                          style: TextStyle(
                            color: supplement.isTaken ? const Color(0xFF22C55E) : textSecondary,
                            fontSize: 12,
                            fontWeight: supplement.isTaken ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (supplement.reminderTime != null)
                    GestureDetector(
                      onTap: () => _showTimePickerSheet(index),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.alarm_rounded, size: 14, color: textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              supplement.reminderTime!.format(context),
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      _updateSupplementAt(
                        index,
                        supplement.copyWith(isTaken: !supplement.isTaken),
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: supplement.isTaken
                            ? const Color(0xFF22C55E).withOpacity(0.1)
                            : (isDark ? darkBorder : lightBackground),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: supplement.isTaken ? const Color(0xFF22C55E) : border,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: supplement.isTaken ? const Color(0xFF22C55E) : textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSupplementSkeleton({
    required bool isDark,
    required Color cardColor,
    required Color border,
  }) {
    final shimmerBase = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);
    final shimmerHighlight = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFFFFFFF);
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
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
                // Gambar suplemen skeleton
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
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
                        width: 90,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Checkbox skeleton
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTimePickerSheet(int index) {
    final supplement = _supplements[index];
    TimeOfDay selectedTime = supplement.reminderTime ?? TimeOfDay.now();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hourController = FixedExtentScrollController(initialItem: selectedTime.hour);
            final minuteController = FixedExtentScrollController(initialItem: selectedTime.minute);

            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? darkSurface
                        : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Atur Pengingat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? darkTextPrimary
                              : const Color(0xFF1F1235),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 140,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              child: ListWheelScrollView.useDelegate(
                                controller: hourController,
                                itemExtent: 45,
                                perspective: 0.005,
                                diameterRatio: 1.2,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (value) {
                                  setModalState(() {
                                    selectedTime = TimeOfDay(hour: value, minute: selectedTime.minute);
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 24,
                                  builder: (context, value) {
                                    final isSelected = selectedTime.hour == value;
                                    return Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: TextStyle(
                                          fontSize: isSelected ? 28 : 20,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade400,
                                        ),
                                        child: Text(value.toString().padLeft(2, '0')),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const Text(
                              ':',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F1235),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: ListWheelScrollView.useDelegate(
                                controller: minuteController,
                                itemExtent: 45,
                                perspective: 0.005,
                                diameterRatio: 1.2,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (value) {
                                  setModalState(() {
                                    selectedTime = TimeOfDay(hour: selectedTime.hour, minute: value);
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 60,
                                  builder: (context, value) {
                                    final isSelected = selectedTime.minute == value;
                                    return Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: TextStyle(
                                          fontSize: isSelected ? 28 : 20,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade400,
                                        ),
                                        child: Text(value.toString().padLeft(2, '0')),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _updateSupplementAt(
                                      index,
                                      supplement.copyWith(reminderTime: selectedTime),
                                    );
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Simpan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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

  void _showItemOptionsSheet(int index) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? darkSurface
                    : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                    'Opsi Suplemen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? darkTextPrimary
                          : const Color(0xFF1F1235),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildBottomSheetOption(
                    icon: Icons.edit_rounded,
                    title: 'Edit',
                    color: Theme.of(context).brightness == Brightness.dark
                        ? darkTextPrimary
                        : const Color(0xFF1F1235),
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupplementDetailPage(supplement: _supplements[index],),
                        ),
                      );
                      if (result != null && result is Supplement) {
                        _updateSupplementAt(index, result);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBottomSheetOption(
                    icon: Icons.delete_outline_rounded,
                    title: 'Hapus',
                    color: Colors.red,
                    onTap: () async {
                      Navigator.pop(context);
                      final deleted = await _deleteSupplementLog(_supplements[index]);
                      if (deleted && mounted) {
                        setState(() {
                          _supplements.removeAt(index);
                        });
                      }
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
          color: color.withOpacity(0.05),
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

  Widget _buildSupplementImage(Supplement supplement) {
    final imageUrl = supplement.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.medication_outlined, color: Color(0xFF8B5CF6), size: 22);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: const Color(0xFFF5F3FF),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)),
        ),
      ),
      errorWidget: (context, url, error) =>
          const Icon(Icons.medication_outlined, color: Color(0xFF8B5CF6), size: 22),
    );
  }
}
