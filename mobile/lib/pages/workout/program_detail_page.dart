import 'package:flutter/material.dart';
import 'package:mobile/models/workout_program_model.dart';
import 'package:mobile/pages/workout/workout_preview_page.dart';
import 'package:mobile/pages/workout/widgets/exercise_list_card.dart';
import 'package:mobile/services/workout_program_service.dart';

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
  static const _bgColor = Color(0xFFF8F8FF);

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
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F0F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF1A1A2E),
              size: 20,
            ),
          ),
        ),
        title: Text(
          widget.programName,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _difficulties.map((difficulty) {
                        final isSelected = difficulty == _selectedDifficulty;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(difficulty),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedDifficulty = difficulty;
                                _futureDetail = _fetchDetail();
                              });
                            },
                            selectedColor: _purple,
                            backgroundColor: const Color(0xFFF3F4F6),
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? _purple
                                  : const Color(0xFFE5E7EB),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF374151),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
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
                            const Icon(
                              Icons.cloud_off_outlined,
                              size: 48,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Gagal memuat latihan.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
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
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final program = snapshot.data;
                  if (program == null || program.exercises.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada latihan untuk tingkat ini.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: _purple,
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
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
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
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
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
                                onDetail: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          WorkoutPreviewPage.fromExercise(
                                        exercise,
                                      ),
                                    ),
                                  );
                                  // Refresh data if workout was completed
                                  if (result == true && mounted) {
                                    // Optionally refresh the program details
                                    setState(() {});
                                  }
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
