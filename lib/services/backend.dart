// lib/services/backend.dart
//
// Shared data-access layer used by every *_service.dart.
//
// Rules (this fixes the old "silent local fallback" bug):
//  * READS  : server first; on failure return the last cached copy (offline
//             read cache). Never throws, so screens never hang on a spinner.
//  * WRITES : server only. On failure a BackendException is thrown, so the
//             form dialogs (which already have try/catch) show the real error
//             instead of a fake "saved ✅" while nothing was stored.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class BackendException implements Exception {
  final String message;
  final Object? cause;
  const BackendException(this.message, [this.cause]);

  factory BackendException.from(Object e) {
    if (e is BackendException) return e;
    if (e is PostgrestException) {
      switch (e.code) {
        case '42501':
          return BackendException('مفيش صلاحية للعملية دي', e);
        case '23505':
          return BackendException('البيانات دي موجودة بالفعل', e);
        case '23503':
          return BackendException('العنصر مرتبط ببيانات تانية', e);
        case '23514':
        case '22P02':
        case '22007':
          return BackendException('قيمة غير صالحة', e);
      }
      return BackendException('حصل خطأ في السيرفر', e);
    }
    return BackendException('تعذّر الاتصال بالسيرفر، اتأكد من النت وحاول تاني', e);
  }

  @override
  String toString() => message;
}

class Repo {
  const Repo._();

  static bool get online =>
      SupabaseService.isInitialized && SupabaseService.isLoggedIn;

  static void _requireOnline() {
    if (!online) {
      throw const BackendException('لازم تكون مسجل دخول ومتصل بالنت');
    }
  }

  static Map<String, dynamic> clean(String table, Map<String, dynamic> row) {
    final out = Map<String, dynamic>.from(row);
    final aid = out['academy_id'];
    if (aid == null || (aid is String && aid.trim().isEmpty)) {
      out.remove('academy_id');
    }
    for (final k in const ['team_id', 'coach_id', 'user_id']) {
      if (table == 'standings' && k == 'team_id') continue;
      final v = out[k];
      if (v is String && v.trim().isEmpty) out[k] = null;
    }
    return out;
  }

  // ------------------------------------------------------------------
  // Local read-cache
  // ------------------------------------------------------------------
  static Future<void> _writeCache(
      String key, List<Map<String, dynamic>> rows) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(rows));
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> readCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
      final decoded = jsonDecode(raw) as List;
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // READ
  // ------------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> list(
    String table, {
    String? cacheKey,
    Map<String, Object> eq = const <String, Object>{},
    String? orderBy,
    bool ascending = true,
    bool throwOnError = false,
  }) async {
    if (online) {
      try {
        // 1. الفلترة
        var filter = SupabaseService.client.from(table).select();
        for (final e in eq.entries) {
          filter = filter.eq(e.key, e.value);
        }

        // 2. ✅ الحل: نستخدم PostgrestTransformBuilder كـ base
        //    (PostgrestFilterBuilder extends PostgrestTransformBuilder)
        final PostgrestTransformBuilder<List<Map<String, dynamic>>> base =
            orderBy != null
                ? filter.order(orderBy, ascending: ascending)
                : filter;

        // 3. الـ paging loop (مفيش order جواه = مفيش تراكم)
        const pageSize = 1000;
        final List<dynamic> data = <dynamic>[];
        for (var from = 0;; from += pageSize) {
          final to = from + pageSize - 1;
          final List<dynamic> chunk = await base.range(from, to);
          data.addAll(chunk);
          if (chunk.length < pageSize) break;
        }

        final rows =
            data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (cacheKey != null) await _writeCache(cacheKey, rows);
        return rows;
      } catch (e) {
        if (kDebugMode) debugPrint('[Repo.list:$table] $e');
        if (throwOnError) throw BackendException.from(e);
      }
    } else if (throwOnError) {
      throw const BackendException('لازم تكون مسجل دخول ومتصل بالنت');
    }

    if (cacheKey == null) return <Map<String, dynamic>>[];
    return await readCache(cacheKey);
  }

  /// One row by equality filters (server first, then cache scan).
  static Future<Map<String, dynamic>?> one(
    String table,
    Map<String, Object> match, {
    String? cacheKey,
  }) async {
    if (online) {
      try {
        var q = SupabaseService.client.from(table).select();
        for (final e in match.entries) {
          q = q.eq(e.key, e.value);
        }
        final data = await q.limit(1).maybeSingle();
        if (data != null) return Map<String, dynamic>.from(data);
        return null;
      } catch (e) {
        if (kDebugMode) debugPrint('[Repo.one:$table] $e');
      }
    }
    if (cacheKey == null) return null;
    for (final row in await readCache(cacheKey)) {
      var ok = true;
      for (final e in match.entries) {
        if (row[e.key]?.toString() != e.value.toString()) {
          ok = false;
          break;
        }
      }
      if (ok) return row;
    }
    return null;
  }

  // ------------------------------------------------------------------
  // WRITE
  // ------------------------------------------------------------------
  static Future<void> insert(String table, Map<String, dynamic> row) async {
    _requireOnline();
    try {
      await SupabaseService.client.from(table).insert(clean(table, row));
    } catch (e) {
      throw BackendException.from(e);
    }
  }

  static Future<void> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    required String onConflict,
    int batchSize = 100,
  }) async {
    if (rows.isEmpty) return;
    _requireOnline();
    try {
      for (var i = 0; i < rows.length; i += batchSize) {
        final end = (i + batchSize < rows.length) ? i + batchSize : rows.length;
        final batch = rows.sublist(i, end).map((r) => clean(table, r)).toList();
        await SupabaseService.client
            .from(table)
            .upsert(batch, onConflict: onConflict);
      }
    } catch (e) {
      throw BackendException.from(e);
    }
  }

  static Future<void> update(
    String table,
    Map<String, dynamic> row,
    Map<String, Object> match,
  ) async {
    _requireOnline();
    try {
      var q = SupabaseService.client.from(table).update(clean(table, row));
      for (final e in match.entries) {
        q = q.eq(e.key, e.value);
      }
      final res = await q.select();
      if (res.isEmpty) {
        throw const BackendException('العنصر مش موجود أو مفيش صلاحية تعديله');
      }
    } on BackendException {
      rethrow;
    } catch (e) {
      throw BackendException.from(e);
    }
  }

  static Future<void> delete(String table, Map<String, Object> match) async {
    _requireOnline();
    try {
      var q = SupabaseService.client.from(table).delete();
      for (final e in match.entries) {
        q = q.eq(e.key, e.value);
      }
      final res = await q.select();
      if (res.isEmpty) {
        throw const BackendException('العنصر مش موجود أو مفيش صلاحية حذفه');
      }
    } on BackendException {
      rethrow;
    } catch (e) {
      throw BackendException.from(e);
    }
  }
}