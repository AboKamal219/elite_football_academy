// lib/l10n/app_text.dart
//
// ============================================================
// LOCALIZATION CORE  (Arabic <-> English, instant, no restart)
// ============================================================
// The app's source language is Arabic. When the user picks English:
//   * every `Text(...)` is translated at build time through [L10n.tr]
//     (dictionary lookup -> templates -> word-boundary fallback, memoised),
//   * form fields / hints / validator messages go through [L10n.trN],
//   * [AppDirectionality] flips the layout to LTR.
//
// `Text` below SHADOWS Flutter's Text. Files import material.dart with
// `hide Text` and import this file instead, so every existing
// `const Text('...')` keeps compiling (the constructor is const) and
// the visual output in Arabic mode is byte-for-byte the same widget.
//
// Rebuild on language change: [Text] and [AppDirectionality] both depend on
// `Localizations` (MaterialApp(locale:) changes when AppSettings changes), so
// Flutter rebuilds them automatically — even inside const subtrees.

import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart' hide Text;
import '../app_settings.dart';
import 'en_dictionary.dart';

class _Tpl {
  final RegExp re;
  final String en;
  _Tpl(this.re, this.en);
}

class L10n {
  L10n._();

  static bool get isArabic => AppSettings.instance.isArabic;
  static TextDirection get dir =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  static final RegExp _hasArabic = RegExp(r'[\u0600-\u06FF]');
  static final RegExp _time = RegExp(r'^(\d{1,2}:\d{2})\s*([صم])$');
  static final Map<String, String> _memo = <String, String>{};
  static List<_Tpl>? _tpls;
  static RegExp? _words;

  /// Translate [s] (Arabic source) for the current language.
  static String tr(String s) {
    if (isArabic || s.isEmpty || !_hasArabic.hasMatch(s)) return s;
    return _memo.putIfAbsent(s, () => _translate(s));
  }

  /// Nullable variant (hintText, errorText, tooltip …).
  static String? trN(String? s) => s == null ? null : tr(s);

  static String _translate(String s) {
    final exact = kEn[s];
    if (exact != null) return exact;

    final trimmed = s.trim();
    if (trimmed.isNotEmpty && trimmed != s) {
      final e = kEn[trimmed];
      if (e != null) return s.replaceFirst(trimmed, e);
    }

    final tm = _time.firstMatch(s);
    if (tm != null) {
      return '${tm.group(1)} ${tm.group(2) == 'ص' ? 'AM' : 'PM'}';
    }

    _tpls ??= kEnTemplates.map((t) => _Tpl(RegExp(t[0]), t[1])).toList();
    for (final t in _tpls!) {
      final mt = t.re.firstMatch(s);
      if (mt == null) continue;
      var out = t.en;
      for (var i = 1; i <= mt.groupCount; i++) {
        out = out.replaceFirst('{}', tr(mt.group(i) ?? ''));
      }
      return out;
    }

    return _byWords(s);
  }

  /// Replaces known phrases that sit on word boundaries (Arabic letters on
  /// either side forbid a match, so "لاعب" never rewrites "لاعبين").
  static String _byWords(String s) {
    if (_words == null) {
      final keys = kEn.keys.where((k) => k.length >= 2).toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      _words = RegExp(
        '(?<![\\u0600-\\u06FF])(?:${keys.map(RegExp.escape).join('|')})(?![\\u0600-\\u06FF])',
      );
    }
    return s.replaceAllMapped(_words!, (mt) => kEn[mt.group(0)!] ?? mt.group(0)!);
  }
}

// ============================================================
// Text  (drop-in replacement for Flutter's Text)
// ============================================================
class Text extends StatelessWidget {
  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  const Text(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  const Text.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  @override
  Widget build(BuildContext context) {
    // dependency => rebuilt when the app language changes
    Localizations.maybeLocaleOf(context);

    if (textSpan != null) {
      return m.Text.rich(
        textSpan!,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }
    return m.Text(
      L10n.tr(data!),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel == null ? null : L10n.tr(semanticsLabel!),
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

// ============================================================
// AppDirectionality — replaces `Directionality(textDirection: rtl, …)`
// ============================================================
class AppDirectionality extends StatelessWidget {
  final Widget child;
  const AppDirectionality({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    Localizations.maybeLocaleOf(context); // rebuild on language change
    return Directionality(textDirection: L10n.dir, child: child);
  }
}
