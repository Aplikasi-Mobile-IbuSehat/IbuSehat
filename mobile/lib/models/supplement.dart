import 'package:flutter/material.dart';

class Supplement {
  final String id;
  final String name;
  final String description;
  final TimeOfDay? reminderTime;
  final bool isSystemRecommendation;

  Supplement({
    required this.id,
    required this.name,
    this.description = '',
    this.reminderTime,
    this.isSystemRecommendation = false,
  });

  Supplement copyWith({
    String? id,
    String? name,
    String? description,
    TimeOfDay? reminderTime,
    bool? isSystemRecommendation,
  }) {
    return Supplement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      isSystemRecommendation: isSystemRecommendation ?? this.isSystemRecommendation,
    );
  }
}
