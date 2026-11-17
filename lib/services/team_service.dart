// lib/services/team_service.dart

import '../models/team.dart';
import 'backend.dart';
import 'player_service.dart';
import 'supabase_service.dart';

class TeamService {
  static const String _table = 'teams';
  static const String _key = 'teams_data';

  static Future<List<Team>> getAllTeams({String? academyId}) async {
    final aid = academyId ?? SupabaseService.academyId;
    final rows = await Repo.list(
      _table,
      cacheKey: _key,
      eq: aid.isEmpty ? <String, Object>{} : <String, Object>{'academy_id': aid},
    );
    return rows.map(Team.fromMap).toList();
  }

  static Future<Team?> getTeamById(String id) async {
    final row = await Repo.one(_table, {'id': id}, cacheKey: _key);
    return row == null ? null : Team.fromMap(row);
  }

  static Future<Team?> getTeamByCoachId(String coachId) async {
    final row = await Repo.one(_table, {'coach_id': coachId}, cacheKey: _key);
    return row == null ? null : Team.fromMap(row);
  }

  static Future<void> addTeam(Team team) => Repo.insert(_table, team.toMap());

  static Future<void> updateTeam(Team team) =>
      Repo.update(_table, team.toMap(), {'id': team.id});

  /// false when the team still has players OR the server refused the delete.
  static Future<bool> deleteTeam(String teamId) async {
    if (await getPlayerCount(teamId) > 0) return false;
    try {
      await Repo.delete(_table, {'id': teamId});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Removes the team. Players are deleted or moved to "no team".
  /// (The database also detaches players/coach automatically.)
  static Future<void> forceDeleteTeam(
    String teamId, {
    bool deletePlayers = false,
  }) async {
    if (deletePlayers) {
      for (final p in await PlayerService.getPlayersByTeam(teamId)) {
        await PlayerService.deletePlayer(p.id);
      }
    }
    await Repo.delete(_table, {'id': teamId});
  }

  /// The DB trigger mirrors coach_id into users.team_id for that coach.
  static Future<void> assignCoachToTeam({
    required String teamId,
    required String coachId,
    required String coachName,
  }) =>
      Repo.update(
          _table, {'coach_id': coachId, 'coach_name': coachName}, {'id': teamId});

  static Future<int> getPlayerCount(String teamId) async =>
      (await PlayerService.getPlayersByTeam(teamId)).length;

  static Future<double> getAvgRating(String teamId) async {
    final players = await PlayerService.getPlayersByTeam(teamId);
    if (players.isEmpty) return 0.0;
    return players.fold<double>(0, (s, p) => s + p.ratingValue) / players.length;
  }

  static Future<int> getAllPlayersCount() async =>
      (await PlayerService.getAllPlayers()).length;

  static Future<void> clearAll() => Repo.clearCache(_key);
}
