// lib/services/training_service.dart

import '../models/training.dart';
import 'backend.dart';
import 'supabase_service.dart';

class TrainingService {
  static const String _table = 'trainings';
  static const String _key = 'trainings_data';

  static Future<List<Training>> getAllTrainings({String? academyId}) async {
    final aid = academyId ?? SupabaseService.academyId;
    final rows = await Repo.list(
      _table,
      cacheKey: _key,
      eq: aid.isEmpty ? <String, Object>{} : <String, Object>{'academy_id': aid},
      orderBy: 'date',
    );
    return rows.map(Training.fromMap).toList();
  }

  static Future<Training?> getTrainingById(String id) async {
    final row = await Repo.one(_table, {'id': id}, cacheKey: _key);
    return row == null ? null : Training.fromMap(row);
  }

  static Future<List<Training>> getTrainingsByTeam(String teamId) async {
    final all = await getAllTrainings();
    return all.where((t) => t.teamId == teamId).toList();
  }

  static Future<List<Training>> getByTeam(String teamId) async {
    final list = await getTrainingsByTeam(teamId);
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  static Future<String> getLatestCoachNote(String teamId) async {
    final withNotes = (await getByTeam(teamId))
        .where((t) => t.notes.trim().isNotEmpty)
        .toList();
    if (withNotes.isEmpty) return '';
    withNotes.sort((a, b) => b.date.compareTo(a.date));
    return withNotes.first.notes;
  }

  static Future<List<Training>> getTrainingsByType(String type) async {
    final all = await getAllTrainings();
    return all.where((t) => t.type == type).toList();
  }

  static Future<List<Training>> getUpcomingTrainings() async {
    final upcoming = (await getAllTrainings()).where((t) => t.isUpcoming).toList();
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    return upcoming;
  }

  static Future<List<Training>> getTrainingsByMonth(int year, int month) async {
    final all = await getAllTrainings();
    return all
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
  }

  static Future<void> addTraining(Training t) =>
      Repo.insert(_table, t.toMap());

  static Future<void> updateTraining(Training t) =>
      Repo.update(_table, t.toMap(), {'id': t.id});

  static Future<void> deleteTraining(String id) =>
      Repo.delete(_table, {'id': id});

  static Future<void> clearAll() => Repo.clearCache(_key);
}
