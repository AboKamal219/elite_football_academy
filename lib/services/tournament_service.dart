// lib/services/tournament_service.dart

import '../models/tournament.dart';
import '../models/standing.dart';
import 'backend.dart';
import 'supabase_service.dart';

class TournamentService {
  static const String _tKey = 'tournaments_data';
  static const String _sKey = 'standings_data';

  static Map<String, Object> get _aidFilter {
    final aid = SupabaseService.academyId;
    return aid.isEmpty ? <String, Object>{} : <String, Object>{'academy_id': aid};
  }

  // ===== TOURNAMENTS =====
  static Future<List<Tournament>> getAllTournaments({String? academyId}) async {
    final rows = await Repo.list('tournaments',
        cacheKey: _tKey,
        eq: academyId == null || academyId.isEmpty
            ? _aidFilter
            : <String, Object>{'academy_id': academyId});
    return rows.map(Tournament.fromMap).toList();
  }

  static Future<void> addTournament(Tournament t) =>
      Repo.insert('tournaments', t.toMap());

  static Future<void> updateTournament(Tournament t) =>
      Repo.update('tournaments', t.toMap(), {'id': t.id});

  static Future<void> deleteTournament(String id) =>
      Repo.delete('tournaments', {'id': id});

  // ===== STANDINGS =====
  static Future<List<Standing>> getAllStandings({String? academyId}) async {
    final rows = await Repo.list('standings',
        cacheKey: _sKey,
        eq: academyId == null || academyId.isEmpty
            ? _aidFilter
            : <String, Object>{'academy_id': academyId});
    return rows.map(Standing.fromMap).toList();
  }

  static Future<List<Standing>> getSortedStandings() async {
    final sorted = List<Standing>.from(await getAllStandings());
    sorted.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      if (byPoints != 0) return byPoints;
      return a.played.compareTo(b.played); // tie-break: fewer games played first
    });
    return sorted;
  }

  /// upsert on (team_id, academy_id)
  static Future<void> updateStanding(Standing s) =>
      Repo.upsert('standings', [s.toMap()], onConflict: 'team_id,academy_id');

  static Future<void> addStanding(Standing s) => updateStanding(s);

  static Future<void> deleteStanding(String teamId) {
    final aid = SupabaseService.academyId;
    return Repo.delete('standings', {
      'team_id': teamId,
      if (aid.isNotEmpty) 'academy_id': aid,
    });
  }

  // ===== STATS =====
  static Future<Map<String, int>> getStats() async {
    final tournaments = await getAllTournaments();
    var ongoing = 0, upcoming = 0, scheduled = 0, finished = 0;
    for (final t in tournaments) {
      switch (t.status) {
        case TournamentStatus.ongoing:
          ongoing++;
          break;
        case TournamentStatus.upcoming:
          upcoming++;
          break;
        case TournamentStatus.scheduled:
          scheduled++;
          break;
        case TournamentStatus.finished:
          finished++;
          break;
      }
    }
    return {
      'total': tournaments.length,
      'ongoing': ongoing,
      'upcoming': upcoming,
      'scheduled': scheduled,
      'finished': finished,
    };
  }

  static Future<void> clearAll() async {
    await Repo.clearCache(_tKey);
    await Repo.clearCache(_sKey);
  }
}
