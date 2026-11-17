// lib/models/match.dart

import 'package:flutter/material.dart';

// ============================================================
// MATCH MODEL
// ============================================================
enum MatchStatus { upcoming, live, finished }

enum MatchResult { win, draw, loss, none }

class Match {
  final String id;
  final String teamId;
  final String teamName;
  final String opponentName;
  final String venue;

  /// التاريخ بصيغة "2026/04/25"
  final String date;

  /// الوقت بصيغة "05:00 م"
  final String time;

  /// نتيجة الفريق الحالي
  final int homeScore;

  /// نتيجة الخصم
  final int awayScore;

  final MatchStatus status;

  /// تقييم اللاعب في الماتش (لو finished)
  final String playerRating;

  /// ✅ جديد: معرّف الأكاديمية اللي الماتش تبعها
  final String academyId;

  const Match({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.opponentName,
    this.venue = 'ملعب الأكاديمية',
    required this.date,
    this.time = '05:00 م',
    this.homeScore = 0,
    this.awayScore = 0,
    this.status = MatchStatus.upcoming,
    this.playerRating = '',
    this.academyId = '',
  });

  // ============================================================
  // HELPER GETTERS
  // ============================================================
  bool get isFinished => status == MatchStatus.finished;
  bool get isLive => status == MatchStatus.live;
  bool get isUpcoming => status == MatchStatus.upcoming;

  MatchResult get result {
    if (!isFinished) return MatchResult.none;
    if (homeScore > awayScore) return MatchResult.win;
    if (homeScore == awayScore) return MatchResult.draw;
    return MatchResult.loss;
  }

  String get resultLabel {
    switch (result) {
      case MatchResult.win:
        return 'فوز';
      case MatchResult.draw:
        return 'تعادل';
      case MatchResult.loss:
        return 'خسارة';
      case MatchResult.none:
        return '—';
    }
  }

  Color get resultColor {
    switch (result) {
      case MatchResult.win:
        return const Color(0xFF12B886);
      case MatchResult.draw:
        return const Color(0xFFF5B700);
      case MatchResult.loss:
        return const Color(0xFFEF4444);
      case MatchResult.none:
        return const Color(0xFF64748B);
    }
  }

  String get scoreLabel {
    if (isUpcoming) return '—';
    return '$homeScore - $awayScore';
  }

  String get statusLabel {
    switch (status) {
      case MatchStatus.upcoming:
        return 'قادمة';
      case MatchStatus.live:
        return 'مباشر';
      case MatchStatus.finished:
        return resultLabel;
    }
  }

  Color get statusColor {
    switch (status) {
      case MatchStatus.upcoming:
        return const Color(0xFF12B886);
      case MatchStatus.live:
        return const Color(0xFFEF4444);
      case MatchStatus.finished:
        return resultColor;
    }
  }

  DateTime get dateTime {
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}
    return DateTime(2000);
  }

  // ============================================================
  // toMap / fromMap
  // ============================================================
  Map<String, dynamic> toMap() => {
        'id': id,
        'team_id': teamId,
        'team_name': teamName,
        'opponent_name': opponentName,
        'venue': venue,
        'date': date,
        'time': time,
        'home_score': homeScore,
        'away_score': awayScore,
        'status': status.name,
        'player_rating': playerRating,
        'academy_id': academyId,
      };

  factory Match.fromMap(Map<String, dynamic> map) => Match(
        id: map['id'] as String? ?? '',
        teamId: map['team_id'] as String? ?? '',
        teamName: map['team_name'] as String? ?? '',
        opponentName: map['opponent_name'] as String? ?? '',
        venue: map['venue'] as String? ?? 'ملعب الأكاديمية',
        date: map['date'] as String? ?? '',
        time: map['time'] as String? ?? '05:00 م',
        homeScore: map['home_score'] as int? ?? 0,
        awayScore: map['away_score'] as int? ?? 0,
        status: MatchStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => MatchStatus.upcoming,
        ),
        playerRating: map['player_rating'] as String? ?? '',
        academyId: map['academy_id'] as String? ?? '',
      );

  // ============================================================
  // copyWith
  // ============================================================
  Match copyWith({
    String? id,
    String? teamId,
    String? teamName,
    String? opponentName,
    String? venue,
    String? date,
    String? time,
    int? homeScore,
    int? awayScore,
    MatchStatus? status,
    String? playerRating,
    String? academyId,
  }) {
    return Match(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      opponentName: opponentName ?? this.opponentName,
      venue: venue ?? this.venue,
      date: date ?? this.date,
      time: time ?? this.time,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      playerRating: playerRating ?? this.playerRating,
      academyId: academyId ?? this.academyId,
    );
  }

  @override
  String toString() =>
      'Match(id: $id, $teamName vs $opponentName, $scoreLabel, $statusLabel)';
}