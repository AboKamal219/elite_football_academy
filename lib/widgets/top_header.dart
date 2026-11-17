// lib/widgets/top_header.dart

import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import '../l10n/app_text.dart';
import '../academy_dashboard_screen.dart'
    show AppColors, AppImages, NetImage;
import '../models/app_user.dart';
import '../models/notification.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../routes.dart';

// ============================================================
// TOP HEADER — موحّد لكل الصفحات
// ============================================================
class TopHeader extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showUserBadge;
  final String title;
  final String subtitle;
  final double logoSize;

  // ✅ جديد: زرار الإضافة (اختياري)
  final VoidCallback? onAdd;

  const TopHeader({
    super.key,
    this.showBackButton = false,
    this.onBack,
    this.showUserBadge = true,
    this.title = 'Elite Football Academy',
    this.subtitle = 'Developing Future Champions',
    this.logoSize = 44,
    this.onAdd, // ✅ جديد
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          if (showBackButton) ...[
            _BackButton(onTap: onBack),
            const SizedBox(width: 8),
          ],

          // ============ اللوجو ============
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green, width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                width: logoSize,
                height: logoSize,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.shield,
                  color: AppColors.green,
                  size: logoSize * 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ============ العنوان ============
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ✅ جديد: زرار الإضافة (لو موجود)
          if (onAdd != null) ...[
            _AddButton(onTap: onAdd!),
            const SizedBox(width: 8),
          ],

          // ============ الإشعارات ============
          const _NotificationBell(),

          // ============ الكوتش (اختياري) ============
          if (showUserBadge) ...[
            const SizedBox(width: 20),
            const _UserBadge(),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// ✅ جديد: ADD BUTTON
// ============================================================
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: AppColors.green.withOpacity(0.15),
          shape: CircleBorder(
            side: BorderSide(
              color: AppColors.green.withOpacity(0.5),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.add_rounded,
                color: AppColors.green,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BACK BUTTON
// ============================================================
class _BackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _BackButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.06),
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white12),
      ),
      child: InkWell(
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_forward,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NOTIFICATION BELL — يفتح Bottom Sheet
// ============================================================
class _NotificationBell extends StatefulWidget {
  const _NotificationBell();

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationService.getUnreadCount();
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  // ✅ فتح Bottom Sheet
  Future<void> _openNotificationsSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationsSheet(),
    );
    // ✅ نحدّث العدد لما يقفل
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openNotificationsSheet,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          if (_unreadCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// NOTIFICATIONS BOTTOM SHEET
// ============================================================
class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<AppNotification> _unread = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await NotificationService.getUnread();
    if (!mounted) return;
    setState(() {
      _unread = all;
      _loading = false;
    });
  }

  Future<void> _markAsRead(AppNotification n) async {
    await NotificationService.markAsRead(n.id);
    await _load();
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppDirectionality(
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
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
                      color: AppColors.green.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // ============ Drag Handle ============
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 45,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    // ============ Header ============
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
                              color: AppColors.orange.withOpacity(0.15),
                              border: Border.all(
                                color: AppColors.orange,
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
                                const Text(
                                  'الإشعارات الجديدة',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _unread.isEmpty
                                      ? 'مفيش إشعارات جديدة'
                                      : '${_unread.length} إشعار جديد',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ✅ "تعليم الكل كمقروء"
                          if (_unread.isNotEmpty)
                            IconButton(
                              onPressed: _markAllAsRead,
                              tooltip: L10n.tr('تعليم الكل كمقروء'),
                              icon: const Icon(
                                Icons.done_all_rounded,
                                color: AppColors.green,
                                size: 22,
                              ),
                            ),
                          // ✅ قفل
                          IconButton(
                            onPressed: () => Navigator.pop(context),
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

                    // ============ Content ============
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.green,
                              ),
                            )
                          : _unread.isEmpty
                              ? _buildEmptyState()
                              : _buildList(scrollController),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              'مفيش إشعارات جديدة',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'كل الإشعارات مقروءة ✅',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ScrollController scrollController) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _unread.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        return _NotificationTile(
          notification: _unread[i],
          onTap: () => _markAsRead(_unread[i]),
        );
      },
    );
  }
}

// ============================================================
// NOTIFICATION TILE
// ============================================================
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = notification;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: item.color.withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Icon
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
                      // Unread dot
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

                  // ✅ Content
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
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
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
                        Row(
                          children: [
                            // Category
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
                            const Spacer(),
                            const Text(
                              'اضغط لتعليمه كمقروء',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                              ),
                            ),
                          ],
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
    );
  }
}

// ============================================================
// ✅ USER BADGE — بيسمع لـ AuthService.listenable
// ============================================================
class _UserBadge extends StatelessWidget {
  const _UserBadge();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.listenable,
      builder: (context, _) {
        final user = AuthService.currentUser;

        final name = user?.name ?? 'مستخدم';
        final role = user?.roleLabel ?? '';
        final photo = user?.photo ?? AppImages.coachAvatar;

        // ✅ Material wrapper لحل مشكلة "No Material widget found"
        return Material(
          color: Colors.transparent,
          child: PopupMenuButton<String>(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: AppColors.green.withOpacity(0.3),
              ),
            ),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.of(context).pushNamed(AppRoutes.profile);
              } else if (value == 'logout') {
                _confirmLogout(context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline,
                        color: AppColors.textPrimary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'الملف الشخصي',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        color: AppColors.red, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: AppColors.red),
                    ),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      role,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                ClipOval(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: NetImage(
                      url: photo,
                      fallbackIcon: Icons.person,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
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
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
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

    if (ok != true) return;

    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }
}