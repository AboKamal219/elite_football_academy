// tool/wipe_all.dart — يمسح كل شيء بأمر واحد (للاستخدام مرة واحدة قبل الإطلاق الحقيقي)
//
// بيعمل:
//   1) يشغّل الدالة public.admin_wipe_all() في Supabase  → كل بيانات الجداول + كل الحسابات + سجل الدخول
//   2) يمسح كل الملفات من كل buckets في Storage (صور البروفايل وغيرها)
//
// التشغيل (PowerShell، من مجلد المشروع):
//   $env:SUPABASE_URL="https://xxxx.supabase.co"
//   $env:SUPABASE_SERVICE_KEY="مفتاح service_role"      # Project Settings > API
//   dart run tool/wipe_all.dart
//
// ⚠️ مفتاح service_role قوي جداً: لا تحطه في التطبيق ولا ترفعه على GitHub.
// ⚠️ لا رجعة فيه. لتخطي سؤال التأكيد: dart run tool/wipe_all.dart --yes

import 'dart:convert';
import 'dart:io';

class _Res {
  final int status;
  final String body;
  _Res(this.status, this.body);
}

late String _url;
late String _key;
final HttpClient _http = HttpClient();

Future<_Res> _call(String method, String path, [Object? body]) async {
  final req = await _http.openUrl(method, Uri.parse('$_url$path'));
  req.headers.set('apikey', _key);
  req.headers.set('Authorization', 'Bearer $_key');
  req.headers.contentType = ContentType.json;
  if (body != null) req.add(utf8.encode(jsonEncode(body)));
  final res = await req.close();
  final text = await res.transform(utf8.decoder).join();
  return _Res(res.statusCode, text);
}

/// كل الملفات داخل bucket (بيدخل في المجلدات)
Future<List<String>> _listFiles(String bucket, String prefix) async {
  final files = <String>[];
  var offset = 0;
  while (true) {
    final r = await _call('POST', '/storage/v1/object/list/$bucket', {
      'prefix': prefix,
      'limit': 100,
      'offset': offset,
      'sortBy': {'column': 'name', 'order': 'asc'},
    });
    if (r.status != 200) {
      throw 'تعذّر قراءة الملفات ($bucket): ${r.status} ${r.body}';
    }
    final items = jsonDecode(r.body) as List<dynamic>;
    for (final it in items) {
      final name = (it as Map<String, dynamic>)['name'] as String;
      final path = prefix.isEmpty ? name : '$prefix/$name';
      if (it['id'] == null) {
        files.addAll(await _listFiles(bucket, path)); // مجلد
      } else {
        files.add(path);
      }
    }
    if (items.length < 100) break;
    offset += 100;
  }
  return files;
}

Future<void> main(List<String> args) async {
  _url = (Platform.environment['SUPABASE_URL'] ?? '').replaceAll(RegExp(r'/+$'), '');
  _key = Platform.environment['SUPABASE_SERVICE_KEY'] ?? '';
  if (_url.isEmpty || _key.isEmpty) {
    stderr.writeln('لازم تحدد SUPABASE_URL و SUPABASE_SERVICE_KEY (اقرأ أول الملف).');
    exit(2);
  }

  if (!args.contains('--yes')) {
    stdout.writeln('⚠️  هيتم مسح كل البيانات والحسابات والصور من:\n    $_url');
    stdout.write('اكتب DELETE ALL للتأكيد: ');
    if (stdin.readLineSync()?.trim() != 'DELETE ALL') {
      stdout.writeln('اتلغى. ماتمسحش حاجة.');
      exit(1);
    }
  }

  // 1) قاعدة البيانات + الحسابات
  stdout.writeln('1/2 مسح قاعدة البيانات والحسابات...');
  final db = await _call('POST', '/rest/v1/rpc/admin_wipe_all', <String, dynamic>{});
  if (db.status == 404) {
    stderr.writeln('الدالة مش موجودة. شغّل database/09_admin_wipe_function.sql في Supabase الأول.');
    exit(3);
  }
  if (db.status != 200) {
    stderr.writeln('فشل مسح قاعدة البيانات: ${db.status} ${db.body}');
    exit(4);
  }
  stdout.writeln('    تم ✅');

  // 2) ملفات Storage (كل الـ buckets)
  stdout.writeln('2/2 مسح ملفات Storage...');
  final b = await _call('GET', '/storage/v1/bucket');
  if (b.status != 200) {
    stderr.writeln('تعذّر قراءة الـ buckets: ${b.status} ${b.body}');
    exit(5);
  }
  var total = 0;
  for (final bucket in jsonDecode(b.body) as List<dynamic>) {
    final id = (bucket as Map<String, dynamic>)['id'] as String;
    final files = await _listFiles(id, '');
    for (var i = 0; i < files.length; i += 100) {
      final chunk = files.sublist(i, i + 100 > files.length ? files.length : i + 100);
      final d = await _call('DELETE', '/storage/v1/object/$id', {'prefixes': chunk});
      if (d.status != 200) {
        stderr.writeln('تعذّر مسح ملفات $id: ${d.status} ${d.body}');
        exit(6);
      }
    }
    total += files.length;
    stdout.writeln('    $id: ${files.length} ملف');
  }
  stdout.writeln('    تم ✅ ($total ملف)');

  stdout.writeln('\nخلصنا ✅ المشروع فاضي وجاهز.');
  stdout.writeln('فاضل خطوة واحدة على كل تليفون جرّب عليه: امسح التطبيق أو "مسح البيانات" من إعدادات الأندرويد.');
  _http.close();
}
