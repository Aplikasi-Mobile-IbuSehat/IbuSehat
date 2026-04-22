import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/config/api_config.dart';
import 'package:mobile/services/api_cache_manager.dart';
import 'package:mobile/models/food.dart';
import 'package:mobile/models/supplement.dart';
import 'package:mobile/pages/diet/add_food_page.dart';
import 'package:mobile/pages/diet/add_supplement_page.dart';
import 'package:mobile/pages/diet/food_detail_page.dart';
import 'package:mobile/pages/diet/water_intake_page.dart';
import 'package:mobile/pages/profile/premium_page.dart';
import 'package:mobile/pages/chat/ai_chat_page.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/widgets/app_background.dart';

class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> with AutomaticKeepAliveClientMixin {
  static const int _maxFoodLogItems = 10;
  static const int _maxSupplementLogItems = 5;
  bool _isLoadingFoods = true;
  bool _isLoadingSupplements = true;
  List<Food> _foodLog = [];

  // MOCK DATA
  int _waterIntakeMl = 500;
  final int waterGoalMl = 2500;

  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchFoodLogs();
    _fetchSupplementLogs();
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

  Future<void> _fetchFoodLogs() async {
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

      if (mounted) {
        setState(() {
          _foodLog = (data as List<dynamic>).map((e) => Food.fromLogJson(e)).toList();
          _isLoadingFoods = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFoods = false);
    }
  }

  Future<void> _fetchSupplementLogs() async {
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

      if (mounted) {
        setState(() {
          _supplements = (data as List<dynamic>)
              .map((e) => Supplement.fromLogJson(
                    e as Map<String, dynamic>,
                    baseUrl: ApiConfig.baseUrl,
                  ))
              .toList();
          _isLoadingSupplements = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSupplements = false);
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
          return Supplement.fromLogJson(
            data,
            baseUrl: ApiConfig.baseUrl,
          );
        }
        ApiCacheManager.instance.invalidate('${ApiConfig.apiBaseUrl}/supplement-logs');
        await _fetchSupplementLogs();
        return null;
      }
      debugPrint('Add supplement failed (${response.statusCode}): ${response.body}');
    } catch (e) {
      debugPrint('Add supplement error: $e');
    }
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


  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bool isScrolled = _scrollController.offset > 5;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  List<Supplement> _supplements = [];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    double totalKcal = _foodLog.fold(0, (sum, item) => sum + item.kcal);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 95.0,
              backgroundColor: _isScrolled ? const Color(0xFFF8F9FB) : Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: _isScrolled ? 1 : 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PremiumPage()),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: SvgPicture.asset(
                              'assets/icons/sparkles_premium.svg',
                              width: 24, // Matches the size of message_circle.svg
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/message_circle.svg',
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF1F1235),
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AiChatPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(left: 20, bottom: 16),
                centerTitle: false,
                title: Text(
                  'Diet & Nutrisi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1235),
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Today's Summary (Calories)
                    _buildSummaryCard(totalKcal),
                    const SizedBox(height: 28),

                    // Section header
                    _buildSectionHeader('Daftar Makanan', '+ Tambah', () async {
                      if (_foodLog.length >= _maxFoodLogItems) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Maksimal 10 makanan per hari. Hapus salah satu dulu.'),
                          ),
                        );
                        return;
                      }

                      final result = await Navigator.push<Food>(context,
                          MaterialPageRoute(builder: (context) => const AddFoodPage()));
                      if (result != null) {
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
                              'jenis': result.jenis,
                            }),
                          );
                            if (response.statusCode == 201) {
                              ApiCacheManager.instance.invalidate('${ApiConfig.apiBaseUrl}/food-logs');
                              final data = jsonDecode(response.body)['data'];
                              setState(() {
                                _foodLog.add(Food.fromLogJson(data));
                              });
                            }
                        } catch (e) {
                          // Handle error ideally, omitting for brevity
                        }
                      }
                    }),
                    const SizedBox(height: 20),
                    _buildFoodLog(),
                    const SizedBox(height: 28),

                    // Water Intake
                    _buildSectionHeader('Asupan Air', null, null),
                    const SizedBox(height: 20),
                    _buildWaterTracker(),
                    const SizedBox(height: 28),

                    // Supplement
                    _buildSectionHeader('Suplemen Saya', '+ Tambah', () async {
                      if (_supplements.length >= _maxSupplementLogItems) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Maksimal 5 suplemen. Hapus salah satu dulu.'),
                          ),
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
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal menambahkan suplemen. Coba lagi.'),
                              ),
                            );
                          }
                        }
                      }
                    }),
                    const SizedBox(height: 20),
                    _buildSupplementList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionHeader(String title, String? actionLabel, VoidCallback? onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1235),
            letterSpacing: -0.3,
          ),
        ),
        if (onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
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

  Widget _buildSummaryCard(double totalKcal) {
    const double targetKcal = 2000;
    final double progress = (totalKcal / targetKcal).clamp(0.0, 1.0);
    final double remaining = (targetKcal - totalKcal).clamp(0, targetKcal);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFB084F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kalori Hari Ini',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalKcal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.5),
                  ),
                  const Text(
                    'kkal',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  )
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('Sisa', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text(
                          '${remaining.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5),
                        ),
                        const Text('kkal', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${totalKcal.toStringAsFixed(0)} kkal dikonsumsi',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                'Target ${targetKcal.toStringAsFixed(0)}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodLog() {
    if (_isLoadingFoods) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      );
    }
    if (_foodLog.isEmpty) {
      return _buildEmptyState(Icons.restaurant_menu_rounded, 'Belum ada makanan dicatat');
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _foodLog.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final Food food = _foodLog[index];
          return GestureDetector(
            onTap: () => _showItemOptionsSheet(context, isFood: true, index: index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                  // Name + weight — constrained so kcal has space
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1F1235)),
                        ),
                        const SizedBox(height: 2),
                        Text('${food.weight.toStringAsFixed(0)} g',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Kcal — fixed, never pushed
                  Text(
                    '${food.kcal.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1F1235)),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaterTracker() {
    double progress = (_waterIntakeMl / waterGoalMl).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WaterIntakePage(
              currentIntake: _waterIntakeMl,
              goalIntake: waterGoalMl,
              onAddWater: (amount) {
                setState(() {
                  _waterIntakeMl += amount;
                });
              },
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SvgPicture.asset(
                        'assets/icons/water_glass.svg',
                        height: 28, color: Colors.blue,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_waterIntakeMl ml',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1F1235), letterSpacing: -0.5),
                      ),
                      Text(
                        '/ $waterGoalMl ml',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFEFF6FF),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF3B82F6), size: 22),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePickerSheet(BuildContext context, int index) {
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
            final FixedExtentScrollController hourController =
                FixedExtentScrollController(initialItem: selectedTime.hour);
            final FixedExtentScrollController minuteController =
                FixedExtentScrollController(initialItem: selectedTime.minute);

            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 40), // Floating bottom margin
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      // Title
                      const Text(
                        'Atur Pengingat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1235),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Dual Wheel Picker (00 : 00)
                      SizedBox(
                        height: 140,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hours
                            SizedBox(
                              width: 80,
                              child: ListWheelScrollView.useDelegate(
                                controller: hourController,
                                itemExtent: 45,
                                perspective: 0.005,
                                diameterRatio: 1.2,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) {
                                  setModalState(() {
                                    selectedTime = TimeOfDay(hour: index, minute: selectedTime.minute);
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 24,
                                  builder: (context, index) {
                                    bool isSelected = selectedTime.hour == index;
                                    return Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: TextStyle(
                                          fontSize: isSelected ? 28 : 20,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade400,
                                        ),
                                        child: Text(index.toString().padLeft(2, '0')),
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
                            // Minutes
                            SizedBox(
                              width: 80,
                              child: ListWheelScrollView.useDelegate(
                                controller: minuteController,
                                itemExtent: 45,
                                perspective: 0.005,
                                diameterRatio: 1.2,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) {
                                  setModalState(() {
                                    selectedTime = TimeOfDay(hour: selectedTime.hour, minute: index);
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 60,
                                  builder: (context, index) {
                                    bool isSelected = selectedTime.minute == index;
                                    return Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: TextStyle(
                                          fontSize: isSelected ? 28 : 20,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade400,
                                        ),
                                        child: Text(index.toString().padLeft(2, '0')),
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
                      
                      // Buttons
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
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildSupplementList() {
    if (_isLoadingSupplements) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      );
    }

    if (_supplements.isEmpty) {
      return _buildEmptyState(Icons.medication_outlined, 'Belum ada suplemen');
    }

    return Container(
      height: 200, // Fixed height for scrollable box
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _supplements.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final supplement = _supplements[index];
          return GestureDetector(
            onTap: () => _showItemOptionsSheet(context, isFood: false, index: index),
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                      Text(supplement.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1F1235))),
                      const SizedBox(height: 2),
                      Text(
                        supplement.isTaken ? 'Sudah diminum' : 'Belum diminum',
                        style: TextStyle(
                            color: supplement.isTaken 
                                ? const Color(0xFF22C55E) 
                                : Colors.grey.shade500, 
                            fontSize: 12,
                            fontWeight: supplement.isTaken ? FontWeight.w600 : FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                if (supplement.reminderTime != null)
                  GestureDetector(
                    onTap: () => _showTimePickerSheet(context, index),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.alarm_rounded,
                              size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            supplement.reminderTime!.format(context),
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: supplement.isTaken 
                          ? const Color(0xFF22C55E).withOpacity(0.1) 
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: supplement.isTaken 
                            ? const Color(0xFF22C55E) 
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: supplement.isTaken 
                          ? const Color(0xFF22C55E) 
                          : Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ));
        },
      ),
    );
  }

  void _showItemOptionsSheet(BuildContext context, {required bool isFood, required int index}) {
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
                color: Colors.white,
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
                    isFood ? 'Opsi Makanan' : 'Opsi Suplemen',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1235),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildBottomSheetOption(
                    icon: Icons.edit_rounded,
                    title: 'Edit',
                    color: const Color(0xFF1F1235),
                    onTap: () async {
                      Navigator.pop(context);
                      if (isFood) {
                        final original = _foodLog[index];
                        final updated = await Navigator.push<Food>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodDetailPage(food: original),
                          ),
                        );
                        if (updated != null) {
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
                                'jenis': updated.jenis,
                              }),
                            );

                            if (response.statusCode == 200) {
                              ApiCacheManager.instance.invalidate('${ApiConfig.apiBaseUrl}/food-logs');
                              final data = jsonDecode(response.body)['data'];
                              if (!mounted) return;
                              setState(() {
                                _foodLog[index] = Food.fromLogJson(data);
                              });
                            }
                          } catch (_) {
                            // Keep silent for now, can be replaced with SnackBar later.
                          }
                        }
                      } else {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddSupplementPage(supplement: _supplements[index])),
                        );
                        if (result != null && result is Supplement) {
                          _updateSupplementAt(index, result);
                        }
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
                      if (isFood) {
                        final foodId = _foodLog[index].id;
                        try {
                          final response = await http.delete(
                            Uri.parse('${ApiConfig.apiBaseUrl}/food-logs/$foodId'),
                            headers: await _jsonHeaders(),
                          );
                          if (response.statusCode == 200) {
                            ApiCacheManager.instance.invalidate('${ApiConfig.apiBaseUrl}/food-logs');
                            setState(() {
                              _foodLog.removeAt(index);
                            });
                          }
                        } catch (e) {
                          // Ignore for now
                        }
                      } else {
                        final deleted = await _deleteSupplementLog(_supplements[index]);
                        if (deleted && mounted) {
                          setState(() {
                            _supplements.removeAt(index);
                          });
                        }
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
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
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

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _updateSupplementAt(int index, Supplement next) async {
    final updated = await _updateSupplementLog(next);
    if (updated == null || !mounted) return;
    setState(() {
      _supplements[index] = updated;
    });
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
    return const Color(0xFF8B5CF6); // Default Purple
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
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)),
        ),
      ),
      errorWidget: (context, url, error) =>
          const Icon(Icons.medication_outlined, color: Color(0xFF8B5CF6), size: 22),
    );
  }
}
