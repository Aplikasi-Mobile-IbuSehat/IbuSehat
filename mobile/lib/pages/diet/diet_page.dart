import 'package:flutter/material.dart';
import 'package:mobile/pages/diet/food_log_section.dart';
import 'package:mobile/pages/diet/supplement_list_section.dart';
import 'package:mobile/pages/diet/water_intake_section.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/widgets/app_header_actions.dart';
import 'package:mobile/widgets/modern_sliver_refresh.dart';

class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<DietFoodLogSectionState> _foodLogKey = GlobalKey();
  final GlobalKey<DietWaterIntakeSectionState> _waterIntakeKey = GlobalKey();
  final GlobalKey<DietSupplementListSectionState> _supplementKey = GlobalKey();
  bool _isScrolled = false;
  double _totalKcal = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }


  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshAllSections() async {
    await Future.wait([
      _foodLogKey.currentState?.refresh(forceRefresh: true) ?? Future.value(),
      _waterIntakeKey.currentState?.refresh(forceRefresh: true) ?? Future.value(),
      _supplementKey.currentState?.refresh(forceRefresh: true) ?? Future.value(),
    ]);
  }

  void _onScroll() {
    final bool isScrolled = _scrollController.offset > 5;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? darkTextPrimary : lightTextPrimary;

    return Scaffold(
      body: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 95.0,
              backgroundColor: _isScrolled
                  ? (isDark ? darkBackground : lightBackground)
                  : Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: _isScrolled ? 1 : 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                AppHeaderActions(titleColor: titleColor),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                centerTitle: false,
                title: Text(
                  'Diet & Nutrisi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            ModernSliverRefreshControl(onRefresh: _refreshAllSections),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Today's Summary (Calories)
                    _buildSummaryCard(_totalKcal),
                    const SizedBox(height: 28),

                    DietFoodLogSection(
                      key: _foodLogKey,
                      onTotalKcalChanged: (value) {
                        if (_totalKcal == value) return;
                        setState(() {
                          _totalKcal = value;
                        });
                      },
                    ),
                    const SizedBox(height: 28),

                    DietWaterIntakeSection(key: _waterIntakeKey),
                    const SizedBox(height: 28),

                    DietSupplementListSection(key: _supplementKey),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }


  Widget _buildSummaryCard(double totalKcal) {
    const double targetKcal = 2000;
    final double progress = (totalKcal / targetKcal).clamp(0.0, 1.0);
    final double remaining = (targetKcal - totalKcal).clamp(0, targetKcal);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.12),
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
                      color: Colors.white.withValues(alpha: 0.2),
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
              backgroundColor: Colors.white.withValues(alpha: 0.25),
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
                    color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                'Target ${targetKcal.toStringAsFixed(0)}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
