enum DeliveryMethod { normal, sesar }

enum ActivityLevel { sedentary, light, moderate, veryActive }

enum Goal { loseWeight, maintainWeight, gainWeight, improvePhysicalHealth, rebuildBodyShape }

class UserProfile {
  final int age;
  final double weight;
  final double targetWeight;
  final double height;
  final ActivityLevel activityLevel;
  final DeliveryMethod deliveryMethod;
  final DateTime deliveryDate;
  final Goal goal;

  UserProfile({
    required this.age,
    required this.weight,
    required this.targetWeight,
    required this.height,
    required this.activityLevel,
    required this.deliveryMethod,
    required this.deliveryDate,
    required this.goal,
  });
}
