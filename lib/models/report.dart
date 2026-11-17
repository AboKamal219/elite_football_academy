// lib/models/report.dart

import 'package:flutter/material.dart';

// ============================================================
// REPORT MODEL
// ============================================================
enum ReportCategory { performance, attendance, financial, other }

class Report {
  final String id;
  final String title;
  final String subtitle;
  final String date;
  final String size;
  final String type;
  final ReportCategory category;

  /// معرّف الفريق (اختياري)
  final String teamId;

  /// ✅ جديد: معرّف الأكاديمية
  final String academyId;

  const Report({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.date,
    this.size = '1.0 MB',
    this.type = 'PDF',
    this.category = ReportCategory.performance,
    this.teamId = '',
    this.academyId = '',
  });

  // ============================================================
  // HELPERS
  // ============================================================
  String get categoryLabel {
    switch (category) {
      case ReportCategory.performance:
        return 'أداء';
      case ReportCategory.attendance:
        return 'حضور';
      case ReportCategory.financial:
        return 'مالي';
      case ReportCategory.other:
        return 'أخرى';
    }
  }

  IconData get icon {
    switch (category) {
      case ReportCategory.performance:
        return Icons.analytics_rounded;
      case ReportCategory.attendance:
        return Icons.fact_check_rounded;
      case ReportCategory.financial:
        return Icons.attach_money_rounded;
      case ReportCategory.other:
        return Icons.description_rounded;
    }
  }

  Color get color {
    switch (category) {
      case ReportCategory.performance:
        return const Color(0xFF8B5CF6);
      case ReportCategory.attendance:
        return const Color(0xFF3B82F6);
      case ReportCategory.financial:
        return const Color(0xFFF97316);
      case ReportCategory.other:
        return const Color(0xFF64748B);
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
        'title': title,
        'subtitle': subtitle,
        'date': date,
        'size': size,
        'type': type,
        'category': category.name,
        'team_id': teamId,
        'academy_id': academyId,
      };

  factory Report.fromMap(Map<String, dynamic> map) => Report(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        subtitle: map['subtitle'] as String? ?? '',
        date: map['date'] as String? ?? '',
        size: map['size'] as String? ?? '1.0 MB',
        type: map['type'] as String? ?? 'PDF',
        category: ReportCategory.values.firstWhere(
          (c) => c.name == map['category'],
          orElse: () => ReportCategory.performance,
        ),
        teamId: map['team_id'] as String? ?? '',
        academyId: map['academy_id'] as String? ?? '',
      );

  // ============================================================
  // copyWith
  // ============================================================
  Report copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? date,
    String? size,
    String? type,
    ReportCategory? category,
    String? teamId,
    String? academyId,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      date: date ?? this.date,
      size: size ?? this.size,
      type: type ?? this.type,
      category: category ?? this.category,
      teamId: teamId ?? this.teamId,
      academyId: academyId ?? this.academyId,
    );
  }

  @override
  String toString() =>
      'Report(id: $id, title: $title, category: ${category.name})';
}