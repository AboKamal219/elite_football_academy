// lib/notifications_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import 'l10n/app_text.dart';
import 'package:uuid/uuid.dart';
import 'academy_dashboard_screen.dart'
    show
        AppColors,
        AppImages,
        GlassCard,
        NetImage,
        DeviceType,
        deviceTypeOf;
import 'models/app_user.dart';
import 'models/notification.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

// ============================================================
// NOTIFICATIONS SCREEN
// ============================================================

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _filterIndex = 0;

  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await NotificationService.getAll();
    if (!mounted) return;
    setState(() {
      _notifications = all;
      _loading = false;
    });
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead();
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم تعليم الكل كمقروء ✅',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (!n.isUnread) return;
    await NotificationService.markAsRead(n.id);
    await _loadData();
  }

  // ============================================================
  // ✅ إضافة إشعار جديد
  // ============================================================
  Future<void> _addNotification() async {
    final saved = await _NotificationFormDialog.show(context);
    if (saved == true && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال الإشعار ✅',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<AppNotification> get _filtered {
    switch (_filterIndex) {
      case 1:
        return _notifications.where((n) => n.isUnread).toList();
      case 2:
        return _notifications
            .where((n) => n.category == NotificationCategory.matches)
            .toList();
      case 3:
        return _notifications
            .where((n) => n.category == NotificationCategory.trainings)
            .toList();
      default:
        return _notifications;
    }
  }

  int get _unreadCount =>
      _notifications.where((n) => n.isUnread).length;

  @override
  Widget build(BuildContext context) {
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
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.green,
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16)
                            .copyWith(top: 20, bottom: 110),
                        child: _NotificationsBody(
                          filterIndex: _filterIndex,
                          onFilterChanged: (i) =>
                              setState(() => _filterIndex = i),
                          notifications: _filtered,
                          unreadCount: _unreadCount,
                          onMarkAllRead: _markAllAsRead,
                          onTapNotification: _markAsRead,
                          onAddNotification: _addNotification,
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
class _NotificationsBody extends StatelessWidget {
  final int filterIndex;
  final ValueChanged<int> onFilterChanged;
  final List<AppNotification> notifications;
  final int unreadCount;
  final VoidCallback onMarkAllRead;
  final ValueChanged<AppNotification> onTapNotification;
  final VoidCallback onAddNotification;

  const _NotificationsBody({
    required this.filterIndex,
    required this.onFilterChanged,
    required this.notifications,
    required this.unreadCount,
    required this.onMarkAllRead,
    required this.onTapNotification,
    required this.onAddNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          unreadCount: unreadCount,
          onMarkAllRead: onMarkAllRead,
          onAddNotification: onAddNotification,
        ),
        const SizedBox(height: 14),
        _NotificationsHero(unreadCount: unreadCount),
        const SizedBox(height: 18),
        _FilterTabs(
          currentIndex: filterIndex,
          onChanged: onFilterChanged,
        ),
        const SizedBox(height: 16),
        _NotificationsList(
          notifications: notifications,
          onTapNotification: onTapNotification,
        ),
      ],
    );
  }
}

// ============================================================
// TOP BAR
// ============================================================
class _TopBar extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onMarkAllRead;
  final VoidCallback onAddNotification;

  const _TopBar({
    required this.unreadCount,
    required this.onMarkAllRead,
    required this.onAddNotification,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final canAdd =
        user?.role == UserRole.admin || user?.role == UserRole.coach;

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
          'الإشعارات',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        const Spacer(),

        // ✅ جديد: زرار إضافة إشعار
        if (canAdd) ...[
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: AppColors.orange.withOpacity(0.20),
                shape: CircleBorder(
                  side: BorderSide(
                    color: AppColors.orange.withOpacity(0.6),
                  ),
                ),
                child: InkWell(
                  onTap: onAddNotification,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.add_rounded,
                      color: AppColors.orange,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // ✅ زرار "تعليم الكل كمقروء" الأصلي
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: unreadCount > 0
                  ? AppColors.green.withOpacity(0.20)
                  : AppColors.green.withOpacity(0.05),
              shape: CircleBorder(
                side: BorderSide(
                  color: unreadCount > 0
                      ? AppColors.green.withOpacity(0.6)
                      : AppColors.green.withOpacity(0.2),
                ),
              ),
              child: InkWell(
                onTap: unreadCount > 0 ? onMarkAllRead : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.done_all_rounded,
                    color: unreadCount > 0
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
// HERO BANNER
// ============================================================
class _NotificationsHero extends StatelessWidget {
  final int unreadCount;
  const _NotificationsHero({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 140,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppImages.coachStadium,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.35),
                    AppColors.orange.withOpacity(0.30),
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
                      AppColors.orange.withOpacity(0.4),
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
                      color: AppColors.orange.withOpacity(0.25),
                      border: Border.all(
                        color: AppColors.orange.withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.orange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الإشعارات',
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
                          'كل جديد من الأكاديمية',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.red.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: AppColors.red,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'جديد',
                            style: TextStyle(
                              color: AppColors.red,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
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
// FILTER TABS
// ============================================================
class _FilterTabs extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _FilterTabs({
    required this.currentIndex,
    required this.onChanged,
  });

  static const filters = [
    ('الكل', Icons.apps_rounded, AppColors.green),
    ('غير مقروء', Icons.mark_email_unread_rounded, AppColors.red),
    ('مباريات', Icons.sports_soccer_rounded, AppColors.orange),
    ('تدريبات', Icons.fitness_center_rounded, AppColors.blue),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (i) {
          final active = i == currentIndex;
          final filter = filters[i];

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: active
                    ? filter.$3
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: active
                      ? filter.$3
                      : Colors.white.withOpacity(0.10),
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: filter.$3.withOpacity(0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter.$2,
                          color: active
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          filter.$1,
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================
// NOTIFICATIONS LIST
// ============================================================
class _NotificationsList extends StatelessWidget {
  final List<AppNotification> notifications;
  final ValueChanged<AppNotification> onTapNotification;

  const _NotificationsList({
    required this.notifications,
    required this.onTapNotification,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                color: AppColors.textSecondary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد إشعارات',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'لم يتم استلام أي إشعارات في هذه الفئة',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < notifications.length; i++) ...[
          _NotificationCard(
            notification: notifications[i],
            onTap: () => onTapNotification(notifications[i]),
          ),
          if (i != notifications.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = notification;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: item.isUnread
                ? item.color.withOpacity(0.08)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isUnread
                  ? item.color.withOpacity(0.4)
                  : Colors.white.withOpacity(0.06),
              width: 1.2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.color.withOpacity(0.15),
                            border: Border.all(
                              color: item.color.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            item.icon,
                            color: item.color,
                            size: 20,
                          ),
                        ),
                        if (item.isUnread)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.red,
                                border: Border.all(
                                  color: AppColors.background,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: item.isUnread
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.time,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: item.color.withOpacity(0.35),
                              ),
                            ),
                            child: Text(
                              item.categoryLabel,
                              style: TextStyle(
                                color: item.color,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
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
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ✅ NOTIFICATION FORM DIALOG — إضافة إشعار جديد
// ============================================================
class _NotificationFormDialog extends StatefulWidget {
  const _NotificationFormDialog();

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _NotificationFormDialog(),
    );
  }

  @override
  State<_NotificationFormDialog> createState() =>
      _NotificationFormDialogState();
}

class _NotificationFormDialogState extends State<_NotificationFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _messageCtrl;

  NotificationCategory _category = NotificationCategory.general;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _messageCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // الحفظ
  // ============================================================
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('مفيش مستخدم مسجل');

      final id = 'notif_${const Uuid().v4().substring(0, 8)}';

      // ✅ الوقت الحالي بصيغة "hh:mm ص/م"
      final now = DateTime.now();
      final h = now.hour == 0
          ? 12
          : (now.hour > 12 ? now.hour - 12 : now.hour);
      final ampm = now.hour >= 12 ? 'م' : 'ص';
      final mm = now.minute.toString().padLeft(2, '0');
      final timeStr = '$h:$mm $ampm';

      final notification = AppNotification(
        id: id,
        title: _titleCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
        time: timeStr,
        isUnread: true,
        category: _category,
        academyId: user.academyId,
      );

      await NotificationService.add(notification);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حصل خطأ: $e',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AppDirectionality(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.98),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.orange.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(onClose: () => Navigator.pop(context)),
                      const Divider(color: Colors.white12, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(
                              icon: Icons.title_rounded,
                              text: 'عنوان الإشعار *',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _titleCtrl,
                              hint: 'مثال: مباراة جديدة',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'لازم تكتب عنوان';
                                }
                                if (v.trim().length < 2) {
                                  return 'العنوان قصير جدًا';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.message_rounded,
                              text: 'نص الإشعار *',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _messageCtrl,
                              hint: 'اكتب تفاصيل الإشعار هنا...',
                              maxLines: 3,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'لازم تكتب نص الإشعار';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.category_rounded,
                              text: 'الفئة *',
                            ),
                            const SizedBox(height: 6),
                            _CategoryPicker(
                              value: _category,
                              onChanged: (v) =>
                                  setState(() => _category = v),
                            ),
                            const SizedBox(height: 22),

                            _Buttons(
                              saving: _saving,
                              onCancel: () => Navigator.pop(context),
                              onSave: _save,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================
class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orange.withOpacity(0.15),
              border: Border.all(color: AppColors.orange),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إرسال إشعار جديد',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'هيوصل لكل الأعضاء في الأكاديمية',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FIELD LABEL
// ============================================================
class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FieldLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.green, size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TEXT FIELD
// ============================================================
class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator == null ? null : (v) => L10n.trN(validator!(v)),
      maxLines: maxLines,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontFamily: 'Cairo',
      ),
      decoration: InputDecoration(
        hintText: L10n.trN(hint),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontFamily: 'Cairo',
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
        errorStyle: const TextStyle(
          color: AppColors.red,
          fontSize: 10,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

// ============================================================
// CATEGORY PICKER
// ============================================================
class _CategoryPicker extends StatelessWidget {
  final NotificationCategory value;
  final ValueChanged<NotificationCategory> onChanged;

  const _CategoryPicker({
    required this.value,
    required this.onChanged,
  });

  static const _options = [
    (
      NotificationCategory.general,
      'عام',
      Icons.notifications_rounded,
      AppColors.green,
    ),
    (
      NotificationCategory.matches,
      'مباريات',
      Icons.sports_soccer_rounded,
      AppColors.orange,
    ),
    (
      NotificationCategory.trainings,
      'تدريبات',
      Icons.fitness_center_rounded,
      AppColors.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final active = opt.$1 == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(opt.$1),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? opt.$4.withOpacity(0.15)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? opt.$4
                          : Colors.white.withOpacity(0.10),
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        opt.$3,
                        color: active
                            ? opt.$4
                            : AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opt.$2,
                        style: TextStyle(
                          color: active
                              ? opt.$4
                              : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================
// BUTTONS
// ============================================================
class _Buttons extends StatelessWidget {
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _Buttons({
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: saving ? null : onCancel,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: const Center(
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: saving ? null : onSave,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: saving
                        ? [AppColors.gray, AppColors.gray]
                        : [
                            AppColors.orange,
                            AppColors.orange.withOpacity(0.7),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: saving
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.orange.withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'إرسال الإشعار',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
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