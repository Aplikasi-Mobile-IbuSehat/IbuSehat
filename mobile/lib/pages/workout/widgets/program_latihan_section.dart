import 'package:flutter/material.dart';
import 'package:mobile/models/workout_program_model.dart';
import 'package:mobile/pages/workout/widgets/workout_program_card.dart';
import 'package:mobile/services/workout_program_service.dart';

class ProgramLatihanSection extends StatefulWidget {
  const ProgramLatihanSection({super.key});

  @override
  State<ProgramLatihanSection> createState() => _ProgramLatihanSectionState();
}

class _ProgramLatihanSectionState extends State<ProgramLatihanSection> {
  late Future<List<WorkoutProgramModel>> _futurePrograms;

  void _loadPrograms() {
    setState(() {
      _futurePrograms = WorkoutProgramService.fetchPrograms();
    });
  }

  @override
  void initState() {
    super.initState();
    _futurePrograms = WorkoutProgramService.fetchPrograms();
  }

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1F1235),
    letterSpacing: -0.3,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Program Latihan', style: _titleStyle),
        const SizedBox(height: 8),
        FutureBuilder<List<WorkoutProgramModel>>(
          future: _futurePrograms,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              debugPrint('ProgramLatihanSection: error=${snapshot.error}');
              return _buildErrorState(snapshot.error);
            }

            final programs = snapshot.data ?? [];
            debugPrint(
              'ProgramLatihanSection: received ${programs.length} programs',
            );
            if (programs.isNotEmpty) {
              debugPrint(
                'ProgramLatihanSection: first=${programs.first.name} '
                'id=${programs.first.id} total=${programs.first.totalExercises}',
              );
            }

            if (programs.isEmpty) {
              return Text(
                'Belum ada program',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              );
            }

            return ListView.builder(
              itemCount: programs.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) =>
                  WorkoutProgramCard(program: programs[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorState(Object? error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gagal memuat program latihan.\n$error',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _loadPrograms,
              icon: const Icon(Icons.refresh, color: Color(0xFF7C3AED)),
              label: const Text(
                'Coba lagi',
                style: TextStyle(
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      itemCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 160,
                      color: const Color(0xFFE5E7EB),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 90,
                      color: const Color(0xFFF3F4F6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
