import 'package:flutter/material.dart';
import 'package:mobile/models/workout_program_model.dart';
import 'package:mobile/pages/workout/workout_preview_page.dart';
import 'package:mobile/pages/workout/widgets/exercise_list_card.dart';
import 'package:mobile/services/workout_program_service.dart';
import 'package:mobile/theme/app_colors.dart';

class ProgramDetailPage extends StatefulWidget {
  const ProgramDetailPage({
    super.key,
    required this.programId,
    required this.programName,
  });

  final int programId;
  final String programName;

  @override
  State<ProgramDetailPage> createState() => _ProgramDetailPageState();
}

class _ProgramDetailPageState extends State<ProgramDetailPage> {
  static const _purple = Color(0xFF7C3AED);

  static const List<String> _difficulties = [
    'Pemula',
    'Menengah',
    'Berpengalaman',
  ];

  String _selectedDifficulty = 'Pemula';
  late Future<WorkoutProgramModel> _futureDetail;
  final Set<int> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _futureDetail = _fetchDetail();
  }

  Future<WorkoutProgramModel> _fetchDetail() {
    return WorkoutProgramService.fetchProgramDetail(
      widget.programId,
      difficulty: _selectedDifficulty,
    );
  }

  void _toggleFavorite(int exerciseId) {
    setState(() {
      if (_favoriteIds.contains(exerciseId)) {
        _favoriteIds.remove(exerciseId);
      } else {
        _favoriteIds.add(exerciseId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? darkBackground : lightBackground;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: textPrimary,
          ),
        ),
        title: Text(
          widget.programName,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Difficulty segmented control (floating, menyatu)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? darkSurface : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: _difficulties.map((difficulty) {
                    final isSelected = difficulty == _selectedDifficulty;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDifficulty = difficulty;
                            _futureDetail = _fetchDetail();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? _purple : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _purple.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              difficulty,
                              style: TextStyle(
                                color: isSelected ? Colors.white : textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            Divider(height: 1, color: border),

            // Body
            Expanded(
              child: FutureBuilder<WorkoutProgramModel>(
                future: _futureDetail,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _purple),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off_outlined,
                              size: 48,
                              color: textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Gagal memuat latihan.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _futureDetail = _fetchDetail();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: border),
                                foregroundColor: textPrimary,
                              ),
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final program = snapshot.data;
                  if (program == null || program.exercises.isEmpty) {
                    return Center(
                      child: Text(
                        'Belum ada latihan untuk tingkat ini.',
                        style: TextStyle(color: textSecondary),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: _purple,
                    backgroundColor: surface,
                    onRefresh: () async {
                      setState(() {
                        _futureDetail = _fetchDetail();
                      });
                      await _futureDetail;
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _purple.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${program.exercises.length} LATIHAN',
                                    style: const TextStyle(
                                      color: _purple,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDifficulty,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          sliver: SliverList.separated(
                            itemCount: program.exercises.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final exercise = program.exercises[index];
                              return ExerciseListCard(
                                exercise: exercise,
                                isFavorite: _favoriteIds.contains(
                                  exercise.id,
                                ),
                                onFavoriteToggle: () =>
                                    _toggleFavorite(exercise.id),
                                onDetail: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          WorkoutPreviewPage.fromExercise(
                                        exercise,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
