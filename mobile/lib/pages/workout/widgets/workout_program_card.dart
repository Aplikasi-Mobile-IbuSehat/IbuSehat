import 'package:flutter/material.dart';
import 'package:mobile/models/workout_program_model.dart';
import 'package:mobile/pages/workout/program_detail_page.dart';
import 'package:mobile/theme/app_colors.dart';

class WorkoutProgramCard extends StatelessWidget {
  const WorkoutProgramCard({super.key, required this.program});

  final WorkoutProgramModel program;
  static const Color _purple = Color(0xFF7C3AED);

  Widget _fallbackPlaceholder(bool isDark) {
    return Container(
      width: 60,
      height: 60,
      color: isDark ? darkBorder : const Color(0xFFEDE9FE),
      alignment: Alignment.center,
      child: const Icon(Icons.fitness_center_rounded, color: _purple, size: 24),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    final url = program.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            color: isDark ? darkBorder : const Color(0xFFE5E7EB),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _purple,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/programs/${program.imageAsset}',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error2, stackTrace2) =>
                _fallbackPlaceholder(isDark),
          );
        },
      );
    }

    return Image.asset(
      'assets/images/programs/${program.imageAsset}',
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _fallbackPlaceholder(isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : const Color(0xFFF0F0F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProgramDetailPage(
                programId: program.id,
                programName: program.name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildThumbnail(isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${program.totalExercises} latihan',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
