// lib/player_detail_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import 'l10n/app_text.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'academy_dashboard_screen.dart'
    show AppColors, GlassCard, NetImage, DeviceType, deviceTypeOf;
import 'models/app_user.dart';
import 'models/match.dart';
import 'models/player.dart';
import 'services/auth_service.dart';
import 'services/match_service.dart';
import 'services/player_service.dart';
import 'widgets/player_form_dialog.dart';
import 'player_qr_screen.dart';

// ============================================================
// PLAYER SKILL (للعرض بس — مش جزء من Player model)
// ============================================================
class PlayerSkill {
  final String label;
  final double value;
  final Color color;
  const PlayerSkill(this.label, this.value, this.color);
}

// ============================================================
// ENTRY SCREEN
// ============================================================
class PlayerDetailScreen extends StatelessWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

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
          extendBodyBehindAppBar: true,
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
                              .copyWith(top: 8, bottom: 110),
                          child: _DetailBody(player: player, device: device),
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
class _DetailBody extends StatelessWidget {
  final Player player;
  final DeviceType device;
  const _DetailBody({required this.player, required this.device});

  @override
  Widget build(BuildContext context) {
    final isTablet = device == DeviceType.tablet;
    final skills = _skillsForPosition(player.position);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(player: player),
        const SizedBox(height: 12),
        _HeroPlayerCard(player: player),
        const SizedBox(height: 16),
        _QuickStatsRow(player: player),
        const SizedBox(height: 16),
        _InfoGrid(player: player),
        const SizedBox(height: 16),
        if (isTablet)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _SkillsCard(skills: skills)),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: _PerformanceCard(player: player),
                ),
              ],
            ),
          )
        else ...[
          _SkillsCard(skills: skills),
          const SizedBox(height: 16),
          _PerformanceCard(player: player),
        ],
        const SizedBox(height: 16),
        _MatchHistoryCard(player: player),
        const SizedBox(height: 16),
        _AchievementsCard(player: player),
        const SizedBox(height: 20),
        _ActionButtons(player: player),
      ],
    );
  }

  // ============================================================
  // ⚠️ مهارات مبنية على المركز (قيم عرض)
  // عشان تبقى حقيقية، محتاج جدول player_skills في الداتابيز.
  // ============================================================
  List<PlayerSkill> _skillsForPosition(String position) {
    switch (position) {
      case 'مهاجم':
        return const [
          PlayerSkill('السرعة', 0.92, AppColors.green),
          PlayerSkill('التسديد', 0.88, AppColors.orange),
          PlayerSkill('التمرير', 0.80, AppColors.blue),
          PlayerSkill('المراوغة', 0.85, AppColors.purple),
          PlayerSkill('الدفاع', 0.55, AppColors.gray),
          PlayerSkill('اللياقة', 0.90, AppColors.gold),
        ];
      case 'وسط ميدان':
        return const [
          PlayerSkill('التمرير', 0.90, AppColors.green),
          PlayerSkill('الرؤية', 0.88, AppColors.orange),
          PlayerSkill('اللياقة', 0.85, AppColors.blue),
          PlayerSkill('المراوغة', 0.78, AppColors.purple),
          PlayerSkill('الدفاع', 0.65, AppColors.gray),
          PlayerSkill('التسديد', 0.70, AppColors.gold),
        ];
      case 'مدافع':
        return const [
          PlayerSkill('الدفاع', 0.92, AppColors.green),
          PlayerSkill('الالتحام', 0.85, AppColors.orange),
          PlayerSkill('التمرير', 0.75, AppColors.blue),
          PlayerSkill('السرعة', 0.70, AppColors.purple),
          PlayerSkill('التسديد', 0.50, AppColors.gray),
          PlayerSkill('اللياقة', 0.88, AppColors.gold),
        ];
      case 'حارس مرمى':
        return const [
          PlayerSkill('التصديات', 0.93, AppColors.green),
          PlayerSkill('الخروج', 0.85, AppColors.orange),
          PlayerSkill('التمرير', 0.78, AppColors.blue),
          PlayerSkill('الردة', 0.82, AppColors.purple),
          PlayerSkill('التسديد', 0.40, AppColors.gray),
          PlayerSkill('اللياقة', 0.86, AppColors.gold),
        ];
      default:
        return const [];
    }
  }
}

// ============================================================
// TOP BAR
// ============================================================
class _TopBar extends StatefulWidget {
  final Player player;
  const _TopBar({required this.player});

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  static const String _bookmarksKey = 'bookmarked_player_ids';
  bool _bookmarked = false;

  Player get player => widget.player;

  @override
  void initState() {
    super.initState();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_bookmarksKey) ?? const <String>[];
      if (!mounted) return;
      setState(() => _bookmarked = ids.contains(player.id));
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    final next = !_bookmarked;
    setState(() => _bookmarked = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = (prefs.getStringList(_bookmarksKey) ?? <String>[]).toList();
      ids.remove(player.id);
      if (next) ids.add(player.id);
      await prefs.setStringList(_bookmarksKey, ids);
    } catch (_) {
      if (!mounted) return;
      setState(() => _bookmarked = !next);
      return;
    }
    if (!mounted) return;
    _snack(next ? 'تمت الإضافة للمفضلة ⭐' : 'تمت الإزالة من المفضلة',
        next ? AppColors.green : AppColors.gray);
  }

  Future<void> _share() async {
    final text = StringBuffer()
      ..writeln(player.name)
      ..writeln('المركز: ${player.position}')
      ..writeln('الفريق: ${player.teamName}')
      ..writeln('التقييم: ${player.rating}')
      ..writeln('أهداف: ${player.goals} | تمريرات حاسمة: ${player.assists}');
    await Clipboard.setData(ClipboardData(text: text.toString().trim()));
    if (!mounted) return;
    _snack('تم نسخ بيانات اللاعب 📋', AppColors.green);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openQr(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerQrScreen(player: player),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_forward,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          const Text(
            'تفاصيل اللاعب',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _CircleIconButton(
            icon: Icons.qr_code_2_rounded,
            onTap: () => _openQr(context),
          ),
          const SizedBox(width: 8),
          _CircleIconButton(icon: Icons.share_outlined, onTap: _share),
          const SizedBox(width: 8),
          _CircleIconButton(
            icon: _bookmarked ? Icons.bookmark : Icons.bookmark_border,
            onTap: _toggleBookmark,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.06),
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white12),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: AppColors.textPrimary, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HERO PLAYER CARD
// ============================================================
class _HeroPlayerCard extends StatelessWidget {
  final Player player;
  const _HeroPlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      radius: 24,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 110,
                height: 110,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.green,
                      AppColors.green.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                  ),
                  child: ClipOval(
                    child: NetImage(
                      url: player.photo,
                      fallbackIcon: Icons.person,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.background,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        player.rating,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            player.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Pill(
                label: player.position,
                color: player.positionColor,
              ),
              const SizedBox(width: 8),
              _Pill(
                label: player.teamName,
                color: AppColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// QUICK STATS
// ============================================================
class _QuickStatsRow extends StatelessWidget {
  final Player player;
  const _QuickStatsRow({required this.player});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickStat(Icons.sports_soccer, AppColors.green, '${player.goals}', 'أهداف'),
      _QuickStat(Icons.handshake_outlined, AppColors.blue, '${player.assists}', 'صناعة'),
      _QuickStat(Icons.calendar_month, AppColors.purple, '${player.matches}', 'مباريات'),
      _QuickStat(Icons.sports_score, AppColors.gold, '${player.yellowCards}', 'بطاقات'),
    ];

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: _QuickStatCard(stat: items[i])),
          if (i != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _QuickStat {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _QuickStat(this.icon, this.color, this.value, this.label);
}

class _QuickStatCard extends StatelessWidget {
  final _QuickStat stat;
  const _QuickStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: SizedBox(
        height: 95,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: stat.color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(stat.icon, color: stat.color, size: 17),
                ),
                const SizedBox(height: 8),
                Text(
                  stat.value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.0,
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
// INFO GRID
// ============================================================
class _InfoGrid extends StatelessWidget {
  final Player player;
  const _InfoGrid({required this.player});

  @override
  Widget build(BuildContext context) {
    final items = [
      _InfoItem(Icons.cake_outlined, 'العمر', player.age),
      _InfoItem(Icons.height, 'الطول', player.height),
      _InfoItem(Icons.monitor_weight_outlined, 'الوزن', player.weight),
      _InfoItem(Icons.directions_walk, 'القدم', player.foot),
      _InfoItem(Icons.flag_outlined, 'الجنسية', player.nationality),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'المعلومات الشخصية',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((e) => _InfoChip(item: e)).toList(),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _InfoChip extends StatelessWidget {
  final _InfoItem item;
  const _InfoChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, color: AppColors.green, size: 14),
          const SizedBox(width: 6),
          Text(
            '${item.label}: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          Text(
            item.value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SKILLS CARD
// ============================================================
class _SkillsCard extends StatelessWidget {
  final List<PlayerSkill> skills;
  const _SkillsCard({required this.skills});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(title: 'المهارات', icon: Icons.bolt),
          const SizedBox(height: 14),
          if (skills.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد بيانات مهارات',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            for (int i = 0; i < skills.length; i++) ...[
              _SkillBar(skill: skills[i]),
              if (i != skills.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _SkillBar extends StatelessWidget {
  final PlayerSkill skill;
  const _SkillBar({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              skill.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(skill.value * 100).round()}%',
              style: TextStyle(
                color: skill.color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Container(height: 8, color: Colors.white.withOpacity(0.06)),
              FractionallySizedBox(
                widthFactor: skill.value.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        skill.color.withOpacity(0.7),
                        skill.color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: skill.color.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
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
// ✅ PERFORMANCE CARD (ديناميكي من MatchService)
// ============================================================
class _PerformanceCard extends StatefulWidget {
  final Player player;
  const _PerformanceCard({required this.player});

  @override
  State<_PerformanceCard> createState() => _PerformanceCardState();
}

class _PerformanceCardState extends State<_PerformanceCard> {
  List<(double, Color)> _ratings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final allMatches = await MatchService.getAllMatches();
      final playerMatches = allMatches
          .where((m) =>
              m.teamId == widget.player.teamId &&
              m.isFinished &&
              m.playerRating.isNotEmpty)
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      final recent = playerMatches.length > 7
          ? playerMatches.sublist(playerMatches.length - 7)
          : playerMatches;

      final list = recent.map((m) {
        final r = double.tryParse(m.playerRating) ?? 0.0;
        Color c;
        if (r >= 8.0) {
          c = AppColors.green;
        } else if (r >= 6.5) {
          c = AppColors.blue;
        } else if (r >= 5.0) {
          c = AppColors.gold;
        } else {
          c = AppColors.red;
        }
        return (r, c);
      }).toList();

      if (!mounted) return;
      setState(() {
        _ratings = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const maxRating = 10.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'تقييم آخر المباريات',
            icon: Icons.show_chart,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(color: AppColors.green),
              ),
            )
          else if (_ratings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'لا توجد مباريات مسجلة',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _ratings.map((r) {
                  final ratio = (r.$1 / maxRating).clamp(0.0, 1.0);
                  return _PerformanceBar(
                    ratio: ratio,
                    label: r.$1.toStringAsFixed(1),
                    color: r.$2,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _PerformanceBar extends StatelessWidget {
  final double ratio;
  final String label;
  final Color color;
  const _PerformanceBar({
    required this.ratio,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: ratio),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Container(
              width: 22,
              height: (value * 110).clamp(20.0, 110.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [color.withOpacity(0.6), color],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// ✅ MATCH HISTORY (ديناميكي من MatchService)
// ============================================================
class _MatchHistoryCard extends StatefulWidget {
  final Player player;
  const _MatchHistoryCard({required this.player});

  @override
  State<_MatchHistoryCard> createState() => _MatchHistoryCardState();
}

class _MatchHistoryCardState extends State<_MatchHistoryCard> {
  List<_MatchData> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final allMatches = await MatchService.getAllMatches();
      final playerMatches = allMatches
          .where((m) => m.teamId == widget.player.teamId && m.isFinished)
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

      final recent = playerMatches.take(5).toList();

      final list = recent.map((m) {
        final resultColor = m.resultColor;
        return _MatchData(
          opponent: m.opponentName,
          date: m.date,
          result: m.resultLabel,
          resultColor: resultColor,
          score: m.scoreLabel,
          playerRating: m.playerRating.isEmpty ? '—' : m.playerRating,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _matches = list;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(title: 'آخر المباريات', icon: Icons.history),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: AppColors.green),
              ),
            )
          else if (_matches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد مباريات مسجلة',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            for (int i = 0; i < _matches.length; i++) ...[
              _MatchRow(match: _matches[i]),
              if (i != _matches.length - 1)
                Divider(color: Colors.white.withOpacity(0.08), height: 18),
            ],
        ],
      ),
    );
  }
}

class _MatchData {
  final String opponent;
  final String date;
  final String result;
  final Color resultColor;
  final String score;
  final String playerRating;
  const _MatchData({
    required this.opponent,
    required this.date,
    required this.result,
    required this.resultColor,
    required this.score,
    required this.playerRating,
  });
}

class _MatchRow extends StatelessWidget {
  final _MatchData match;
  const _MatchRow({required this.match});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: match.resultColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: match.resultColor.withOpacity(0.4)),
          ),
          child: Text(
            match.score,
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
                match.opponent,
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
            match.result,
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
              'التقييم',
              style: TextStyle(color: AppColors.textMuted, fontSize: 9),
            ),
            Text(
              match.playerRating,
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
// ✅ ACHIEVEMENTS (ديناميكي بناءً على أرقام اللاعب)
// ============================================================
class _AchievementsCard extends StatelessWidget {
  final Player player;
  const _AchievementsCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final achievements = _buildAchievements(player);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(title: 'الإنجازات', icon: Icons.emoji_events),
          const SizedBox(height: 12),
          if (achievements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد إنجازات بعد',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            for (int i = 0; i < achievements.length; i++) ...[
              _AchievementRow(item: achievements[i]),
              if (i != achievements.length - 1)
                Divider(color: Colors.white.withOpacity(0.08), height: 16),
            ],
        ],
      ),
    );
  }

  List<_AchievementData> _buildAchievements(Player player) {
    final list = <_AchievementData>[];

    // ✅ إنجازات مبنية على أرقام اللاعب الحقيقية
    if (player.goals >= 10) {
      list.add(_AchievementData(
        Icons.emoji_events,
        AppColors.gold,
        'هدّاف الأكاديمية',
        '${player.goals} هدف',
      ));
    }

    final rating = double.tryParse(player.rating) ?? 0.0;
    if (rating >= 9.0) {
      list.add(_AchievementData(
        Icons.star,
        AppColors.orange,
        'أفضل لاعب',
        'تقييم ${player.rating}',
      ));
    }

    if (player.assists >= 5) {
      list.add(_AchievementData(
        Icons.trending_up,
        AppColors.green,
        'صنّاع الأهداف',
        '${player.assists} صناعة',
      ));
    }

    if (player.matches >= 10) {
      list.add(_AchievementData(
        Icons.calendar_month,
        AppColors.blue,
        'لاعب منتظم',
        '${player.matches} مباراة',
      ));
    }

    return list;
  }
}

class _AchievementData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _AchievementData(this.icon, this.color, this.title, this.subtitle);
}

class _AchievementRow extends StatelessWidget {
  final _AchievementData item;
  const _AchievementRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: item.color.withOpacity(0.5)),
          ),
          child: Icon(item.icon, color: item.color, size: 18),
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
              Text(
                item.subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
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
// ✅ ACTION BUTTONS
// ============================================================
class _ActionButtons extends StatelessWidget {
  final Player player;
  const _ActionButtons({required this.player});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    switch (user?.role) {
      case UserRole.admin:
      case UserRole.coach:
        return Row(
          children: [
            Expanded(
              child: _GradientButton(
                label: 'تعديل البيانات',
                icon: Icons.edit_outlined,
                onTap: () => _openEdit(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutlineButton(
                label: 'حذف اللاعب',
                icon: Icons.delete_outline,
                color: AppColors.red,
                onTap: () => _confirmDelete(context),
              ),
            ),
          ],
        );

      case UserRole.player:
      default:
        return const SizedBox();
    }
  }

  Future<void> _openEdit(BuildContext context) async {
    final saved = await PlayerFormDialog.show(context, player: player);
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم حفظ التعديلات ✅',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDirectionality(
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.red.withOpacity(0.4)),
          ),
          title: const Text(
            'تأكيد الحذف',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'متأكد إنك عايز تحذف "${player.name}"؟\nمش هتقدر ترجع البيانات بعد كده.',
            style: const TextStyle(
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

    if (ok != true) return;

    await PlayerService.deletePlayer(player.id);
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حذف اللاعب 🗑️',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================
// GRADIENT BUTTON
// ============================================================
class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.green, AppColors.greenDark],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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
// OUTLINE BUTTON
// ============================================================
class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: c.withOpacity(0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: c.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: c, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: c,
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
// SECTION HEADER
// ============================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  const _SectionHeader({required this.title, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.chevron_left,
                color: AppColors.textSecondary, size: 18),
            SizedBox(width: 4),
            Text(
              'عرض الكل',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: iconColor ?? AppColors.textSecondary),
            ],
          ],
        ),
      ],
    );
  }
}