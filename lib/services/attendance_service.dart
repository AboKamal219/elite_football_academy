// lib/services/attendance_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_status.dart';
import 'backend.dart';
import 'supabase_service.dart';

class AttendanceService {
  static const String _storageKey = 'attendance_data';

  /// Last state known to be on the server (key -> status). Used so saveAll
  /// uploads only what changed (not the whole history on every tap).
  static Map<String, AttendanceStatus> _synced = {};

  static String buildKey(DateTime date, String playerId) =>
      '${_dateOnly(date)}:$playerId';

  static String _dateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static ({DateTime date, String playerId})? parseKey(String key) {
    final colonIndex = key.indexOf(':');
    if (colonIndex <= 0 || colonIndex >= key.length - 1) return null;
    final parts = key.substring(0, colonIndex).split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return (date: DateTime(y, m, d), playerId: key.substring(colonIndex + 1));
  }

  // ============================================================
  // GET ALL (server first, cache as offline fallback)
  // ============================================================
  /// Whole-day rows (training_id IS NULL) of the last [days] days only —
  /// the old version downloaded the entire history on every screen open.
  static Future<List<Map<String, dynamic>>> _fetchWindow(int days) async {
    final since = _dateOnly(DateTime.now().subtract(Duration(days: days)));
    final out = <Map<String, dynamic>>[];
    for (var from = 0;; from += 1000) {
      final chunk = await SupabaseService.client
          .from('attendance')
          .select('player_id,date,status')
          .gte('date', since)
          .isFilter('training_id', null)
          .order('date')
          .order('player_id')
          .range(from, from + 999);
      out.addAll(List<Map<String, dynamic>>.from(chunk));
      if (chunk.length < 1000) break;
    }
    return out;
  }

  static Future<Map<String, AttendanceStatus>> getAll({int days = 180}) async {
    if (Repo.online) {
      try {
        final rows = await _fetchWindow(days);
        final map = <String, AttendanceStatus>{};
        for (final row in rows) {
          final playerId = (row['player_id'] ?? '').toString();
          final status =
              AttendanceStatusHelper.fromStorage((row['status'] ?? '').toString());
          final dt = DateTime.tryParse((row['date'] ?? '').toString());
          if (playerId.isEmpty || status == null || dt == null) continue;
          map[buildKey(DateTime(dt.year, dt.month, dt.day), playerId)] = status;
        }
        _synced = Map.of(map);
        await _saveLocalOnly(map);
        return map;
      } catch (_) {}
    }
    return _getLocalOnly();
  }

  // ============================================================
  // SAVE ALL
  // ============================================================
  static Future<void> saveAll(
    Map<String, AttendanceStatus> attendance, {
    List<dynamic>? players,
  }) async {
    // team_id is filled by the DB trigger (trg_attendance_check) from the player row.
    final rows = <Map<String, dynamic>>[];
    attendance.forEach((key, status) {
      if (_synced[key] == status) return; // unchanged
      final parsed = parseKey(key);
      if (parsed == null) return;
      rows.add({
        'player_id': parsed.playerId,
        'date': _dateOnly(parsed.date),
        'training_id': null,
        'status': status.storageKey,
      });
    });
    if (rows.isNotEmpty) {
      await Repo.upsert('attendance', rows,
          onConflict: 'player_id,date,training_id');
    }

    // "not marked" again = the row is removed (no row == not marked)
    final removed = _synced.keys.where((k) => !attendance.containsKey(k)).toList();
    for (final k in removed) {
      final parsed = parseKey(k);
      if (parsed == null) continue;
      await SupabaseService.client
          .from('attendance')
          .delete()
          .eq('player_id', parsed.playerId)
          .eq('date', _dateOnly(parsed.date))
          .isFilter('training_id', null);
    }

    _synced = Map.of(attendance);
    await _saveLocalOnly(attendance);
  }
  static Future<void> setStatus({
    required DateTime date,
    required String playerId,
    required AttendanceStatus status,
    String? teamId,
  }) async {
    await Repo.upsert(
      'attendance',
      [
        {
          'player_id': playerId,
          'date': _dateOnly(date),
          'training_id': null,
          'status': status.storageKey,
        }
      ],
      onConflict: 'player_id,date,training_id',
    );
    final key = buildKey(date, playerId);
    _synced[key] = status;
    final all = await _getLocalOnly();
    all[key] = status;
    await _saveLocalOnly(all);
  }

  static Future<AttendanceStatus?> getStatus({
    required DateTime date,
    required String playerId,
  }) async =>
      (await getAll())[buildKey(date, playerId)];

  static Future<Map<DateTime, AttendanceStatus>> getForPlayer(
      String playerId) async {
    final result = <DateTime, AttendanceStatus>{};
    (await getAll()).forEach((key, status) {
      final parsed = parseKey(key);
      if (parsed != null && parsed.playerId == playerId) {
        result[parsed.date] = status;
      }
    });
    return result;
  }

  static Future<Map<String, AttendanceStatus>> getForDate(DateTime date) async {
    final result = <String, AttendanceStatus>{};
    (await getAll()).forEach((key, status) {
      final parsed = parseKey(key);
      if (parsed != null && _isSameDay(parsed.date, date)) {
        result[parsed.playerId] = status;
      }
    });
    return result;
  }

  static Future<Set<int>> getEventDaysInMonth({
    required int year,
    required int month,
    String? playerId,
  }) async {
    final days = <int>{};
    (await getAll()).forEach((key, _) {
      final parsed = parseKey(key);
      if (parsed == null) return;
      if (playerId != null && parsed.playerId != playerId) return;
      if (parsed.date.year == year && parsed.date.month == month) {
        days.add(parsed.date.day);
      }
    });
    return days;
  }

  /// ⚠️ Used to DELETE the academy's attendance rows on the server. It is now
  /// local-cache only (same as clearLocal) so it can never wipe real data.
  static Future<void> clearAll() => clearLocal();

  static Future<void> clearLocal() async {
    _synced = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  // ---------------- local cache ----------------
  static Future<Map<String, AttendanceStatus>> _getLocalOnly() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey) ?? '';
    final map = <String, AttendanceStatus>{};
    for (final entry in raw.split(';')) {
      if (entry.isEmpty) continue;
      final first = entry.indexOf(':');
      if (first <= 0) continue;
      final second = entry.indexOf(':', first + 1);
      if (second <= 0) continue;
      final status =
          AttendanceStatusHelper.fromStorage(entry.substring(second + 1));
      if (status == null) continue;
      map[entry.substring(0, second)] = status;
    }
    return map;
  }

  static Future<void> _saveLocalOnly(
      Map<String, AttendanceStatus> attendance) async {
    final buffer = StringBuffer();
    attendance.forEach((key, value) => buffer.write('$key:${value.storageKey};'));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, buffer.toString());
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}