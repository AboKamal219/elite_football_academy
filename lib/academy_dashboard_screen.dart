// lib/academy_dashboard_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import 'l10n/app_text.dart';
import 'players_list_screen.dart';
import 'teams_screen.dart';
import 'training_schedule_screen.dart';
import 'statistics_screen.dart';
import 'more_screen.dart';
import 'widgets/top_header.dart';
import 'widgets/bottom_nav.dart';
import 'models/app_user.dart';
import 'models/match.dart';
import 'models/player.dart';
import 'services/attendance_service.dart';
import 'services/auth_service.dart';
import 'services/coach_service.dart';
import 'services/match_service.dart';
import 'models/training.dart';
import 'services/player_service.dart';
import 'services/team_service.dart';
import 'services/training_service.dart';
import 'services/tournament_service.dart';
import 'my_matches_screen.dart';
import 'my_trainings_screen.dart';
import 'attendance_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'coaches_screen.dart';
import 'widgets/player_form_dialog.dart';
import 'widgets/coach_form_dialog.dart';

// ============================================================
// IMAGES
// ============================================================
class AppImages {
  static const heroBackground = 'assets/images/hero.jpg';
  static const heroPlayersBackground = 'assets/images/hero_players.jpg';
  static const coachStadium = 'assets/images/coach_stadium.jpg';
  static const promoBackground = 'assets/images/promo.jpg';
  static const coachAvatar = 'https://i.pravatar.cc/300?img=68';
  static const player1 = 'https://i.pravatar.cc/300?img=12';
  static const player2 = 'https://i.pravatar.cc/300?img=33';
  static const player3 = 'https://i.pravatar.cc/300?img=53';
}

// ============================================================
// COLORS
// ============================================================
class AppColors {
  static const Color background = Color(0xFF090E1A);
  static const Color surface = Color(0xFF141C2F);
  static const Color surfaceLight = Color(0xFF1B2540);
  static const Color border = Color(0xFF232E4A);

  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF8B96AD);
  static const Color textMuted = Color(0xFF5C6785);

  static const Color green = Color(0xFF12B886);
  static const Color greenDark = Color(0xFF0E9B72);
  static const Color blue = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color orange = Color(0xFFF97316);
  static const Color gray = Color(0xFF64748B);
  static const Color gold = Color(0xFFF5B700);
  static const Color silver = Color(0xFFB0BAC9);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color red = Color(0xFFEF4444);
}

// ============================================================
// RESPONSIVE HELPERS
// ============================================================
enum DeviceType { mobile, tablet }

DeviceType deviceTypeOf(double width) =>
    width >= 700 ? DeviceType.tablet : DeviceType.mobile;

// ============================================================
// GLASS CARD
// ============================================================
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.blur = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.07),
                Colors.white.withOpacity(0.02),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ============================================================
// NET IMAGE
// ============================================================
class NetImage extends StatelessWidget {
  final String url;
  final IconData fallbackIcon;
  final BoxFit fit;
  const NetImage({
    super.key,
    required this.url,
    this.fallbackIcon = Icons.image,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: AppColors.surfaceLight,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: AppColors.textSecondary, size: 28),
      );
    }

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        errorBuilder: (context, error, stack) => Container(
          color: AppColors.surfaceLight,
          alignment: Alignment.center,
          child: Icon(fallbackIcon, color: AppColors.textSecondary, size: 28),
        ),
      );
    }

    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(color: AppColors.surfaceLight);
      },
      errorBuilder: (context, error, stack) => Container(
        color: AppColors.surfaceLight,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: AppColors.textSecondary, size: 28),
      ),
    );
  }
}

// ============================================================
// ENTRY WIDGET
// ============================================================
class AcademyDashboardScreen extends StatefulWidget {
  const AcademyDashboardScreen({super.key});

  @override
  State<AcademyDashboardScreen> createState() => _AcademyDashboardScreenState();
}

class _AcademyDashboardScreenState extends State<AcademyDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.apply(
      fontFamily: 'Cairo',
    );

    return AppDirectionality(
      child: Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.background,
          textTheme: textTheme,
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
          extendBody: true,
          body: Stack(
            children: [
              const _BackgroundGlow(),
              // ✅ FIX: الهيدر كان بيتعمل تحت الـ status bar لأن removePadding كان
              // بيصفّر الـ padding العلوي (وبيخلّي أي SafeArea جوّه الصفحات ملهاش أثر).
              SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final device = deviceTypeOf(constraints.maxWidth);
                    final maxContentWidth = device == DeviceType.tablet
                        ? 1100.0
                        : constraints.maxWidth;
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: _buildPage(_currentIndex, device),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index, DeviceType device) {
    final user = AuthService.currentUser;
    final isAdmin = user?.role == UserRole.admin;

    if (index == 0) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 100, top: 0),
        child: _DashboardBody(
          device: device,
          onNavigate: (i) => setState(() => _currentIndex = i),
        ),
      );
    }

    if (index == 1) {
      if (user?.role == UserRole.player) {
        return const MyMatchesScreen();
      } else {
        return const PlayersListScreen();
      }
    }

    if (index == 2) {
      if (isAdmin) {
        return const TeamsScreen();
      } else if (user?.role == UserRole.player) {
        return const MyTrainingsScreen();
      } else {
        return const TrainingScheduleScreen();
      }
    }

    if (index == 3) {
      return const StatisticsScreen();
    }

    if (index == 4) {
      return const MoreScreen();
    }

    return const SizedBox();
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
class _DashboardBody extends StatelessWidget {
  final DeviceType device;
  final Function(int) onNavigate;

  const _DashboardBody({
    required this.device,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = device == DeviceType.tablet;
    final user = AuthService.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TopHeader(),
        const SizedBox(height: 16),
        _HeroBanner(user: user),
        const SizedBox(height: 20),
        _StatsGrid(isTablet: isTablet, user: user),
        const SizedBox(height: 16),
        _QuickActionsRow(
          isTablet: isTablet,
          user: user,
          onNavigate: onNavigate,
        ),
        const SizedBox(height: 20),

        if (isTablet)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 6, child: _UpcomingSection()),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: _PlayersAndRankingSection(user: user),
                ),
              ],
            ),
          )
        else ...[
          const _UpcomingSection(),
          const SizedBox(height: 16),
          _PlayersAndRankingSection(user: user),
        ],

        const SizedBox(height: 16),
        _QuickStatsSection(user: user),
        const SizedBox(height: 16),

        if (isTablet)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _RecentActivitySection(user: user),
                ),
                const SizedBox(width: 16),
                const Expanded(flex: 4, child: _PromoBanner()),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _QuickSummarySection(user: user),
                ),
              ],
            ),
          )
        else ...[
          _RecentActivitySection(user: user),
          const SizedBox(height: 16),
          const _PromoBanner(),
          const SizedBox(height: 16),
          _QuickSummarySection(user: user),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;

  const _SectionHeader({
    required this.title,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        if (icon != null) ...[
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: iconColor ?? AppColors.textSecondary),
        ],
      ],
    );
  }
}

// ============================================================
// HERO BANNER
// ============================================================
class _HeroBanner extends StatelessWidget {
  final AppUser? user;
  const _HeroBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'مستخدم';

    String subtitle;
    switch (user?.role) {
      case UserRole.admin:
        subtitle = 'إدارة الأكاديمية بالكامل';
        break;
      case UserRole.coach:
        subtitle = 'معاً نصنع أبطال المستقبل';
        break;
      case UserRole.player:
        subtitle = 'استعد لمباراتك الجاية';
        break;
      default:
        subtitle = '';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 240,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const NetImage(url: AppImages.heroBackground, fallbackIcon: Icons.sports_soccer),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.35),
                    AppColors.green.withOpacity(0.25),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Better\nPlayers\nBetter\nTomorrow',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'DancingScript',
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 17,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: const [
                        Text('👋', style: TextStyle(fontSize: 15)),
                        SizedBox(width: 6),
                        Text('مرحباً بك مجدداً',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showTodayDetails(context),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withOpacity(0.5),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.chevron_left, color: Colors.white, size: 15),
                              SizedBox(width: 5),
                              Text(
                                'عرض تفاصيل اليوم',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
    );
  }
}

// ============================================================
// KPI STATS GRID
// ============================================================
class _StatItem {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String delta;
  const _StatItem(this.icon, this.color, this.value, this.label, this.delta);
}

class _StatsGrid extends StatefulWidget {
  final bool isTablet;
  final AppUser? user;
  const _StatsGrid({required this.isTablet, required this.user});

  @override
  State<_StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<_StatsGrid> {
  List<_StatItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = widget.user;
    if (user == null) return;

    List<_StatItem> items = [];

    switch (user.role) {
      case UserRole.admin:
        // ✅ قراءة بيانات حقيقية من كل خدمة
        final teams = await TeamService.getAllTeams();
        final coaches = await CoachService.getAllCoaches();
        final players = await PlayerService.getAllPlayers();
        // ✅ بدل "الإيرادات" (مكانش ليها جدول بيانات وكانت صفر دايماً)
        final allMatches = await MatchService.getAllMatches();
        final upcomingAll =
            allMatches.where((m) => m.isUpcoming || m.isLive).length;
        items = [
          _StatItem(Icons.shield_rounded, AppColors.blue, '${teams.length}', 'الفرق', ''),
          _StatItem(Icons.person_add_alt, AppColors.green, '${coaches.length}', 'المدربين', ''),
          _StatItem(Icons.groups, AppColors.purple, '${players.length}', 'اللاعبين', ''),
          _StatItem(Icons.emoji_events, AppColors.orange, '$upcomingAll', 'مباريات قادمة', ''),
        ];
        break;

      case UserRole.coach:
        final myPlayers = user.teamId != null
            ? await PlayerService.getPlayersByTeam(user.teamId!)
            : <Player>[];
        final avgRating = myPlayers.isEmpty
            ? 0.0
            : myPlayers.fold<double>(
                    0, (s, p) => s + (double.tryParse(p.rating) ?? 0)) /
                myPlayers.length;
        // ✅ أرقام حقيقية من قاعدة البيانات (كانت '0' ثابتة)
        final teamId = user.teamId ?? '';
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekEnd = today.add(const Duration(days: 7));
        final trainings = teamId.isEmpty
            ? <Training>[]
            : await TrainingService.getTrainingsByTeam(teamId);
        final weekTrainings = trainings.where((t) {
          final d = DateTime(t.date.year, t.date.month, t.date.day);
          return !d.isBefore(today) && d.isBefore(weekEnd);
        }).length;
        final upcomingMatches = teamId.isEmpty
            ? 0
            : (await MatchService.getUpcomingMatches(teamId)).length;
        items = [
          _StatItem(Icons.groups, AppColors.blue, '${myPlayers.length}', 'لاعبين فريقي', ''),
          _StatItem(Icons.calendar_month, AppColors.purple, '$weekTrainings', 'تدريبات الأسبوع', ''),
          _StatItem(Icons.emoji_events, AppColors.orange, '$upcomingMatches', 'مباريات قادمة', ''),
          _StatItem(Icons.star, AppColors.gold, avgRating.toStringAsFixed(1), 'متوسط التقييم', ''),
        ];
        break;

      case UserRole.player:
        final me = await PlayerService.getPlayerByUserId(user.id);
        items = [
          _StatItem(Icons.sports_soccer, AppColors.green, '${me?.goals ?? 0}', 'أهدافي', ''),
          _StatItem(Icons.handshake_outlined, AppColors.blue, '${me?.assists ?? 0}', 'صناعة', ''),
          _StatItem(Icons.calendar_month, AppColors.purple, '${me?.matches ?? 0}', 'مباريات', ''),
          _StatItem(Icons.star, AppColors.gold, me?.rating ?? '0.0', 'تقييمي', ''),
        ];
        break;
    }

    if (!mounted) return;
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox();

    final screenWidth = MediaQuery.of(context).size.width;

    double aspectRatio;
    if (widget.isTablet) {
      aspectRatio = 1.7;
    } else if (screenWidth < 360) {
      aspectRatio = 1.1;
    } else if (screenWidth < 420) {
      aspectRatio = 1.2;
    } else {
      aspectRatio = 1.35;
    }

    return GridView.count(
      crossAxisCount: widget.isTablet ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: aspectRatio,
      children: _items.map((s) => _KpiCard(item: s)).toList(),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _StatItem item;
  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
            ],
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
                if (item.delta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_upward,
                          color: AppColors.green, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        item.delta,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK ACTIONS
// ============================================================
class _ActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _ActionItem(this.icon, this.title, this.subtitle, this.color);
}

class _QuickActionsRow extends StatelessWidget {
  final bool isTablet;
  final AppUser? user;
  final Function(int) onNavigate;

  const _QuickActionsRow({
    required this.isTablet,
    required this.user,
    required this.onNavigate,
  });

  List<_ActionItem> get _items {
    switch (user?.role) {
      case UserRole.admin:
        return const [
          _ActionItem(Icons.person_add, 'إضافة لاعب', 'جديد', AppColors.blue),
          _ActionItem(Icons.sports_rounded, 'أعضاء الأكاديمية', 'المدربين', AppColors.green),
          _ActionItem(Icons.bar_chart, 'التقارير', 'المالية', AppColors.orange),
          _ActionItem(Icons.groups, 'الفرق', 'إدارة', AppColors.purple),
          _ActionItem(Icons.settings, 'الإعدادات', 'الصلاحيات', AppColors.gray),
        ];
      case UserRole.coach:
        return const [
          _ActionItem(Icons.qr_code_scanner, 'مسح QR', 'حضور', AppColors.green),
          _ActionItem(Icons.event_note, 'جدول التدريبات', 'والحضور', AppColors.purple),
          _ActionItem(Icons.star, 'تقييم لاعب', 'سريع', AppColors.gold),
          _ActionItem(Icons.bar_chart, 'التقارير', 'فريقي', AppColors.orange),
          _ActionItem(Icons.settings, 'الإعدادات', 'والصلاحيات', AppColors.gray),
        ];
      case UserRole.player:
        return const [
          _ActionItem(Icons.sports_soccer, 'مبارياتي', 'القادمة', AppColors.green),
          _ActionItem(Icons.fitness_center, 'تدريباتي', 'الأسبوع', AppColors.purple),
          _ActionItem(Icons.bar_chart, 'إحصائياتي', 'الأداء', AppColors.orange),
          _ActionItem(Icons.emoji_events, 'إنجازاتي', 'الجوائز', AppColors.gold),
          _ActionItem(Icons.settings, 'الإعدادات', 'حسابي', AppColors.gray),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) return const SizedBox();

    return GridView.count(
      crossAxisCount: isTablet ? 5 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: items
          .map((a) => _ActionButton(
                item: a,
                onNavigate: onNavigate,
              ))
          .toList(),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final _ActionItem item;
  final Function(int) onNavigate;

  const _ActionButton({
    required this.item,
    required this.onNavigate,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  Color _darken(Color color, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  void _handleTap(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) return;

    switch (widget.item.title) {
      case 'مسح QR':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AttendanceScreen()),
        );
        break;
      case 'جدول التدريبات':
        widget.onNavigate(2);
        break;
      case 'تقييم لاعب':
        widget.onNavigate(1);
        break;

      case 'إضافة لاعب':
        widget.onNavigate(1);
        break;
      case 'أعضاء الأكاديمية':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CoachesScreen()),
        );
        break;
      case 'الفرق':
        widget.onNavigate(2);
        break;

      case 'التقارير':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        );
        break;
      case 'الإعدادات':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;

      case 'مبارياتي':
        widget.onNavigate(1);
        break;
      case 'تدريباتي':
        widget.onNavigate(2);
        break;
      case 'إحصائياتي':
      case 'إنجازاتي':
        widget.onNavigate(3);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    final baseColor = _darken(item.color, 0.20);
    final hoverColor = _darken(item.color, 0.30);
    final pressedColor = _darken(item.color, 0.40);

    final currentColor = _isPressed
        ? pressedColor
        : _isHovered
            ? hoverColor
            : baseColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => _handleTap(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: currentColor,
            boxShadow: [
              BoxShadow(
                color: currentColor.withOpacity(_isHovered ? 0.55 : 0.35),
                blurRadius: _isHovered ? 22 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: Colors.white, size: 28),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 10,
                  ),
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
// UPCOMING SECTION (TrainingService)
// ============================================================
class _EventItem {
  final IconData icon;
  final Color color;
  final String time;
  final String date;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  const _EventItem(this.icon, this.color, this.time, this.date, this.title,
      this.subtitle, this.statusLabel, this.statusColor);
}

class _UpcomingSection extends StatefulWidget {
  const _UpcomingSection();

  @override
  State<_UpcomingSection> createState() => _UpcomingSectionState();
}

class _UpcomingSectionState extends State<_UpcomingSection> {
  List<_EventItem> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final trainings = await TrainingService.getUpcomingTrainings();
      if (!mounted) return;
      setState(() {
        _events = trainings.take(3).map((t) {
          return _EventItem(
            t.icon,
            t.iconColor,
            t.time.isEmpty ? '—' : t.time,
            t.dateString,
            t.title,
            t.location.isEmpty ? '—' : t.location,
            t.statusLabel,
            t.statusColor,
          );
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const GlassCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.green),
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'المباريات والتدريبات القادمة',
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 14),
          if (_events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد تدريبات قادمة',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            for (int i = 0; i < _events.length; i++) ...[
              _EventRow(event: _events[i]),
              if (i != _events.length - 1)
                Divider(color: Colors.white.withOpacity(0.08), height: 20),
            ],
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final _EventItem event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: event.color.withOpacity(0.18), shape: BoxShape.circle),
          child: Icon(event.icon, color: event.color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(event.subtitle,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: event.statusColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(event.statusLabel,
                  style: TextStyle(
                      color: event.statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 4),
            Text('${event.time}  •  ${event.date}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// PLAYER PERFORMANCE + TEAM RANKING
// ============================================================
class _PlayerItem {
  final String number;
  final String name;
  final String role;
  final String rating;
  final String delta;
  final String photo;
  const _PlayerItem(this.number, this.name, this.role, this.rating,
      this.delta, this.photo);
}

class _RankItem {
  final int rank;
  final Color medal;
  final String team;
  final String points;
  const _RankItem(this.rank, this.medal, this.team, this.points);
}

class _PlayersAndRankingSection extends StatefulWidget {
  final AppUser? user;
  const _PlayersAndRankingSection({required this.user});

  @override
  State<_PlayersAndRankingSection> createState() =>
      _PlayersAndRankingSectionState();
}

class _PlayersAndRankingSectionState
    extends State<_PlayersAndRankingSection> {
  List<_PlayerItem> _players = [];
  List<_RankItem> _ranks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final players = await PlayerService.getAllPlayers();
      final sorted = List<Player>.from(players)
        ..sort((a, b) {
          final ra = double.tryParse(a.rating) ?? 0;
          final rb = double.tryParse(b.rating) ?? 0;
          return rb.compareTo(ra);
        });

      List<_RankItem> ranks = [];
      try {
        final standings = await TournamentService.getSortedStandings();
        ranks = standings.take(3).toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final s = entry.value;
          Color medal;
          switch (idx) {
            case 0:
              medal = AppColors.gold;
              break;
            case 1:
              medal = AppColors.silver;
              break;
            case 2:
              medal = AppColors.bronze;
              break;
            default:
              medal = AppColors.gray;
          }
          return _RankItem(
            idx + 1,
            medal,
            s.teamName,
            '${s.points} نقطة',
          );
        }).toList();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _players = sorted.take(3).map((p) {
          return _PlayerItem(
            p.id.length >= 2 ? p.id.substring(p.id.length - 2) : '00',
            p.name,
            p.position,
            p.rating,
            '+0.1',
            p.photo,
          );
        }).toList();
        _ranks = ranks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlayer = widget.user?.role == UserRole.player;

    if (_loading) {
      return const GlassCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.green),
          ),
        ),
      );
    }

    if (isPlayer) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionHeader(
                title: 'أداء اللاعبين',
                icon: Icons.bar_chart,
              ),
              const SizedBox(height: 14),
              if (_players.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'لا توجد بيانات لاعبين',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _players
                      .map((p) => _PlayerAvatarCard(player: p))
                      .toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionHeader(
                title: 'ترتيب الفرق',
                icon: Icons.emoji_events,
              ),
              const SizedBox(height: 12),
              if (_ranks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'لا توجد بيانات ترتيب',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                )
              else
                for (int i = 0; i < _ranks.length; i++) ...[
                  _RankRow(rank: _ranks[i]),
                  if (i != _ranks.length - 1)
                    Divider(color: Colors.white.withOpacity(0.08), height: 18),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerAvatarCard extends StatelessWidget {
  final _PlayerItem player;
  const _PlayerAvatarCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.green, width: 2),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: NetImage(url: player.photo, fallbackIcon: Icons.person),
              ),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(player.rating,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            Positioned(
              bottom: -2,
              left: -2,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: AppColors.surface, shape: BoxShape.circle),
                child: Text(player.number,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(player.name,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        Text(player.role,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_upward, color: AppColors.green, size: 10),
            Text(player.delta,
                style: const TextStyle(
                    color: AppColors.green, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final _RankItem rank;
  const _RankRow({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: rank.medal.withOpacity(0.18), shape: BoxShape.circle),
          child: Center(
              child: Text('${rank.rank}',
                  style: TextStyle(
                      color: rank.medal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rank.team,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              Text(rank.points,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.surfaceLight,
            child: Icon(Icons.shield,
                size: 14, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ============================================================
// QUICK STATS (CIRCULAR)
// ============================================================
class _CircleStatItem {
  final double value;
  final String label;
  final Color color;
  const _CircleStatItem(this.value, this.label, this.color);
}

class _QuickStatsSection extends StatefulWidget {
  final AppUser? user;
  const _QuickStatsSection({required this.user});

  @override
  State<_QuickStatsSection> createState() => _QuickStatsSectionState();
}

class _QuickStatsSectionState extends State<_QuickStatsSection> {
  List<_CircleStatItem> _stats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = widget.user;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    List<_CircleStatItem> stats = [];

    try {
      final players = await PlayerService.getAllPlayers();
      final teams = await TeamService.getAllTeams();

      switch (user.role) {
        case UserRole.admin:
          final withTeam = players.where((p) => p.teamId.isNotEmpty).length;
          final playerRate = players.isEmpty
              ? 0.0
              : withTeam / players.length;

          final teamsWithCoach =
              teams.where((t) => t.coachId.isNotEmpty).length;
          final teamRate =
              teams.isEmpty ? 0.0 : teamsWithCoach / teams.length;

          final avgRating = players.isEmpty
              ? 0.0
              : players.fold<double>(
                      0, (s, p) => s + (double.tryParse(p.rating) ?? 0)) /
                  players.length;

          stats = [
            _CircleStatItem(
              playerRate.clamp(0.0, 1.0),
              'توزيع اللاعبين',
              AppColors.blue,
            ),
            _CircleStatItem(
              teamRate.clamp(0.0, 1.0),
              'تغطية الفرق',
              AppColors.purple,
            ),
            _CircleStatItem(
              (avgRating / 10).clamp(0.0, 1.0),
              'متوسط التقييم',
              AppColors.green,
            ),
          ];
          break;

        case UserRole.coach:
          final myPlayers = user.teamId != null
              ? players.where((p) => p.teamId == user.teamId).toList()
              : <Player>[];

          final avgRating = myPlayers.isEmpty
              ? 0.0
              : myPlayers.fold<double>(
                      0, (s, p) => s + (double.tryParse(p.rating) ?? 0)) /
                  myPlayers.length;

          stats = [
            _CircleStatItem(
              myPlayers.isEmpty
                  ? 0.0
                  : (myPlayers.where((p) => p.ratingValue >= 7).length /
                          myPlayers.length)
                      .clamp(0.0, 1.0),
              'لاعبين متميزين',
              AppColors.blue,
            ),
            _CircleStatItem(
              (avgRating / 10).clamp(0.0, 1.0),
              'متوسط التقييم',
              AppColors.green,
            ),
            _CircleStatItem(
              myPlayers.isEmpty
                  ? 0.0
                  : (myPlayers.where((p) => p.goals > 0).length /
                          myPlayers.length)
                      .clamp(0.0, 1.0),
              'لاعبين هدّافين',
              AppColors.orange,
            ),
          ];
          break;

        case UserRole.player:
          final me = await PlayerService.getPlayerByUserId(user.id);
          if (me != null) {
            stats = [
              _CircleStatItem(
                me.ratingValue / 10,
                'تقييمي',
                AppColors.green,
              ),
              _CircleStatItem(
                (me.goals / 20).clamp(0.0, 1.0),
                'معدل الأهداف',
                AppColors.orange,
              ),
              _CircleStatItem(
                (me.assists / 15).clamp(0.0, 1.0),
                'معدل الصناعة',
                AppColors.blue,
              ),
            ];
          }
          break;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const GlassCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.green),
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(title: 'إحصائيات سريعة'),
          const SizedBox(height: 16),
          if (_stats.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد إحصائيات',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _stats.map((s) => _CircleStat(stat: s)).toList(),
            ),
        ],
      ),
    );
  }
}

class _CircleStat extends StatelessWidget {
  final _CircleStatItem stat;
  const _CircleStat({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: stat.value,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation(stat.color),
                ),
              ),
              Text('${(stat.value * 100).round()}%',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(stat.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

// ============================================================
// RECENT ACTIVITY (ديناميكي)
// ============================================================
class _ActivityItem {
  final IconData icon;
  final Color color;
  final String text;
  final String time;
  const _ActivityItem(this.icon, this.color, this.text, this.time);
}

class _RecentActivitySection extends StatefulWidget {
  final AppUser? user;
  const _RecentActivitySection({required this.user});

  @override
  State<_RecentActivitySection> createState() =>
      _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<_RecentActivitySection> {
  List<_ActivityItem> _activities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<_ActivityItem> activities = [];

    try {
      try {
        final trainings = await TrainingService.getAllTrainings();
        trainings.sort((a, b) => b.date.compareTo(a.date));
        for (final t in trainings.take(2)) {
          activities.add(_ActivityItem(
            Icons.fitness_center,
            AppColors.green,
            'تدريب: ${t.title}',
            t.dateString,
          ));
        }
      } catch (_) {}

      try {
        final matches = await MatchService.getAllMatches();
        matches.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        for (final m in matches.take(2)) {
          final isFinished = m.isFinished;
          activities.add(_ActivityItem(
            Icons.sports_soccer,
            isFinished ? AppColors.blue : AppColors.orange,
            '${m.isFinished ? "ماتش" : "ماتش قادم"}: ${m.teamName} × ${m.opponentName}',
            m.date,
          ));
        }
      } catch (_) {}
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _activities = activities.take(4).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const GlassCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.green),
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'أحدث النشاطات',
            icon: Icons.history,
          ),
          const SizedBox(height: 14),
          if (_activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد نشاطات',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            for (int i = 0; i < _activities.length; i++) ...[
              _ActivityRow(activity: _activities[i]),
              if (i != _activities.length - 1)
                Divider(color: Colors.white.withOpacity(0.08), height: 18),
            ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: activity.color.withOpacity(0.18),
              shape: BoxShape.circle),
          child: Icon(activity.icon, color: activity.color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(activity.text,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12))),
        const SizedBox(width: 8),
        Text(activity.time,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

// ============================================================
// PROMO BANNER
// ============================================================
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 260,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/promo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppColors.surface),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.75),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'معاً نصنع\nمستقبل أفضل',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'أكاديمية النخبة لكرة القدم',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          shadows: const [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 8,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _PromoIconLabel(
                          Icons.trending_up, 'تطوير\nالمهارات'),
                      _PromoIconLabel(Icons.groups, 'بناء\nاللاعبين'),
                      _PromoIconLabel(
                          Icons.emoji_events, 'تحقيق\nالأحلام'),
                    ],
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

class _PromoIconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PromoIconLabel(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black87,
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// QUICK SUMMARY (ديناميكي)
// ============================================================
class _SummaryItem {
  final String value;
  final String label;
  final Color color;
  const _SummaryItem(this.value, this.label, this.color);
}

class _QuickSummarySection extends StatefulWidget {
  final AppUser? user;
  const _QuickSummarySection({required this.user});

  @override
  State<_QuickSummarySection> createState() =>
      _QuickSummarySectionState();
}

class _QuickSummarySectionState extends State<_QuickSummarySection> {
  List<_SummaryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = widget.user;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    List<_SummaryItem> items = [];

    try {
      switch (user.role) {
        case UserRole.admin:
          final teams = await TeamService.getAllTeams();
          final players = await PlayerService.getAllPlayers();
          final trainings = await TrainingService.getAllTrainings();

          items = [
            _SummaryItem('${teams.length}', 'إجمالي الفرق', AppColors.blue),
            _SummaryItem(
                '${players.length}', 'إجمالي اللاعبين', AppColors.green),
            _SummaryItem(
                '${trainings.length}', 'إجمالي التدريبات', AppColors.purple),
          ];
          break;

        case UserRole.coach:
          final myPlayers = user.teamId != null
              ? await PlayerService.getPlayersByTeam(user.teamId!)
              : <Player>[];
          final allTrainings = await TrainingService.getAllTrainings();
          final myTrainings = user.teamId != null
              ? allTrainings.where((t) => t.teamId == user.teamId).length
              : 0;

          items = [
            _SummaryItem(
                '${myPlayers.length}', 'لاعبين فريقي', AppColors.blue),
            _SummaryItem(
                '$myTrainings', 'تدريبات فريقي', AppColors.green),
            _SummaryItem('${myPlayers.where((p) => p.goals > 0).length}',
                'لاعبين هدّافين', AppColors.orange),
          ];
          break;

        case UserRole.player:
          final me = await PlayerService.getPlayerByUserId(user.id);
          if (me != null) {
            items = [
              _SummaryItem('${me.goals}', 'أهدافي', AppColors.green),
              _SummaryItem('${me.assists}', 'صناعتي', AppColors.blue),
              _SummaryItem('${me.matches}', 'مبارياتي', AppColors.purple),
            ];
          }
          break;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const GlassCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.green),
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department,
                  color: AppColors.orange, size: 18),
              SizedBox(width: 6),
              Text('ملخص سريع',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد بيانات',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            for (int i = 0; i < _items.length; i++) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_items[i].value,
                      style: TextStyle(
                          color: _items[i].color,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_items[i].label,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11)),
                  ),
                ],
              ),
              if (i != _items.length - 1)
                Divider(color: Colors.white.withOpacity(0.08), height: 18),
            ],
          const SizedBox(height: 8),
          const Text('"الالتزام اليوم يصنع الأبطال غداً"',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

// ============================================================
// TODAY DETAILS BOTTOM SHEET (ديناميكي)
// ============================================================
void _showTodayDetails(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _TodayDetailsSheet(),
  );
}

class _TodayDetailsSheet extends StatelessWidget {
  const _TodayDetailsSheet();

  @override
  Widget build(BuildContext context) {
    return AppDirectionality(
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
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
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 45,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
                              color: AppColors.green.withOpacity(0.15),
                              border: Border.all(
                                color: AppColors.green,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.today_rounded,
                              color: AppColors.green,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تفاصيل اليوم',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'ملخص شامل لكل أنشطة اليوم',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            _TodaySummaryRow(),
                            SizedBox(height: 20),
                            _TodaySectionTitle(
                              title: 'التدريبات النهاردة',
                              icon: Icons.fitness_center,
                            ),
                            SizedBox(height: 10),
                            _TodayTrainingCard(),
                            SizedBox(height: 20),
                            _TodaySectionTitle(
                              title: 'المباريات النهاردة',
                              icon: Icons.emoji_events,
                            ),
                            SizedBox(height: 10),
                            _TodayMatchCard(),
                            SizedBox(height: 20),
                            _TodaySectionTitle(
                              title: 'حضور اللاعبين',
                              icon: Icons.groups,
                            ),
                            SizedBox(height: 10),
                            _TodayAttendanceCard(),
                            SizedBox(height: 20),
                            _TodaySectionTitle(
                              title: 'ملاحظات المدرب',
                              icon: Icons.edit_note,
                            ),
                            SizedBox(height: 10),
                            _TodayNotesCard(),
                            SizedBox(height: 20),
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
    );
  }
}

class _TodaySummaryRow extends StatefulWidget {
  const _TodaySummaryRow();

  @override
  State<_TodaySummaryRow> createState() => _TodaySummaryRowState();
}

class _TodaySummaryRowState extends State<_TodaySummaryRow> {
  int _trainingCount = 0;
  int _matchCount = 0;
  int _attendanceCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int trCount = 0;
    try {
      final trainings = await TrainingService.getAllTrainings();
      trCount = trainings.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        return d == today;
      }).length;
    } catch (_) {}

    int mtCount = 0;
    try {
      final matches = await MatchService.getAllMatches();
      mtCount = matches.where((m) {
        final d = m.dateTime;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).length;
    } catch (_) {}

    int attCount = 0;
    try {
      final todayAttendance = await AttendanceService.getForDate(today);
      attCount = todayAttendance.values
          .where((s) => s.name == 'present')
          .length;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _trainingCount = trCount;
      _matchCount = mtCount;
      _attendanceCount = attCount;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.fitness_center,
            value: _loading ? '...' : '$_trainingCount',
            label: 'تدريبات',
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.emoji_events,
            value: _loading ? '...' : '$_matchCount',
            label: 'مباراة',
            color: AppColors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.groups,
            value: _loading ? '...' : '$_attendanceCount',
            label: 'حاضر',
            color: AppColors.blue,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _TodaySectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.green, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TodayTrainingCard extends StatefulWidget {
  const _TodayTrainingCard();

  @override
  State<_TodayTrainingCard> createState() => _TodayTrainingCardState();
}

class _TodayTrainingCardState extends State<_TodayTrainingCard> {
  bool _loading = true;
  List<dynamic> _todayTrainings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    try {
      final trainings = await TrainingService.getAllTrainings();
      final list = trainings.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        return d == today;
      }).toList();
      if (!mounted) return;
      setState(() {
        _todayTrainings = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_todayTrainings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.025),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_soccer, color: AppColors.green, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'لا توجد تدريبات النهاردة',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: _todayTrainings.map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.025),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.sports_soccer, color: AppColors.green, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${t.title} - ${t.time}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _TodayMatchCard extends StatefulWidget {
  const _TodayMatchCard();

  @override
  State<_TodayMatchCard> createState() => _TodayMatchCardState();
}

class _TodayMatchCardState extends State<_TodayMatchCard> {
  bool _loading = true;
  List<dynamic> _todayMatches = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    try {
      final matches = await MatchService.getAllMatches();
      final list = matches.where((m) {
        final d = m.dateTime;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();
      if (!mounted) return;
      setState(() {
        _todayMatches = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_todayMatches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.025),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events, color: AppColors.orange, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'لا توجد مباريات النهاردة',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: _todayMatches.map((m) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.025),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${m.teamName} × ${m.opponentName} - ${m.time}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _TodayAttendanceCard extends StatefulWidget {
  const _TodayAttendanceCard();

  @override
  State<_TodayAttendanceCard> createState() => _TodayAttendanceCardState();
}

class _TodayAttendanceCardState extends State<_TodayAttendanceCard> {
  int _present = 0;
  int _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int pres = 0;
    try {
      final att = await AttendanceService.getForDate(today);
      pres = att.values.where((s) => s.name == 'present').length;
    } catch (_) {}

    int tot = 0;
    try {
      final players = await PlayerService.getAllPlayers();
      tot = players.length;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _present = pres;
      _total = tot;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final percentage = _total == 0 ? 0.0 : (_present / _total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _loading ? '...' : '${(percentage * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'نسبة الحضور',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _loading ? '...' : '$_present من $_total لاعب',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _loading ? 0 : percentage,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: const AlwaysStoppedAnimation(AppColors.green),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayNotesCard extends StatelessWidget {
  const _TodayNotesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.3),
        ),
      ),
      child: const Text(
        'لا توجد ملاحظات',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.6,
        ),
      ),
    );
  }
}