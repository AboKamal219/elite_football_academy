// lib/services/report_builder.dart
// Builds the CONTENT of a report from live data (so a report is never an empty record).

import '../models/attendance_status.dart';
import '../models/player.dart';
import '../models/report.dart';
import 'attendance_service.dart';
import 'player_service.dart';

class ReportBuilder {
  const ReportBuilder._();

  static Future<String> build(Report r) async {
    final head = StringBuffer()
      ..writeln(r.title)
      ..writeln('التاريخ: ${r.date}')
      ..writeln(r.subtitle.isEmpty ? '' : r.subtitle)
      ..writeln('────────────────');

    switch (r.category) {
      case ReportCategory.attendance:
        return head.toString() + await _attendance(r);
      case ReportCategory.performance:
        return head.toString() + await _performance(r);
      case ReportCategory.financial:
        return '${head}لا توجد بيانات مالية مسجّلة في النظام حتى الآن.';
      case ReportCategory.other:
        return '$head${r.subtitle.isEmpty ? 'لا توجد تفاصيل إضافية.' : r.subtitle}';
    }
  }

  static Future<List<Player>> _players(Report r) async {
    final all = await PlayerService.getAllPlayers();
    return r.teamId.isEmpty
        ? all
        : all.where((p) => p.teamId == r.teamId).toList();
  }

  static Future<String> _attendance(Report r) async {
    final players = await _players(r);
    if (players.isEmpty) return 'لا يوجد لاعبون.';
    final att = await AttendanceService.getAll(days: 30);
    final from = DateTime.now().subtract(const Duration(days: 30));

    final rows = <String>[];
    var totalPresent = 0, totalAll = 0;
    for (final p in players) {
      var present = 0, late = 0, absent = 0;
      att.forEach((key, status) {
        final k = AttendanceService.parseKey(key);
        if (k == null || k.playerId != p.id || k.date.isBefore(from)) return;
        switch (status) {
          case AttendanceStatus.present:
            present++;
            break;
          case AttendanceStatus.late:
            late++;
            break;
          case AttendanceStatus.absent:
            absent++;
            break;
        }
      });
      final total = present + late + absent;
      final pct = total == 0 ? 0 : (((present + late) / total) * 100).round();
      totalPresent += present + late;
      totalAll += total;
      rows.add('${p.name}: حاضر $present | متأخر $late | غائب $absent | نسبة $pct%');
    }
    final overall = totalAll == 0 ? 0 : ((totalPresent / totalAll) * 100).round();
    return 'آخر 30 يوم — نسبة الحضور العامة: $overall%\n\n${rows.join('\n')}';
  }

  static Future<String> _performance(Report r) async {
    final players = await _players(r);
    if (players.isEmpty) return 'لا يوجد لاعبون.';
    players.sort((a, b) => (double.tryParse(b.rating) ?? 0)
        .compareTo(double.tryParse(a.rating) ?? 0));
    final rows = <String>[];
    for (var i = 0; i < players.length; i++) {
      final p = players[i];
      rows.add('${i + 1}. ${p.name} (${p.position}) — تقييم ${p.rating} | '
          'أهداف ${p.goals} | صناعة ${p.assists} | مباريات ${p.matches}');
    }
    return 'ترتيب اللاعبين حسب التقييم:\n\n${rows.join('\n')}';
  }
}
