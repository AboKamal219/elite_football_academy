// lib/models/tournament.dart

import 'package:flutter/material.dart';

// ============================================================
// TOURNAMENT MODEL
// ============================================================
enum TournamentStatus { ongoing, upcoming, scheduled, finished }

class Tournament {
  final String id;
  final String name;
  final String subtitle;
  final String date;
  final TournamentStatus status;
  final int teamsCount;
  final String iconName;

  /// ✅ جديد: معرّف الأكاديمية
  final String academyId;

  const Tournament({
    required this.id,
    required this.name,
    this.subtitle = '',
    required this.date,
    this.status = TournamentStatus.upcoming,
    this.teamsCount = 0,
    this.iconName = 'trophy',
    this.academyId = '',
  });

  // ============================================================
  // HELPERS
  // ============================================================
  String get statusLabel {
    switch (status) {
      case TournamentStatus.ongoing:
        return 'جاري';
      case TournamentStatus.upcoming:
        return 'قريباً';
      case TournamentStatus.scheduled:
        return 'مجدول';
      case TournamentStatus.finished:
        return 'منتهي';
    }
  }

  Color get statusColor {
    switch (status) {
      case TournamentStatus.ongoing:
        return const Color(0xFF12B886);
      case TournamentStatus.upcoming:
        return const Color(0xFF3B82F6);
      case TournamentStatus.scheduled:
        return const Color(0xFF8B5CF6);
      case TournamentStatus.finished:
        return const Color(0xFF64748B);
    }
  }

  Color get color {
    switch (iconName) {
      case 'trophy':
        return const Color(0xFFF5B700);
      case 'medal':
        return const Color(0xFF3B82F6);
      case 'stadium':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF12B886);
    }
  }

  IconData get icon {
    switch (iconName) {
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'medal':
        return Icons.military_tech_rounded;
      case 'stadium':
        return Icons.stadium_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  // ============================================================
  // toMap / fromMap
  // ============================================================
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'date': date,
        'status': status.name,
        'teams_count': teamsCount,
        'icon_name': iconName,
        'academy_id': academyId,
      };

  factory Tournament.fromMap(Map<String, dynamic> map) => Tournament(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        subtitle: map['subtitle'] as String? ?? '',
        date: map['date'] as String? ?? '',
        status: TournamentStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => TournamentStatus.upcoming,
        ),
        teamsCount: map['teams_count'] as int? ?? 0,
        iconName: map['icon_name'] as String? ?? 'trophy',
        academyId: map['academy_id'] as String? ?? '',
      );

  Tournament copyWith({
    String? id,
    String? name,
    String? subtitle,
    String? date,
    TournamentStatus? status,
    int? teamsCount,
    String? iconName,
    String? academyId,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      date: date ?? this.date,
      status: status ?? this.status,
      teamsCount: teamsCount ?? this.teamsCount,
      iconName: iconName ?? this.iconName,
      academyId: academyId ?? this.academyId,
    );
  }
}