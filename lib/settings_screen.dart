// lib/settings_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import 'l10n/app_text.dart';
import 'academy_dashboard_screen.dart'
    show
        AppColors,
        AppImages,
        GlassCard,
        NetImage,
        DeviceType,
        deviceTypeOf;
import 'app_settings.dart';
import 'services/auth_service.dart';
import 'auth/login_screen.dart';
import 'profile_screen.dart';

// ============================================================
// SETTINGS SCREEN
// ============================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasChanges = false;

  AppSettings get _settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  // ✅ حفظ
  Future<void> _saveSettings() async {
    if (!mounted) return;
    setState(() => _hasChanges = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حفظ الإعدادات ✅',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _update(VoidCallback fn) {
    setState(() {
      fn();
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;

    return AppDirectionality(
      child: Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.background,
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              const _BackgroundGlow(),
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16)
                      .copyWith(top: 20, bottom: 32),
                  child: _SettingsBody(
                    // ✅ الإعدادات من AppSettings
                    pushNotifications: s.notifications,
                    autoSave: s.autoSave,
                    hapticFeedback: s.hapticFeedback,
                    hasChanges: _hasChanges,
                    onPushChanged: (v) {
                      s.setNotifications(v);
                      _update(() {});
                    },
                    onAutoSaveChanged: (v) {
                      s.setAutoSave(v);
                      _update(() {});
                    },
                    onHapticChanged: (v) {
                      s.setHapticFeedback(v);
                      _update(() {});
                    },
                    onSave: _saveSettings,
                    onLogout: () =>
                        _showLogoutDialog(context),
                    onDeleteAccount: () =>
                        _showDeleteAccountDialog(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AppDirectionality(
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.red.withOpacity(0.3)),
          ),
          title: const Text(
            'حذف الحساب',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'هيتم حذف حسابك وبياناتك نهائياً ومش هتقدر ترجعهم. متأكد؟',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final err = await AuthService.deleteAccount();
                if (!context.mounted) return;
                if (err == null) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      err == 'last_admin_has_members'
                          ? 'مينفعش تحذف حساب الأدمن وفيه أعضاء. احذف الأعضاء الأول.'
                          : 'حصل خطأ، حاول تاني',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    backgroundColor: AppColors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'حذف',
                style: TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AppDirectionality(
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppColors.red.withOpacity(0.3),
            ),
          ),
          title: const Text(
            'تسجيل الخروج',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'متأكد إنك عايز تسجل خروج؟',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await AuthService.logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'خروج',
                style: TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BACKGROUND GLOW
// ============================================================
class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000),
              Color(0xFF0A1428),
              Color(0xFF0D1B33),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BODY
// ============================================================
class _SettingsBody extends StatelessWidget {
  final bool pushNotifications;
  final bool autoSave;
  final bool hapticFeedback;
  final bool hasChanges;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onAutoSaveChanged;
  final ValueChanged<bool> onHapticChanged;
  final VoidCallback onSave;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const _SettingsBody({
    required this.pushNotifications,
    required this.autoSave,
    required this.hapticFeedback,
    required this.hasChanges,
    required this.onPushChanged,
    required this.onAutoSaveChanged,
    required this.onHapticChanged,
    required this.onSave,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(hasChanges: hasChanges, onSave: onSave),
        const SizedBox(height: 14),
        const _SettingsHero(),
        const SizedBox(height: 20),

        // ============ الحساب ============
        const _SettingsSectionTitle(
          title: 'الحساب',
          icon: Icons.person_rounded,
          color: AppColors.blue,
        ),
        const SizedBox(height: 10),
        _SettingsGroup(
          items: [
            _SettingItem(
              icon: Icons.person_outline_rounded,
              title: 'الملف الشخصي',
              subtitle: 'بياناتك الشخصية',
              type: _SettingType.navigate,
              color: AppColors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),
            _SettingItem(
              icon: Icons.lock_outline_rounded,
              title: 'الأمان',
              subtitle: 'كلمة المرور والتحقق',
              type: _SettingType.navigate,
              color: AppColors.green,
              onTap: () => _showSecuritySheet(context),
            ),
            _SettingItem(
              icon: Icons.privacy_tip_outlined,
              title: 'الخصوصية',
              subtitle: 'إعدادات الخصوصية',
              type: _SettingType.navigate,
              color: AppColors.purple,
              onTap: () => _showPrivacySheet(context),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ============ الإشعارات ============
        const _SettingsSectionTitle(
          title: 'الإشعارات',
          icon: Icons.notifications_rounded,
          color: AppColors.orange,
        ),
        const SizedBox(height: 10),
        _SettingsGroup(
          items: [
            _SettingItem(
              icon: Icons.notifications_active_rounded,
              title: 'إشعارات التطبيق',
              subtitle: 'تنبيهات فورية',
              type: _SettingType.toggle,
              color: AppColors.orange,
              value: pushNotifications,
              onToggle: onPushChanged,
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ============ عام ============
        const _SettingsSectionTitle(
          title: 'عام',
          icon: Icons.settings_rounded,
          color: AppColors.orange,
        ),
        const SizedBox(height: 10),
        _SettingsGroup(
          items: [
            _SettingItem(
              icon: Icons.save_rounded,
              title: 'الحفظ التلقائي',
              subtitle: 'حفظ تلقائي للبيانات',
              type: _SettingType.toggle,
              color: AppColors.green,
              value: autoSave,
              onToggle: onAutoSaveChanged,
            ),
            _SettingItem(
              icon: Icons.vibration_rounded,
              title: 'الاهتزاز اللمسي',
              subtitle: 'عند التفاعل',
              type: _SettingType.toggle,
              color: AppColors.purple,
              value: hapticFeedback,
              onToggle: onHapticChanged,
            ),
            // ✅ اللغة (عربي / English) — نفس مكوّن الـ select الموجود في التصميم
            _SettingItem(
              icon: Icons.language_rounded,
              title: 'اللغة',
              subtitle: AppSettings.instance.isArabic ? 'العربية' : 'English',
              type: _SettingType.select,
              color: AppColors.blue,
              onTap: () => _showLanguageSheet(context),
            ),
            _SettingItem(
              icon: Icons.help_outline_rounded,
              title: 'المساعدة والدعم',
              subtitle: 'الأسئلة الشائعة',
              type: _SettingType.navigate,
              color: AppColors.blue,
              onTap: () => _showHelpSheet(context),
            ),
            _SettingItem(
              icon: Icons.info_outline_rounded,
              title: 'عن التطبيق',
              subtitle: 'الإصدار 1.0.0',
              type: _SettingType.navigate,
              color: AppColors.gold,
              onTap: () => _showAboutSheet(context),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ============ زرار تسجيل الخروج ============
        _LogoutButton(onTap: onLogout),

        const SizedBox(height: 10),

        // ✅ حذف الحساب (الخصوصية بتوعد بيه)
        _DeleteAccountButton(onTap: onDeleteAccount),

        const SizedBox(height: 20),

        const _VersionFooter(),
      ],
    );
  }

  // ============================================================
  // Bottom Sheets
  // ============================================================
  void _showLanguageSheet(BuildContext context) {
    _showInfoSheet(
      context: context,
      title: 'اللغة',
      icon: Icons.language_rounded,
      color: AppColors.blue,
      children: const [
        _LanguageOption(value: 'العربية', label: 'العربية', hint: 'Arabic · RTL'),
        _LanguageOption(value: 'English', label: 'English', hint: 'الإنجليزية · LTR'),
      ],
    );
  }

  void _showSecuritySheet(BuildContext context) {
    _showInfoSheet(
      context: context,
      title: 'الأمان',
      icon: Icons.lock_outline_rounded,
      color: AppColors.green,
      children: const [
        _SheetBullet(
          icon: Icons.password_rounded,
          title: 'كلمة المرور',
          body: 'لازم تكون 6 أحرف على الأقل، ويُفضّل تحتوي على أرقام ورموز.',
        ),
        _SheetBullet(
          icon: Icons.devices_rounded,
          title: 'الأجهزة',
          body: 'مفيش أجهزة تانية مسجلة على حسابك حالياً.',
        ),
      ],
    );
  }

  void _showPrivacySheet(BuildContext context) {
    _showInfoSheet(
      context: context,
      title: 'الخصوصية',
      icon: Icons.privacy_tip_outlined,
      color: AppColors.purple,
      children: const [
        _SheetBullet(
          icon: Icons.visibility_off_rounded,
          title: 'إخفاء البيانات',
          body: 'بياناتك الشخصية مش بتظهر لأي حد غير الإدارة.',
        ),
        _SheetBullet(
          icon: Icons.share_rounded,
          title: 'مشاركة البيانات',
          body: 'إحنا مابنشاركش بياناتك مع أي طرف تالت.',
        ),
        _SheetBullet(
          icon: Icons.delete_outline_rounded,
          title: 'حذف الحساب',
          body: 'تقدر تطلب حذف حسابك نهائياً من الإعدادات.',
        ),
      ],
    );
  }

  void _showHelpSheet(BuildContext context) {
    _showInfoSheet(
      context: context,
      title: 'المساعدة والدعم',
      icon: Icons.help_outline_rounded,
      color: AppColors.blue,
      children: const [
        _SheetBullet(
          icon: Icons.quiz_rounded,
          title: 'الأسئلة الشائعة',
          body: 'هتلاقي إجابات لأكتر الأسئلة تكراراً في صفحة الدعم.',
        ),
        _SheetBullet(
          icon: Icons.support_agent_rounded,
          title: 'تواصل مع الدعم',
          body: 'support@elite.com — بنرد خلال 24 ساعة.',
        ),
      ],
    );
  }

  void _showAboutSheet(BuildContext context) {
    _showInfoSheet(
      context: context,
      title: 'عن التطبيق',
      icon: Icons.info_outline_rounded,
      color: AppColors.gold,
      children: const [
        _SheetBullet(
          icon: Icons.sports_soccer_rounded,
          title: 'Elite Football Academy',
          body: 'تطبيق إدارة أكاديمية كرة القدم — إصدار 1.0.0',
        ),
        _SheetBullet(
          icon: Icons.code_rounded,
          title: 'المطوّر',
          body: 'Developed by Joker © 2026',
        ),
        _SheetBullet(
          icon: Icons.description_rounded,
          title: 'الشروط والأحكام',
          body: 'باستخدامك للتطبيق، أنت موافق على الشروط وسياسة الخصوصية.',
        ),
      ],
    );
  }

  // ============================================================
  // Helper: Bottom Sheet موحّد
  // ============================================================
  void _showInfoSheet({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppDirectionality(
        child: DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.98),
                    border: Border(
                      top: BorderSide(
                        color: color.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 45,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withOpacity(0.15),
                                border: Border.all(color: color, width: 1.5),
                              ),
                              child: Icon(icon, color: color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: Colors.white.withOpacity(0.08),
                        height: 1,
                      ),
                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...children,
                              const SizedBox(height: 20),
                              // ✅ زرار إغلاق
                              SizedBox(
                                width: double.infinity,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(ctx),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [color, color.withOpacity(0.7)],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withOpacity(0.4),
                                            blurRadius: 14,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'تمام',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// LANGUAGE OPTION  (same look as _SheetBullet / glass cards)
// ============================================================
class _LanguageOption extends StatelessWidget {
  final String value; // value stored in AppSettings.language
  final String label;
  final String hint;

  const _LanguageOption({
    required this.value,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final selected = AppSettings.instance.language == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            AppSettings.instance.setLanguage(value);
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.blue.withOpacity(0.12)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.blue.withOpacity(0.6)
                    : Colors.white.withOpacity(0.10),
                width: selected ? 1.5 : 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Icon(
                    Icons.translate_rounded,
                    color: selected ? AppColors.blue : AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.blue,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SHEET BULLET
// ============================================================
class _SheetBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _SheetBullet({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            child: Icon(icon, color: AppColors.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TOP BAR
// ============================================================
class _TopBar extends StatelessWidget {
  final bool hasChanges;
  final VoidCallback onSave;

  const _TopBar({required this.hasChanges, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.white.withOpacity(0.06),
              shape: const CircleBorder(
                side: BorderSide(color: Colors.white12),
              ),
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.arrow_forward,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),

        const Spacer(),

        const Text(
          'الإعدادات',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        const Spacer(),

        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: hasChanges
                  ? AppColors.green.withOpacity(0.3)
                  : AppColors.green.withOpacity(0.1),
              shape: CircleBorder(
                side: BorderSide(
                  color: hasChanges
                      ? AppColors.green
                      : AppColors.green.withOpacity(0.3),
                ),
              ),
              child: InkWell(
                onTap: hasChanges ? onSave : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.check_rounded,
                    color: hasChanges
                        ? AppColors.green
                        : AppColors.green.withOpacity(0.4),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// HERO
// ============================================================
class _SettingsHero extends StatelessWidget {
  const _SettingsHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 140,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const NetImage(
              url: AppImages.coachStadium,
              fallbackIcon: Icons.sports_soccer,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.35),
                    AppColors.green.withOpacity(0.30),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.green.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              left: 20,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.green.withOpacity(0.25),
                      border: Border.all(
                        color: AppColors.green.withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الإعدادات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            shadows: const [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تخصيص تجربتك في التطبيق',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================
class _SettingsSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SettingsSectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SETTINGS GROUP
// ============================================================
enum _SettingType { toggle, navigate, select }

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final _SettingType type;
  final Color color;
  final bool? value;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.color,
    this.value,
    this.onToggle,
    this.onTap,
  });
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingItem> items;

  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _SettingTile(item: items[i]),
                if (i != items.length - 1)
                  Divider(
                    color: Colors.white.withOpacity(0.05),
                    height: 1,
                    indent: 60,
                    endIndent: 16,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final _SettingItem item;

  const _SettingTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.type == _SettingType.toggle ? null : item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.color.withOpacity(0.12),
                  border: Border.all(
                    color: item.color.withOpacity(0.4),
                  ),
                ),
                child: Icon(item.icon, color: item.color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.type != _SettingType.select) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.type == _SettingType.toggle &&
                  item.value != null &&
                  item.onToggle != null)
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: item.value!,
                    onChanged: item.onToggle,
                    activeColor: item.color,
                    activeTrackColor: item.color.withOpacity(0.4),
                    inactiveThumbColor: AppColors.textMuted,
                    inactiveTrackColor: Colors.white.withOpacity(0.08),
                  ),
                )
              else if (item.type == _SettingType.select)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: item.color.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: item.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more_rounded,
                        color: item.color,
                        size: 12,
                      ),
                    ],
                  ),
                )
              else
                const Icon(
                  Icons.chevron_left,
                  color: AppColors.textMuted,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOGOUT BUTTON
// ============================================================
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.red.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.red.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.logout_rounded,
                color: AppColors.red,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: AppColors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DELETE ACCOUNT BUTTON (same visual language as the logout button)
// ============================================================
class _DeleteAccountButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DeleteAccountButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.red.withOpacity(0.25),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.delete_outline_rounded,
                color: AppColors.red,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'حذف الحساب',
                style: TextStyle(
                  color: AppColors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// VERSION FOOTER
// ============================================================
class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.green.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.sports_soccer,
                  color: AppColors.green,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Elite Football Academy',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2026 — Developed by Joker | Version 1.0.0',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}