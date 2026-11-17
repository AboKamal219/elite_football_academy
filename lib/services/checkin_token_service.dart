// lib/services/checkin_token_service.dart
// Signed, expiring check-in tokens.
//   player phone : issue()  -> token shown as QR (valid 10 minutes)
//   coach phone  : scan()   -> ONE server call that verifies + records attendance
// Server side: database/04_qr_attendance.sql (issue_checkin_token / scan_attendance)

import 'package:supabase_flutter/supabase_flutter.dart';

enum ScanOutcome { recorded, already, error }

class ScanResult {
  final ScanOutcome outcome;
  final String? playerId;
  final String? name;
  final String? error; // invalid_token | token_expired | player_not_found | forbidden | network
  const ScanResult(this.outcome, {this.playerId, this.name, this.error});

  bool get ok => outcome != ScanOutcome.error;

  String get message {
    switch (outcome) {
      case ScanOutcome.recorded:
        return 'تم تسجيل حضور ${name ?? 'اللاعب'} ✅';
      case ScanOutcome.already:
        return '${name ?? 'اللاعب'} متسجل حاضر قبل كده';
      case ScanOutcome.error:
        switch (error) {
          case 'token_expired':
            return 'الكود منتهي. اطلب من اللاعب يفتح الكود من جديد';
          case 'invalid_token':
            return 'كود غير صالح (مش كود لاعب من التطبيق)';
          case 'player_not_found':
            return 'اللاعب مش موجود في الأكاديمية دي';
          case 'forbidden':
            return 'مفيش صلاحية لمسح الكود';
          case 'server_setup':
            return 'قاعدة البيانات مش جاهزة: شغّل FULL_SETUP.sql في Supabase';
          default:
            return 'تعذّر التسجيل. تأكد من الإنترنت';
        }
    }
  }
}

class CheckinTokenService {
  const CheckinTokenService._();

  static SupabaseClient get _db => Supabase.instance.client;

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Token for the QR shown on the player's phone.
  static Future<String> issue(String playerId) async {
    final res = await _db.rpc('issue_checkin_token', params: {'p_player': playerId});
    return res.toString();
  }

  /// Staff side: verifies signature + expiry + academy AND records "present".
  static Future<ScanResult> scan(String raw, DateTime date) async {
    try {
      final res = await _db.rpc('scan_attendance', params: {
        'p_token': raw.trim(),
        'p_date': _day(date),
      });
      final m = Map<String, dynamic>.from(res as Map);
      final outcome =
          m['result'] == 'already' ? ScanOutcome.already : ScanOutcome.recorded;
      return ScanResult(outcome,
          playerId: m['player_id'] as String?, name: m['name'] as String?);
    } on PostgrestException catch (e) {
      final msg = '${e.message} ${e.details ?? ''}';
      for (final k in const [
        'token_expired', 'invalid_token', 'player_not_found', 'forbidden'
      ]) {
        if (msg.contains(k)) return ScanResult(ScanOutcome.error, error: k);
      }
      if (e.code == '42501') return const ScanResult(ScanOutcome.error, error: 'forbidden');
      if (e.code == 'PGRST202' || e.code == '42883') {
        // function missing -> the SQL was not run
        return const ScanResult(ScanOutcome.error, error: 'server_setup');
      }
      return const ScanResult(ScanOutcome.error, error: 'network');
    } catch (_) {
      return const ScanResult(ScanOutcome.error, error: 'network');
    }
  }
}
