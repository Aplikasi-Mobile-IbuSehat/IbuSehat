import 'package:flutter/material.dart';

class Supplement {
  final String id;
  final String name;
  final String description;
  final TimeOfDay? reminderTime;
  final bool isSystemRecommendation;
  final bool isTaken;

  Supplement({
    required this.id,
    required this.name,
    this.description = '',
    this.reminderTime,
    this.isSystemRecommendation = false,
    this.isTaken = false,
  });

  Supplement copyWith({
    String? id,
    String? name,
    String? description,
    TimeOfDay? reminderTime,
    bool? isSystemRecommendation,
    bool? isTaken,
  }) {
    return Supplement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      isSystemRecommendation: isSystemRecommendation ?? this.isSystemRecommendation,
      isTaken: isTaken ?? this.isTaken,
    );
  }
}
