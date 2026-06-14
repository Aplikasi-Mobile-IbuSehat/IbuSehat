import 'package:flutter/material.dart';
import 'package:mobile/models/workout_program_model.dart';
import 'package:mobile/pages/workout/active_workout_page.dart';

class WorkoutPreviewPage extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? imageAsset;
  final String duration;
  final String difficulty;
  final String target;
  final String equipment;
  final List<String> instructions;
  final List<String> playlist;
  final List<ExerciseData> exerciseDetails;

  static const _defaultPlaylist = [
    'assets/videos/vid_1.mp4',
    'assets/videos/vid_3.mp4',
    'assets/videos/vid_4.mp4',
  ];

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
    required this.playlist,
    required this.exerciseDetails,
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
      playlist: _defaultPlaylist,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: _buildHeaderImage(),
          ),
          // Gradient over image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.white.withOpacity(0.8),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.4, 0.9, 1.0],
                ),
              ),
            ),
          ),
          

          // Content
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // White Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F1235),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoItem(Icons.schedule, "Duration", duration),
                                _buildInfoItem(Icons.show_chart, "Difficulty", difficulty),
                                _buildInfoItem(Icons.track_changes, "Target", target),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.fitness_center, color: Colors.grey.shade700, size: 20),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Equipment",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        equipment,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F1235),
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
                      
                      const SizedBox(height: 32),
                      
                      // Instructions Title
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Instructions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F1235),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Instructions List
                      ...List.generate(instructions.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8B5CF6),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "${index + 1}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    instructions[index],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 160), // padding for bottom button

                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF8B5CF6)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // Bottom Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActiveWorkoutPage(
                          playlist: playlist,
                          exerciseDetails: exerciseDetails,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Start Workout",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildHeaderImage() {
    final asset = imageAsset;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildNetworkOrPlaceholder(),
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
        child: Icon(Icons.fitness_center, size: 72, color: Colors.white70),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF8B5CF6).withOpacity(0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F1235),
          ),
        ),
      ],
    );
  }
}
