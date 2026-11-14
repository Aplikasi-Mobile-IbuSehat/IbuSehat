import 'package:flutter/material.dart';
import 'package:mobile/models/workout_program_model.dart';
import 'package:mobile/pages/workout/active_workout_page.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/utils/video_pool.dart';

class WorkoutPreviewPage extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? imageAsset;
  final String duration;
  final String difficulty;
  final String target;
  final String equipment;
  final List<String> instructions;
  final List<ExerciseData> exerciseDetails;
  final int? workoutId;

  static const _purple = Color(0xFF7C3AED);

  WorkoutPreviewPage({
    super.key,
    required this.title,
    this.imageUrl,
    this.imageAsset,
    required this.duration,
    required this.difficulty,
    required this.target,
    required this.equipment,
    required this.instructions,
    required this.exerciseDetails,
    this.workoutId,
  });

  factory WorkoutPreviewPage.fromExercise(WorkoutExerciseModel exercise) {
    final instructions = exercise.instructions.isNotEmpty
        ? exercise.instructions
        : [
            if (exercise.description != null &&
                exercise.description!.trim().isNotEmpty)
              exercise.description!.trim()
            else
              'Ikuti gerakan dengan tempo terkontrol dan napas teratur.',
          ];

    final assetPath = exercise.imageAsset.trim().isNotEmpty
        ? 'assets/images/workouts/${exercise.imageAsset}'
        : null;

    final description = exercise.description?.trim().isNotEmpty == true
        ? exercise.description!.trim()
        : 'Latihan ${exercise.name} untuk memperkuat ${exercise.targetMuscle ?? 'tubuh'}.';

    return WorkoutPreviewPage(
      title: exercise.name,
      imageAsset: assetPath,
      imageUrl: exercise.imageUrl,
      duration: exercise.duration,
      difficulty: exercise.difficulty,
      target: exercise.targetMuscle ?? 'Full Body',
      equipment: exercise.equipment ?? 'None / Mat (opsional)',
      instructions: instructions,
      exerciseDetails: [
        ExerciseData(
          title: exercise.name,
          description: description,
          tips: instructions,
          categories: [
            if (exercise.targetMuscle != null) exercise.targetMuscle!,
            exercise.difficulty,
          ],
        ),
      ],
      workoutId: exercise.id, // Pass workout ID
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final bg = isDark ? darkBackground : lightBackground;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final cardBorder = isDark ? darkBorder : Colors.transparent;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: _buildHeaderImage(),
          ),
          // Gradient over image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    bg.withValues(alpha: 0.85),
                    bg,
                  ],
                  stops: const [0.0, 0.4, 0.88, 1.0],
                ),
              ),
            ),
          ),

          // Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.26),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorder),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.07),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Stats row
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoItem(
                                  Icons.schedule_rounded,
                                  'Durasi',
                                  duration,
                                  textPrimary,
                                  textSecondary,
                                ),
                                _buildDivider(isDark),
                                _buildInfoItem(
                                  Icons.show_chart_rounded,
                                  'Tingkat',
                                  difficulty,
                                  textPrimary,
                                  textSecondary,
                                ),
                                _buildDivider(isDark),
                                _buildInfoItem(
                                  Icons.track_changes_rounded,
                                  'Target',
                                  target,
                                  textPrimary,
                                  textSecondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Equipment row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? darkBorder
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.fitness_center_rounded,
                                    color: textSecondary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Peralatan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        equipment,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Instructions
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Panduan Latihan',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      ...List.generate(instructions.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: _purple,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    instructions[index],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Back button (Floating, clean)
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          // Bottom Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: cardBorder)),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: () async {
                    if (workoutId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ID latihan tidak ditemukan, coba muat ulang halaman.')),
                      );
                      return;
                    }

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActiveWorkoutPage(
                          playlist: VideoPool.getVideos(2),
                          exerciseDetails: exerciseDetails,
                          workoutId: workoutId,
                        ),
                      ),
                    );
                    
                    // After workout completes, pop back to previous screen with result
                    if (result == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mulai Latihan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? darkBorder : const Color(0xFFE5E7EB),
    );
  }

  Widget _buildHeaderImage() {
    final asset = imageAsset;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildNetworkOrPlaceholder(),
      );
    }
    return _buildNetworkOrPlaceholder();
  }

  Widget _buildNetworkOrPlaceholder() {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9B59B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.fitness_center_rounded, size: 72, color: Colors.white54),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      children: [
        Icon(icon, color: _purple, size: 22),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
