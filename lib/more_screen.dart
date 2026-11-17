// lib/more_screen.dart

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
import 'widgets/top_header.dart';
import 'models/app_user.dart';
import 'services/auth_service.dart';
import 'services/player_service.dart';
import 'services/match_service.dart';
import 'services/training_service.dart';
import 'tournaments_screen.dart';
import 'teams_screen.dart';
import 'attendance_screen.dart';
import 'my_attendance_screen.dart';
import 'coaches_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'reports_screen.dart';
import 'my_reports_screen.dart';
import 'my_coaches_screen.dart';

// ============================================================
// MORE SCREEN
// ============================================================

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final device = deviceTypeOf(constraints.maxWidth);

        return AppDirectionality(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              110,
            ),
            child: _MoreBody(device: device),
          ),
        );
      },
    );
  }
}

// ============================================================
// BODY
// ============================================================

class _MoreBody extends StatelessWidget {
  final DeviceType device;

  const _MoreBody({
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool mobile = width < 700;
    final bool tablet = width >= 700 && width < 1100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TopHeader(),

        const SizedBox(height: 14),

        const _MoreHero(),

        const SizedBox(height: 14),

        const _AcademyBanner(),

        const SizedBox(height: 24),

        const _SectionTitle(
          title: 'الميزات الرئيسية',
          icon: Icons.star_rounded,
        ),

        const SizedBox(height: 12),

        _FeaturesGrid(
          mobile: mobile,
          tablet: tablet,
        ),

        const SizedBox(height: 18),

        if (mobile) ...[
          const _AcademyInformation(),
          const SizedBox(height: 14),
          const _QuickStatistics(),
          const SizedBox(height: 14),
          const _BottomPromo(),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                flex: 5,
                child: _AcademyInformation(),
              ),
              const SizedBox(width: 14),
              const Expanded(
                flex: 5,
                child: _QuickStatistics(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _BottomPromo(),
        ],
      ],
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _MoreHero extends StatelessWidget {
  const _MoreHero();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final mobile = width < 700;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: mobile ? 260 : 245,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppImages.coachStadium,
              fit: BoxFit.cover,
            ),

            // DARK OVERLAY
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(.45),
                    Colors.black.withOpacity(.52),
                    Colors.black.withOpacity(.78),
                  ],
                ),
              ),
            ),

            // MOBILE
            if (mobile) const _MobileMoreHero(),

            // DESKTOP
            if (!mobile) const _DesktopMoreHero(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MOBILE HERO
// ============================================================

class _MobileMoreHero extends StatelessWidget {
  const _MobileMoreHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 240,
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
                    Colors.black.withOpacity(0.68),
                    Colors.black.withOpacity(0.28),
                    AppColors.green.withOpacity(0.22),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 28,
              right: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'المزيد',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 27,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Icon(
                        Icons.grid_view_rounded,
                        color: AppColors.green,
                        size: 32,
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'كل ما تحتاجه في مكان واحد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 20,
              bottom: 30,
              child: SizedBox(
                width: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Better\nPlayers\nBigger\nDreams',
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'DancingScript',
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 20,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green.withOpacity(.5),
                            blurRadius: 10,
                          ),
                        ],
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
// DESKTOP HERO
// ============================================================

class _DesktopMoreHero extends StatelessWidget {
  const _DesktopMoreHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 28,
          top: 52,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Better\nPlayers\nBigger\nDreams',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'DancingScript',
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 20,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),

        Positioned(
          right: 30,
          top: 57,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Text(
                    'المزيد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
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
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.grid_view_rounded,
                    color: AppColors.green,
                    size: 38,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              const Text(
                'كل ما تحتاجه في مكان واحد',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ACADEMY BANNER
// ============================================================

class _AcademyBanner extends StatelessWidget {
  const _AcademyBanner();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 17,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.green,
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elite Football Academy',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Developing Future Champions',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    'معًا نصنع أبطال المستقبل',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.green,
                    size: 22,
                  ),
                ],
              ),
              SizedBox(height: 6),
              SizedBox(
                width: 115,
                child: Divider(
                  color: AppColors.green,
                  thickness: 2,
                ),
              ),
            ],
          ),
        ],
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

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.green,
          size: 23,
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FEATURES GRID — حسب الدور
// ============================================================

class _FeaturesGrid extends StatelessWidget {
  final bool mobile;
  final bool tablet;

  const _FeaturesGrid({
    required this.mobile,
    required this.tablet,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    // ✅ الأقسام حسب الدور
    List<_FeatureData> features;
    switch (user?.role) {
      case UserRole.admin:
        features = [
          const _FeatureData(
            icon: Icons.emoji_events_rounded,
            title: 'البطولات والمباريات',
            subtitle: 'الجدول والنتائج',
            color: AppColors.orange,
          ),
          const _FeatureData(
            icon: Icons.calendar_month_rounded,
            title: 'الحضور والغياب',
            subtitle: 'متابعة الحضور',
            color: AppColors.green,
          ),
          const _FeatureData(
            icon: Icons.groups_rounded,
            title: 'الفرق',
            subtitle: 'مجموعات اللاعبين',
            color: AppColors.blue,
          ),
          const _FeatureData(
            icon: Icons.person_rounded,
            title: 'المدربين',
            subtitle: 'فريق العمل الفني',
            color: AppColors.purple,
          ),
          const _FeatureData(
            icon: Icons.person_outline_rounded,
            title: 'الملف الشخصي',
            subtitle: 'بياناتك الشخصية',
            color: AppColors.green,
          ),
          const _FeatureData(
            icon: Icons.settings_rounded,
            title: 'الإعدادات',
            subtitle: 'تخصيص التطبيق',
            color: AppColors.blue,
          ),
          const _FeatureData(
            icon: Icons.notifications_rounded,
            title: 'الإشعارات',
            subtitle: 'كل جديد من الأكاديمية',
            color: AppColors.orange,
          ),
          const _FeatureData(
            icon: Icons.description_rounded,
            title: 'التقارير',
            subtitle: 'تقارير الأداء والإحصائيات',
            color: AppColors.purple,
          ),
        ];
        break;

      case UserRole.coach:
        features = [
          const _FeatureData(
            icon: Icons.emoji_events_rounded,
            title: 'البطولات والمباريات',
            subtitle: 'الجدول والنتائج',
            color: AppColors.orange,
          ),
          const _FeatureData(
            icon: Icons.calendar_month_rounded,
            title: 'الحضور والغياب',
            subtitle: 'متابعة الحضور',
            color: AppColors.green,
          ),
          const _FeatureData(
            icon: Icons.groups_rounded,
            title: 'الفرق',
            subtitle: 'مجموعات اللاعبين',
            color: AppColors.blue,
          ),
          const _FeatureData(
            icon: Icons.person_outline_rounded,
            title: 'الملف الشخصي',
            subtitle: 'بياناتك الشخصية',
            color: AppColors.green,
          ),
          const _FeatureData(
            icon: Icons.settings_rounded,
            title: 'الإعدادات',
            subtitle: 'تخصيص التطبيق',
            color: AppColors.blue,
          ),
          const _FeatureData(
            icon: Icons.notifications_rounded,
            title: 'الإشعارات',
            subtitle: 'كل جديد من الأكاديمية',
            color: AppColors.orange,
          ),
          const _FeatureData(
            icon: Icons.description_rounded,
            title: 'التقارير',
            subtitle: 'تقارير الأداء والإحصائيات',
            color: AppColors.purple,
          ),
        ];
        break;

      case UserRole.player:
        features = [
          const _FeatureData(
            icon: Icons.emoji_events_rounded,
            title: 'البطولات والمباريات',
            subtitle: 'الجدول والنتائج',
            color: AppColors.orange,
          ),
          const _FeatureData(
            icon: Icons.calendar_month_rounded,
            title: 'الحضور والغياب',
            subtitle: 'حضوري',
            color: AppColors.green,
          ),
          const _FeatureData(
            icon: Icons.description_rounded,
            title: 'التقارير',
            subtitle: 'تقرير أدائي',
            color: AppColors.purple,
          ),
          const _FeatureData(
            icon: Icons.workspace_premium_rounded,
            title: 'المدربين',
            subtitle: 'مدربي',
            color: AppColors.blue,
          ),
          const _FeatureData(
            icon: Icons.person_outline_rounded,
            title: 'الملف الشخصي',
            subtitle: 'بياناتك الشخصية',
            color: AppColors.green,
          ),
          const _FeatureData(
            icon: Icons.settings_rounded,
            title: 'الإعدادات',
            subtitle: 'تخصيص التطبيق',
            color: AppColors.blue,
          ),
          const _FeatureData(
            icon: Icons.notifications_rounded,
            title: 'الإشعارات',
            subtitle: 'كل جديد',
            color: AppColors.orange,
          ),
        ];
        break;

      default:
        features = [];
    }

    int columns;

    if (mobile) {
      columns = 2;
    } else if (tablet) {
      columns = 3;
    } else {
      columns = 4;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: mobile ? 172 : 182,
      ),
      itemBuilder: (context, index) {
        return _FeatureCard(
          data: features[index],
        );
      },
    );
  }
}

// ============================================================
// FEATURE DATA
// ============================================================

class _FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

// ============================================================
// FEATURE CARD
// ============================================================

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;

  const _FeatureCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () {
        final user = AuthService.currentUser;

        if (data.title == 'البطولات والمباريات') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TournamentsScreen(),
            ),
          );
        } else if (data.title == 'الفرق') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TeamsScreen()),
          );
        } else if (data.title == 'الحضور والغياب') {
          if (user?.role == UserRole.player) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyAttendanceScreen(),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AttendanceScreen(),
              ),
            );
          }
        } else if (data.title == 'المدربين') {
          if (user?.role == UserRole.player) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyCoachesScreen(),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CoachesScreen(),
              ),
            );
          }
        } else if (data.title == 'الملف الشخصي') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        } else if (data.title == 'الإعدادات') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        } else if (data.title == 'الإشعارات') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        } else if (data.title == 'التقارير') {
          if (user?.role == UserRole.player) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyReportsScreen(),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ReportsScreen(),
              ),
            );
          }
        }
      },
      child: GlassCard(
        radius: 17,
        padding: const EdgeInsets.all(13),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 67,
              height: 67,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.color.withOpacity(.06),
                border: Border.all(
                  color: data.color.withOpacity(.75),
                  width: 1,
                ),
              ),
              child: Icon(
                data.icon,
                color: data.color,
                size: 31,
              ),
            ),

            const SizedBox(height: 11),

            Text(
              data.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),

            const SizedBox(height: 8),

            const Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ACADEMY INFORMATION
// ============================================================

class _AcademyInformation extends StatelessWidget {
  const _AcademyInformation();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.shield_rounded,
                color: AppColors.green,
                size: 21,
              ),
              SizedBox(width: 7),
              Text(
                'معلومات الأكاديمية',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _InfoRow(
            icon: Icons.location_on_rounded,
            title: 'الموقع',
            value: 'القاهرة - مصر',
          ),

          _InfoRow(
            icon: Icons.email_rounded,
            title: 'البريد الإلكتروني',
            value: 'info@eliteacademy.com',
          ),

          _InfoRow(
            icon: Icons.phone_rounded,
            title: 'رقم الهاتف',
            value: '+20 101 234 5678',
          ),

          _InfoRow(
            icon: Icons.language_rounded,
            title: 'الموقع الإلكتروني',
            value: 'www.eliteacademy.com',
          ),

        ],
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.green.withOpacity(.65),
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.green,
              size: 18,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
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
// QUICK STATISTICS — ديناميكية من الـ Services
// ============================================================

class _QuickStatistics extends StatefulWidget {
  const _QuickStatistics();

  @override
  State<_QuickStatistics> createState() => _QuickStatisticsState();
}

class _QuickStatisticsState extends State<_QuickStatistics> {
  int _playersCount = 0;
  int _matchesCount = 0;
  int _trainingsCount = 0;
  String _avgRating = '0.0';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final players = await PlayerService.getAllPlayers();
      final matches = await MatchService.getAllMatches();
      final trainings = await TrainingService.getAllTrainings();

      final avg = players.isEmpty
          ? 0.0
          : players.fold<double>(
                  0, (s, p) => s + (double.tryParse(p.rating) ?? 0)) /
              players.length;

      if (!mounted) return;
      setState(() {
        _playersCount = players.length;
        _matchesCount = matches.length;
        _trainingsCount = trainings.length;
        _avgRating = avg.toStringAsFixed(1);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: AppColors.green,
                size: 21,
              ),
              SizedBox(width: 7),
              Text(
                'إحصائيات سريعة',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.green),
              ),
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: [
                _QuickStat(
                  icon: Icons.groups_rounded,
                  value: '$_playersCount',
                  title: 'إجمالي اللاعبين',
                  color: AppColors.green,
                ),
                _QuickStat(
                  icon: Icons.emoji_events_rounded,
                  value: '$_matchesCount',
                  title: 'المباريات',
                  color: AppColors.orange,
                ),
                _QuickStat(
                  icon: Icons.fitness_center_rounded,
                  value: '$_trainingsCount',
                  title: 'التدريبات',
                  color: AppColors.blue,
                ),
                _QuickStat(
                  icon: Icons.star_rounded,
                  value: _avgRating,
                  title: 'متوسط التقييم',
                  color: AppColors.orange,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK STAT
// ============================================================

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.value,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(.55),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(.65),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 8,
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
// BOTTOM PROMO
// ============================================================

class _BottomPromo extends StatelessWidget {
  const _BottomPromo();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: SizedBox(
        height: 105,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const NetImage(
              url: AppImages.heroPlayersBackground,
              fallbackIcon: Icons.sports_soccer_rounded,
            ),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.black.withOpacity(.78),
                    Colors.black.withOpacity(.45),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.green.withOpacity(.10),
                      border: Border.all(
                        color: AppColors.green,
                      ),
                    ),
                    child: const Icon(
                      Icons.sports_soccer_rounded,
                      color: AppColors.green,
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'معًا نبني مستقبل أفضل',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'أكاديمية النخبة لتطوير المواهب',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
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