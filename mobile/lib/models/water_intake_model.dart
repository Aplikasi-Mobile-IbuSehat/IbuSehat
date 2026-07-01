class WaterIntakeModel {
  final int waterIntake;
  final int goalIntake;

  const WaterIntakeModel({
    required this.waterIntake,
    required this.goalIntake,
  });

  factory WaterIntakeModel.fromJson(Map<String, dynamic> json) {
    return WaterIntakeModel(
      waterIntake: int.parse(json['water_intake'].toString()),
      goalIntake: int.parse(json['goal_intake'].toString()),
    );
  }

  WaterIntakeModel copyWith({int? waterIntake, int? goalIntake}) {
    return WaterIntakeModel(
      waterIntake: waterIntake ?? this.waterIntake,
      goalIntake: goalIntake ?? this.goalIntake,
    );
  }
}