// lib/services/match_service.dart

import '../models/match.dart';
import 'backend.dart';
import 'supabase_service.dart';

class MatchService {
  static const String _table = 'matches';
  static const String _key = 'matches_data';

  static Future<List<Match>> getAllMatches({String? academyId}) async {
    final aid = academyId ?? SupabaseService.academyId;
    final rows = await Repo.list(
      _table,
      cacheKey: _key,
      eq: aid.isEmpty ? <String, Object>{} : <String, Object>{'academy_id': aid},
    );
    return rows.map(Match.fromMap).toList();
  }

  static Future<Match?> getMatchById(String id) async {
    final row = await Repo.one(_table, {'id': id}, cacheKey: _key);
    return row == null ? null : Match.fromMap(row);
  }

  static Future<List<Match>> getMatchesByTeam(String teamId) async {
    final all = await getAllMatches();
    return all.where((m) => m.teamId == teamId).toList();
  }

  static Future<List<Match>> getUpcomingMatches(String teamId) async {
    final list = (await getMatchesByTeam(teamId))
        .where((m) => m.isUpcoming || m.isLive)
        .toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  static Future<List<Match>> getFinishedMatches(String teamId) async {
    final list =
        (await getMatchesByTeam(teamId)).where((m) => m.isFinished).toList();
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  static Future<Match?> getNextMatch(String teamId) async {
    final upcoming = await getUpcomingMatches(teamId);
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  static Future<void> addMatch(Match m) => Repo.insert(_table, m.toMap());

  static Future<void> updateMatch(Match m) =>
      Repo.update(_table, m.toMap(), {'id': m.id});

  static Future<void> deleteMatch(String id) =>
      Repo.delete(_table, {'id': id});

  static Future<void> clearAll() => Repo.clearCache(_key);
}
