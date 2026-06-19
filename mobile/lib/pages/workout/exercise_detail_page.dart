import 'package:flutter/material.dart';
import 'package:mobile/models/workout_program_model.dart';

class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({super.key, required this.exercise});

  final WorkoutExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: const Center(
        child: Text(
          'Halaman detail latihan akan segera hadir.',
          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}
