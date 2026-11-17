import '../l10n/app_text.dart';
// lib/utils/validators.dart

// ============================================================
// VALIDATORS — validation موحّد للتطبيق كله
// ============================================================

class Validators {
  Validators._(); // منع الإنشاء

  // ============================================================
  // الباسوردات الشائعة الضعيفة
  // ============================================================
  static const List<String> _weakPasswords = [
    '123456',
    '1234567',
    '12345678',
    '123456789',
    '1234567890',
    'password',
    'password1',
    'password123',
    'qwerty',
    'qwerty123',
    '111111',
    '11111111',
    '000000',
    'abcdef',
    'abcdefgh',
    'admin',
    'admin123',
    'welcome',
    'letmein',
    'iloveyou',
    'monkey',
    'dragon',
  ];

  // ============================================================
  // REGEX
  // ============================================================
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _hasUpper = RegExp(r'[A-Z]');
  static final RegExp _hasLower = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'[0-9]');
  static final RegExp _hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=]');
  static final RegExp _hasArabic = RegExp(r'[\u0600-\u06FF]');
  static final RegExp _hasSpaces = RegExp(r'\s');

  // ============================================================
  // الاسم
  // ============================================================
  /// بيرجع `null` لو سليم — أو رسالة الخطأ
  static String? name(String? value) {
    final v = (value ?? '').trim();

    if (v.isEmpty) return L10n.tr('الاسم مطلوب');
    if (v.length < 2) return L10n.tr('الاسم قصير جدًا');
    if (v.length > 50) return L10n.tr('الاسم طويل جدًا');

    return null;
  }

  // ============================================================
  // الإيميل
  // ============================================================
  static String? email(String? value) {
    final v = (value ?? '').trim();

    if (v.isEmpty) return L10n.tr('الإيميل مطلوب');
    if (!_emailRegex.hasMatch(v)) return L10n.tr('الإيميل مش صحيح');
    if (v.length > 100) return L10n.tr('الإيميل طويل جدًا');

    // The account must receive a REAL verification code, so common typos and
    // throw-away inboxes are rejected up-front (Gmail is recommended).
    final domain = v.split('@').last.toLowerCase();
    const typos = <String, String>{
      'gmial.com': 'gmail.com',
      'gmai.com': 'gmail.com',
      'gamil.com': 'gmail.com',
      'gmail.con': 'gmail.com',
      'gmail.co': 'gmail.com',
      'gmil.com': 'gmail.com',
      'hotmial.com': 'hotmail.com',
      'yaho.com': 'yahoo.com',
      'yahooo.com': 'yahoo.com',
    };
    final fix = typos[domain];
    if (fix != null) return L10n.tr('هل تقصد @$fix ؟');
    const disposable = <String>{
      'mailinator.com',
      '10minutemail.com',
      'guerrillamail.com',
      'tempmail.com',
      'temp-mail.org',
      'yopmail.com',
      'trashmail.com',
      'sharklasers.com',
      'getnada.com',
    };
    if (disposable.contains(domain)) {
      return L10n.tr('استخدم إيميل حقيقي (يفضّل Gmail) عشان توصلك رسالة التفعيل');
    }

    return null;
  }

  // ============================================================
  // رقم التليفون (اختياري)
  // ============================================================
  static String? phone(String? value) {
    final v = (value ?? '').trim();

    if (v.isEmpty) return null; // اختياري

    // نقبل + وأرقام ومسافات وشرطات
    final cleaned = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return L10n.tr('رقم التليفون مش صحيح');
    }

    return null;
  }

  // ============================================================
  // الباسورد القوي
  // ============================================================
  /// المعايير:
  /// - 8 أحرف على الأقل
  /// - حرف كبير (A-Z)
  /// - حرف صغير (a-z)
  /// - رقم (0-9)
  /// - مش من قائمة الباسوردات الضعيفة
  /// - مفيش مسافات
  static String? password(String? value) {
    final v = value ?? '';

    if (v.isEmpty) return L10n.tr('الباسورد مطلوب');
    if (v.length < 8) return L10n.tr('الباسورد لازم 8 أحرف على الأقل');
    if (v.length > 64) return L10n.tr('الباسورد طويل جدًا');

    if (_hasSpaces.hasMatch(v)) {
      return L10n.tr('الباسورد مش ممكن يحتوي على مسافات');
    }

    if (!_hasUpper.hasMatch(v)) {
      return L10n.tr('الباسورد لازم يحتوي على حرف كبير (A-Z)');
    }

    if (!_hasLower.hasMatch(v)) {
      return L10n.tr('الباسورد لازم يحتوي على حرف صغير (a-z)');
    }

    if (!_hasDigit.hasMatch(v)) {
      return L10n.tr('الباسورد لازم يحتوي على رقم (0-9)');
    }

    if (_weakPasswords.contains(v.toLowerCase())) {
      return L10n.tr('الباسورد ده ضعيف جدًا، اختار حاجة أقوى');
    }

    return null;
  }

  // ============================================================
  // تأكيد الباسورد
  // ============================================================
  static String? confirmPassword(String? value, String original) {
    final v = value ?? '';

    if (v.isEmpty) return L10n.tr('تأكيد الباسورد مطلوب');
    if (v != original) return L10n.tr('الباسورد مش متطابق');

    return null;
  }

  // ============================================================
  // الباسورد مش زي الإيميل
  // ============================================================
  static String? passwordNotEmail(String? value, String email) {
    final v = (value ?? '').trim();
    final e = email.trim();

    if (v.isEmpty || e.isEmpty) return null;
    if (v.toLowerCase() == e.toLowerCase()) {
      return L10n.tr('الباسورد مش ممكن يكون نفس الإيميل');
    }

    return null;
  }

  // ============================================================
  // الباسورد مش زي الاسم
  // ============================================================
  static String? passwordNotName(String? value, String name) {
    final v = (value ?? '').trim();
    final n = name.trim();

    if (v.isEmpty || n.isEmpty) return null;
    if (v.toLowerCase() == n.toLowerCase()) {
      return L10n.tr('الباسورد مش ممكن يكون نفس الاسم');
    }

    return null;
  }

  // ============================================================
  // الباسورد الجديد مختلف عن القديم
  // ============================================================
  static String? passwordDifferent(String? value, String oldPassword) {
    final v = value ?? '';

    if (v.isEmpty || oldPassword.isEmpty) return null;
    if (v == oldPassword) {
      return L10n.tr('الباسورد الجديد لازم يكون مختلف عن القديم');
    }

    return null;
  }

  // ============================================================
  // قوة الباسورد (0.0 → 1.0) — للعرض
  // ============================================================
  static double passwordStrength(String password) {
    if (password.isEmpty) return 0.0;

    double score = 0.0;

    if (password.length >= 8) score += 0.25;
    if (password.length >= 12) score += 0.15;
    if (_hasUpper.hasMatch(password)) score += 0.15;
    if (_hasLower.hasMatch(password)) score += 0.15;
    if (_hasDigit.hasMatch(password)) score += 0.15;
    if (_hasSpecial.hasMatch(password)) score += 0.15;

    // خصم لو فيه باسورد ضعيف
    if (_weakPasswords.contains(password.toLowerCase())) score = 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// بيرجع: 'weak' / 'medium' / 'strong'
  static String passwordLabel(String password) {
    final s = passwordStrength(password);
    if (s < 0.5) return L10n.tr('ضعيف');
    if (s < 0.8) return L10n.tr('متوسط');
    return L10n.tr('قوي');
  }

  // ============================================================
  // نص عربي (اختياري — لو محتاجه)
  // ============================================================
  static String? arabicOnly(String? value) {
    final v = (value ?? '').trim();

    if (v.isEmpty) return L10n.tr('مطلوب');
    if (!_hasArabic.hasMatch(v)) {
      return L10n.tr('لازم يحتوي على حروف عربية');
    }

    return null;
  }

  // ============================================================
  // طول النص (عام)
  // ============================================================
  static String? minLength(String? value, int min, {String? label}) {
    final v = (value ?? '').trim();
    final l = label ?? 'الحقل';

    if (v.isEmpty) return L10n.tr('$l مطلوب');
    if (v.length < min) return L10n.tr('$l لازم $min أحرف على الأقل');

    return null;
  }

  static String? maxLength(String? value, int max, {String? label}) {
    final v = (value ?? '').trim();
    final l = label ?? 'الحقل';

    if (v.isEmpty) return L10n.tr('$l مطلوب');
    if (v.length > max) return L10n.tr('$l لازم $max أحرف كحد أقصى');

    return null;
  }

  static String? required(String? value, {String? label}) {
    final v = (value ?? '').trim();
    final l = label ?? 'الحقل';

    if (v.isEmpty) return L10n.tr('$l مطلوب');
    return null;
  }
}