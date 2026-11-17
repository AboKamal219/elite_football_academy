// lib/models/standing.dart

import 'package:flutter/material.dart';

// ============================================================
// STANDING MODEL (صف في جدول الترتيب)
// ============================================================
class Standing {
  final String teamId;
  final String teamName;
  final int played;
  final int won;
  final int drawn;
  final int lost;

  /// ✅ جديد: معرّف الأكاديمية
  final String academyId;

  const Standing({
    required this.teamId,
    required this.teamName,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.academyId = '',
  });

  // ============================================================
  // HELPERS
  // ============================================================
  int get points => (won * 3) + drawn;

  Color medalColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFF5B700);
      case 2:
        return const Color(0xFFB0BAC9);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF64748B);
    }
  }

  // ============================================================
  // toMap / fromMap
  // ============================================================
  Map<String, dynamic> toMap() => {
        'team_id': teamId,
        'team_name': teamName,
        'played': played,
        'won': won,
        'drawn': drawn,
        'lost': lost,
        'academy_id': academyId,
      };

  factory Standing.fromMap(Map<String, dynamic> map) => Standing(
        teamId: map['team_id'] as String? ?? '',
        teamName: map['team_name'] as String? ?? '',
        played: map['played'] as int? ?? 0,
        won: map['won'] as int? ?? 0,
        drawn: map['drawn'] as int? ?? 0,
        lost: map['lost'] as int? ?? 0,
        academyId: map['academy_id'] as String? ?? '',
      );

  Standing copyWith({
    String? teamId,
    String? teamName,
    int? played,
    int? won,
    int? drawn,
    int? lost,
    String? academyId,
  }) {
    return Standing(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      played: played ?? this.played,
      won: won ?? this.won,
      drawn: drawn ?? this.drawn,
      lost: lost ?? this.lost,
      academyId: academyId ?? this.academyId,
    );
  }
}