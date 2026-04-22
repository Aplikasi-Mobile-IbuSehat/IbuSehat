import 'package:flutter/material.dart';
import 'package:mobile/models/workout_program_model.dart';
import 'package:mobile/pages/workout/exercise_detail_page.dart';
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
  static const List<String> _difficulties = [
    'Pemula',
    'Menengah',
    'Berpengalaman',
  ];

  String _selectedDifficulty = 'Pemula';
  late Future<WorkoutProgramModel> _futureDetail;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.programName),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _difficulties.map((difficulty) {
                    final isSelected = difficulty == _selectedDifficulty;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(difficulty),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedDifficulty = difficulty;
                            _futureDetail = _fetchDetail();
                          });
                        },
                        selectedColor: const Color(0xFF7C3AED),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFFD1D5DB),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<WorkoutProgramModel>(
                future: _futureDetail,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Gagal memuat detail program.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF6B7280)),
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Text(
                          '${program.exercises.length} LATIHAN',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: program.exercises.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final exercise = program.exercises[index];
                            final isCompleted = index == 0;

                            return ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ExerciseDetailPage(exercise: exercise),
                                  ),
                                );
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/programs/${exercise.imageAsset}',
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 70,
                                                height: 70,
                                                color: const Color(0xFFE5E7EB),
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.fitness_center,
                                                  color: Color(0xFF7C3AED),
                                                ),
                                              ),
                                    ),
                                  ),
                                  if (isCompleted)
                                    const Positioned(
                                      top: 4,
                                      right: 4,
                                      child: CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Color(0xFF7C3AED),
                                        child: Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                exercise.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              subtitle: Text(
                                '${exercise.duration} • ${exercise.difficulty}',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              trailing: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.favorite_border,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
