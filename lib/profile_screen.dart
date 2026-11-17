// lib/profile_screen.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Text;
import 'l10n/app_text.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'academy_dashboard_screen.dart'
    show
        AppColors,
        AppImages,
        GlassCard,
        NetImage,
        DeviceType,
        deviceTypeOf;
import 'models/app_user.dart';
import 'models/match.dart';
import 'models/player.dart';
import 'models/training.dart';
import 'app_settings.dart';
import 'services/auth_service.dart';
import 'services/coach_service.dart';
import 'services/match_service.dart';
import 'services/player_service.dart';
import 'services/team_service.dart';
import 'services/training_service.dart';
import 'services/supabase_service.dart';
import 'auth/login_screen.dart';
import 'player_qr_screen.dart';
import 'utils/validators.dart';

// ============================================================
// PROFILE SCREEN
// ============================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _teamsCount = 0;
  int _coachesCount = 0;
  int _playersCount = 0;
  String _avgRating = '0.0';
  bool _loadingStats = true;

  // إحصائيات اللاعب الشخصية
  int _myGoals = 0;
  int _myAssists = 0;
  int _myMatches = 0;
  String _myRating = '0.0';

  Map<String, String>? _academyCodes;
  bool _loadingCode = true;

  final ImagePicker _picker = ImagePicker();

  AppSettings get _settings => AppSettings.instance;
  AppUser? get _user => AuthService.currentUser;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadAcademyCodes();
    _settings.addListener(_refresh);
  }

  @override
  void dispose() {
    _settings.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAcademyCodes() async {
    final user = _user;
    if (user == null) {
      if (mounted) setState(() => _loadingCode = false);
      return;
    }

    if (user.role == UserRole.player) {
      if (mounted) setState(() => _loadingCode = false);
      return;
    }

    try {
      final codes = await SupabaseService.getAcademyCodes();
      if (!mounted) return;
      setState(() {
        _academyCodes = codes;
        _loadingCode = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCode = false);
    }
  }

  Future<void> _regenerateCode(String roleType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDirectionality(
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.orange.withOpacity(0.4)),
          ),
          title: const Text(
            'تأكيد تغيير الكود',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'لو غيرت الكود، أي حد معاه الكود القديم مش هيعرف يسجل بيه. اللي سجلوا بيه قبل كده مش هيتأثروا.\n\nمتأكد؟',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'تغيير',
                style: TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    final newCode = await SupabaseService.regenerateCode(roleType);
    if (!mounted) return;

    if (newCode != null) {
      _loadAcademyCodes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم توليد كود جديد ✅',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حصل خطأ، حاول تاني',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadStats() async {
    try {
      final user = _user;
      if (user == null) {
        if (mounted) setState(() => _loadingStats = false);
        return;
      }

      if (user.role == UserRole.player) {
        // ✅ للاعب: نقرأ بياناته الشخصية
        final me = await PlayerService.getPlayerByUserId(user.id);
        if (!mounted) return;
        setState(() {
          _myGoals = me?.goals ?? 0;
          _myAssists = me?.assists ?? 0;
          _myMatches = me?.matches ?? 0;
          _myRating = me?.rating ?? '0.0';
          _loadingStats = false;
        });
      } else {
        // ✅ للأدمن/المدرب: نقرأ بيانات الأكاديمية
        final teams = await TeamService.getAllTeams();
        final coaches = await CoachService.getAllCoaches();
        final players = await PlayerService.getAllPlayers();

        final avg = players.isEmpty
            ? 0.0
            : players.fold<double>(
                    0, (s, p) => s + (double.tryParse(p.rating) ?? 0)) /
                players.length;

        if (!mounted) return;
        setState(() {
          _teamsCount = teams.length;
          _coachesCount = coaches.length;
          _playersCount = players.length;
          _avgRating = avg.toStringAsFixed(1);
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStats = false);
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    final user = _user;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final addressCtrl = TextEditingController(text: user.address);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDirectionality(
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.green.withOpacity(0.4)),
          ),
          title: const Text(
            'تعديل البيانات',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, 'الاسم', Icons.person_rounded),
                const SizedBox(height: 12),
                _dialogField(phoneCtrl, 'رقم التليفون', Icons.phone_rounded,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _dialogField(
                    addressCtrl, 'العنوان', Icons.location_on_rounded),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().length < 2) return;
                Navigator.pop(ctx, true);
              },
              child: const Text(
                'حفظ',
                style: TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final newName = nameCtrl.text.trim();
    final newPhone = phoneCtrl.text.trim();
    final newAddress = addressCtrl.text.trim();

    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();

    if (result != true || !mounted) return;

    final updated = user.copyWith(
      name: newName,
      phone: newPhone,
      address: newAddress,
    );

    final ok = await AuthService.updateUser(updated);
    if (!mounted) return;

    if (ok) {
      _refresh();
      _showSnackBar('تم حفظ التعديلات ✅', AppColors.green);
    } else {
      _showSnackBar('حصل خطأ، حاول تاني', AppColors.red);
    }
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Cairo',
      ),
      decoration: InputDecoration(
        hintText: L10n.trN(hint),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontFamily: 'Cairo',
        ),
        prefixIcon: Icon(icon, color: AppColors.green, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 2),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final user = _user;
    if (user == null) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AppDirectionality(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.green),
                title: const Text(
                  'الكاميرا',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.green),
                title: const Text(
                  'المعرض',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    _showLoadingDialog();

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 500,
      );

      if (picked == null) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        return;
      }

      final String ext = picked.name.split('.').last.toLowerCase();
      final String mimeType = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storage = SupabaseService.client.storage;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await storage.from('avatars').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: mimeType,
          ),
        );
      } else {
        final file = File(picked.path);
        await storage.from('avatars').upload(
          fileName,
          file,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: mimeType,
          ),
        );
      }

      final publicUrl = storage.from('avatars').getPublicUrl(fileName);

      final updated = user.copyWith(photo: publicUrl);
      final ok = await AuthService.updateUser(updated);

      if (user.role == UserRole.player) {
        try {
          final myPlayer = await PlayerService.getPlayerByUserId(user.id);
          if (myPlayer != null) {
            await PlayerService.updatePlayer(
              myPlayer.copyWith(photo: publicUrl),
            );
          }
        } catch (_) {}
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (ok) {
        _refresh();
        _showSnackBar('تم تحديث الصورة ✅', AppColors.green);
      } else {
        _showSnackBar(
            'حصل خطأ في الحفظ: ${AuthService.lastUpdateError ?? 'غير معروف'}',
            AppColors.red);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar('حصل خطأ في رفع الصورة: $e', AppColors.red);
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDirectionality(
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.green.withOpacity(0.4)),
          ),
          title: const Text(
            'تغيير كلمة المرور',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _passwordField(oldCtrl, 'كلمة المرور الحالية'),
                  const SizedBox(height: 10),
                  _passwordField(newCtrl, 'كلمة المرور الجديدة'),
                  const SizedBox(height: 10),
                  _passwordField(confirmCtrl, 'تأكيد كلمة المرور'),
                  if (newCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _PasswordStrengthMini(password: newCtrl.text),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final oldPass = oldCtrl.text;
                final newPass = newCtrl.text;

                if (Validators.required(oldPass, label: 'الباسورد القديم') !=
                    null) {
                  return;
                }

                final passError = Validators.password(newPass);
                if (passError != null) {
                  Navigator.pop(ctx);
                  _showSnackBar(passError, AppColors.red);
                  return;
                }

                final diffError =
                    Validators.passwordDifferent(newPass, oldPass);
                if (diffError != null) {
                  Navigator.pop(ctx);
                  _showSnackBar(diffError, AppColors.red);
                  return;
                }

                final confirmError = Validators.confirmPassword(
                  confirmCtrl.text,
                  newPass,
                );
                if (confirmError != null) {
                  Navigator.pop(ctx);
                  _showSnackBar(confirmError, AppColors.red);
                  return;
                }

                Navigator.pop(ctx, true);
              },
              child: const Text(
                'حفظ',
                style: TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final oldPass = oldCtrl.text;
    final newPass = newCtrl.text;

    oldCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();

    if (ok != true || !mounted) return;

    _showLoadingDialog();

    final result = await AuthService.changePassword(
      oldPassword: oldPass,
      newPassword: newPass,
    );

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    switch (result) {
      case ChangePasswordResult.success:
        _showSnackBar('تم تغيير كلمة المرور ✅', AppColors.green);
        break;
      case ChangePasswordResult.wrongOldPassword:
        _showSnackBar('كلمة المرور الحالية غلط ❌', AppColors.red);
        break;
      case ChangePasswordResult.mockAccount:
        _showSnackBar(
          'الحسابات التجريبية مش بتقبل تغيير الباسورد',
          AppColors.orange,
        );
        break;
      case ChangePasswordResult.notLoggedIn:
        _showSnackBar('مفيش مستخدم مسجل', AppColors.red);
        break;
      case ChangePasswordResult.error:
        _showSnackBar('حصل خطأ، حاول تاني', AppColors.red);
        break;
    }
  }

  Widget _passwordField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Cairo',
      ),
      decoration: InputDecoration(
        hintText: L10n.trN(hint),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontFamily: 'Cairo',
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 2),
        ),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final device = deviceTypeOf(constraints.maxWidth);
                    final maxWidth = device == DeviceType.tablet
                        ? 900.0
                        : constraints.maxWidth;
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16)
                              .copyWith(top: 20, bottom: 110),
                          child: _ProfileBody(
                            user: _user,
                            notificationsEnabled: s.notifications,
                            teamsCount: _teamsCount,
                            coachesCount: _coachesCount,
                            playersCount: _playersCount,
                            avgRating: _avgRating,
                            myGoals: _myGoals,
                            myAssists: _myAssists,
                            myMatches: _myMatches,
                            myRating: _myRating,
                            loadingStats: _loadingStats,
                            academyCodes: _academyCodes,
                            loadingCode: _loadingCode,
                            onRegenerateCode: _regenerateCode,
                            onEditProfile: () => _editProfile(context),
                            onEditPhoto: () => _pickPhoto(context),
                            onChangePassword: () =>
                                _changePassword(context),
                            onToggleNotifications: (v) {
                              _settings.setNotifications(v);
                            },
                          ),
                        ),
                      ),
                    );
                  },
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
class _ProfileBody extends StatelessWidget {
  final AppUser? user;
  final bool notificationsEnabled;
  final int teamsCount;
  final int coachesCount;
  final int playersCount;
  final String avgRating;
  final int myGoals;
  final int myAssists;
  final int myMatches;
  final String myRating;
  final bool loadingStats;
  final Map<String, String>? academyCodes;
  final bool loadingCode;
  final ValueChanged<String> onRegenerateCode;
  final VoidCallback onEditProfile;
  final VoidCallback onEditPhoto;
  final VoidCallback onChangePassword;
  final ValueChanged<bool> onToggleNotifications;

  const _ProfileBody({
    required this.user,
    required this.notificationsEnabled,
    required this.teamsCount,
    required this.coachesCount,
    required this.playersCount,
    required this.avgRating,
    required this.myGoals,
    required this.myAssists,
    required this.myMatches,
    required this.myRating,
    required this.loadingStats,
    required this.academyCodes,
    required this.loadingCode,
    required this.onRegenerateCode,
    required this.onEditProfile,
    required this.onEditPhoto,
    required this.onChangePassword,
    required this.onToggleNotifications,
  });

  @override
  Widget build(BuildContext context) {
    bool showAdminCode = user?.role == UserRole.admin;
    bool showCoachCode = user?.role == UserRole.admin;
    bool showPlayerCode = user?.role == UserRole.admin || user?.role == UserRole.coach;
    bool hasAnyCode = showAdminCode || showCoachCode || showPlayerCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          onEditProfile: onEditProfile,
          onShowQr: () => _showQr(context),
        ),
        const SizedBox(height: 14),
        _ProfileHero(user: user, onPhotoTap: onEditPhoto),
        const SizedBox(height: 18),
        _QuickStats(
          user: user,
          teamsCount: teamsCount,
          coachesCount: coachesCount,
          playersCount: playersCount,
          avgRating: avgRating,
          myGoals: myGoals,
          myAssists: myAssists,
          myMatches: myMatches,
          myRating: myRating,
          loading: loadingStats,
        ),
        const SizedBox(height: 18),

        if (hasAnyCode) ...[
          const _SectionTitle(
            title: 'أكواد الدعوة',
            icon: Icons.vpn_key_rounded,
            color: AppColors.gold,
          ),
          const SizedBox(height: 12),
          if (loadingCode)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            )
          else ...[
            if (showAdminCode)
              _CodeCard(
                title: 'كود الأكاديمية (الأدمن)',
                code: academyCodes?['admin'],
                color: AppColors.purple,
                icon: Icons.admin_panel_settings_rounded,
                onRegenerate: () => onRegenerateCode('admin'),
              ),
            if (showCoachCode) ...[
              const SizedBox(height: 10),
              _CodeCard(
                title: 'كود دعوة المدربين',
                code: academyCodes?['coach'],
                color: AppColors.blue,
                icon: Icons.sports_rounded,
                onRegenerate: () => onRegenerateCode('coach'),
              ),
            ],
            if (showPlayerCode) ...[
              const SizedBox(height: 10),
              _CodeCard(
                title: 'كود دعوة اللاعبين',
                code: academyCodes?['player'],
                color: AppColors.green,
                icon: Icons.person_rounded,
                onRegenerate: showAdminCode ? () => onRegenerateCode('player') : null,
              ),
            ],
          ],
          const SizedBox(height: 18),
        ],

        const _SectionTitle(
          title: 'المعلومات الشخصية',
          icon: Icons.person_rounded,
          color: AppColors.blue,
        ),
        const SizedBox(height: 12),
        _PersonalInfo(user: user),
        const SizedBox(height: 18),
        const _SectionTitle(
          title: 'الإنجازات',
          icon: Icons.emoji_events_rounded,
          color: AppColors.gold,
        ),
        const SizedBox(height: 12),
        _Achievements(user: user),
        const SizedBox(height: 18),
        const _SectionTitle(
          title: 'النشاطات الأخيرة',
          icon: Icons.history_rounded,
          color: AppColors.purple,
        ),
        const SizedBox(height: 12),
        _RecentActivity(user: user),
        const SizedBox(height: 18),
        const _SectionTitle(
          title: 'إعدادات سريعة',
          icon: Icons.settings_rounded,
          color: AppColors.green,
        ),
        const SizedBox(height: 12),
        _QuickSettings(
          notificationsEnabled: notificationsEnabled,
          onToggleNotifications: onToggleNotifications,
          onChangePassword: onChangePassword,
        ),
        const SizedBox(height: 20),
        const _LogoutButton(),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showQr(BuildContext context) async {
    final u = user;
    if (u == null) return;

    final player = await PlayerService.getPlayerByUserId(u.id);
    if (!context.mounted) return;

    if (player == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'مفيش كود QR متاح لحسابك',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlayerQrScreen(player: player)),
    );
  }
}

// ============================================================
// CODE CARD
// ============================================================
class _CodeCard extends StatelessWidget {
  final String title;
  final String? code;
  final Color color;
  final IconData icon;
  final VoidCallback? onRegenerate;

  const _CodeCard({
    required this.title,
    required this.code,
    required this.color,
    required this.icon,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.12),
                Colors.white.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (onRegenerate != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onRegenerate,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'توليد جديد',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (code == null || code!.isEmpty)
                const Text(
                  'مفيش كود متاح',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          code!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: code!));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ الكود ✅', style: TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: AppColors.green,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withOpacity(0.5)),
                            ),
                            child: Icon(Icons.copy_rounded, color: color, size: 16),
                          ),
                        ),
                      ),
                    ],
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
// TOP BAR
// ============================================================
class _TopBar extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onShowQr;

  const _TopBar({
    required this.onEditProfile,
    required this.onShowQr,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final showQr = user?.role == UserRole.player;

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
          'الملف الشخصي',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (showQr) ...[
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: AppColors.green.withOpacity(0.15),
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.green),
                ),
                child: InkWell(
                  onTap: onShowQr,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      color: AppColors.green,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: AppColors.green.withOpacity(0.15),
              shape: CircleBorder(
                side: BorderSide(
                  color: AppColors.green.withOpacity(0.4),
                ),
              ),
              child: InkWell(
                onTap: onEditProfile,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.edit_rounded,
                    color: AppColors.green,
                    size: 18,
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
// PROFILE HERO
// ============================================================
class _ProfileHero extends StatelessWidget {
  final AppUser? user;
  final VoidCallback onPhotoTap;

  const _ProfileHero({required this.user, required this.onPhotoTap});

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'مستخدم';
    final role = user?.roleLabel ?? '';
    final isCoach = user?.role == UserRole.coach;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 240,
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
                    Colors.black.withOpacity(0.45),
                    AppColors.green.withOpacity(0.30),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
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
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onPhotoTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.green,
                                AppColors.greenDark,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withOpacity(0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.background,
                            ),
                            child: ClipOval(
                              child: _buildAvatar(user?.photo),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.green,
                              border: Border.all(
                                color: AppColors.background,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.green.withOpacity(0.6),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.green,
                                    size: 11,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'موثق',
                                    style: TextStyle(
                                      color: AppColors.green,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCoach
                              ? 'المدرب الرئيسي - الفريق الأول'
                              : role,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 6,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _SmallInfo(
                              icon: Icons.location_on_rounded,
                              text: (user?.address.isNotEmpty ?? false)
                                  ? user!.address
                                  : '—',
                            ),
                            const SizedBox(width: 12),
                            _SmallInfo(
                              icon: Icons.calendar_today_rounded,
                              text: (user?.joinDate.isNotEmpty ?? false)
                                  ? 'منذ ${user!.joinDate}'
                                  : '—',
                            ),
                          ],
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

  Widget _buildAvatar(String? photo) {
    if (photo == null || photo.isEmpty) {
      return Container(
        color: AppColors.surfaceLight,
        alignment: Alignment.center,
        child: const Icon(
          Icons.person,
          color: AppColors.textSecondary,
          size: 40,
        ),
      );
    }

    if (!kIsWeb && (photo.startsWith('/') || photo.startsWith('file://'))) {
      return Image.file(
        File(photo),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surfaceLight,
          alignment: Alignment.center,
          child: const Icon(
            Icons.person,
            color: AppColors.textSecondary,
            size: 40,
          ),
        ),
      );
    }

    return Image.network(
      photo,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surfaceLight,
        alignment: Alignment.center,
        child: const Icon(
          Icons.person,
          color: AppColors.textSecondary,
          size: 40,
        ),
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 11),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// QUICK STATS
// ============================================================
class _QuickStats extends StatelessWidget {
  final AppUser? user;
  final int teamsCount;
  final int coachesCount;
  final int playersCount;
  final String avgRating;
  final int myGoals;
  final int myAssists;
  final int myMatches;
  final String myRating;
  final bool loading;

  const _QuickStats({
    required this.user,
    required this.teamsCount,
    required this.coachesCount,
    required this.playersCount,
    required this.avgRating,
    required this.myGoals,
    required this.myAssists,
    required this.myMatches,
    required this.myRating,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.green),
        ),
      );
    }

    final List<(IconData, String, String, Color)> stats;

    switch (user?.role) {
      case UserRole.admin:
        stats = [
          (Icons.shield_rounded, '$teamsCount', 'فرق', AppColors.green),
          (Icons.person_rounded, '$coachesCount', 'مدربين', AppColors.blue),
          (Icons.groups_rounded, '$playersCount', 'لاعب', AppColors.purple),
          (Icons.star_rounded, avgRating, 'تقييم', AppColors.gold),
        ];
        break;
      case UserRole.coach:
        stats = [
          (Icons.groups_rounded, '$playersCount', 'لاعب', AppColors.blue),
          (Icons.shield_rounded, '$teamsCount', 'فرق', AppColors.green),
          (Icons.person_rounded, '$coachesCount', 'مدربين', AppColors.purple),
          (Icons.star_rounded, avgRating, 'تقييم', AppColors.gold),
        ];
        break;
      case UserRole.player:
        // ✅ إحصائيات اللاعب الشخصية
        stats = [
          (Icons.sports_soccer, '$myGoals', 'أهدافي', AppColors.green),
          (Icons.handshake_outlined, '$myAssists', 'صناعتي', AppColors.blue),
          (Icons.calendar_month, '$myMatches', 'مبارياتي', AppColors.purple),
          (Icons.star_rounded, myRating, 'تقييمي', AppColors.gold),
        ];
        break;
      default:
        stats = [
          (Icons.person, '0', '—', AppColors.gray),
          (Icons.person, '0', '—', AppColors.gray),
          (Icons.person, '0', '—', AppColors.gray),
          (Icons.person, '0', '—', AppColors.gray),
        ];
    }

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          Expanded(
            child: _StatCard(
              icon: stats[i].$1,
              value: stats[i].$2,
              label: stats[i].$3,
              color: stats[i].$4,
            ),
          ),
          if (i != stats.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  border: Border.all(
                    color: color.withOpacity(0.5),
                  ),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    height: 1.0,
                  ),
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
// SECTION TITLE
// ============================================================
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle({
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
            border: Border.all(
              color: color.withOpacity(0.4),
            ),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PERSONAL INFO
// ============================================================
class _PersonalInfo extends StatelessWidget {
  final AppUser? user;
  const _PersonalInfo({required this.user});

  @override
  Widget build(BuildContext context) {
    final phone = (user?.phone.isNotEmpty ?? false) ? user!.phone : '—';
    final address =
        (user?.address.isNotEmpty ?? false) ? user!.address : '—';
    final jobNumber =
        (user?.jobNumber.isNotEmpty ?? false) ? user!.jobNumber : '—';
    final joinDate =
        (user?.joinDate.isNotEmpty ?? false) ? user!.joinDate : '—';

    final items = [
      (
        Icons.email_rounded,
        'البريد الإلكتروني',
        user?.email ?? '—',
        AppColors.green,
      ),
      (Icons.phone_rounded, 'رقم الهاتف', phone, AppColors.blue),
      (Icons.location_on_rounded, 'العنوان', address, AppColors.orange),
      (Icons.badge_rounded, 'الرقم الوظيفي', jobNumber, AppColors.purple),
      (
        Icons.calendar_month_rounded,
        'تاريخ الانضمام',
        joinDate,
        AppColors.gold,
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(4),
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
                _InfoRow(
                  icon: items[i].$1,
                  label: items[i].$2,
                  value: items[i].$3,
                  color: items[i].$4,
                ),
                if (i != items.length - 1)
                  Divider(color: Colors.white.withOpacity(0.05), height: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(
                color: color.withOpacity(0.4),
              ),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_left,
            color: AppColors.textMuted,
            size: 18,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ✅ ACHIEVEMENTS (ديناميكي بناءً على أرقام اللاعب)
// ============================================================
class _Achievements extends StatefulWidget {
  final AppUser? user;
  const _Achievements({required this.user});

  @override
  State<_Achievements> createState() => _AchievementsState();
}

class _AchievementsState extends State<_Achievements> {
  List<(IconData, String, String, Color)> _achievements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = widget.user;
    if (user == null || user.role != UserRole.player) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final me = await PlayerService.getPlayerByUserId(user.id);
      if (me == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final list = <(IconData, String, String, Color)>[];

      if (me.goals >= 10) {
        list.add((
          Icons.emoji_events,
          'هدّاف الأكاديمية',
          '${me.goals} هدف',
          AppColors.gold,
        ));
      }

      final rating = double.tryParse(me.rating) ?? 0.0;
      if (rating >= 9.0) {
        list.add((
          Icons.star,
          'أفضل لاعب',
          'تقييم ${me.rating}',
          AppColors.orange,
        ));
      }

      if (me.assists >= 5) {
        list.add((
          Icons.trending_up,
          'صنّاع الأهداف',
          '${me.assists} صناعة',
          AppColors.green,
        ));
      }

      if (me.matches >= 10) {
        list.add((
          Icons.calendar_month,
          'لاعب منتظم',
          '${me.matches} مباراة',
          AppColors.blue,
        ));
      }

      if (!mounted) return;
      setState(() {
        _achievements = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
          ),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                )
              : _achievements.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'لا توجد إنجازات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < _achievements.length; i++) ...[
                          _AchievementRow(
                            icon: _achievements[i].$1,
                            title: _achievements[i].$2,
                            subtitle: _achievements[i].$3,
                            color: _achievements[i].$4,
                          ),
                          if (i != _achievements.length - 1)
                            Divider(
                              color: Colors.white.withOpacity(0.05),
                              height: 16,
                            ),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AchievementRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(
              color: color.withOpacity(0.5),
            ),
          ),
          child: Icon(icon, color: color, size: 20),
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.verified_rounded,
          color: color,
          size: 18,
        ),
      ],
    );
  }
}

// ============================================================
// ✅ RECENT ACTIVITY (ديناميكي من التدريبات والماتشات)
// ============================================================
class _RecentActivity extends StatefulWidget {
  final AppUser? user;
  const _RecentActivity({required this.user});

  @override
  State<_RecentActivity> createState() => _RecentActivityState();
}

class _RecentActivityState extends State<_RecentActivity> {
  List<(IconData, String, String, Color)> _activities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = widget.user;
      final trainingList = <Training>[];
      final matchList = <Match>[];

      if (user?.role == UserRole.player) {
        final me = await PlayerService.getPlayerByUserId(user!.id);
        if (me != null && me.teamId.isNotEmpty) {
          final myTrainings =
              await TrainingService.getByTeam(me.teamId);
          final myMatches =
              await MatchService.getMatchesByTeam(me.teamId);
          trainingList.addAll(myTrainings);
          matchList.addAll(myMatches);
        }
      } else {
        trainingList.addAll(await TrainingService.getAllTrainings());
        matchList.addAll(await MatchService.getAllMatches());
      }

      trainingList.sort((a, b) => b.date.compareTo(a.date));
      matchList.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      final list = <(IconData, String, String, Color)>[];

      for (final t in trainingList.take(2)) {
        list.add((
          Icons.fitness_center,
          'تدريب: ${t.title}',
          t.dateString,
          AppColors.green,
        ));
      }

      for (final m in matchList.take(2)) {
        list.add((
          Icons.sports_soccer,
          '${m.isFinished ? "ماتش" : "ماتش قادم"}: ${m.teamName} × ${m.opponentName}',
          m.date,
          m.isFinished ? AppColors.blue : AppColors.orange,
        ));
      }

      if (!mounted) return;
      setState(() {
        _activities = list.take(4).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
          ),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                )
              : _activities.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'لا توجد نشاطات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < _activities.length; i++) ...[
                          _ActivityRow(
                            icon: _activities[i].$1,
                            text: _activities[i].$2,
                            time: _activities[i].$3,
                            color: _activities[i].$4,
                          ),
                          if (i != _activities.length - 1)
                            Divider(
                              color: Colors.white.withOpacity(0.05),
                              height: 16,
                            ),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String time;
  final Color color;

  const _ActivityRow({
    required this.icon,
    required this.text,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 12)),
        ),
        Text(time,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

// ============================================================
// QUICK SETTINGS
// ============================================================
class _QuickSettings extends StatelessWidget {
  final bool notificationsEnabled;
  final ValueChanged<bool> onToggleNotifications;
  final VoidCallback onChangePassword;

  const _QuickSettings({
    required this.notificationsEnabled,
    required this.onToggleNotifications,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(4),
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
              _SettingRow(
                icon: Icons.notifications_rounded,
                label: 'الإشعارات',
                color: AppColors.orange,
                trailing: Switch(
                  value: notificationsEnabled,
                  activeColor: AppColors.green,
                  onChanged: onToggleNotifications,
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.05), height: 1),
              _SettingRow(
                icon: Icons.lock_rounded,
                label: 'الأمان',
                color: AppColors.green,
                trailing: const Icon(
                  Icons.chevron_left,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                onTap: onChangePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: content,
      ),
    );
  }
}

// ============================================================
// LOGOUT BUTTON
// ============================================================
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: AppColors.red, size: 18),
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

  void _showLogoutDialog(BuildContext context) {
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
// PASSWORD STRENGTH MINI
// ============================================================
class _PasswordStrengthMini extends StatelessWidget {
  final String password;
  const _PasswordStrengthMini({required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = Validators.passwordStrength(password);
    final label = Validators.passwordLabel(password);

    Color color;
    if (strength < 0.5) {
      color = AppColors.red;
    } else if (strength < 0.8) {
      color = AppColors.orange;
    } else {
      color = AppColors.green;
    }

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 4,
                  color: Colors.white.withOpacity(0.06),
                ),
                FractionallySizedBox(
                  widthFactor: strength.clamp(0.1, 1.0),
                  child: Container(
                    height: 4,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}