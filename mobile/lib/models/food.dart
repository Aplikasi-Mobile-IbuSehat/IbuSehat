import 'package:flutter/material.dart';

class Food {
  final String id;
  final String name;
  final double weight; // in grams
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final IconData? icon;
  final Color? color;

  Food({
    required this.id,
    required this.name,
    required this.weight,
    required this.kcal,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.icon,
    this.color,
  });
}
