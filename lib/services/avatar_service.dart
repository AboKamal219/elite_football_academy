// lib/services/avatar_service.dart
// Private avatars: store PATHS in the DB, show them through short-lived signed URLs.

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarService {
  const AvatarService._();
  static SupabaseClient get _db => Supabase.instance.client;
  static const _bucket = 'avatars';
  static final Map<String, ({String url, DateTime exp})> _cache = {};

  /// Accepts a path or an old public URL and returns the object path.
  static String? toPath(String? stored) {
    if (stored == null || stored.trim().isEmpty) return null;
    final m = RegExp(r'/storage/v1/object/(?:public|sign)/avatars/([^?]+)').firstMatch(stored);
    if (m != null) return Uri.decodeComponent(m.group(1)!);
    if (stored.startsWith('http')) return null; // external image, not ours
    return stored;
  }

  static Future<String?> signedUrl(String? stored) async {
    final path = toPath(stored);
    if (path == null) return stored != null && stored.startsWith('http') ? stored : null;
    final hit = _cache[path];
    if (hit != null && hit.exp.isAfter(DateTime.now())) return hit.url;
    try {
      final url = await _db.storage.from(_bucket).createSignedUrl(path, 3600);
      _cache[path] = (url: url, exp: DateTime.now().add(const Duration(minutes: 50)));
      return url;
    } catch (_) {
      return null;
    }
  }

  /// [folder]: 'users/<uid>' for own photo, 'players' for staff uploading a player photo.
  /// Returns the PATH to store in users.photo / players.photo.
  static Future<String> upload({
    required XFile picked,
    required String academyId,
    required String folder,
    String? previousStored,
  }) async {
    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > 2 * 1024 * 1024) throw Exception('image_too_large');
    final name = picked.name.toLowerCase();
    final ext = name.endsWith('.png') ? 'png' : name.endsWith('.webp') ? 'webp' : 'jpg';
    final mime = ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg';
    
    // --- التعديل هنا: إضافة معرف المستخدم الحالي ليتوافق مع سياسات الـ RLS ---
    final userId = _db.auth.currentUser!.id;
    final path = '$userId/$academyId/$folder/${DateTime.now().millisecondsSinceEpoch}.$ext';
    
    await _db.storage.from(_bucket).uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
    final old = toPath(previousStored);
    if (old != null && old != path) {
      try { await _db.storage.from(_bucket).remove([old]); } catch (_) {}
    }
    return path;
  }
}
