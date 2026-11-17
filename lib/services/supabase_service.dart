// lib/services/supabase_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// SUPABASE SERVICE — نقطة الاتصال الوحيدة
// ============================================================
class SupabaseService {
  // The anon key is a PUBLIC key by design (security comes from RLS).
  // Optionally override per build:  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dpuyjoxpbhyerkxbkzcq.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'sb_publishable_lhnqp-zVqzoarGkxtvk1hw_1GNCKLko',
  );

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static String _cachedAcademyId = '';
  static String Function()? _academyIdResolver;

  static void setAcademyIdResolver(String Function() resolver) {
    _academyIdResolver = resolver;
  }

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _initialized = true;
    } catch (e) {
      _initialized = false;
      if (kDebugMode) debugPrint('Supabase init failed: $e');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get authUser {
    if (!_initialized) return null;
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static bool get isLoggedIn => authUser != null;

  static String get academyId {
    try {
      final fromResolver = _academyIdResolver?.call();
      if (fromResolver != null && fromResolver.isNotEmpty) return fromResolver;
    } catch (_) {}
    return _cachedAcademyId;
  }

  static void setAcademyId(String id) => _cachedAcademyId = id;
  static void clearAcademyId() => _cachedAcademyId = '';

  // ============================================================
  // أكواد الأكاديمية — via RPC (the codes table is not readable directly)
  //   admin  -> sees all 3 | coach -> sees only the player code
  // ============================================================
  static Future<Map<String, String>?> getAcademyCodes() async {
    if (!_initialized || !isLoggedIn) return null;
    try {
      final res = await client.rpc('get_academy_codes');
      if (res is! Map) return null;
      return {
        'admin': (res['admin'] ?? '').toString(),
        'coach': (res['coach'] ?? '').toString(),
        'player': (res['player'] ?? '').toString(),
      };
    } catch (e) {
      if (kDebugMode) debugPrint('getAcademyCodes: $e');
      return null;
    }
  }

  /// roleType: 'admin' | 'coach' | 'player'. Returns the new code or null.
  static Future<String?> regenerateCode(String roleType) async {
    if (!_initialized || !isLoggedIn) return null;
    try {
      final res =
          await client.rpc('regenerate_academy_code', params: {'p_role': roleType});
      final code = res?.toString();
      return (code == null || code.isEmpty) ? null : code;
    } catch (e) {
      if (kDebugMode) debugPrint('regenerateCode: $e');
      return null;
    }
  }
}
