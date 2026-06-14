import 'package:flutter/material.dart';
import 'package:mobile/pages/progress/widgets/langkah_card.dart';
import 'package:mobile/pages/progress/widgets/score_tidur_card.dart';
import 'package:mobile/pages/progress/widgets/berat_card.dart';
import 'package:mobile/pages/progress/widgets/waktu_latihan_card.dart';
import 'package:mobile/pages/progress/widgets/kalori_makanan_card.dart';
import 'package:mobile/widgets/app_background.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/pages/profile/premium_page.dart';
import 'package:mobile/pages/chat/ai_chat_page.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(ProgressPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      setState(() {});
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
              backgroundColor: _isScrolled
                  ? const Color(0xFFF8F9FB)
                  : Colors.transparent,
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
                            MaterialPageRoute(
                              builder: (context) => const PremiumPage(),
                            ),
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
                            MaterialPageRoute(
                              builder: (context) => const AiChatPage(),
                            ),
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
                  'Progress',
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: LangkahCard(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ScoreTidurCard(
                            key: ValueKey(widget.refreshToken),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const BeratCard(),
                    const SizedBox(height: 16),
                    const WaktuLatihanCard(),
                    const SizedBox(height: 16),
                    const KaloriMakananCard(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
