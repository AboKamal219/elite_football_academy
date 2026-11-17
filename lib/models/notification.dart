// lib/models/notification.dart

import 'package:flutter/material.dart';

// ============================================================
// NOTIFICATION MODEL
// ============================================================
enum NotificationCategory { general, matches, trainings }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isUnread;
  final NotificationCategory category;

  /// ✅ جديد: معرّف الأكاديمية
  final String academyId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isUnread = false,
    this.category = NotificationCategory.general,
    this.academyId = '',
  });

  // ============================================================
  // HELPERS
  // ============================================================
  String get categoryLabel {
    switch (category) {
      case NotificationCategory.general:
        return 'عام';
      case NotificationCategory.matches:
        return 'مباريات';
      case NotificationCategory.trainings:
        return 'تدريبات';
    }
  }

  IconData get icon {
    switch (category) {
      case NotificationCategory.matches:
        return Icons.sports_soccer_rounded;
      case NotificationCategory.trainings:
        return Icons.fitness_center_rounded;
      case NotificationCategory.general:
        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (category) {
      case NotificationCategory.matches:
        return const Color(0xFFF97316);
      case NotificationCategory.trainings:
        return const Color(0xFF3B82F6);
      case NotificationCategory.general:
        return const Color(0xFF12B886);
    }
  }

  // ============================================================
  // toMap / fromMap
  // ============================================================
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'message': message,
        'time': time,
        'is_unread': isUnread,
        'category': category.name,
        'academy_id': academyId,
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        message: map['message'] as String? ?? '',
        time: map['time'] as String? ?? '',
        isUnread: map['is_unread'] as bool? ?? false,
        category: NotificationCategory.values.firstWhere(
          (c) => c.name == map['category'],
          orElse: () => NotificationCategory.general,
        ),
        academyId: map['academy_id'] as String? ?? '',
      );

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? time,
    bool? isUnread,
    NotificationCategory? category,
    String? academyId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isUnread: isUnread ?? this.isUnread,
      category: category ?? this.category,
      academyId: academyId ?? this.academyId,
    );
  }
}