// lib/services/report_service.dart

import '../models/report.dart';
import 'backend.dart';
import 'supabase_service.dart';

class ReportService {
  static const String _table = 'reports';
  static const String _key = 'reports_data';

  static Future<List<Report>> getAllReports({String? academyId}) async {
    final aid = academyId ?? SupabaseService.academyId;
    final rows = await Repo.list(
      _table,
      cacheKey: _key,
      eq: aid.isEmpty ? <String, Object>{} : <String, Object>{'academy_id': aid},
    );
    return rows.map(Report.fromMap).toList();
  }

  static Future<Report?> getById(String id) async {
    final row = await Repo.one(_table, {'id': id}, cacheKey: _key);
    return row == null ? null : Report.fromMap(row);
  }

  static Future<List<Report>> getByCategory(ReportCategory category) async {
    final all = await getAllReports();
    return all.where((r) => r.category == category).toList();
  }

  static Future<List<Report>> getByTeam(String teamId) async {
    final all = await getAllReports();
    return all.where((r) => r.teamId == teamId).toList();
  }

  static Future<List<Report>> getSorted() async {
    final sorted = List<Report>.from(await getAllReports());
    sorted.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return sorted;
  }

  static Future<Map<String, int>> getStats() async {
    final all = await getAllReports();
    final now = DateTime.now();
    int count(ReportCategory c) => all.where((r) => r.category == c).length;
    return {
      'total': all.length,
      'thisMonth': all
          .where((r) =>
              r.dateTime.year == now.year && r.dateTime.month == now.month)
          .length,
      'performance': count(ReportCategory.performance),
      'attendance': count(ReportCategory.attendance),
      'financial': count(ReportCategory.financial),
    };
  }

  static Future<void> addReport(Report r) => Repo.insert(_table, r.toMap());

  static Future<void> updateReport(Report r) =>
      Repo.update(_table, r.toMap(), {'id': r.id});

  static Future<void> deleteReport(String id) =>
      Repo.delete(_table, {'id': id});

  static Future<void> clearAll() => Repo.clearCache(_key);
}
