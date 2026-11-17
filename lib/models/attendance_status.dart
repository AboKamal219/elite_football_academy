// lib/models/attendance_status.dart

import 'package:flutter/material.dart';
import '../academy_dashboard_screen.dart' show AppColors;

// ============================================================
// ATTENDANCE STATUS
// ============================================================

enum AttendanceStatus { present, absent, late }

extension AttendanceStatusX on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'حاضر';
      case AttendanceStatus.absent:
        return 'غائب';
      case AttendanceStatus.late:
        return 'متأخر';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return AppColors.green;
      case AttendanceStatus.absent:
        return AppColors.red;
      case AttendanceStatus.late:
        return AppColors.orange;
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.present:
        return Icons.check_circle_rounded;
      case AttendanceStatus.absent:
        return Icons.cancel_rounded;
      case AttendanceStatus.late:
        return Icons.access_time_rounded;
    }
  }

  String get storageKey {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
    }
  }
}

class AttendanceStatusHelper {
  static AttendanceStatus? fromStorage(String value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      default:
        return null;
    }
  }
}