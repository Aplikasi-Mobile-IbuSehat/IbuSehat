import 'package:flutter/material.dart';
import 'package:mobile/pages/workout/widgets/categories_section.dart';
import 'package:mobile/pages/workout/widgets/recommended_section.dart';
import 'package:mobile/pages/workout/widgets/running_banner.dart';
import 'package:mobile/pages/workout/active_workout_page.dart';
import 'package:mobile/widgets/app_background.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  String _selectedCategory = 'Semua';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Workout',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1235),
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
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
                const SizedBox(height: 28),
                RecommendedSection(selectedCategory: _selectedCategory),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
