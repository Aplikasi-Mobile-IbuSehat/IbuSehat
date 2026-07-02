import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/models/water_intake_model.dart';
import 'package:mobile/pages/diet/water_intake_page.dart';
import 'package:mobile/providers/progress_provider.dart';
import 'package:mobile/services/water_intake_service.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DietWaterIntakeSection extends StatefulWidget {
  const DietWaterIntakeSection({super.key});

  @override
  State<DietWaterIntakeSection> createState() => DietWaterIntakeSectionState();
}

class DietWaterIntakeSectionState extends State<DietWaterIntakeSection> {
  final _service = WaterIntakeService.instance;

  WaterIntakeModel? _data;
  bool _isLoading = true;
  String? _error;
  bool _retryScheduled = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _retryScheduled = false;
    super.dispose();
  }

  Future<void> refresh({bool forceRefresh = false}) =>
      _fetchData(forceRefresh: forceRefresh);

  void _scheduleAutoRetry() {
    if (_retryScheduled || !mounted) return;
    _retryScheduled = true;
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || _error == null) return;
      _retryScheduled = false;
      _fetchData(forceRefresh: true);
    });
  }

  Future<void> _fetchData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = _data == null;
      _error = null;
      _retryScheduled = false;
    });
    try {
      final data = await _service.getWaterIntake(forceRefresh: forceRefresh);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
      _scheduleAutoRetry();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? darkTextPrimary : lightTextPrimary;
    final surfaceColor = isDark ? darkSurface : lightSurface;
    final borderColor = isDark ? darkBorder : lightBorder;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asupan Air',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: titleColor,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 20),
        if (_isLoading)
          _buildSkeleton(
            isDark: isDark,
            cardColor: surfaceColor,
            border: borderColor,
          )
        else if (_error != null)
          _buildError()
        else
          _buildCard(
            context,
            isDark: isDark,
            titleColor: titleColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textSecondary: textSecondary,
          ),
      ],
    );
  }

  Widget _buildSkeleton({
    required bool isDark,
    required Color cardColor,
    required Color border,
  }) {
    final shimmerBase =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);
    final shimmerHighlight =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFFFFFFF);
    final blockColor =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: shimmerBase,
        highlightColor: shimmerHighlight,
        duration: const Duration(milliseconds: 1200),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: blockColor,
                borderRadius: BorderRadius.circular(16),
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
                      Container(
                        height: 18,
                        width: 80,
                        decoration: BoxDecoration(
                          color: blockColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Container(
                        height: 13,
                        width: 60,
                        decoration: BoxDecoration(
                          color: blockColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: blockColor,
                      borderRadius: BorderRadius.circular(10),
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
                color: blockColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            'Gagal memuat asupan air',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          TextButton(
            onPressed: () => refresh(forceRefresh: true),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required bool isDark,
    required Color titleColor,
    required Color surfaceColor,
    required Color borderColor,
    required Color textSecondary,
  }) {
    final currentIntake = _data!.waterIntake;
    final goalIntake = _data!.goalIntake;
    final progress = (currentIntake / goalIntake).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () async {
        final progressProvider = context.read<ProgressProvider>();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WaterIntakePage(
              currentIntake: currentIntake,
              goalIntake: goalIntake,
              onAddWater: (amount) {
                if (mounted) {
                  setState(() {
                    _data = _data!.copyWith(
                      waterIntake: _data!.waterIntake + amount,
                    );
                  });
                }
              },
            ),
          ),
        );

        await _fetchData();
        if (mounted) progressProvider.fetchSummary(forceRefresh: true);
        
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? darkBorder : lightBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SvgPicture.asset(
                'assets/icons/water_glass.svg',
                height: 28,
                colorFilter: ColorFilter.mode(titleColor, BlendMode.srcIn),
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
                        '$currentIntake ml',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: titleColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '/ $goalIntake ml',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark ? darkBorder : lightBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFA855F7)),
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
                color: isDark ? darkBorder : lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chevron_right_rounded,
                  color: titleColor, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}