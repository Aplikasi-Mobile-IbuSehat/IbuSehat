class WorkoutProgramModel {
  WorkoutProgramModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageAsset,
    this.imageUrl,
    required this.totalExercises,
    required this.category,
    this.exercises = const [],
  });

  final int id;
  final String name;
  final String? description;

  /// Filename under Flutter assets, e.g. `kalistenik.png`
  final String imageAsset;

  /// Full URL from API when server provides `image_url`
  final String? imageUrl;
  final int totalExercises;
  final String category;
  final List<WorkoutExerciseModel> exercises;

  static int _parseTotalExercises(Map<String, dynamic> json) {
    final te = json['total_exercises'];
    final ec = json['exercises_count'];

    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    final totalFromField = asInt(te);
    if (totalFromField > 0) {
      return totalFromField;
    }
    return asInt(ec);
  }

  static String? _parseImageUrl(dynamic v) {
    if (v == null) return null;
    if (v is String && v.isNotEmpty) return v;
    return null;
  }

  factory WorkoutProgramModel.fromJson(Map<String, dynamic> json) {
    final exercisesRaw = json['exercises'] as List<dynamic>? ?? [];
    return WorkoutProgramModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '-',
      description: json['description'] as String?,
      imageAsset: (json['image_asset'] as String?) ?? '',
      imageUrl: _parseImageUrl(json['image_url']),
      totalExercises: _parseTotalExercises(json),
      category: (json['category'] as String?) ?? '-',
      exercises: exercisesRaw
          .map((e) => WorkoutExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkoutExerciseModel {
  WorkoutExerciseModel({
    required this.id,
    required this.name,
    required this.duration,
    required this.difficulty,
    required this.imageAsset,
    this.imageUrl,
    required this.description,
    required this.instructions,
    required this.equipment,
    required this.targetMuscle,
    required this.videoAsset,
    required this.order,
  });

  final int id;
  final String name;
  final String duration;
  final String difficulty;
  final String imageAsset;
  final String? imageUrl;
  final String? description;
  final List<String> instructions;
  final String? equipment;
  final String? targetMuscle;
  final String? videoAsset;
  final int order;

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) {
    final instructionRaw = json['instructions'] as List<dynamic>? ?? [];
    final url = json['image_url'];
    return WorkoutExerciseModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '-',
      duration: (json['duration'] as String?) ?? '-',
      difficulty: (json['difficulty'] as String?) ?? '-',
      imageAsset: (json['image_asset'] as String?) ?? '',
      imageUrl: url is String && url.isNotEmpty ? url : null,
      description: json['description'] as String?,
      instructions: instructionRaw.map((e) => e.toString()).toList(),
      equipment: json['equipment'] as String?,
      targetMuscle: json['target_muscle'] as String?,
      videoAsset: json['video_asset'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}
