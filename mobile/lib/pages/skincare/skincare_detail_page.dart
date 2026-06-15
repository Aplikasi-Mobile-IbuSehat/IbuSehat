import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';

class SkincareDetailPage extends StatefulWidget {
  final String title;
  final String overview;
  final List<ItemDetail> recommendations;
  final List<String> avoid;
  final String tips;
  final Color themeColor;
  final String imagePath;

  const SkincareDetailPage({
    super.key,
    required this.title,
    required this.overview,
    required this.recommendations,
    required this.avoid,
    required this.tips,
    required this.themeColor,
    required this.imagePath,
  });

  @override
  State<SkincareDetailPage> createState() => _SkincareDetailPageState();
}

class _SkincareDetailPageState extends State<SkincareDetailPage> {
  late ScrollController _scrollController;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.offset > 200 && !_isCollapsed) {
          setState(() => _isCollapsed = true);
        } else if (_scrollController.offset <= 200 && _isCollapsed) {
          setState(() => _isCollapsed = false);
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? darkBackground : const Color(0xFFF8F9FE);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewSection(isDark),
                  const SizedBox(height: 32),
                  _buildRecommendationSection(isDark),
                  const SizedBox(height: 32),
                  _buildAvoidSection(isDark),
                  const SizedBox(height: 32),
                  _buildExpertTipsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    final surface = isDark ? darkSurface : Colors.white;
    final textPrimary = isDark ? darkTextPrimary : const Color(0xFF1F1235);

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: surface,
      surfaceTintColor: surface,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded, 
          color: _isCollapsed ? textPrimary : Colors.white, 
          size: 20
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isCollapsed ? 1 : 0,
        child: Text(
          widget.title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Header Image
            Image.asset(
              widget.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: widget.themeColor,
                child: Center(
                  child: Icon(Icons.image_not_supported_rounded, color: Colors.white.withOpacity(0.5), size: 64),
                ),
              ),
            ),
            // Fade overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isCollapsed ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERAWATAN KULIT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(bool isDark) {
    final surface = isDark ? darkSurface : Colors.white;
    final textPrimary = isDark ? darkTextPrimary : const Color(0xFF1F1235);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Tentang Kondisi Ini', widget.themeColor),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: widget.themeColor.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            widget.overview,
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: textPrimary.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Langkah Perawatan', const Color(0xFF10B981)),
        const SizedBox(height: 16),
        ...widget.recommendations.map((item) => _buildRecommendCard(item, isDark)),
      ],
    );
  }

  Widget _buildRecommendCard(ItemDetail item, bool isDark) {
    final surface = isDark ? darkSurface : Colors.white;
    final textPrimary = isDark ? darkTextPrimary : const Color(0xFF1F1235);
    final textSecondary = isDark ? darkTextSecondary : const Color(0xFF1F1235).withOpacity(0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_outline_rounded, 
              color: Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.desc,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvoidSection(bool isDark) {
    final boxColor = isDark ? const Color(0xFF3F1616) : const Color(0xFFFEF2F2);
    final textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Yang Harus Dihindari', const Color(0xFFEF4444)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.1)),
          ),
          child: Column(
            children: widget.avoid.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExpertTipsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tips Ahli untuk Ibu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.tips,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class ItemDetail {
  final String title;
  final String desc;
  const ItemDetail({required this.title, required this.desc});
}
