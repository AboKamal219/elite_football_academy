// lib/services/notification_service.dart
//
// "Unread" is now PER USER (table notification_reads). Before, a single
// is_unread flag was shared, so one person opening a notification marked it
// read for the whole academy.

import '../models/notification.dart';
import 'backend.dart';
import 'supabase_service.dart';

class NotificationService {
  static const String _key = 'notifications_data';
  static const String _readKey = 'notification_reads_data';

  static String? get _uid => SupabaseService.authUser?.id;

  static Future<Set<String>> _readIds() async {
    final uid = _uid;
    if (uid == null) return <String>{};
    final rows = await Repo.list('notification_reads',
        cacheKey: _readKey, eq: <String, Object>{'user_id': uid});
    return rows.map((r) => (r['notification_id'] ?? '').toString()).toSet();
  }

  static Future<List<AppNotification>> getAll({String? academyId}) async {
    final aid = academyId ?? SupabaseService.academyId;
    final rows = await Repo.list(
      'notifications',
      cacheKey: _key,
      eq: aid.isEmpty ? <String, Object>{} : <String, Object>{'academy_id': aid},
      orderBy: 'created_at',
      ascending: false,
    );
    final read = await _readIds();
    return rows
        .map(AppNotification.fromMap)
        .map((n) => n.copyWith(isUnread: !read.contains(n.id)))
        .toList();
  }

  static Future<int> getUnreadCount() async =>
      (await getAll()).where((n) => n.isUnread).length;

  static Future<List<AppNotification>> getUnread() async =>
      (await getAll()).where((n) => n.isUnread).toList();

  static Future<List<AppNotification>> getByCategory(
      NotificationCategory category) async {
    final all = await getAll();
    return all.where((n) => n.category == category).toList();
  }

  static Future<void> markAsRead(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await Repo.upsert(
      'notification_reads',
      [
        {'notification_id': id, 'user_id': uid}
      ],
      onConflict: 'notification_id,user_id',
    );
  }

  static Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null) return;
    final unread = await getUnread();
    if (unread.isEmpty) return;
    await Repo.upsert(
      'notification_reads',
      unread
          .map((n) => <String, dynamic>{'notification_id': n.id, 'user_id': uid})
          .toList(),
      onConflict: 'notification_id,user_id',
    );
  }

  static Future<void> add(AppNotification n) =>
      Repo.insert('notifications', n.toMap());

  static Future<void> delete(String id) =>
      Repo.delete('notifications', {'id': id});

  static Future<void> clearAll() async {
    await Repo.clearCache(_key);
    await Repo.clearCache(_readKey);
  }
}
