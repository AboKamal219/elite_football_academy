// lib/services/player_service.dart

import '../models/player.dart';
import 'backend.dart';
import 'supabase_service.dart';

class PlayerService {
  static const String _table = 'players';
  static const String _key = 'players_data';

  static Future<List<Player>> getAllPlayers({String? academyId}) async {
    final aid = academyId ?? SupabaseService.academyId;
    final rows = await Repo.list(
      _table,
      cacheKey: _key,
      eq: aid.isEmpty ? <String, Object>{} : <String, Object>{'academy_id': aid},
    );
    return rows.map(Player.fromMap).toList();
  }

  static Future<Player?> getPlayerById(String id) async {
    final row = await Repo.one(_table, {'id': id}, cacheKey: _key);
    return row == null ? null : Player.fromMap(row);
  }

  static Future<Player?> getPlayerByUserId(String userId) async {
    final row = await Repo.one(_table, {'user_id': userId}, cacheKey: _key);
    return row == null ? null : Player.fromMap(row);
  }

  static Future<List<Player>> getPlayersByTeam(String teamId) async {
    final aid = SupabaseService.academyId;
    try {
      final rows = await Repo.list(
        _table,
        eq: <String, Object>{
          if (aid.isNotEmpty) 'academy_id': aid,
          'team_id': teamId,
        },
        throwOnError: true,
      );
      return rows.map(Player.fromMap).toList();
    } catch (_) {
      final all = await getAllPlayers();
      return all.where((p) => p.teamId == teamId).toList();
    }
  }

  static Future<void> addPlayer(Player player) =>
      Repo.insert(_table, player.toMap());

  static Future<void> updatePlayer(Player player) =>
      Repo.update(_table, player.toMap(), {'id': player.id});

  static Future<void> deletePlayer(String id) =>
      Repo.delete(_table, {'id': id});

  static Future<void> assignPlayerToTeam({
    required String playerId,
    required String teamId,
    required String teamName,
  }) =>
      Repo.update(
          _table, {'team_id': teamId, 'team_name': teamName}, {'id': playerId});

  static Future<Player> createPlayerFromUser({
    required String userId,
    required String name,
    required String academyId,
    String? photo,
  }) async {
    final p = Player(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: name,
      position: 'لاعب',
      photo: photo ?? '',
      academyId: academyId,
    );
    await addPlayer(p);
    return p;
  }

  /// Local cache only (called on logout).
  static Future<void> clearAll() => Repo.clearCache(_key);
}
