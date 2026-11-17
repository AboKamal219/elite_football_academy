// lib/models/team.dart

import 'package:flutter/material.dart';

// ============================================================
// TEAM MODEL
// ============================================================
class Team {
  final String id;
  final String name;
  final String category;
  final String coachId;
  final String coachName;
  final Color color;
  final String iconName;

  /// ✅ جديد: وصف الفريق
  final String description;

  /// ✅ معرّف الأكاديمية اللي الفريق تبعها
  final String academyId;

  const Team({
    required this.id,
    required this.name,
    required this.category,
    this.coachId = '',
    this.coachName = '',
    this.color = const Color(0xFF12B886),
    this.iconName = 'shield',
    this.description = '', // ✅ جديد
    this.academyId = '',
  });

  // ============================================================
  // toMap / fromMap
  // ============================================================
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'coach_id': coachId,
        'coach_name': coachName,
        'color': color.value,
        'icon_name': iconName,
        'description': description, // ✅ جديد
        'academy_id': academyId,
      };

  factory Team.fromMap(Map<String, dynamic> map) {
    // ✅ تعامل آمن مع color (int أو String)
    Color parsedColor = const Color(0xFF12B886);
    final colorValue = map['color'];
    if (colorValue is int) {
      parsedColor = Color(colorValue);
    } else if (colorValue is String) {
      try {
        parsedColor = Color(int.parse(colorValue));
      } catch (_) {
        parsedColor = const Color(0xFF12B886);
      }
    }

    return Team(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      coachId: (map['coach_id'] ?? map['coachId']) as String? ?? '',
      coachName: (map['coach_name'] ?? map['coachName']) as String? ?? '',
      color: parsedColor,
      iconName: (map['icon_name'] ?? map['iconName']) as String? ?? 'shield',
      description: map['description'] as String? ?? '', // ✅ جديد
      academyId: map['academy_id'] as String? ?? '',
    );
  }

  // ============================================================
  // copyWith
  // ============================================================
  Team copyWith({
    String? id,
    String? name,
    String? category,
    String? coachId,
    String? coachName,
    Color? color,
    String? iconName,
    String? description, // ✅ جديد
    String? academyId,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      color: color ?? this.color,
      iconName: iconName ?? this.iconName,
      description: description ?? this.description, // ✅ جديد
      academyId: academyId ?? this.academyId,
    );
  }

  // ============================================================
  // Helper: IconData من iconName
  // ============================================================
  IconData get icon {
    switch (iconName) {
      case 'shield':
        return Icons.shield_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'group':
        return Icons.groups_rounded;
      default:
        return Icons.shield_rounded;
    }
  }

  // ============================================================
  // Helpers
  // ============================================================
  bool get isAssignedToCoach => coachId.isNotEmpty && coachName.isNotEmpty;

  String get displayCoachName => coachName.isNotEmpty ? coachName : '—';

  bool get hasDescription => description.trim().isNotEmpty;

  @override
  String toString() =>
      'Team(id: $id, name: $name, coachId: $coachId, coachName: $coachName)';
}