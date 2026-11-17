// lib/services/coach_service.dart

import '../models/coach.dart';
import 'backend.dart';
import 'supabase_service.dart';

class CoachService {
  static const String _table = 'coaches';
  static const String _key = 'coaches_data';

  static Future<List<Coach>> getAllCoaches({String? academyId}) async {
    final aid = academyId ?? SupabaseService.academyId;
    final rows = await Repo.list(
      _table,
      cacheKey: _key,
      eq: aid.isEmpty ? <String, Object>{} : <String, Object>{'academy_id': aid},
    );
    return rows.map(Coach.fromMap).toList();
  }

  static Future<Coach?> getCoachById(String id) async {
    final row = await Repo.one(_table, {'id': id}, cacheKey: _key);
    return row == null ? null : Coach.fromMap(row);
  }

  static Future<List<Coach>> getCoachesByCategory(String category) async {
    final coaches = await getAllCoaches();
    return coaches.where((c) => c.category == category).toList();
  }

  static Future<void> addCoach(Coach coach) =>
      Repo.insert(_table, coach.toMap());

  static Future<void> updateCoach(Coach coach) =>
      Repo.update(_table, coach.toMap(), {'id': coach.id});

  static Future<bool> deleteCoach(String id) async {
    try {
      await Repo.delete(_table, {'id': id});
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearAll() => Repo.clearCache(_key);
}
