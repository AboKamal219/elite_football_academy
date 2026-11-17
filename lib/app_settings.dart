// lib/app_settings.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// APP SETTINGS — Global State (ChangeNotifier)
// ============================================================
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const String _kDarkMode = 'dark_mode_enabled';
  static const String _kLanguage = 'language';
  static const String _kNotifications = 'notifications_enabled';
  static const String _kFontSize = 'font_size';
  static const String _kAutoSave = 'auto_save_enabled';       // ✅ جديد
  static const String _kHapticFeedback = 'haptic_feedback_enabled'; // ✅ جديد

  bool _darkMode = true;
  String _language = 'العربية';
  bool _notifications = true;
  String _fontSize = 'متوسط';
  bool _autoSave = true;          // ✅ جديد
  bool _hapticFeedback = true;    // ✅ جديد

  bool get darkMode => _darkMode;
  String get language => _language;
  bool get notifications => _notifications;
  String get fontSize => _fontSize;
  bool get autoSave => _autoSave;              // ✅ جديد
  bool get hapticFeedback => _hapticFeedback;  // ✅ جديد

  bool get isArabic => _language == 'العربية';

  Locale get currentLocale =>
      isArabic ? const Locale('ar', 'EG') : const Locale('en', 'US');

  ThemeMode get currentThemeMode =>
      _darkMode ? ThemeMode.dark : ThemeMode.light;

  // ✅ helper: مضاعف حجم الخط
  double get fontScale {
    switch (_fontSize) {
      case 'صغير':
        return 0.9;
      case 'كبير':
        return 1.15;
      case 'متوسط':
      default:
        return 1.0;
    }
  }

  // ============================================================
  // تحميل الإعدادات (تتنادى في main)
  // ============================================================
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_kDarkMode) ?? true;
    _language = prefs.getString(_kLanguage) ?? 'العربية';
    _notifications = prefs.getBool(_kNotifications) ?? true;
    _fontSize = prefs.getString(_kFontSize) ?? 'متوسط';
    _autoSave = prefs.getBool(_kAutoSave) ?? true;              // ✅ جديد
    _hapticFeedback = prefs.getBool(_kHapticFeedback) ?? true;  // ✅ جديد
    notifyListeners();
  }

  // ============================================================
  // تحديث الإعدادات
  // ============================================================
  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, value);
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, value);
  }

  Future<void> setNotifications(bool value) async {
    _notifications = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifications, value);
  }

  Future<void> setFontSize(String value) async {
    _fontSize = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFontSize, value);
  }

  // ✅ جديد
  Future<void> setAutoSave(bool value) async {
    _autoSave = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoSave, value);
  }

  // ✅ جديد
  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHapticFeedback, value);
  }
}