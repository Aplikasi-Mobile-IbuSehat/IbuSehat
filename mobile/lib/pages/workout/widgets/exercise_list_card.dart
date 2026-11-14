import 'package:flutter/material.dart';
import 'package:mobile/models/workout_program_model.dart';
import 'package:mobile/theme/app_colors.dart';

class ExerciseListCard extends StatelessWidget {
  const ExerciseListCard({
    super.key,
    required this.exercise,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onDetail,
  });

  final WorkoutExerciseModel exercise;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDetail;

  static const _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image area
          SizedBox(
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ExerciseImage(exercise: exercise),
                // Bottom gradient
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? const Color(0xFFE11D48) : Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Difficulty badge
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: _DifficultyBadge(difficulty: exercise.difficulty),
                ),
              ],
            ),
          ),

          // Content area
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 13, color: _purple),
                    const SizedBox(width: 4),
                    Text(
                      exercise.duration,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onDetail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseImage extends StatelessWidget {
  const _ExerciseImage({required this.exercise});

  final WorkoutExerciseModel exercise;
  static const _assetPrefix = 'assets/images/workouts/';

  @override
  Widget build(BuildContext context) {
    final assetName = exercise.imageAsset.trim();
    if (assetName.isNotEmpty) {
      return Image.asset(
        '$_assetPrefix$assetName',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackForName(assetName),
      );
    }
    return const _ImagePlaceholder();
  }

  Widget _fallbackForName(String assetName) {
    const fallbacks = {
      'wall_push_up.png': 'assets/images/programs/exercise_warmup.png',
      'bodyweight_squat.png': 'assets/images/programs/exercise_squat.png',
      'glute_bridge.png': 'assets/images/programs/exercise_cooldown.png',
    };
    final path = fallbacks[assetName];
    if (path != null) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _ImagePlaceholder(),
      );
    }
    return const _ImagePlaceholder();
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9B59B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.fitness_center_rounded, size: 52, color: Colors.white54),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final String difficulty;

  Color get _color {
    switch (difficulty) {
      case 'Pemula':
        return const Color(0xFF16A34A);
      case 'Menengah':
        return const Color(0xFF2563EB);
      case 'Berpengalaman':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            difficulty,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
