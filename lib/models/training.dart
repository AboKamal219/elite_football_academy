// lib/models/training.dart

import 'package:flutter/material.dart';

// ============================================================
// TRAINING MODEL
// ============================================================
class Training {
  final String id;
  final String title;
  final String type;        // تدريب / مباراة / اجتماع
  final String location;
  final DateTime date;
  final String time;        // "05:00 م"
  final int durationMinutes;
  final String teamId;      // الفريق المعني
  final String teamName;
  final String coachId;
  final String coachName;
  final String notes;

  /// ✅ معرّف الأكاديمية
  final String academyId;

  const Training({
    required this.id,
    required this.title,
    this.type = 'تدريب',
    this.location = '',
    required this.date,
    this.time = '',
    this.durationMinutes = 60,
    this.teamId = '',
    this.teamName = '',
    this.coachId = '',
    this.coachName = '',
    this.notes = '',
    this.academyId = '',
  });

  // ============================================================
  // toMap / fromMap
  // ============================================================
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'type': type,
        'location': location,
        'date': date.toIso8601String(),
        'time': time,
        'duration_minutes': durationMinutes,
        'team_id': teamId,
        'team_name': teamName,
        'coach_id': coachId,
        'coach_name': coachName,
        'notes': notes,
        'academy_id': academyId,
      };

  factory Training.fromMap(Map<String, dynamic> map) {
    return Training(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? 'تدريب',
      location: map['location'] as String? ?? '',
      date: _parseDate(map['date']),
      time: map['time'] as String? ?? '',
      durationMinutes: _asInt(map['duration_minutes'], 60),
      teamId: (map['team_id'] ?? map['teamId']) as String? ?? '',
      teamName: (map['team_name'] ?? map['teamName']) as String? ?? '',
      coachId: (map['coach_id'] ?? map['coachId']) as String? ?? '',
      coachName: (map['coach_name'] ?? map['coachName']) as String? ?? '',
      notes: map['notes'] as String? ?? '',
      academyId: map['academy_id'] as String? ?? '',
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
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
  Training copyWith({
    String? id,
    String? title,
    String? type,
    String? location,
    DateTime? date,
    String? time,
    int? durationMinutes,
    String? teamId,
    String? teamName,
    String? coachId,
    String? coachName,
    String? notes,
    String? academyId,
  }) {
    return Training(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      location: location ?? this.location,
      date: date ?? this.date,
      time: time ?? this.time,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      notes: notes ?? this.notes,
      academyId: academyId ?? this.academyId,
    );
  }

  // ============================================================
  // Helpers
  // ============================================================

  /// ✅ icon (متوافق مع my_trainings_screen)
  IconData get icon {
    switch (type) {
      case 'مباراة':
        return Icons.emoji_events_rounded;
      case 'اجتماع':
        return Icons.groups_rounded;
      case 'تدريب':
      default:
        return Icons.sports_soccer_rounded;
    }
  }

  /// ✅ typeIcon (اسم بديل — للتوافق مع training_schedule_screen)
  IconData get typeIcon => icon;

  /// ✅ iconColor (متوافق مع my_trainings_screen)
  Color get iconColor {
    switch (type) {
      case 'مباراة':
        return const Color(0xFFF97316); // orange
      case 'اجتماع':
        return const Color(0xFF8B5CF6); // purple
      case 'تدريب':
      default:
        return const Color(0xFF12B886); // green
    }
  }

  /// ✅ typeColor (اسم بديل — للتوافق مع training_schedule_screen)
  Color get typeColor => iconColor;

  /// ✅ التاريخ بصيغة yyyy/MM/dd
  String get dateString {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  /// ✅ "قادم" / "النهاردة" / "خلص"
  String get statusLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'النهاردة';
    if (target.isAfter(today)) {
      final diff = target.difference(today).inDays;
      if (diff == 1) return 'بكرة';
      if (diff <= 7) return 'قريباً';
      return 'قادم';
    }
    return 'خلص';
  }

  Color get statusColor {
    switch (statusLabel) {
      case 'النهاردة':
        return const Color(0xFF12B886); // green
      case 'بكرة':
        return const Color(0xFF3B82F6); // blue
      case 'قريباً':
        return const Color(0xFFF97316); // orange
      case 'قادم':
        return const Color(0xFF3B82F6); // blue
      case 'خلص':
      default:
        return const Color(0xFF64748B); // gray
    }
  }

  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return !target.isBefore(today);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Training && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Training(id: $id, title: $title, date: $dateString)';
}

// ============================================================
// TRAINING TYPES
// ============================================================
class TrainingTypes {
  static const String practice = 'تدريب';
  static const String match = 'مباراة';
  static const String meeting = 'اجتماع';

  static const List<String> all = [practice, match, meeting];
}

// ============================================================
// ✅ ALIAS: TrainingType (مفرد) — للتوافق مع my_trainings_screen
// ============================================================
class TrainingType {
  static const String training = 'تدريب';
  static const String match = 'مباراة';
  static const String meeting = 'اجتماع';

  static const List<String> all = [training, match, meeting];
}