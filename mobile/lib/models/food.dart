import 'package:flutter/material.dart';

class Food {
  final String id;
  final String name;
  final double weight; // in grams (default 100g per serving)
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final String? category;
  final String? imageUrl;
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
    this.category,
    this.imageUrl,
    this.icon,
    this.color,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'].toString(),
      name: json['nama_makanan'] as String,
      weight: 100.0, // default serving size per 100g
      kcal: double.tryParse(json['kalori_kkal'].toString()) ?? 0,
      protein: double.tryParse(json['protein_g'].toString()) ?? 0,
      carbs: double.tryParse(json['karbo_g'].toString()) ?? 0,
      fat: double.tryParse(json['lemak_g'].toString()) ?? 0,
      category: json['kategori'] as String?,
      imageUrl: json['gambar']?.toString(),
    );
  }

  factory Food.fromLogJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'].toString(),
      name: json['nama_makanan'] as String,
      weight: double.tryParse(json['weight'].toString()) ?? 0,
      kcal: double.tryParse(json['kcal'].toString()) ?? 0,
      protein: double.tryParse(json['protein'].toString()) ?? 0,
      carbs: double.tryParse(json['carbs'].toString()) ?? 0,
      fat: double.tryParse(json['fat'].toString()) ?? 0,
      category: json['category'] as String?,
      imageUrl: json['gambar']?.toString(),
    );
  }
}
