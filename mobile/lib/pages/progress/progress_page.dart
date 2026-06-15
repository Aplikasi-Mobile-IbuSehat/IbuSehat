import 'package:flutter/material.dart';
import 'package:mobile/pages/progress/widgets/langkah_card.dart';
import 'package:mobile/pages/progress/widgets/score_tidur_card.dart';
import 'package:mobile/pages/progress/widgets/berat_card.dart';
import 'package:mobile/pages/progress/widgets/waktu_latihan_card.dart';
import 'package:mobile/pages/progress/widgets/kalori_makanan_card.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/widgets/app_header_actions.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? darkTextPrimary : lightTextPrimary;
    return Scaffold(
      body: AppBackground(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
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
                  'Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
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
                      children: const [
                        Expanded(child: LangkahCard()),
                        SizedBox(width: 16),
                        Expanded(child: ScoreTidurCard()),
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
