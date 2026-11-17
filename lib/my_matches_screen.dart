// lib/my_matches_screen.dart

import 'package:flutter/material.dart' hide Text;
import 'l10n/app_text.dart';
import 'academy_dashboard_screen.dart'
    show AppColors, AppImages, GlassCard, DeviceType, deviceTypeOf;
import 'widgets/top_header.dart';
import 'models/match.dart';
import 'models/player.dart';
import 'services/auth_service.dart';
import 'services/match_service.dart';
import 'services/player_service.dart';

// ============================================================
// MY MATCHES SCREEN — للاعب بس
// ============================================================

class MyMatchesScreen extends StatefulWidget {
  const MyMatchesScreen({super.key});

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen> {
  Player? _player;
  Match? _nextMatch;
  List<Match> _finishedMatches = [];
  bool _loading = true;

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

    final me = await PlayerService.getPlayerByUserId(user.id);

    // ✅ لو اللاعب عنده فريق → نجيب الماتشات
    Match? next;
    List<Match> finished = [];

    if (me != null && me.teamId.isNotEmpty) {
      next = await MatchService.getNextMatch(me.teamId);
      finished = await MatchService.getFinishedMatches(me.teamId);
    }

    if (!mounted) return;
    setState(() {
      _player = me;
      _nextMatch = next;
      _finishedMatches = finished;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final device = deviceTypeOf(constraints.maxWidth);
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
            bottom: 110,
            top: 0,
          ),
          child: _MyMatchesBody(
            device: device,
            player: _player,
            nextMatch: _nextMatch,
            finishedMatches: _finishedMatches,
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
class _MyMatchesBody extends StatelessWidget {
  final DeviceType device;
  final Player? player;
  final Match? nextMatch;
  final List<Match> finishedMatches;
  final bool loading;

  const _MyMatchesBody({
    required this.device,
    required this.player,
    required this.nextMatch,
    required this.finishedMatches,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = device == DeviceType.tablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TopHeader(),
        const SizedBox(height: 16),
        const _MatchesHero(),
        const SizedBox(height: 18),

        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.green),
            ),
          )
        else ...[
          // المباراة الجاية
          _NextMatchSection(
            player: player,
            nextMatch: nextMatch,
          ),
          const SizedBox(height: 18),

          // آخر المباريات
          _RecentMatchesSection(
            isTablet: isTablet,
            matches: finishedMatches,
          ),
          const SizedBox(height: 18),

          // إحصائياتي في المباريات
          _MatchStatsSection(
            isTablet: isTablet,
            matches: finishedMatches,
          ),
        ],
      ],
    );
  }
}

// ============================================================
// HERO
// ============================================================
class _MatchesHero extends StatelessWidget {
  const _MatchesHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppImages.coachStadium,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surface,
              ),
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
              top: 22,
              right: 22,
              left: 22,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
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
                      Icons.sports_soccer,
                      color: AppColors.green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'مبارياتي',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'تابع مبارياتك القادمة واللي فاتت',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white70,
                          fontSize: 11,
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
    );
  }
}

// ============================================================
// NEXT MATCH
// ============================================================
class _NextMatchSection extends StatelessWidget {
  final Player? player;
  final Match? nextMatch;

  const _NextMatchSection({
    required this.player,
    required this.nextMatch,
  });

  @override
  Widget build(BuildContext context) {
    final hasTeam = player != null && player!.teamId.isNotEmpty;
    final teamName = hasTeam ? player!.teamName : 'بدون فريق';

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.event, color: AppColors.green, size: 18),
              SizedBox(width: 8),
              Text(
                'المباراة القادمة',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.green.withOpacity(0.15),
                  AppColors.green.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.green.withOpacity(0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // الفريق بتاعنا
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.green.withOpacity(0.15),
                              border: Border.all(
                                color: AppColors.green.withOpacity(0.6),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: AppColors.green,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            teamName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // VS + التاريخ
                    Column(
                      children: [
                        const Text(
                          'VS',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            nextMatch?.date ?? '—',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          nextMatch?.time ?? '—',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    // الخصم
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.blue.withOpacity(0.15),
                              border: Border.all(
                                color: AppColors.blue.withOpacity(0.6),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: AppColors.blue,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            nextMatch?.opponentName ?? '—',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      nextMatch?.venue ??
                          (hasTeam ? 'مفيش مباراة محددة' : 'مفيش فريق'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
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
// RECENT MATCHES
// ============================================================
class _RecentMatchesSection extends StatelessWidget {
  final bool isTablet;
  final List<Match> matches;

  const _RecentMatchesSection({
    required this.isTablet,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.history, color: AppColors.green, size: 18),
              SizedBox(width: 8),
              Text(
                'آخر المباريات',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (matches.isEmpty)
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
            for (int i = 0; i < matches.length; i++) ...[
              _MatchRow(match: matches[i]),
              if (i != matches.length - 1)
                Divider(color: Colors.white.withOpacity(0.08), height: 18),
            ],
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
    return Row(
      children: [
        Container(
          width: 48,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: match.resultColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: match.resultColor.withOpacity(0.4)),
          ),
          child: Text(
            match.scoreLabel,
            style: TextStyle(
              color: match.resultColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.opponentName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                match.date,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: match.resultColor.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            match.resultLabel,
            style: TextStyle(
              color: match.resultColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'تقييمك',
              style: TextStyle(color: AppColors.textMuted, fontSize: 9),
            ),
            Text(
              match.playerRating.isEmpty ? '—' : match.playerRating,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// MATCH STATS
// ============================================================
class _MatchStatsSection extends StatelessWidget {
  final bool isTablet;
  final List<Match> matches;

  const _MatchStatsSection({
    required this.isTablet,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    final totalMatches = matches.length;

    int wins = 0, draws = 0, losses = 0;
    for (final m in matches) {
      switch (m.result) {
        case MatchResult.win:
          wins++;
          break;
        case MatchResult.draw:
          draws++;
          break;
        case MatchResult.loss:
          losses++;
          break;
        case MatchResult.none:
          break;
      }
    }

    final stats = [
      ('$totalMatches', 'مباراة', AppColors.purple, Icons.calendar_month),
      ('$wins', 'فوز', AppColors.green, Icons.emoji_events),
      ('$draws', 'تعادل', AppColors.gold, Icons.horizontal_rule),
      ('$losses', 'خسارة', AppColors.red, Icons.close),
    ];

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart, color: AppColors.green, size: 18),
              SizedBox(width: 8),
              Text(
                'إحصائياتي في المباريات',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                Expanded(
                  child: _StatCard(
                    value: stats[i].$1,
                    label: stats[i].$2,
                    color: stats[i].$3,
                    icon: stats[i].$4,
                  ),
                ),
                if (i != stats.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
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