// lib/models/player.dart

import 'dart:convert';
import 'package:flutter/material.dart';

// ============================================================
// PLAYER MODEL
// ============================================================
class Player {
  final String id;
  final String userId;
  final String name;
  final String position;
  final String teamId;
  final String teamName;
  final String photo;
  final String rating;
  final int goals;
  final int assists;
  final int matches;
  final int yellowCards;
  final int redCards;
  final String age;
  final String height;
  final String weight;
  final String foot;
  final String nationality;

  /// ✅ معرّف الأكاديمية اللي اللاعب تبعها
  final String academyId;

  const Player({
    required this.id,
    this.userId = '',
    required this.name,
    required this.position,
    this.teamId = '',
    this.teamName = 'بدون فريق',
    this.photo = '',
    this.rating = '0.0',
    this.goals = 0,
    this.assists = 0,
    this.matches = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.age = '—',
    this.height = '—',
    this.weight = '—',
    this.foot = '—',
    this.nationality = '—',
    this.academyId = '',
  });

  // ============================================================
  // Helpers (للتعامل مع أنواع البيانات اللي جاية من الباك)
  // ============================================================
  static int _asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static String _asString(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    return v.toString();
  }

  // ============================================================
  // toMap / fromMap
  // ============================================================
  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'position': position,
        'team_id': teamId,
        'team_name': teamName,
        'photo': photo,
        'rating': rating,
        'goals': goals,
        'assists': assists,
        'matches': matches,
        'yellow_cards': yellowCards,
        'red_cards': redCards,
        'age': age,
        'height': height,
        'weight': weight,
        'foot': foot,
        'nationality': nationality,
        'academy_id': academyId, // ✅ متوافق مع Supabase
      };

  factory Player.fromMap(Map<String, dynamic> map) => Player(
        id: _asString(map['id']),
        userId: _asString(map['user_id'] ?? map['userId']),
        name: _asString(map['name']),
        position: _asString(map['position'], 'لاعب'),
        teamId: _asString(map['team_id'] ?? map['teamId']),
        teamName: _asString(map['team_name'] ?? map['teamName'], 'بدون فريق'),
        photo: _asString(map['photo']),
        rating: _asString(map['rating'], '0.0'),
        goals: _asInt(map['goals']),
        assists: _asInt(map['assists']),
        matches: _asInt(map['matches']),
        yellowCards: _asInt(map['yellow_cards'] ?? map['yellowCards']),
        redCards: _asInt(map['red_cards'] ?? map['redCards']),
        age: _asString(map['age'], '—'),
        height: _asString(map['height'], '—'),
        weight: _asString(map['weight'], '—'),
        foot: _asString(map['foot'], '—'),
        nationality: _asString(map['nationality'], '—'),
        // ✅ يقرا من academy_id أو academyId (توافق مع الباك)
        academyId: _asString(map['academy_id'] ?? map['academyId']),
      );

  // ============================================================
  // toJson / fromJson (لو هتستخدم REST API / SharedPreferences)
  // ============================================================
  String toJson() => jsonEncode(toMap());

  factory Player.fromJson(String source) =>
      Player.fromMap(jsonDecode(source) as Map<String, dynamic>);

  // ============================================================
  // copyWith
  // ============================================================
  Player copyWith({
    String? id,
    String? userId,
    String? name,
    String? position,
    String? teamId,
    String? teamName,
    String? photo,
    String? rating,
    int? goals,
    int? assists,
    int? matches,
    int? yellowCards,
    int? redCards,
    String? age,
    String? height,
    String? weight,
    String? foot,
    String? nationality,
    String? academyId,
  }) {
    return Player(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      position: position ?? this.position,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      photo: photo ?? this.photo,
      rating: rating ?? this.rating,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      matches: matches ?? this.matches,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      foot: foot ?? this.foot,
      nationality: nationality ?? this.nationality,
      academyId: academyId ?? this.academyId,
    );
  }

  // ============================================================
  // Helper Getters
  // ============================================================
  Color get positionColor {
    switch (position.trim()) {
      case 'مهاجم':
        return const Color(0xFFF97316);
      case 'وسط ميدان':
        return const Color(0xFF3B82F6);
      case 'مدافع':
        return const Color(0xFF12B886);
      case 'حارس مرمى':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  /// ✅ هل اللاعب عنده فريق؟
  bool get hasTeam => teamId.isNotEmpty && teamName != 'بدون فريق';

  /// ✅ هل اللاعب مربوط بحساب مستخدم؟
  bool get isLinkedToUser => userId.isNotEmpty;

  /// ✅ تقييم رقمي (للحسابات)
  double get ratingValue => double.tryParse(rating) ?? 0.0;

  // ============================================================
  // == / hashCode (عشان المقارنة بالـ id)
  // ============================================================
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // ============================================================
  // toString
  // ============================================================
  @override
  String toString() =>
      'Player(id: $id, name: $name, position: $position, teamId: $teamId)';
}

// ============================================================
// POSITIONS
// ============================================================
class PlayerPositions {
  static const String forward = 'مهاجم';
  static const String midfielder = 'وسط ميدان';
  static const String defender = 'مدافع';
  static const String goalkeeper = 'حارس مرمى';

  static const List<String> all = [
    forward,
    midfielder,
    defender,
    goalkeeper,
  ];
}