// lib/services/lineup_service.dart
// Match line-up: starters + substitutes + how many starters the coach decided on.
// Server side: database/08_lineups.sql (table match_lineups).

import 'backend.dart';
import 'supabase_service.dart';

class Lineup {
  /// عدد اللاعبين الأساسيين اللي المدرب حدّده (الافتراضي 11)
  final int squadSize;
  final List<String> starters; // player ids بالترتيب
  final List<String> subs; // player ids بالترتيب
  const Lineup({
    this.squadSize = defaultSize,
    this.starters = const [],
    this.subs = const [],
  });

  static const int defaultSize = 11;
  bool get isEmpty => starters.isEmpty && subs.isEmpty;
}

class LineupService {
  const LineupService._();
  static const String _table = 'match_lineups';

  static Future<Lineup> get(String matchId) async {
    final rows = await Repo.list(
      _table,
      eq: <String, Object>{'match_id': matchId},
      orderBy: 'sort_order',
    );
    final starters = <String>[];
    final subs = <String>[];
    var size = Lineup.defaultSize;
    for (final r in rows) {
      final id = r['player_id'] as String? ?? '';
      if (id.isEmpty) continue;
      final s = r['squad_size'];
      if (s is int) size = s;
      if (r['role'] == 'starter') {
        starters.add(id);
      } else {
        subs.add(id);
      }
    }
    return Lineup(squadSize: size, starters: starters, subs: subs);
  }

  /// يحفظ التشكيلة كاملة (upsert للموجودين + حذف اللي اتشالوا).
  static Future<void> save(
    String matchId, {
    required int squadSize,
    required List<String> starters,
    required List<String> subs,
  }) async {
    final aid = SupabaseService.academyId;
    final rows = <Map<String, dynamic>>[
      for (var i = 0; i < starters.length; i++)
        {
          'match_id': matchId,
          'player_id': starters[i],
          'academy_id': aid,
          'role': 'starter',
          'sort_order': i,
          'squad_size': squadSize,
        },
      for (var i = 0; i < subs.length; i++)
        {
          'match_id': matchId,
          'player_id': subs[i],
          'academy_id': aid,
          'role': 'sub',
          'sort_order': i,
          'squad_size': squadSize,
        },
    ];

    await Repo.upsert(_table, rows, onConflict: 'match_id,player_id');

    // احذف أي لاعب اتشال من التشكيلة
    try {
      final keep = [...starters, ...subs];
      var q = SupabaseService.client
          .from(_table)
          .delete()
          .eq('match_id', matchId);
      if (keep.isNotEmpty) {
        q = q.not('player_id', 'in', '(${keep.join(',')})');
      }
      await q;
    } catch (e) {
      throw BackendException.from(e);
    }
  }
}
