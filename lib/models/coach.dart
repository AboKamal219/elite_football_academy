// lib/models/coach.dart

import 'package:flutter/material.dart';

// ============================================================
// COACH MODEL
// ============================================================
class Coach {
  final String id;
  final String name;
  final String specialty; // مدرب رئيسي / مساعد / لياقة / حراس / تكتيك
  final String category;  // فني / بدني / حراس
  final int years;
  final String photo;
  final String phone;
  final String email;

  /// ✅ معرّف الأكاديمية
  final String academyId;

  const Coach({
    required this.id,
    required this.name,
    this.specialty = 'مدرب',
    this.category = 'فني',
    this.years = 0,
    this.photo = '',
    this.phone = '',
    this.email = '',
    this.academyId = '',
  });

  // ============================================================
  // toMap / fromMap
  // ============================================================
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'specialty': specialty,
        'category': category,
        'years': years,
        'photo': photo,
        'phone': phone,
        'email': email,
        'academy_id': academyId,
      };

  factory Coach.fromMap(Map<String, dynamic> map) {
    return Coach(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      specialty: map['specialty'] as String? ?? 'مدرب',
      category: map['category'] as String? ?? 'فني',
      years: _asInt(map['years']),
      photo: map['photo'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      academyId: map['academy_id'] as String? ?? '',
    );
  }

  static int _asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  // ============================================================
  // copyWith
  // ============================================================
  Coach copyWith({
    String? id,
    String? name,
    String? specialty,
    String? category,
    int? years,
    String? photo,
    String? phone,
    String? email,
    String? academyId,
  }) {
    return Coach(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      category: category ?? this.category,
      years: years ?? this.years,
      photo: photo ?? this.photo,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      academyId: academyId ?? this.academyId,
    );
  }

  // ============================================================
  // Helpers
  // ============================================================
  Color get categoryColor {
    switch (category.trim()) {
      case 'فني':
        return const Color(0xFF12B886); // green
      case 'بدني':
        return const Color(0xFFF97316); // orange
      case 'حراس':
        return const Color(0xFF3B82F6); // blue
      default:
        return const Color(0xFF8B5CF6); // purple
    }
  }

  IconData get categoryIcon {
    switch (category.trim()) {
      case 'فني':
        return Icons.sports_soccer_rounded;
      case 'بدني':
        return Icons.fitness_center_rounded;
      case 'حراس':
        return Icons.sports_handball_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasEmail => email.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coach && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Coach(id: $id, name: $name, specialty: $specialty)';
}

// ============================================================
// COACH CATEGORIES
// ============================================================
class CoachCategories {
  static const String technical = 'فني';
  static const String physical = 'بدني';
  static const String goalkeepers = 'حراس';

  static const List<String> all = [technical, physical, goalkeepers];
}

// ============================================================
// COACH SPECIALTIES
// ============================================================
class CoachSpecialties {
  static const String headCoach = 'مدرب رئيسي';
  static const String assistant = 'مدرب مساعد';
  static const String fitness = 'مدرب لياقة';
  static const String goalkeepers = 'مدرب حراس';
  static const String tactics = 'مدرب تكتيك';
  static const String youth = 'مدرب ناشئين';

  static const List<String> all = [
    headCoach,
    assistant,
    fitness,
    goalkeepers,
    tactics,
    youth,
  ];
}