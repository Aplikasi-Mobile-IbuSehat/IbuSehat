import 'package:flutter/material.dart';
import 'package:mobile/pages/workout/widgets/categories_section.dart';
import 'package:mobile/pages/workout/widgets/program_latihan_section.dart';
import 'package:mobile/pages/workout/widgets/recommended_section.dart';
import 'package:mobile/pages/workout/widgets/running_banner.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/widgets/app_header_actions.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  String _selectedCategory = 'Semua';
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
                  'Workout',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const RunningBanner(),
                    const SizedBox(height: 28),
                    CategoriesSection(
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    RecommendedSection(selectedCategory: _selectedCategory),
                    // Sama ritme vertikal dengan jarak banner → Rekomendasi (28)
                    const SizedBox(height: 28),
                    const ProgramLatihanSection(),
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
