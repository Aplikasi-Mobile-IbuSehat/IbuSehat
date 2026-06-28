import 'package:flutter/material.dart';

class Supplement {
  final String? logId;
  final String id;
  final String name;
  final String description;
  final TimeOfDay? reminderTime;
  final bool isSystemRecommendation;
  final bool isTaken;

  // New Fields
  final String composition;
  final String dosageForm;
  final String packaging;
  final String rules;
  final String source;
  final String? imageUrl;

  Supplement({
    this.logId,
    required this.id,
    required this.name,
    this.description = '',
    this.reminderTime,
    this.isSystemRecommendation = false,
    this.isTaken = false,
    this.composition = '',
    this.dosageForm = '',
    this.packaging = '',
    this.rules = 'Gunakan sesuai anjuran dokter atau petunjuk pada kemasan',
    this.source = '',
    this.imageUrl,
  });

  Supplement copyWith({
    String? logId,
    String? id,
    String? name,
    String? description,
    TimeOfDay? reminderTime,
    bool? isSystemRecommendation,
    bool? isTaken,
    String? composition,
    String? dosageForm,
    String? packaging,
    String? rules,
    String? source,
    String? imageUrl,
  }) {
    return Supplement(
      logId: logId ?? this.logId,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      isSystemRecommendation: isSystemRecommendation ?? this.isSystemRecommendation,
      isTaken: isTaken ?? this.isTaken,
      composition: composition ?? this.composition,
      dosageForm: dosageForm ?? this.dosageForm,
      packaging: packaging ?? this.packaging,
      rules: rules ?? this.rules,
      source: source ?? this.source,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Supplement.fromJson(
    Map<String, dynamic> json, {
    String? baseUrl,
  }) {
    final rawImage = (json['gambar'] ?? json['image_url'] ?? '').toString().trim();
    final resolvedImage = _resolveImageUrl(rawImage, baseUrl);

    return Supplement(
      id: (json['id'] ?? '').toString(),
      name: (json['nama_suplemen'] ?? json['name'] ?? '').toString(),
      description: (json['deskripsi'] ?? '').toString(),
      composition: (json['komposisi'] ?? '').toString(),
      dosageForm: (json['bentuk_sediaan'] ?? '').toString(),
      packaging: (json['kemasan'] ?? '').toString(),
      rules: (json['aturan_pakai'] ?? '').toString(),
      source: (json['sumber'] ?? '').toString(),
      imageUrl: resolvedImage,
    );
  }

  factory Supplement.fromLogJson(
    Map<String, dynamic> json, {
    String? baseUrl,
  }) {
    final rawImage = (json['gambar'] ?? '').toString().trim();
    final resolvedImage = _resolveImageUrl(rawImage, baseUrl);
    final reminder = _parseReminderTime(json['reminder_time']?.toString());

    return Supplement(
      logId: (json['id'] ?? '').toString(),
      id: (json['supplement_id'] ?? '').toString(),
      name: (json['nama_suplemen'] ?? '').toString(),
      composition: (json['komposisi'] ?? '').toString(),
      packaging: (json['kemasan'] ?? '').toString(),
      rules: (json['aturan_pakai'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      imageUrl: resolvedImage,
      reminderTime: reminder,
      isTaken: json['is_taken'] == true || json['is_taken']?.toString() == '1',
    );
  }

  static TimeOfDay? _parseReminderTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String? _resolveImageUrl(String value, String? baseUrl) {
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    if (baseUrl == null || baseUrl.isEmpty) return value;

    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedValue = value.replaceAll('\\', '/').trim();

    if (normalizedValue.startsWith('/')) {
      return '$normalizedBase$normalizedValue';
    }

    if (normalizedValue.contains('/')) {
      return '$normalizedBase/$normalizedValue';
    }

    return '$normalizedBase/images/suplement/$normalizedValue';
  }
}
