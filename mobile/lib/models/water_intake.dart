class WaterIntakeModel {
  final int waterIntake;
  final int goalIntake;

  const WaterIntakeModel({
    required this.waterIntake,
    required this.goalIntake,
  });

  factory WaterIntakeModel.fromJson(Map<String, dynamic> json) {
    return WaterIntakeModel(
      waterIntake: (json['water_intake'] as num).toInt(),
      goalIntake: (json['goal_intake'] as num).toInt(),
    );
  }

  WaterIntakeModel copyWith({int? waterIntake, int? goalIntake}) {
    return WaterIntakeModel(
      waterIntake: waterIntake ?? this.waterIntake,
      goalIntake: goalIntake ?? this.goalIntake,
    );
  }
}