import 'package:flutter/material.dart';
import 'package:mobile/pages/diet/diet_page.dart';
import 'package:mobile/pages/progress/progress_page.dart';
import 'package:mobile/pages/workout/workout_page.dart';
import 'package:mobile/widgets/app_background.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/pages/profile/premium_page.dart';
import 'package:mobile/pages/chat/ai_chat_page.dart';
import 'sleep_fab.dart';

class BerandaPage extends StatefulWidget {
  final Function(int)? onTabSelected;

  const BerandaPage({super.key, this.onTabSelected});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

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

  void _onScroll() {
    final bool isScrolled = _scrollController.offset > 20;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                              width: 24,
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
              centerTitle: true,
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isScrolled ? 1.0 : 0.0,
                child: _buildLogo(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                centerTitle: false,
                title: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isScrolled ? 0.0 : 1.0,
                  child: const Text(
                    'IbuSehat',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F1235),
                      fontSize: 22,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeeklyActivityCard(),
                    const SizedBox(height: 16),
                    _buildProgressTodaySection(),
                    const SizedBox(height: 16),
                    _buildQuickActionsSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          ).createShader(bounds),
          child: const Text(
            'IbuSehat',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyActivityCard() {
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivitas 7 Hari Terakhir',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(days.length, (index) {
              final bool isActive = index != 2; // contoh: hari Rabu kosong
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isActive ? 0.18 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.50),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: isActive
                          ? const Color.fromARGB(255, 233, 112, 46)
                          : const Color(0xFF9CA3AF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress Hari Ini',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4B164C),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildProgressCard(
              title: 'Olahraga',
              subtitle: '20 mnt',
              valueLabel: '20 mnt',
              maxLabel: '50 mnt',
              progressColor: const Color(0xFFFB7185),
              progress: 0.4,
            ),
            _buildProgressCard(
              title: 'Air Putih',
              subtitle: '6 gelas',
              valueLabel: '6 gelas',
              maxLabel: '8 gelas',
              progressColor: const Color(0xFF3B82F6),
              progress: 0.75,
            ),
            _buildProgressCard(
              title: 'Nutrisi',
              subtitle: '67%',
              valueLabel: '1200 kkal',
              maxLabel: '1800 kkal',
              progressColor: const Color(0xFFA855F7),
              progress: 0.67,
            ),
            _buildProgressCard(
              title: 'Skincare',
              subtitle: '50%',
              valueLabel: '1x',
              maxLabel: '2x',
              progressColor: const Color(0xFFF59E0B),
              progress: 0.5,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String subtitle,
    required String valueLabel,
    required String maxLabel,
    required Color progressColor,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B164C),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF9CA3AF),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                valueLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B164C),
                ),
              ),
              Text(
                maxLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildQuickActionCard(
          context: context,
          title: 'Diet',
          subtitle: 'Atur pola makan',
          icon: Icons.restaurant_menu_rounded,
          iconColor: const Color(0xFF22C55E),
        ),
        _buildQuickActionCard(
          context: context,
          title: 'Progress',
          subtitle: 'Lihat perkembangan',
          icon: Icons.show_chart_rounded,
          iconColor: const Color(0xFF6366F1),
        ),
        _buildQuickActionCard(
          context: context,
          title: 'Workout',
          subtitle: 'Olahraga harian',
          icon: Icons.fitness_center_rounded,
          iconColor: const Color(0xFFF97316),
        ),
        _buildQuickActionCard(
          context: context,
          title: 'Skincare',
          subtitle: 'Perawatan kulit',
          icon: Icons.spa_rounded,
          iconColor: const Color(0xFFEC4899),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    void handleTap() {
      if (widget.onTabSelected != null) {
        if (title == 'Diet') {
          widget.onTabSelected!(2);
        } else if (title == 'Progress' || title == 'Skincare') {
          widget.onTabSelected!(1);
        } else if (title == 'Workout') {
          widget.onTabSelected!(3);
        }
      } else {
        if (title == 'Diet') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DietPage()),
          );
        } else if (title == 'Progress') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProgressPage()),
          );
        } else if (title == 'Workout') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkoutPage()),
          );
        } else if (title == 'Skincare') {
          // Belum ada halaman skincare spesifik, arahkan ke Progress dulu
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProgressPage()),
          );
        }
      }
    }

    return GestureDetector(
      onTap: handleTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1235),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
