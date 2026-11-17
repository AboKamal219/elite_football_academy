// test/widget_test.dart
//
// ✅ FIX: الملف القديم كان قالب الـ Counter الافتراضي (بيستورد MyApp
// اللي مش موجود) وكان بيكسر `flutter analyze` و `flutter test`.
// دلوقتي اختبارات خفيفة لا تحتاج Supabase.

import 'package:flutter_test/flutter_test.dart';
import 'package:elite_football_academy/models/attendance_status.dart';
import 'package:elite_football_academy/models/player.dart';
import 'package:elite_football_academy/services/attendance_service.dart';

void main() {
  group('AttendanceService keys', () {
    test('buildKey / parseKey round-trip', () {
      final key = AttendanceService.buildKey(DateTime(2026, 3, 9), 'pl_1');
      expect(key, '2026-03-09:pl_1');
      final parsed = AttendanceService.parseKey(key);
      expect(parsed, isNotNull);
      expect(parsed!.playerId, 'pl_1');
      expect(parsed.date, DateTime(2026, 3, 9));
    });

    test('parseKey rejects malformed keys', () {
      expect(AttendanceService.parseKey('garbage'), isNull);
      expect(AttendanceService.parseKey(':x'), isNull);
    });
  });

  group('Player map', () {
    test('toMap emits snake_case and fromMap reads both styles', () {
      final p = Player.fromMap({
        'id': 'pl_1',
        'user_id': 'u1',
        'name': 'Test',
        'team_id': 't1',
        'team_name': 'U12',
        'yellow_cards': 2,
        'academy_id': 'a1',
      });
      final m = p.toMap();
      expect(m['team_id'], 't1');
      expect(m['yellow_cards'], 2);
      expect(m.containsKey('teamId'), isFalse);

      // legacy camelCase (old local cache) must still load
      final legacy = Player.fromMap({'id': 'x', 'teamId': 't9', 'yellowCards': 3});
      expect(legacy.teamId, 't9');
      expect(legacy.yellowCards, 3);
    });
  });

  group('AttendanceStatus storage', () {
    test('every status round-trips through storageKey', () {
      for (final s in AttendanceStatus.values) {
        expect(AttendanceStatusHelper.fromStorage(s.storageKey), s);
      }
    });
  });
}
