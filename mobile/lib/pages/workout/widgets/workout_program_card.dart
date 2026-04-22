import 'package:flutter/material.dart';
import 'package:mobile/models/workout_program_model.dart';
import 'package:mobile/pages/workout/program_detail_page.dart';

class WorkoutProgramCard extends StatelessWidget {
  const WorkoutProgramCard({super.key, required this.program});

  final WorkoutProgramModel program;
  static const Color _purple = Color(0xFF7C3AED);

  Widget _fallbackPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: const Icon(Icons.fitness_center, color: _purple),
    );
  }

  Widget _buildThumbnail() {
    final url = program.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 70,
            height: 70,
            color: const Color(0xFFE5E7EB),
            alignment: Alignment.center,
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _purple.withValues(alpha: 0.7),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/programs/${program.imageAsset}',
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (context, error2, stackTrace2) =>
                _fallbackPlaceholder(),
          );
        },
      );
    }

    return Image.asset(
      'assets/images/programs/${program.imageAsset}',
      width: 70,
      height: 70,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallbackPlaceholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.8),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildThumbnail(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1235),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${program.totalExercises} latihan',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
