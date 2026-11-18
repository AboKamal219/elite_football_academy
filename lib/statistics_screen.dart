// lib/statistics_screen.dart

import 'dart:math' as math;
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
import 'models/app_user.dart';
import 'models/match.dart';
import 'models/player.dart';
import 'models/training.dart';
import 'services/auth_service.dart';
import 'services/match_service.dart';
import 'services/player_service.dart';
import 'services/training_service.dart';
import 'widgets/top_header.dart';

// ============================================================
// ✅ STATS PERIOD
// ============================================================
enum StatsPeriod { thisWeek, thisMonth, thisSeason, allTime }

extension StatsPeriodX on StatsPeriod {
  String get label {
    switch (this) {
      case StatsPeriod.thisWeek:
        return 'هذا الأسبوع';
      case StatsPeriod.thisMonth:
        return 'هذا الشهر';
      case StatsPeriod.thisSeason:
        return 'هذا الموسم';
      case StatsPeriod.allTime:
        return 'كل المواسم';
    }
  }

  bool contains(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    switch (this) {
      case StatsPeriod.thisWeek:
        final weekAgo = today.subtract(const Duration(days: 7));
        return !target.isBefore(weekAgo) && !target.isAfter(today);
      case StatsPeriod.thisMonth:
        return target.year == now.year && target.month == now.month;
      case StatsPeriod.thisSeason:
        return target.year == now.year;
      case StatsPeriod.allTime:
        return true;
    }
  }
}

// ============================================================
// STATISTICS SCREEN
// ============================================================
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Player? _player;
  List<Player> _allPlayers = [];
  List<Match> _matches = [];
  List<Training> _trainings = [];
  bool _loading = true;

  StatsPeriod _period = StatsPeriod.thisMonth;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AuthService.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final allMatches = await MatchService.getAllMatches();
    final allTrainings = await TrainingService.getAllTrainings();

    if (user.role == UserRole.player) {
      final me = await PlayerService.getPlayerByUserId(user.id);
      if (!mounted) return;
      setState(() {
        _player = me;
        _matches = allMatches;
        _trainings = allTrainings;
        _loading = false;
      });
    } else if (user.role == UserRole.coach) {
      final players = user.teamId != null
          ? await PlayerService.getPlayersByTeam(user.teamId!)
          : <Player>[];
      if (!mounted) return;
      setState(() {
        _allPlayers = players;
        _matches = allMatches;
        _trainings = allTrainings;
        _loading = false;
      });
    } else {
      final players = await PlayerService.getAllPlayers();
      if (!mounted) return;
      setState(() {
        _allPlayers = players;
        _matches = allMatches;
        _trainings = allTrainings;
        _loading = false;
      });
    }
  }

  List<Match> get _filteredMatches {
    return _matches.where((m) => _period.contains(m.dateTime)).toList();
  }

  List<Training> get _filteredTrainings {
    return _trainings.where((t) => _period.contains(t.date)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final device = deviceTypeOf(constraints.maxWidth);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          child: _StatisticsBody(
            device: device,
            player: _player,
            allPlayers: _allPlayers,
            matches: _filteredMatches,
            allMatches: _matches,
            trainings: _filteredTrainings,
            period: _period,
            onPeriodChanged: (p) => setState(() => _period = p),
            loading: _loading,
          ),
        );
      },
    );
  }
}

// ============================================================
// BODY
// ============================================================
class _StatisticsBody extends StatelessWidget {
  final DeviceType device;
  final Player? player;
  final List<Player> allPlayers;
  final List<Match> matches;
  final List<Match> allMatches;
  final List<Training> trainings;
  final StatsPeriod period;
  final ValueChanged<StatsPeriod> onPeriodChanged;
  final bool loading;

  const _StatisticsBody({
    required this.device,
    required this.player,
    required this.allPlayers,
    required this.matches,
    required this.allMatches,
    required this.trainings,
    required this.period,
    required this.onPeriodChanged,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = device == DeviceType.tablet;
    final user = AuthService.currentUser;
    final isPlayer = user?.role == UserRole.player;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TopHeader(),
        const SizedBox(height: 16),
        _StatisticsHero(user: user),
        const SizedBox(height: 16),
        _PeriodTabs(current: period, onChanged: onPeriodChanged),
        const SizedBox(height: 16),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.green),
            ),
          )
        else ...[
          _KpiSection(
            user: user,
            player: player,
            allPlayers: allPlayers,
            matches: matches,
            trainings: trainings,
            period: period,
          ),
          const SizedBox(height: 16),
          if (isPlayer) ...[
            _PlayerCharts(
              isTablet: isTablet,
              player: player,
              matches: matches,
            ),
          ] else ...[
            _TopCharts(isTablet: isTablet, allPlayers: allPlayers),
          ],
          const SizedBox(height: 16),
          if (isPlayer) ...[
            _PlayerPerformanceCard(
              player: player,
              matches: matches,
            ),
          ] else ...[
            _MiddleCharts(
              isTablet: isTablet,
              allPlayers: allPlayers,
              allMatches: allMatches,
            ),
          ],
          const SizedBox(height: 16),
          if (isPlayer) ...[
            _PlayerInsightsCard(player: player),
          ] else ...[
            _BottomCharts(
              isTablet: isTablet,
              allPlayers: allPlayers,
            ),
          ],
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

// ============================================================
// HERO
// ============================================================
class _StatisticsHero extends StatelessWidget {
  final AppUser? user;
  const _StatisticsHero({required this.user});

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;
    IconData icon;

    switch (user?.role) {
      case UserRole.player:
        title = 'إحصائياتي';
        subtitle = 'تطورك في الأرقام .. ومسارك في الملعب';
        icon = Icons.person;
        break;
      case UserRole.coach:
        title = 'إحصائيات فريقي';
        subtitle = 'أرقام فريقك .. وأداء لاعبيك';
        icon = Icons.groups;
        break;
      case UserRole.admin:
      default:
        title = 'الإحصائيات';
        subtitle = 'أرقام تصنع الفرق .. وتكشف الإمكانيات';
        icon = Icons.bar_chart_rounded;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 240,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppImages.heroPlayersBackground,
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
                        title,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 29,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Icon(icon, color: AppColors.green, size: 28),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 22,
              bottom: 24,
              child: SizedBox(
                width: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data',
                      style: TextStyle(
                        fontFamily: 'DancingScript',
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Drives',
                      style: TextStyle(
                        fontFamily: 'DancingScript',
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Better',
                      style: TextStyle(
                        fontFamily: 'DancingScript',
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Decisions',
                      style: TextStyle(
                        fontFamily: 'DancingScript',
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      width: 80,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green.withOpacity(0.5),
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
// PERIOD TABS
// ============================================================
class _PeriodTabs extends StatelessWidget {
  final StatsPeriod current;
  final ValueChanged<StatsPeriod> onChanged;

  const _PeriodTabs({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.28),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.green.withOpacity(0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: StatsPeriod.values.map((p) {
              return _PeriodTab(
                title: p.label,
                active: p == current,
                onTap: () => onChanged(p),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _PeriodTab extends StatefulWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  State<_PeriodTab> createState() => _PeriodTabState();
}

class _PeriodTabState extends State<_PeriodTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final isHovered = _isHovered;

    Color bgColor;
    Color textColor;

    if (active) {
      bgColor = AppColors.green;
      textColor = Colors.white;
    } else if (isHovered) {
      bgColor = AppColors.green.withOpacity(0.15);
      textColor = AppColors.green;
    } else {
      bgColor = Colors.transparent;
      textColor = AppColors.textSecondary;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            widget.title,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// KPI SECTION
// ============================================================
class _KpiSection extends StatelessWidget {
  final AppUser? user;
  final Player? player;
  final List<Player> allPlayers;
  final List<Match> matches;
  final List<Training> trainings;
  final StatsPeriod period;

  const _KpiSection({
    required this.user,
    required this.player,
    required this.allPlayers,
    required this.matches,
    required this.trainings,
    required this.period,
  });

  int _estimatedGoals(Player? p, int filteredMatches) {
    if (p == null || p.matches == 0) return 0;
    return ((p.goals / p.matches) * filteredMatches).round();
  }

  int _estimatedAssists(Player? p, int filteredMatches) {
    if (p == null || p.matches == 0) return 0;
    return ((p.assists / p.matches) * filteredMatches).round();
  }

  List<_KpiData> get _items {
    switch (user?.role) {
      case UserRole.player:
        final filteredCount = matches.length;
        final goals = _estimatedGoals(player, filteredCount);
        final assists = _estimatedAssists(player, filteredCount);

        return [
          _KpiData(
            title: 'أهدافي',
            value: '$goals',
            change: '',
            icon: Icons.sports_soccer,
            color: AppColors.green,
          ),
          _KpiData(
            title: 'صناعتي',
            value: '$assists',
            change: '',
            icon: Icons.handshake_outlined,
            color: Colors.blue,
          ),
          _KpiData(
            title: 'مبارياتي',
            value: '$filteredCount',
            change: '',
            icon: Icons.calendar_month,
            color: Colors.purple,
          ),
          _KpiData(
            title: 'تقييمي',
            value: player?.rating ?? '0.0',
            change: '',
            icon: Icons.star,
            color: Colors.orange,
          ),
          _KpiData(
            title: 'بطاقاتي',
            value: '${(player?.yellowCards ?? 0) + (player?.redCards ?? 0)}',
            change: '',
            icon: Icons.sports_score,
            color: AppColors.gold,
          ),
        ];

      case UserRole.coach:
      case UserRole.admin:
      default:
        final totalGoals =
            allPlayers.fold<int>(0, (sum, p) => sum + p.goals);
        final totalAssists =
            allPlayers.fold<int>(0, (sum, p) => sum + p.assists);
        final avgRating = allPlayers.isEmpty
            ? 0.0
            : allPlayers.fold<double>(0,
                    (sum, p) => sum + (double.tryParse(p.rating) ?? 0)) /
                allPlayers.length;

        return [
          _KpiData(
            title: 'إجمالي اللاعبين',
            value: '${allPlayers.length}',
            change: '',
            icon: Icons.person,
            color: AppColors.green,
          ),
          _KpiData(
            title: 'الماتشات',
            value: '${matches.length}',
            change: '',
            icon: Icons.sports_soccer,
            color: Colors.purpleAccent,
          ),
          _KpiData(
            title: 'التدريبات',
            value: '${trainings.length}',
            change: '',
            icon: Icons.fitness_center,
            color: Colors.lightBlue,
          ),
          _KpiData(
            title: 'متوسط التقييم',
            value: avgRating.toStringAsFixed(1),
            change: '',
            icon: Icons.star,
            color: Colors.orange,
          ),
          _KpiData(
            title: 'معدل الأداء',
            value: '${((avgRating / 10) * 100).round()}%',
            change: '',
            icon: Icons.shield,
            color: AppColors.green,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isSmall ? 2 : 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 164,
          ),
          itemBuilder: (_, index) {
            return _KpiCard(data: items[index]);
          },
        );
      },
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });
}

class _KpiCard extends StatefulWidget {
  final _KpiData data;

  const _KpiCard({
    required this.data,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: GlassCard(
          radius: 17,
          padding: const EdgeInsets.all(13),
          child: Column(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.color.withOpacity(0.08),
                  border: Border.all(
                    color: data.color.withOpacity(_isHovered ? 1.0 : 0.70),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: 23,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                data.value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              if (data.change.isNotEmpty)
                Text(
                  data.change,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 10,
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
// PLAYER CHARTS (لللاعب بس)
// ============================================================
class _PlayerCharts extends StatelessWidget {
  final bool isTablet;
  final Player? player;
  final List<Match> matches;
  const _PlayerCharts({
    required this.isTablet,
    required this.player,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTablet) {
      return Column(
        children: [
          _PlayerPerformanceChartCard(player: player, matches: matches),
          const SizedBox(height: 16),
          _PlayerRadarCard(player: player),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _PlayerPerformanceChartCard(player: player, matches: matches),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _PlayerRadarCard(player: player),
        ),
      ],
    );
  }
}

class _PlayerPerformanceChartCard extends StatelessWidget {
  final Player? player;
  final List<Match> matches;
  const _PlayerPerformanceChartCard({required this.player, required this.matches});

  @override
  Widget build(BuildContext context) {
    // ✅ استخراج التقييمات الحقيقية من الماتشات اللي خلصت
    final ratings = matches
        .where((m) => m.isFinished && m.playerRating.isNotEmpty)
        .map((m) => double.tryParse(m.playerRating) ?? 0.0)
        .where((r) => r > 0)
        .toList();

    final hasData = ratings.isNotEmpty;
    final lastRating = hasData ? ratings.last : (double.tryParse(player?.rating ?? '0.0') ?? 0.0);
    
    // لو مفيش داتا كفاية، نعرض خط ثابت
    final values = hasData && ratings.length > 1
        ? ratings
        : [lastRating, lastRating, lastRating, lastRating, lastRating];

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(
                Icons.insights,
                color: AppColors.green,
                size: 20,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'تطور أدائي',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'لا توجد تقييمات مسجلة في المباريات',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            SizedBox(
              height: 235,
              child: CustomPaint(
                painter: _LineChartPainter(
                  values: values,
                  lastLabel: lastRating.toStringAsFixed(1),
                  labels: _generateMatchLabels(matches),
                ),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _generateMatchLabels(List<Match> matches) {
    final finished = matches.where((m) => m.isFinished).toList();
    if (finished.isEmpty) return ['—', '—', '—', '—', '—'];
    return finished.map((m) => m.date).toList();
  }
}

class _PlayerRadarCard extends StatelessWidget {
  final Player? player;
  const _PlayerRadarCard({required this.player});

  @override
  Widget build(BuildContext context) {
    // ⚠️ ملاحظة: دي مهارات ثابتة بناءً على المركز.
    // عشان تخليها حقيقية، محتاج جدول player_skills في الداتابيز.
    final values = _radarValuesForPosition(player?.position ?? '');

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(13),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(
                Icons.radar,
                color: AppColors.green,
                size: 20,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'مهاراتي الفنية',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 245,
            child: CustomPaint(
              painter: _RadarPainter(values: values),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  List<double> _radarValuesForPosition(String position) {
    switch (position) {
      case 'مهاجم':
        return [0.82, 0.76, 0.84, 0.78, 0.88];
      case 'وسط ميدان':
        return [0.88, 0.72, 0.82, 0.80, 0.85];
      case 'مدافع':
        return [0.72, 0.68, 0.86, 0.70, 0.90];
      case 'حارس مرمى':
        return [0.70, 0.60, 0.88, 0.65, 0.86];
      default:
        return [0.75, 0.70, 0.80, 0.72, 0.82];
    }
  }
}

// ============================================================
// ✅ PLAYER PERFORMANCE CARD
// ============================================================
class _PlayerPerformanceCard extends StatelessWidget {
  final Player? player;
  final List<Match> matches;
  const _PlayerPerformanceCard({
    required this.player,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    final finishedWithRating = matches
        .where((m) => m.isFinished && m.playerRating.isNotEmpty)
        .toList();

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 20,
              ),
              SizedBox(width: 6),
              Text(
                'تقييمي في آخر المباريات',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (finishedWithRating.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد مباريات مسجلة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...finishedWithRating.map((m) {
              return _MatchRatingRow(
                opponent: m.opponentName,
                date: m.date,
                rating: m.playerRating,
                result: m.resultLabel,
                resultColor: m.resultColor,
              );
            }),
        ],
      ),
    );
  }
}

class _MatchRatingRow extends StatelessWidget {
  final String opponent;
  final String date;
  final String rating;
  final String result;
  final Color resultColor;

  const _MatchRatingRow({
    required this.opponent,
    required this.date,
    required this.rating,
    required this.result,
    required this.resultColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: resultColor.withOpacity(0.4)),
            ),
            child: Icon(
              result == 'فوز' ? Icons.emoji_events : Icons.sports_soccer,
              color: resultColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              result,
              style: TextStyle(
                color: resultColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'تقييمي',
                style: TextStyle(color: AppColors.textMuted, fontSize: 9),
              ),
              Text(
                rating,
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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
// PLAYER INSIGHTS
// ============================================================
class _PlayerInsightsCard extends StatelessWidget {
  final Player? player;
  const _PlayerInsightsCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights();

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.green,
                size: 20,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ملاحظات على أدائي',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (insights.isEmpty)
            const _InsightItem(
              text: 'لا توجد ملاحظات حالياً — استمر في التدريب!',
            )
          else
            ...insights.map((text) => _InsightItem(text: text)),
          const SizedBox(height: 15),
          const Text(
            'التحليل الجيد يصنع الفارق',
            textAlign: TextAlign.start,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildInsights() {
    final p = player;
    if (p == null) return [];

    final list = <String>[];

    if (p.goals >= 10) {
      list.add('معدل تهديفي ممتاز — استمر على نفس المستوى');
    }
    if (p.assists >= 5) {
      list.add('دقة عالية في التمريرات الحاسمة');
    }
    if (p.matches >= 10) {
      list.add('مشاركة منتظمة في المباريات');
    }

    final rating = double.tryParse(p.rating) ?? 0.0;
    if (rating >= 9.0) {
      list.add('أداء استثنائي في المباريات الأخيرة');
    } else if (rating >= 7.5) {
      list.add('أداء قوي ومستقر');
    }

    if (p.yellowCards >= 3) {
      list.add('يُنصح بالتركيز على الانضباط داخل الملعب');
    }

    if (list.isEmpty) {
      list.add('تحتاج لمزيد من المباريات لتحليل أدائك');
    }

    return list;
  }
}

class _InsightItem extends StatelessWidget {
  final String text;

  const _InsightItem({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TOP CHARTS (للمدرب والمدير)
// ============================================================
class _TopCharts extends StatelessWidget {
  final bool isTablet;
  final List<Player> allPlayers;

  const _TopCharts({
    required this.isTablet,
    required this.allPlayers,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTablet) {
      return Column(
        children: [
          _PerformanceChartCard(allPlayers: allPlayers),
          const SizedBox(height: 16),
          _PositionDistributionCard(allPlayers: allPlayers),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _PerformanceChartCard(allPlayers: allPlayers),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _PositionDistributionCard(allPlayers: allPlayers),
        ),
      ],
    );
  }
}

class _PerformanceChartCard extends StatefulWidget {
  final List<Player> allPlayers;
  const _PerformanceChartCard({required this.allPlayers});

  @override
  State<_PerformanceChartCard> createState() => _PerformanceChartCardState();
}

class _PerformanceChartCardState extends State<_PerformanceChartCard> {
  bool _loading = true;
  List<double> _values = [];
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// ✅ بيانات حقيقية: متوسط تقييم المباريات المنتهية لكل يوم (آخر 6 أيام فيها مباريات).
  /// قبل كده كان بيرسم خط ثابت بنفس الرقم (متوسط تقييم اللاعبين) مهما حصل.
  Future<void> _load() async {
    final matches = await MatchService.getAllMatches();
    final byDate = <String, List<double>>{};
    for (final m in matches) {
      if (!m.isFinished) continue;
      final r = double.tryParse(m.playerRating);
      if (r == null || r <= 0) continue;
      byDate.putIfAbsent(m.date, () => []).add(r);
    }
    final dates = byDate.keys.toList()..sort();
    final last = dates.length > 6 ? dates.sublist(dates.length - 6) : dates;
    final values = <double>[];
    final labels = <String>[];
    for (final d in last) {
      final list = byDate[d]!;
      values.add(list.reduce((x, y) => x + y) / list.length);
      final parts = d.split('/');
      labels.add(parts.length == 3 ? '${parts[2]}/${parts[1]}' : d);
    }
    if (!mounted) return;
    setState(() {
      _values = values;
      _labels = labels;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasChart = _values.length >= 2;

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(
                Icons.insights,
                color: AppColors.green,
                size: 20,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'تطور الأداء العام',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 235,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.green),
                  )
                : hasChart
                    ? CustomPaint(
                        painter: _LineChartPainter(
                          values: _values
                              .map((v) => v.clamp(5.0, 10.0).toDouble())
                              .toList(),
                          lastLabel: _values.last.toStringAsFixed(1),
                          labels: _labels,
                        ),
                        child: const SizedBox.expand(),
                      )
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'الرسم هيظهر لما يكون فيه مباريات منتهية بتقييم في يومين مختلفين على الأقل (سجّل النتيجة والتقييم من شاشة المباريات)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.7,
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PositionDistributionCard extends StatelessWidget {
  final List<Player> allPlayers;
  const _PositionDistributionCard({required this.allPlayers});

  @override
  Widget build(BuildContext context) {
    int forwards = 0, midfielders = 0, defenders = 0, goalkeepers = 0;

    for (final p in allPlayers) {
      switch (p.position) {
        case 'مهاجم':
          forwards++;
          break;
        case 'وسط ميدان':
          midfielders++;
          break;
        case 'مدافع':
          defenders++;
          break;
        case 'حارس مرمى':
          goalkeepers++;
          break;
      }
    }

    final total = forwards + midfielders + defenders + goalkeepers;

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(
                Icons.groups,
                color: AppColors.green,
                size: 20,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'توزيع اللاعبين حسب المراكز',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: Row(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: _DonutPainter(
                      values: [
                        forwards.toDouble(),
                        midfielders.toDouble(),
                        defenders.toDouble(),
                        goalkeepers.toDouble(),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'لاعب',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _LegendItem(
                        title: 'مهاجم',
                        value: '$forwards',
                        color: AppColors.green,
                      ),
                      _LegendItem(
                        title: 'وسط ميدان',
                        value: '$midfielders',
                        color: Colors.blue,
                      ),
                      _LegendItem(
                        title: 'مدافع',
                        value: '$defenders',
                        color: Colors.purpleAccent,
                      ),
                      _LegendItem(
                        title: 'حارس مرمى',
                        value: '$goalkeepers',
                        color: Colors.orange,
                      ),
                    ],
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

class _LegendItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _LegendItem({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 7),
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MIDDLE CHARTS
// ============================================================
class _MiddleCharts extends StatelessWidget {
  final bool isTablet;
  final List<Player> allPlayers;
  final List<Match> allMatches;

  const _MiddleCharts({
    required this.isTablet,
    required this.allPlayers,
    required this.allMatches,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTablet) {
      return Column(
        children: [
          _TopScorersCard(allPlayers: allPlayers),
          const SizedBox(height: 16),
          _MatchResultsCard(matches: allMatches),
          const SizedBox(height: 16),
          _OverallPerformanceCard(allPlayers: allPlayers),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _TopScorersCard(allPlayers: allPlayers)),
        const SizedBox(width: 14),
        Expanded(
            flex: 2,
            child: _MatchResultsCard(matches: allMatches)),
        const SizedBox(width: 14),
        Expanded(child: _OverallPerformanceCard(allPlayers: allPlayers)),
      ],
    );
  }
}

class _TopScorersCard extends StatelessWidget {
  final List<Player> allPlayers;
  const _TopScorersCard({required this.allPlayers});

  @override
  Widget build(BuildContext context) {
    final sorted = List<Player>.from(allPlayers)
      ..sort((a, b) => b.goals.compareTo(a.goals));
    final top = sorted.take(5).toList();

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(13),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.sports_soccer, color: AppColors.green, size: 19),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'أفضل الهدافين',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: const [
                Expanded(
                  child: Text(
                    '#',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'اللاعب',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'الأهداف',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (top.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد بيانات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...List.generate(top.length, (i) {
              return _ScorerRow(
                name: top[i].name,
                goals: '${top[i].goals}',
                rank: i + 1,
              );
            }),
        ],
      ),
    );
  }
}

class _ScorerRow extends StatelessWidget {
  final String name;
  final String goals;
  final int rank;

  const _ScorerRow({
    required this.name,
    required this.goals,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.055),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              width: 25,
              height: 25,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.green.withOpacity(0.55),
                ),
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rank == 1
                      ? AppColors.green
                      : AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                ClipOval(
                  child: SizedBox(
                    width: 29,
                    height: 29,
                    child: NetImage(
                      url: AppImages.coachAvatar,
                      fallbackIcon: Icons.person,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              goals,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: rank == 1
                    ? AppColors.green
                    : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchResultsCard extends StatelessWidget {
  final List<Match> matches;
  const _MatchResultsCard({required this.matches});

  @override
  Widget build(BuildContext context) {
    final sortedMatches = List<Match>.from(matches)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final recent = sortedMatches.take(5).toList();

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(13),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'نتائج المباريات الأخيرة',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد مباريات مسجلة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...recent.map(
              (match) => _MatchRow(match: match),
            ),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  final Match match;

  const _MatchRow({required this.match});

  @override
  Widget build(BuildContext context) {
    final resultColor = match.resultColor;

    return Container(
      height: 55,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.055),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: resultColor.withOpacity(0.35),
              ),
            ),
            child: Text(
              match.resultLabel,
              style: TextStyle(
                color: resultColor,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              match.opponentName,
              textAlign: TextAlign.start,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              match.scoreLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              match.teamName,
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallPerformanceCard extends StatelessWidget {
  final List<Player> allPlayers;
  const _OverallPerformanceCard({required this.allPlayers});

  @override
  Widget build(BuildContext context) {
    // ✅ نحسب المتوسطات الحقيقية من بيانات اللاعبين
    double avgOf(String pos) {
      final subset = allPlayers.where((p) => p.position == pos).toList();
      if (subset.isEmpty) return 0.0;
      return subset.fold<double>(
              0, (s, p) => s + (double.tryParse(p.rating) ?? 0)) /
          subset.length;
    }

    final forwardsAvg = avgOf('مهاجم');
    final midfieldersAvg = avgOf('وسط ميدان');
    final defendersAvg = avgOf('مدافع');
    final goalkeepersAvg = avgOf('حارس مرمى');

    final totalAvg = allPlayers.isEmpty
        ? 0.0
        : allPlayers.fold<double>(
                0, (sum, p) => sum + (double.tryParse(p.rating) ?? 0)) /
            allPlayers.length;

    final progress = (totalAvg / 10).clamp(0.0, 1.0);

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.star, color: AppColors.green, size: 20),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'نسبة الأداء العام',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 125,
            height: 125,
            child: CustomPaint(
              painter: _CircleProgressPainter(progress: progress),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      progress >= 0.85
                          ? 'ممتاز'
                          : progress >= 0.7
                              ? 'جيد جداً'
                              : 'جيد',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PerformanceBar(
            title: 'الهجوم',
            value: '${forwardsAvg.toStringAsFixed(1)}',
            progress: (forwardsAvg / 10).clamp(0.0, 1.0),
            color: AppColors.green,
          ),
          const SizedBox(height: 8),
          _PerformanceBar(
            title: 'الوسط',
            value: '${midfieldersAvg.toStringAsFixed(1)}',
            progress: (midfieldersAvg / 10).clamp(0.0, 1.0),
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          _PerformanceBar(
            title: 'الدفاع',
            value: '${defendersAvg.toStringAsFixed(1)}',
            progress: (defendersAvg / 10).clamp(0.0, 1.0),
            color: Colors.purpleAccent,
          ),
          const SizedBox(height: 8),
          _PerformanceBar(
            title: 'حراسة المرمى',
            value: '${goalkeepersAvg.toStringAsFixed(1)}',
            progress: (goalkeepersAvg / 10).clamp(0.0, 1.0),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;

  _CircleProgressPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.07);

    final foreground = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = AppColors.green;

    canvas.drawCircle(center, radius, background);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PerformanceBar extends StatelessWidget {
  final String title;
  final String value;
  final double progress;
  final Color color;

  const _PerformanceBar({
    required this.title,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Container(color: Colors.white.withOpacity(0.06)),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// BOTTOM CHARTS
// ============================================================
class _BottomCharts extends StatelessWidget {
  final bool isTablet;
  final List<Player> allPlayers;

  const _BottomCharts({
    required this.isTablet,
    required this.allPlayers,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTablet) {
      return Column(
        children: [
          _MostParticipatingCard(allPlayers: allPlayers),
          const SizedBox(height: 16),
          const _RadarCard(),
          const SizedBox(height: 16),
          const _InsightsCard(allPlayers: []),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _MostParticipatingCard(allPlayers: allPlayers)),
        const SizedBox(width: 14),
        const Expanded(child: _RadarCard()),
        const SizedBox(width: 14),
        Expanded(child: _InsightsCard(allPlayers: allPlayers)),
      ],
    );
  }
}

class _MostParticipatingCard extends StatelessWidget {
  final List<Player> allPlayers;
  const _MostParticipatingCard({required this.allPlayers});

  @override
  Widget build(BuildContext context) {
    final sorted = List<Player>.from(allPlayers)
      ..sort((a, b) => b.matches.compareTo(a.matches));
    final top = sorted.take(5).toList();
    
    // ✅ نحدد أعلى عدد مباريات عشان نستخدمه في الـ progress
    final maxMatches = top.isEmpty ? 1.0 : top.first.matches.toDouble();

    final colors = [
      AppColors.green,
      Colors.blue,
      Colors.purpleAccent,
      Colors.orange,
      Colors.blueGrey,
    ];

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(13),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.groups, color: AppColors.green, size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'أكثر اللاعبين مشاركة',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (top.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد بيانات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...List.generate(top.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _ParticipationRow(
                  name: top[i].name,
                  matches: top[i].matches,
                  maxMatches: maxMatches,
                  color: colors[i % colors.length],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ParticipationRow extends StatelessWidget {
  final String name;
  final int matches;
  final double maxMatches;
  final Color color;

  const _ParticipationRow({
    required this.name,
    required this.matches,
    required this.maxMatches,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$matches',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 9,
              child: Stack(
                children: [
                  Container(color: Colors.white.withOpacity(0.06)),
                  FractionallySizedBox(
                    widthFactor: maxMatches == 0
                        ? 0
                        : (matches / maxMatches).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ClipOval(
          child: SizedBox(
            width: 28,
            height: 28,
            child: NetImage(
              url: AppImages.coachAvatar,
              fallbackIcon: Icons.person,
            ),
          ),
        ),
        const SizedBox(width: 7),
        SizedBox(
          width: 75,
          child: Text(
            name,
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadarCard extends StatelessWidget {
  const _RadarCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(13),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.radar, color: AppColors.green, size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'تحليل الأداء الفني',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 245,
            child: CustomPaint(
              painter: _RadarPainter(
                values: const [0.82, 0.76, 0.84, 0.78, 0.88],
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  _RadarPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    final radius = math.min(size.width, size.height) * 0.31;

    const sides = 5;

    final labels = [
      'التمريرات',
      'التسديد',
      'القدرة البدنية',
      'المراوغة',
      'الانضباط',
    ];

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.lightBlue.withOpacity(0.35);

    for (int level = 1; level <= 4; level++) {
      final path = Path();
      final r = radius * level / 4;

      for (int i = 0; i < sides; i++) {
        final angle = -math.pi / 2 + (math.pi * 2 / sides) * i;
        final point = Offset(
          center.dx + math.cos(angle) * r,
          center.dy + math.sin(angle) * r,
        );

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 / sides) * i;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawLine(center, point, gridPaint);
    }

    final dataPath = Path();

    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 / sides) * i;
      final r = radius * values[i];
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );

      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }

    dataPath.close();

    final fillPaint = Paint()
      ..color = AppColors.green.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    canvas.drawPath(dataPath, fillPaint);

    final borderPaint = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(dataPath, borderPaint);

    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 / sides) * i;
      final r = radius * values[i];
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      canvas.drawCircle(point, 3, Paint()..color = AppColors.green);
    }

    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 / sides) * i;
      final labelRadius = radius + 28;
      final point = Offset(
        center.dx + math.cos(angle) * labelRadius,
        center.dy + math.sin(angle) * labelRadius,
      );

      final painter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
          ),
        ),
        textAlign: TextAlign.center,
      )..layout(maxWidth: 80);

      painter.paint(
        canvas,
        Offset(
          point.dx - painter.width / 2,
          point.dy - painter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InsightsCard extends StatelessWidget {
  final List<Player> allPlayers;
  const _InsightsCard({required this.allPlayers});

  @override
  Widget build(BuildContext context) {
    final list = <String>[];
    if (allPlayers.isNotEmpty) {
      final avgRating = allPlayers.fold<double>(
              0, (sum, p) => sum + (double.tryParse(p.rating) ?? 0)) /
          allPlayers.length;

      if (avgRating >= 8.0) {
        list.add('مستوى الفريق ممتاز .. حافظوا على هذا الأداء');
      } else if (avgRating >= 6.5) {
        list.add('أداء الفريق جيد ومستقر .. يحتاج لمزيد من التركيز');
      } else {
        list.add('يحتاج الفريق لمزيد من التدريبات لتحسين المستوى');
      }

      final highScorers = allPlayers.where((p) => p.goals >= 5).length;
      if (highScorers > 0) {
        list.add('يوجد $highScorers لاعبين لديهم قدرة تهديفية عالية');
      } else {
        list.add('يحتاج الفريق لتحسين الجانب الهجومي');
      }
    } else {
      list.add('لا توجد بيانات كافية لتحليل أداء الفريق');
    }

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: AppColors.green, size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ملاحظات وتحليلات',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...list.map((text) => _InsightItem(text: text)),
          const SizedBox(height: 15),
          const Text(
            'التحليل الجيد يصنع الفارق',
            textAlign: TextAlign.start,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LINE CHART PAINTER
// ============================================================
class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final String lastLabel;
  final List<String> labels;

  _LineChartPainter({
    required this.values,
    required this.lastLabel,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 35.0;
    const right = 10.0;
    const top = 12.0;
    const bottom = 30.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.055)
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      final y = top + (chartHeight / 5) * i;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      final value = 10 - i;
      _drawText(
        canvas,
        '$value',
        Offset(5, y - 7),
        const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 9,
        ),
      );
    }

    for (int i = 0; i < values.length; i++) {
      final x = left + (chartWidth / (values.length - 1)) * i;
      canvas.drawLine(
        Offset(x, top),
        Offset(x, size.height - bottom),
        gridPaint,
      );
    }

    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = left + (chartWidth / (values.length - 1)) * i;
      final normalized = (values[i] - 5) / 5;
      final y = top + chartHeight - normalized * chartHeight;
      points.add(Offset(x, y));
    }

    final areaPath = Path()
      ..moveTo(points.first.dx, size.height - bottom)
      ..lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      areaPath.lineTo(points[i].dx, points[i].dy);
    }

    areaPath
      ..lineTo(points.last.dx, size.height - bottom)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.green.withOpacity(0.30),
          AppColors.green.withOpacity(0.02),
        ],
      ).createShader(
        Rect.fromLTWH(0, top, size.width, chartHeight),
      );

    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(linePath, linePaint);

    final pointPaint = Paint()..color = AppColors.green;
    final whitePaint = Paint()..color = Colors.white;

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
      canvas.drawCircle(point, 1.6, whitePaint);
    }

    final last = points.last;

    final bubble = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(last.dx, last.dy - 22),
        width: 38,
        height: 24,
      ),
      const Radius.circular(6),
    );

    final bubblePaint = Paint()..color = AppColors.green;

    canvas.drawRRect(bubble, bubblePaint);

    _drawText(
      canvas,
      lastLabel,
      Offset(last.dx - 11, last.dy - 30),
      const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    );

    for (int i = 0; i < labels.length; i++) {
      final x = left + (chartWidth / (labels.length - 1)) * i;
      _drawText(
        canvas,
        labels[i],
        Offset(x - 18, size.height - 19),
        const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 8,
        ),
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// DONUT PAINTER
// ============================================================
class _DonutPainter extends CustomPainter {
  final List<double> values;
  _DonutPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;

    final colors = [
      AppColors.green,
      Colors.blue,
      Colors.purpleAccent,
      Colors.orange,
    ];

    final total = values.fold<double>(0, (a, b) => a + b);

    if (total == 0) return;

    double start = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;

      final sweep = (values[i] / total) * math.pi * 2;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..color = colors[i];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep - 0.025,
        false,
        paint,
      );

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}