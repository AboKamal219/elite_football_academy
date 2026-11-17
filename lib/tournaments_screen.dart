// lib/tournaments_screen.dart

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
import 'models/match.dart';
import 'models/standing.dart';
import 'models/team.dart';
import 'models/tournament.dart';
import 'services/auth_service.dart';
import 'services/match_service.dart';
import 'services/team_service.dart';
import 'services/tournament_service.dart';

// ============================================================
// TOURNAMENTS SCREEN
// ============================================================

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  int _filterIndex = 0;

  List<Match> _matches = [];
  List<Tournament> _tournaments = [];
  List<Standing> _standings = [];
  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final matches = await MatchService.getAllMatches();
    final tournaments = await TournamentService.getAllTournaments();
    final standings = await TournamentService.getSortedStandings();
    final stats = await TournamentService.getStats();

    matches.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    if (!mounted) return;
    setState(() {
      _matches = matches;
      _tournaments = tournaments;
      _standings = standings;
      _stats = stats;
      _loading = false;
    });
  }

  // ============================================================
  // ✅ إضافة بطولة
  // ============================================================
  Future<void> _addTournament() async {
    final saved = await _TournamentFormDialog.show(context);
    if (saved == true && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تمت إضافة البطولة ✅',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // ✅ إضافة/تعديل ترتيب فريق
  // ============================================================
  Future<void> _addStanding() async {
    final saved = await _StandingFormDialog.show(context);
    if (saved == true && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم حفظ الترتيب ✅',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: error ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ✅ مباريات: إضافة / تعديل / حذف  (الـ backend كان جاهز بس مفيش زراير)
  // ============================================================
  Future<void> _addMatch() async {
    final saved = await _MatchFormDialog.show(context);
    if (saved == true && mounted) {
      await _loadData();
      if (!mounted) return;
      _snack('تمت إضافة المباراة ✅');
    }
  }

  Future<void> _editMatch(Match m) async {
    final saved = await _MatchFormDialog.show(context, match: m);
    if (saved == true && mounted) {
      await _loadData();
      if (!mounted) return;
      _snack('تم حفظ التعديلات ✅');
    }
  }

  Future<void> _deleteMatch(Match m) async {
    final ok = await _confirmDelete(context, '${m.teamName} × ${m.opponentName}');
    if (ok != true) return;
    try {
      await MatchService.deleteMatch(m.id);
    } catch (e) {
      if (mounted) _snack('حصل خطأ: $e', error: true);
      return;
    }
    if (!mounted) return;
    await _loadData();
    if (!mounted) return;
    _snack('تم حذف المباراة 🗑️');
  }

  // ============================================================
  // ✅ بطولات: تعديل / حذف — وترتيب: حذف
  // ============================================================
  Future<void> _editTournament(Tournament t) async {
    final saved = await _TournamentFormDialog.show(context, tournament: t);
    if (saved == true && mounted) {
      await _loadData();
      if (!mounted) return;
      _snack('تم حفظ التعديلات ✅');
    }
  }

  Future<void> _deleteTournament(Tournament t) async {
    final ok = await _confirmDelete(context, t.name);
    if (ok != true) return;
    try {
      await TournamentService.deleteTournament(t.id);
    } catch (e) {
      if (mounted) _snack('حصل خطأ: $e', error: true);
      return;
    }
    if (!mounted) return;
    await _loadData();
    if (!mounted) return;
    _snack('تم حذف البطولة 🗑️');
  }

  Future<void> _deleteStanding(Standing s) async {
    final ok = await _confirmDelete(context, s.teamName);
    if (ok != true) return;
    try {
      await TournamentService.deleteStanding(s.teamId);
    } catch (e) {
      if (mounted) _snack('حصل خطأ: $e', error: true);
      return;
    }
    if (!mounted) return;
    await _loadData();
    if (!mounted) return;
    _snack('تم حذف الترتيب 🗑️');
  }

  List<Match> get _filteredMatches {
    switch (_filterIndex) {
      case 1:
        return _matches.where((m) => m.isUpcoming).toList();
      case 2:
        return _matches.where((m) => m.isLive).toList();
      case 3:
        return _matches.where((m) => m.isFinished).toList();
      default:
        return _matches;
    }
  }

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
                        child: _TournamentsBody(
                          device: deviceTypeOf(MediaQuery.of(context).size.width),
                          filterIndex: _filterIndex,
                          onFilterChanged: (i) =>
                              setState(() => _filterIndex = i),
                          matches: _filteredMatches,
                          tournaments: _tournaments,
                          standings: _standings,
                          stats: _stats,
                          onAddTournament: _addTournament,
                          onAddStanding: _addStanding,
                          onAddMatch: _addMatch,
                          onEditMatch: _editMatch,
                          onDeleteMatch: _deleteMatch,
                          onEditTournament: _editTournament,
                          onDeleteTournament: _deleteTournament,
                          onDeleteStanding: _deleteStanding,
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
class _TournamentsBody extends StatelessWidget {
  final DeviceType device;
  final int filterIndex;
  final ValueChanged<int> onFilterChanged;
  final List<Match> matches;
  final List<Tournament> tournaments;
  final List<Standing> standings;
  final Map<String, int> stats;
  final VoidCallback onAddTournament;
  final VoidCallback onAddStanding;
  final VoidCallback onAddMatch;
  final ValueChanged<Match> onEditMatch;
  final ValueChanged<Match> onDeleteMatch;
  final ValueChanged<Tournament> onEditTournament;
  final ValueChanged<Tournament> onDeleteTournament;
  final ValueChanged<Standing> onDeleteStanding;

  const _TournamentsBody({
    required this.device,
    required this.filterIndex,
    required this.onFilterChanged,
    required this.matches,
    required this.tournaments,
    required this.standings,
    required this.stats,
    required this.onAddTournament,
    required this.onAddStanding,
    required this.onAddMatch,
    required this.onEditMatch,
    required this.onDeleteMatch,
    required this.onEditTournament,
    required this.onDeleteTournament,
    required this.onDeleteStanding,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final canEdit =
        user?.role == UserRole.admin || user?.role == UserRole.coach;

    final featured = matches.where((m) => m.isUpcoming).isNotEmpty
        ? matches.firstWhere((m) => m.isUpcoming)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TopBar(),
        const SizedBox(height: 14),

        _TournamentsHero(stats: stats, matchesCount: matches.length),
        const SizedBox(height: 18),

        if (featured != null) ...[
          _FeaturedMatch(match: featured),
          const SizedBox(height: 20),
        ],

        _SectionTitle(
          title: 'المباريات',
          icon: Icons.sports_soccer_rounded,
          color: AppColors.green,
          onAdd: canEdit ? onAddMatch : null,
          addLabel: 'إضافة مباراة',
        ),
        const SizedBox(height: 12),

        _FilterTabs(
          currentIndex: filterIndex,
          onChanged: onFilterChanged,
        ),
        const SizedBox(height: 14),

        _MatchesSection(
          matches: matches,
          onEdit: canEdit ? onEditMatch : null,
          onDelete: canEdit ? onDeleteMatch : null,
        ),

        const SizedBox(height: 20),

        // ✅ بطولات + زرار إضافة
        _SectionTitle(
          title: 'البطولات',
          icon: Icons.emoji_events_rounded,
          color: AppColors.orange,
          onAdd: canEdit ? onAddTournament : null,
          addLabel: 'إضافة بطولة',
        ),
        const SizedBox(height: 12),

        _TournamentsSection(
          tournaments: tournaments,
          onEdit: canEdit ? onEditTournament : null,
          onDelete: canEdit ? onDeleteTournament : null,
        ),

        const SizedBox(height: 20),

        // ✅ ترتيب + زرار إضافة
        _SectionTitle(
          title: 'جدول الترتيب',
          icon: Icons.leaderboard_rounded,
          color: AppColors.blue,
          onAdd: canEdit ? onAddStanding : null,
          addLabel: 'إضافة ترتيب',
        ),
        const SizedBox(height: 12),

        _StandingsSection(
          standings: standings,
          onDelete: canEdit ? onDeleteStanding : null,
        ),
      ],
    );
  }
}

// ============================================================
// TOP BAR
// ============================================================
class _TopBar extends StatelessWidget {
  const _TopBar();

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
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.green, width: 1.5),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'البطولات والمباريات',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'تابع كل المباريات',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppColors.textPrimary,
                size: 20,
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
class _TournamentsHero extends StatelessWidget {
  final Map<String, int> stats;
  final int matchesCount;

  const _TournamentsHero({
    required this.stats,
    required this.matchesCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = stats['total'] ?? 0;
    final ongoing = stats['ongoing'] ?? 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 220,
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
                    Colors.black.withOpacity(0.30),
                    AppColors.orange.withOpacity(0.35),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.orange.withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 22,
              right: 22,
              left: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          'البطولات',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 30,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            shadows: const [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.orange.withOpacity(0.25),
                          border: Border.all(
                            color: AppColors.orange.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.orange,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'كل المباريات والبطولات في مكان واحد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 18,
              left: 18,
              right: 18,
              child: Row(
                children: [
                  _HeroStat(
                    icon: Icons.sports_soccer_rounded,
                    value: '$matchesCount',
                    label: 'مباراة',
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 8),
                  _HeroStat(
                    icon: Icons.emoji_events_rounded,
                    value: '$total',
                    label: 'بطولات',
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 8),
                  _HeroStat(
                    icon: Icons.play_circle_rounded,
                    value: '$ongoing',
                    label: 'جارية',
                    color: AppColors.gold,
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

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.20),
                    border: Border.all(
                      color: color.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 9,
                          height: 1.2,
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
    );
  }
}

// ============================================================
// FEATURED MATCH
// ============================================================
class _FeaturedMatch extends StatelessWidget {
  final Match match;
  const _FeaturedMatch({required this.match});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.green.withOpacity(0.15),
                AppColors.greenDark.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.green.withOpacity(0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withOpacity(0.20),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.green.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.star_rounded,
                          color: AppColors.green,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'المباراة المميزة',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_left,
                    color: AppColors.green,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _FeaturedTeam(
                      name: match.teamName,
                      icon: Icons.shield_rounded,
                      color: AppColors.green,
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'VS',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          match.date,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        match.time,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: _FeaturedTeam(
                      name: match.opponentName,
                      icon: Icons.shield_rounded,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.green, AppColors.greenDark],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'تفاصيل المباراة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 14,
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

class _FeaturedTeam extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;

  const _FeaturedTeam({
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(
              color: color.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ✅ SECTION TITLE — معدّل بزرار إضافة اختياري
// ============================================================
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onAdd;
  final String addLabel;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
    this.onAdd,
    this.addLabel = 'إضافة',
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
        const Spacer(),
        // ✅ زرار إضافة (لو موجود)
        if (onAdd != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: color, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      addLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          const Text(
            'عرض الكل',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Icon(
            Icons.chevron_left,
            color: AppColors.green,
            size: 16,
          ),
        ],
      ],
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
    ('الكل', Icons.apps_rounded),
    ('قادمة', Icons.schedule_rounded),
    ('مباشر', Icons.play_circle_rounded),
    ('منتهية', Icons.check_circle_rounded),
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
                    ? AppColors.green
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: active
                      ? AppColors.green
                      : Colors.white.withOpacity(0.10),
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.green.withOpacity(0.4),
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
// MATCHES SECTION
// ============================================================
class _MatchesSection extends StatelessWidget {
  final List<Match> matches;
  final ValueChanged<Match>? onEdit;
  final ValueChanged<Match>? onDelete;

  const _MatchesSection({required this.matches, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: AppColors.textSecondary,
                size: 40,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'لا توجد مباريات',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < matches.length; i++) ...[
          _MatchCard(
            match: matches[i],
            onEdit: onEdit == null ? null : () => onEdit!(matches[i]),
            onDelete: onDelete == null ? null : () => onDelete!(matches[i]),
          ),
          if (i != matches.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _MatchCard({required this.match, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: match.isLive
                  ? AppColors.red.withOpacity(0.5)
                  : Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: match.statusColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (match.isLive)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(left: 5),
                            decoration: const BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          match.statusLabel,
                          style: TextStyle(
                            color: match.statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.textMuted,
                    size: 10,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    match.date,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.textMuted,
                    size: 10,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    match.time,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 10),
                    _IconActionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.green,
                      onTap: onEdit!,
                    ),
                  ],
                  if (onDelete != null) ...[
                    const SizedBox(width: 6),
                    _IconActionButton(
                      icon: Icons.delete_outline,
                      color: AppColors.red,
                      onTap: onDelete!,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TeamBox(
                      name: match.teamName,
                      icon: Icons.shield_rounded,
                      color: AppColors.green,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: match.isLive
                          ? AppColors.red.withOpacity(0.15)
                          : Colors.black.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: match.statusColor.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      match.scoreLabel,
                      style: TextStyle(
                        color: match.isLive
                            ? AppColors.red
                            : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _TeamBox(
                      name: match.opponentName,
                      icon: Icons.shield_rounded,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.textMuted,
                    size: 11,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    match.venue,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamBox extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;

  const _TeamBox({
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
            border: Border.all(
              color: color.withOpacity(0.45),
              width: 1.2,
            ),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TOURNAMENTS SECTION
// ============================================================
class _TournamentsSection extends StatelessWidget {
  final List<Tournament> tournaments;
  final ValueChanged<Tournament>? onEdit;
  final ValueChanged<Tournament>? onDelete;

  const _TournamentsSection({
    required this.tournaments,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'لا توجد بطولات',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < tournaments.length; i++) ...[
          _TournamentCard(
            tournament: tournaments[i],
            onEdit: onEdit == null ? null : () => onEdit!(tournaments[i]),
            onDelete: onDelete == null ? null : () => onDelete!(tournaments[i]),
          ),
          if (i != tournaments.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _TournamentCard({required this.tournament, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = tournament.color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.10),
                Colors.white.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                left: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.15),
                        border: Border.all(
                          color: color.withOpacity(0.5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.25),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(
                        tournament.icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tournament.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: tournament.statusColor
                                      .withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  tournament.statusLabel,
                                  style: TextStyle(
                                    color: tournament.statusColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tournament.subtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: AppColors.textMuted,
                                size: 10,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tournament.date,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.groups_rounded,
                                color: color.withOpacity(0.7),
                                size: 10,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${tournament.teamsCount} فريق',
                                style: TextStyle(
                                  color: color.withOpacity(0.9),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onEdit != null || onDelete != null) ...[
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          if (onEdit != null)
                            _IconActionButton(
                              icon: Icons.edit_outlined,
                              color: AppColors.green,
                              onTap: onEdit!,
                            ),
                          if (onEdit != null && onDelete != null)
                            const SizedBox(height: 6),
                          if (onDelete != null)
                            _IconActionButton(
                              icon: Icons.delete_outline,
                              color: AppColors.red,
                              onTap: onDelete!,
                            ),
                        ],
                      ),
                    ],
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
// STANDINGS SECTION
// ============================================================
class _StandingsSection extends StatelessWidget {
  final List<Standing> standings;
  final ValueChanged<Standing>? onDelete;

  const _StandingsSection({required this.standings, this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'لا توجد بيانات ترتيب',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 30),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'الفريق',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 28,
                      child: Text(
                        'لعب',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 28,
                      child: Text(
                        'فاز',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 40,
                      child: Text(
                        'نقاط',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (onDelete != null) const SizedBox(width: 34),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              for (int i = 0; i < standings.length; i++) ...[
                _StandingRow(
                  standing: standings[i],
                  rank: i + 1,
                  onDelete:
                      onDelete == null ? null : () => onDelete!(standings[i]),
                ),
                if (i != standings.length - 1)
                  Divider(
                    color: Colors.white.withOpacity(0.05),
                    height: 1,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final Standing standing;
  final int rank;
  final VoidCallback? onDelete;

  const _StandingRow({
    required this.standing,
    required this.rank,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final medal = standing.medalColor(rank);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medal.withOpacity(0.15),
              border: Border.all(
                color: medal.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: medal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              standing.teamName,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${standing.played}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${standing.won}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${standing.points}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            _IconActionButton(
              icon: Icons.delete_outline,
              color: AppColors.red,
              onTap: onDelete!,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// ✅ TOURNAMENT FORM DIALOG
// ============================================================
class _TournamentFormDialog extends StatefulWidget {
  final Tournament? tournament; // null = add, otherwise edit

  const _TournamentFormDialog({this.tournament});

  static Future<bool?> show(BuildContext context, {Tournament? tournament}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TournamentFormDialog(tournament: tournament),
    );
  }

  @override
  State<_TournamentFormDialog> createState() => _TournamentFormDialogState();
}

class _TournamentFormDialogState extends State<_TournamentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _teamsCountCtrl;

  TournamentStatus _status = TournamentStatus.upcoming;
  String _iconName = 'trophy';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _subtitleCtrl = TextEditingController();
    _dateCtrl = TextEditingController();
    _teamsCountCtrl = TextEditingController();
    final edit = widget.tournament;
    if (edit != null) {
      _nameCtrl.text = edit.name;
      _subtitleCtrl.text = edit.subtitle;
      _dateCtrl.text = edit.date;
      _teamsCountCtrl.text = '${edit.teamsCount}';
      _status = edit.status;
      _iconName = edit.iconName;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subtitleCtrl.dispose();
    _dateCtrl.dispose();
    _teamsCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.orange,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() => _dateCtrl.text = '$y/$m/$d');
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('مفيش مستخدم مسجل');

      final id =
          widget.tournament?.id ?? 'tour_${const Uuid().v4().substring(0, 8)}';

      final tournament = Tournament(
        id: id,
        name: _nameCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim(),
        date: _dateCtrl.text.trim(),
        status: _status,
        teamsCount: int.tryParse(_teamsCountCtrl.text.trim()) ?? 0,
        iconName: _iconName,
        academyId: widget.tournament?.academyId ?? user.academyId,
      );

      if (widget.tournament == null) {
        await TournamentService.addTournament(tournament);
      } else {
        await TournamentService.updateTournament(tournament);
      }

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
                      _DialogHeader(
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.orange,
                        title: widget.tournament == null
                            ? 'إضافة بطولة جديدة'
                            : 'تعديل البطولة',
                        subtitle: 'املأ بيانات البطولة',
                        onClose: () => Navigator.pop(context),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(
                              icon: Icons.title_rounded,
                              text: 'اسم البطولة *',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _nameCtrl,
                              hint: 'مثال: كأس الجمهورية',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'لازم تكتب اسم البطولة';
                                }
                                if (v.trim().length < 2) {
                                  return 'الاسم قصير جدًا';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.notes_rounded,
                              text: 'وصف مختصر',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _subtitleCtrl,
                              hint: 'مثال: دوري الناشئين',
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.calendar_today_rounded,
                              text: 'التاريخ',
                            ),
                            const SizedBox(height: 6),
                            _DateField(
                              controller: _dateCtrl,
                              onTap: _pickDate,
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.groups_rounded,
                              text: 'عدد الفرق',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _teamsCountCtrl,
                              hint: 'مثال: 8',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.info_rounded,
                              text: 'الحالة *',
                            ),
                            const SizedBox(height: 6),
                            _StatusPicker(
                              value: _status,
                              onChanged: (v) =>
                                  setState(() => _status = v),
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.image_rounded,
                              text: 'الأيقونة',
                            ),
                            const SizedBox(height: 6),
                            _IconPicker(
                              value: _iconName,
                              onChanged: (v) =>
                                  setState(() => _iconName = v),
                            ),
                            const SizedBox(height: 22),

                            _DialogButtons(
                              saving: _saving,
                              color: AppColors.orange,
                              saveLabel: 'حفظ البطولة',
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
// ✅ CONFIRM DELETE  (same look as the logout dialog)
// ============================================================
Future<bool?> _confirmDelete(BuildContext context, String name) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AppDirectionality(
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.red.withOpacity(0.3)),
        ),
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'متأكد إنك عايز تحذف "$name"؟',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
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
}

// ============================================================
// ✅ ICON ACTION BUTTON (identical to the one used in teams/coaches)
// ============================================================
class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
      ),
    );
  }
}

// ============================================================
// ✅ MATCH FORM DIALOG  (add / edit) — built from the same private
//    widgets as the tournament dialog (header, fields, buttons…)
// ============================================================
class _MatchFormDialog extends StatefulWidget {
  final Match? match; // null = add, otherwise edit

  const _MatchFormDialog({this.match});

  static Future<bool?> show(BuildContext context, {Match? match}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MatchFormDialog(match: match),
    );
  }

  @override
  State<_MatchFormDialog> createState() => _MatchFormDialogState();
}

class _MatchFormDialogState extends State<_MatchFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _opponentCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _venueCtrl;
  late final TextEditingController _homeCtrl;
  late final TextEditingController _awayCtrl;

  MatchStatus _status = MatchStatus.upcoming;
  List<Team> _teams = [];
  Team? _team;
  String? _teamId;
  String? _teamName;
  bool _loadingTeams = true;
  bool _saving = false;

  bool get _isEdit => widget.match != null;

  @override
  void initState() {
    super.initState();
    final m = widget.match;
    _opponentCtrl = TextEditingController(text: m?.opponentName ?? '');
    _dateCtrl = TextEditingController(text: m?.date ?? '');
    _timeCtrl = TextEditingController(text: m?.time ?? '05:00 م');
    _venueCtrl = TextEditingController(text: m?.venue ?? 'ملعب الأكاديمية');
    _homeCtrl = TextEditingController(text: '${m?.homeScore ?? 0}');
    _awayCtrl = TextEditingController(text: '${m?.awayScore ?? 0}');
    _status = m?.status ?? MatchStatus.upcoming;
    _teamId = (m == null || m.teamId.isEmpty) ? null : m.teamId;
    _teamName = m?.teamName;
    _loadTeams();
  }

  @override
  void dispose() {
    _opponentCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _venueCtrl.dispose();
    _homeCtrl.dispose();
    _awayCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await TeamService.getAllTeams();
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _loadingTeams = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTeams = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.green,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() => _dateCtrl.text = '$y/$m/$d');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_teamId == null || _teamId!.isEmpty) {
      _snack('اختار فريق الأول');
      return;
    }

    setState(() => _saving = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('مفيش مستخدم مسجل');

      final scored = _status != MatchStatus.upcoming;
      final match = Match(
        id: widget.match?.id ?? 'match_${const Uuid().v4().replaceAll('-', '')}',
        teamId: _teamId!,
        teamName: _teamName ?? '',
        opponentName: _opponentCtrl.text.trim(),
        venue: _venueCtrl.text.trim(),
        date: _dateCtrl.text.trim(),
        time: _timeCtrl.text.trim(),
        homeScore: scored ? (int.tryParse(_homeCtrl.text.trim()) ?? 0) : 0,
        awayScore: scored ? (int.tryParse(_awayCtrl.text.trim()) ?? 0) : 0,
        status: _status,
        playerRating: widget.match?.playerRating ?? '',
        academyId: widget.match?.academyId ?? user.academyId,
      );

      if (_isEdit) {
        await MatchService.updateMatch(match);
      } else {
        await MatchService.addMatch(match);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('حصل خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final showScore = _status != MatchStatus.upcoming;

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
                  color: AppColors.green.withOpacity(0.5),
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
                      _DialogHeader(
                        icon: Icons.sports_soccer_rounded,
                        color: AppColors.green,
                        title: _isEdit ? 'تعديل المباراة' : 'إضافة مباراة جديدة',
                        subtitle: 'املأ بيانات المباراة',
                        onClose: () => Navigator.pop(context),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(
                              icon: Icons.shield_rounded,
                              text: 'الفريق *',
                            ),
                            const SizedBox(height: 6),
                            _TeamDropdown(
                              teams: _teams,
                              loading: _loadingTeams,
                              selectedId: _teamId,
                              onChanged: (id, name) {
                                setState(() {
                                  _teamId = id;
                                  _team = _teams.cast<Team?>().firstWhere(
                                        (t) => t?.id == id,
                                        orElse: () => null,
                                      );
                                  _teamName = _team?.name ?? name;
                                });
                              },
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.sports_rounded,
                              text: 'الفريق المنافس *',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _opponentCtrl,
                              hint: 'مثال: أكاديمية الأهلي',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'لازم تكتب اسم المنافس';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.calendar_today_rounded,
                              text: 'التاريخ *',
                            ),
                            const SizedBox(height: 6),
                            _DateField(
                              controller: _dateCtrl,
                              onTap: _pickDate,
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.access_time_rounded,
                              text: 'الوقت',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _timeCtrl,
                              hint: 'مثال: 05:00 م',
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.location_on_rounded,
                              text: 'الملعب',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _venueCtrl,
                              hint: 'مثال: ملعب الأكاديمية',
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.info_rounded,
                              text: 'الحالة *',
                            ),
                            const SizedBox(height: 6),
                            _MatchStatusPicker(
                              value: _status,
                              onChanged: (v) => setState(() => _status = v),
                            ),

                            if (showScore) ...[
                              const SizedBox(height: 14),
                              _FieldLabel(
                                icon: Icons.scoreboard_rounded,
                                text: 'النتيجة (فريقنا - المنافس)',
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: _TextField(
                                      controller: _homeCtrl,
                                      hint: 'مثال: 8',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _TextField(
                                      controller: _awayCtrl,
                                      hint: 'مثال: 8',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 22),

                            _DialogButtons(
                              saving: _saving,
                              color: AppColors.green,
                              saveLabel: 'حفظ المباراة',
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

// Same pill style as _StatusPicker (tournament), for match statuses.
class _MatchStatusPicker extends StatelessWidget {
  final MatchStatus value;
  final ValueChanged<MatchStatus> onChanged;

  const _MatchStatusPicker({required this.value, required this.onChanged});

  static const _options = [
    (MatchStatus.upcoming, 'قادمة', AppColors.blue),
    (MatchStatus.live, 'مباشر', AppColors.red),
    (MatchStatus.finished, 'منتهية', AppColors.gray),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _options.map((opt) {
        final active = opt.$1 == value;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(opt.$1),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? opt.$3.withOpacity(0.20)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? opt.$3 : Colors.white.withOpacity(0.10),
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Text(
                opt.$2,
                style: TextStyle(
                  color: active ? opt.$3 : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
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
// ✅ STANDING FORM DIALOG
// ============================================================
class _StandingFormDialog extends StatefulWidget {
  const _StandingFormDialog();

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _StandingFormDialog(),
    );
  }

  @override
  State<_StandingFormDialog> createState() => _StandingFormDialogState();
}

class _StandingFormDialogState extends State<_StandingFormDialog> {
  final _formKey = GlobalKey<FormState>();

  List<Team> _teams = [];
  Team? _selectedTeam;
  bool _loadingTeams = true;

  late final TextEditingController _playedCtrl;
  late final TextEditingController _wonCtrl;
  late final TextEditingController _drawnCtrl;
  late final TextEditingController _lostCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _playedCtrl = TextEditingController();
    _wonCtrl = TextEditingController();
    _drawnCtrl = TextEditingController();
    _lostCtrl = TextEditingController();
    _loadTeams();
  }

  @override
  void dispose() {
    _playedCtrl.dispose();
    _wonCtrl.dispose();
    _drawnCtrl.dispose();
    _lostCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await TeamService.getAllTeams();
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _loadingTeams = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTeams = false);
    }
  }

  Future<void> _save() async {
    if (_selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'اختار فريق الأول',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('مفيش مستخدم مسجل');

      final standing = Standing(
        teamId: _selectedTeam!.id,
        teamName: _selectedTeam!.name,
        played: int.tryParse(_playedCtrl.text.trim()) ?? 0,
        won: int.tryParse(_wonCtrl.text.trim()) ?? 0,
        drawn: int.tryParse(_drawnCtrl.text.trim()) ?? 0,
        lost: int.tryParse(_lostCtrl.text.trim()) ?? 0,
        academyId: user.academyId,
      );

      await TournamentService.addStanding(standing);

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
                  color: AppColors.blue.withOpacity(0.5),
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
                      _DialogHeader(
                        icon: Icons.leaderboard_rounded,
                        color: AppColors.blue,
                        title: 'إضافة ترتيب فريق',
                        subtitle: 'سجّل نتائج الفريق',
                        onClose: () => Navigator.pop(context),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(
                              icon: Icons.shield_rounded,
                              text: 'الفريق *',
                            ),
                            const SizedBox(height: 6),
                            _TeamDropdown(
                              teams: _teams,
                              loading: _loadingTeams,
                              selectedId: _selectedTeam?.id,
                              onChanged: (id, name) {
                                setState(() {
                                  _selectedTeam = _teams.firstWhere(
                                    (t) => t.id == id,
                                    orElse: () => _teams.first,
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _FieldLabel(
                                        icon: Icons.sports_soccer_rounded,
                                        text: 'لعب',
                                      ),
                                      const SizedBox(height: 6),
                                      _TextField(
                                        controller: _playedCtrl,
                                        hint: '0',
                                        keyboardType:
                                            TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _FieldLabel(
                                        icon: Icons.emoji_events_rounded,
                                        text: 'فاز',
                                      ),
                                      const SizedBox(height: 6),
                                      _TextField(
                                        controller: _wonCtrl,
                                        hint: '0',
                                        keyboardType:
                                            TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _FieldLabel(
                                        icon: Icons.horizontal_rule_rounded,
                                        text: 'تعادل',
                                      ),
                                      const SizedBox(height: 6),
                                      _TextField(
                                        controller: _drawnCtrl,
                                        hint: '0',
                                        keyboardType:
                                            TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _FieldLabel(
                                        icon: Icons.close_rounded,
                                        text: 'خسر',
                                      ),
                                      const SizedBox(height: 6),
                                      _TextField(
                                        controller: _lostCtrl,
                                        hint: '0',
                                        keyboardType:
                                            TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),

                            _DialogButtons(
                              saving: _saving,
                              color: AppColors.blue,
                              saveLabel: 'حفظ الترتيب',
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
// ✅ SHARED DIALOG COMPONENTS
// ============================================================
class _DialogHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

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
              color: color.withOpacity(0.15),
              border: Border.all(color: color),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
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

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;

  const _DateField({
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontFamily: 'Cairo',
      ),
      decoration: InputDecoration(
        hintText: L10n.tr('اختر التاريخ'),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontFamily: 'Cairo',
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        prefixIcon: const Icon(
          Icons.calendar_month_rounded,
          color: AppColors.orange,
          size: 18,
        ),
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
      ),
    );
  }
}

class _StatusPicker extends StatelessWidget {
  final TournamentStatus value;
  final ValueChanged<TournamentStatus> onChanged;

  const _StatusPicker({
    required this.value,
    required this.onChanged,
  });

  static const _options = [
    (TournamentStatus.upcoming, 'قريباً', AppColors.blue),
    (TournamentStatus.ongoing, 'جاري', AppColors.green),
    (TournamentStatus.scheduled, 'مجدول', AppColors.purple),
    (TournamentStatus.finished, 'منتهي', AppColors.gray),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _options.map((opt) {
        final active = opt.$1 == value;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(opt.$1),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: active
                    ? opt.$3.withOpacity(0.20)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? opt.$3
                      : Colors.white.withOpacity(0.10),
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Text(
                opt.$2,
                style: TextStyle(
                  color: active
                      ? opt.$3
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight:
                      active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _IconPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _IconPicker({
    required this.value,
    required this.onChanged,
  });

  static const _options = [
    ('trophy', Icons.emoji_events_rounded, 'كأس'),
    ('medal', Icons.military_tech_rounded, 'ميدالية'),
    ('stadium', Icons.stadium_rounded, 'ملعب'),
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
                        ? AppColors.orange.withOpacity(0.15)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? AppColors.orange
                          : Colors.white.withOpacity(0.10),
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        opt.$2,
                        color: active
                            ? AppColors.orange
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opt.$3,
                        style: TextStyle(
                          color: active
                              ? AppColors.orange
                              : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w600,
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

class _TeamDropdown extends StatelessWidget {
  final List<Team> teams;
  final bool loading;
  final String? selectedId;
  final void Function(String? id, String? name) onChanged;

  const _TeamDropdown({
    required this.teams,
    required this.loading,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: AppColors.green,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (teams.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.orange.withOpacity(0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.orange,
              size: 16,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'مفيش فرق في الأكاديمية. ضيف فرق الأول.',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.green,
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Cairo',
          ),
          hint: const Text(
            'اختر فريق',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          items: teams.map((t) {
            return DropdownMenuItem<String>(
              value: t.id,
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_rounded,
                    color: AppColors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (id) {
            if (id == null) return;
            final team = teams.firstWhere((t) => t.id == id);
            onChanged(team.id, team.name);
          },
        ),
      ),
    );
  }
}

class _DialogButtons extends StatelessWidget {
  final bool saving;
  final Color color;
  final String saveLabel;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _DialogButtons({
    required this.saving,
    required this.color,
    required this.saveLabel,
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
                        : [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: saving
                      ? []
                      : [
                          BoxShadow(
                            color: color.withOpacity(0.4),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              saveLabel,
                              style: const TextStyle(
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