// lib/teams_screen.dart

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
import 'models/team.dart';
import 'player_detail_screen.dart';
import 'services/auth_service.dart';
import 'services/match_service.dart';
import 'services/player_service.dart';
import 'services/team_service.dart';
import 'widgets/team_form_dialog.dart';

// ============================================================
// TEAMS SCREEN
// ============================================================

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  int _filterIndex = 0;
  bool _showAll = false;

  List<Team> _teams = [];
  List<Player> _allPlayers = [];
  List<Match> _allMatches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AuthService.currentUser;

    List<Team> teams = [];
    List<Player> players = [];
    List<Match> matches = [];

    if (user != null) {
      if (user.role == UserRole.admin) {
        teams = await TeamService.getAllTeams();
        players = await PlayerService.getAllPlayers();
        matches = await MatchService.getAllMatches();
      } else if (user.role == UserRole.coach && user.teamId != null) {
        final t = await TeamService.getTeamById(user.teamId!);
        teams = t != null ? [t] : [];
        players = await PlayerService.getPlayersByTeam(user.teamId!);
        matches = await MatchService.getMatchesByTeam(user.teamId!);
      }
    }

    if (!mounted) return;
    setState(() {
      _teams = teams;
      _allPlayers = players;
      _allMatches = matches;
      _loading = false;
    });
  }

  // ============================================================
  // ➕ إضافة فريق
  // ============================================================
  Future<void> _addTeam() async {
    final saved = await TeamFormDialog.show(context);
    if (saved == true && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تمت إضافة الفريق ✅',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // ✏️ تعديل فريق
  // ============================================================
  Future<void> _editTeam(Team team) async {
    final saved = await TeamFormDialog.show(context, team: team);
    if (saved == true && mounted) {
      await _loadData();
      if (!mounted) return;
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
    }
  }

  // ============================================================
  // 🗑️ حذف فريق
  // ============================================================
  Future<void> _deleteTeam(Team team) async {
    final playersCount = await TeamService.getPlayerCount(team.id);

    if (playersCount > 0) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AppDirectionality(
          child: AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.orange.withOpacity(0.5)),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.orange, size: 22),
                SizedBox(width: 8),
                Text(
                  'مش هينفع نحذف',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            content: Text(
              'الفريق ده فيه $playersCount لاعب.\n'
              'انقل اللاعبين لفريق تاني أو احذفهم الأول.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'تمام',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

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
            'متأكد إنك عايز تحذف "${team.name}"؟',
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

    final deleted = await TeamService.deleteTeam(team.id);

    if (!mounted) return;

    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'مش هينفع نحذف الفريق ❌',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حذف الفريق 🗑️',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                            .copyWith(top: 4, bottom: 110),
                        child: _TeamsBody(
                          device: deviceTypeOf(MediaQuery.of(context).size.width),
                          filterIndex: _filterIndex,
                          onFilterChanged: (i) =>
                              setState(() => _filterIndex = i),
                          teams: _teams,
                          allPlayers: _allPlayers,
                          allMatches: _allMatches,
                          onAddTeam: _addTeam,
                          onEditTeam: _editTeam,
                          onDeleteTeam: _deleteTeam,
                          showAll: _showAll,
                          onShowAllTapped: () {
                            setState(() => _showAll = true);
                          },
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
class _TeamsBody extends StatelessWidget {
  final DeviceType device;
  final int filterIndex;
  final ValueChanged<int> onFilterChanged;
  final List<Team> teams;
  final List<Player> allPlayers;
  final List<Match> allMatches;
  final VoidCallback onAddTeam;
  final ValueChanged<Team> onEditTeam;
  final ValueChanged<Team> onDeleteTeam;
  final bool showAll;
  final VoidCallback onShowAllTapped;

  const _TeamsBody({
    required this.device,
    required this.filterIndex,
    required this.onFilterChanged,
    required this.teams,
    required this.allPlayers,
    required this.allMatches,
    required this.onAddTeam,
    required this.onEditTeam,
    required this.onDeleteTeam,
    required this.showAll,
    required this.onShowAllTapped,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final isCoach = user?.role == UserRole.coach;
    final canEdit = user?.role == UserRole.admin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          onAddTeam: canEdit ? onAddTeam : null,
        ),

        const SizedBox(height: 14),

        _TeamsHero(
          teamsCount: teams.length,
          playersCount: allPlayers.length,
          matchesCount: allMatches.length,
        ),

        const SizedBox(height: 18),

        _SectionTitle(
          title: isCoach ? 'فريقي' : 'جميع الفرق',
          icon: Icons.groups_rounded,
          color: AppColors.blue,
          onShowAll: !showAll ? onShowAllTapped : null,
        ),

        const SizedBox(height: 12),

        _FilterTabs(
          currentIndex: filterIndex,
          onChanged: onFilterChanged,
          teams: teams,
        ),

        const SizedBox(height: 14),

        _TeamsGrid(
          filterIndex: filterIndex,
          teams: teams,
          allPlayers: allPlayers,
          allMatches: allMatches,
          onEditTeam: canEdit ? onEditTeam : null,
          onDeleteTeam: canEdit ? onDeleteTeam : null,
          showAll: showAll,
        ),

        const SizedBox(height: 20),

        _TopPlayersSection(players: allPlayers),
      ],
    );
  }
}

// ============================================================
// TOP BAR
// ============================================================
class _TopBar extends StatelessWidget {
  final VoidCallback? onAddTeam;
  const _TopBar({this.onAddTeam});

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
                'الفرق',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'فرق الأكاديمية',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        if (onAddTeam != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAddTeam,
              customBorder: const CircleBorder(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green.withOpacity(0.15),
                  border: Border.all(
                    color: AppColors.green.withOpacity(0.5),
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.green,
                  size: 22,
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
class _TeamsHero extends StatelessWidget {
  final int teamsCount;
  final int playersCount;
  final int matchesCount;

  const _TeamsHero({
    required this.teamsCount,
    required this.playersCount,
    required this.matchesCount,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 200,
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
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.30),
                    AppColors.blue.withOpacity(0.35),
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
                      AppColors.blue.withOpacity(0.35),
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
                          'الفرق',
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
                          color: AppColors.blue.withOpacity(0.25),
                          border: Border.all(
                            color: AppColors.blue.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: AppColors.blue,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تعرف على فرق الأكاديمية',
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
                    icon: Icons.groups_rounded,
                    value: '$teamsCount',
                    label: 'فرق',
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 8),
                  _HeroStat(
                    icon: Icons.person_rounded,
                    value: '$playersCount',
                    label: 'لاعب',
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 8),
                  _HeroStat(
                    icon: Icons.emoji_events_rounded,
                    value: '$matchesCount',
                    label: 'مباراة',
                    color: AppColors.orange,
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
// SECTION TITLE
// ============================================================
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onShowAll;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
    this.onShowAll,
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
        if (onShowAll != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onShowAll,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'عرض الكل',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_left,
                      color: AppColors.green,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
  final List<Team> teams;

  const _FilterTabs({
    required this.currentIndex,
    required this.onChanged,
    required this.teams,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['الكل', ...teams.map((t) => t.name).toList()];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (i) {
          final active = i == currentIndex;

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
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Text(
                      filters[i],
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
// TEAMS GRID
// ============================================================
class _TeamsGrid extends StatelessWidget {
  final int filterIndex;
  final List<Team> teams;
  final List<Player> allPlayers;
  final List<Match> allMatches;
  final ValueChanged<Team>? onEditTeam;
  final ValueChanged<Team>? onDeleteTeam;
  final bool showAll;

  const _TeamsGrid({
    required this.filterIndex,
    required this.teams,
    required this.allPlayers,
    required this.allMatches,
    this.onEditTeam,
    this.onDeleteTeam,
    required this.showAll,
  });

  List<Team> get _filteredTeams {
    if (filterIndex == 0) {
      return showAll ? teams : teams.take(5).toList();
    }
    final index = filterIndex - 1;
    if (index >= teams.length) return teams;
    return [teams[index]];
  }

  int _playersCountForTeam(String teamId) {
    return allPlayers.where((p) => p.teamId == teamId).length;
  }

  ({int wins, int total, double rate}) _teamStats(String teamId) {
    final teamMatches = allMatches
        .where((m) => m.teamId == teamId && m.isFinished)
        .toList();
    final total = teamMatches.length;
    final wins = teamMatches
        .where((m) => m.result == MatchResult.win)
        .length;
    final rate = total == 0 ? 0.0 : wins / total;
    return (wins: wins, total: total, rate: rate);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTeams;

    if (filtered.isEmpty) {
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
                Icons.groups_outlined,
                color: AppColors.textSecondary,
                size: 40,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'لا توجد فرق',
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
        for (int i = 0; i < filtered.length; i++) ...[
          _TeamCard(
            team: filtered[i],
            playersCount: _playersCountForTeam(filtered[i].id),
            stats: _teamStats(filtered[i].id),
            onTap: () => _showTeamPlayers(context, filtered[i]),
            onEdit: onEditTeam != null
                ? () => onEditTeam!(filtered[i])
                : null,
            onDelete: onDeleteTeam != null
                ? () => onDeleteTeam!(filtered[i])
                : null,
          ),
          if (i != filtered.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;
  final int playersCount;
  final ({int wins, int total, double rate}) stats;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TeamCard({
    required this.team,
    required this.playersCount,
    required this.stats,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final winRate = stats.rate;
    final matchesCount = stats.total;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                team.color.withOpacity(0.12),
                Colors.white.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: team.color.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                left: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: team.color.withOpacity(0.08),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: team.color.withOpacity(0.15),
                            border: Border.all(
                              color: team.color.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: team.color.withOpacity(0.3),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Icon(
                            team.icon,
                            color: team.color,
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: team.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  team.category,
                                  style: TextStyle(
                                    color: team.color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (onEdit != null || onDelete != null)
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
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'المدرب',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                team.displayCoachName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _TeamStat(
                          icon: Icons.person_rounded,
                          value: '$playersCount',
                          label: 'لاعب',
                          color: team.color,
                        ),
                        const SizedBox(width: 10),
                        _TeamStat(
                          icon: Icons.sports_soccer_rounded,
                          value: '$matchesCount',
                          label: 'مباراة',
                          color: AppColors.purple,
                        ),
                        const SizedBox(width: 10),
                        _TeamStat(
                          icon: Icons.emoji_events_rounded,
                          value: '${(winRate * 100).round()}%',
                          label: 'فوز',
                          color: AppColors.gold,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'نسبة الفوز',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '${(winRate * 100).round()}%',
                              style: TextStyle(
                                color: team.color,
                                fontSize: 11,
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
                              Container(
                                height: 8,
                                color: Colors.white.withOpacity(0.06),
                              ),
                              FractionallySizedBox(
                                widthFactor: winRate.clamp(0.0, 1.0),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        team.color.withOpacity(0.7),
                                        team.color,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: team.color.withOpacity(0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}

// ============================================================
// ICON ACTION BUTTON
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
            border: Border.all(
              color: color.withOpacity(0.4),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 14,
          ),
        ),
      ),
    );
  }
}

class _TeamStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _TeamStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TOP PLAYERS SECTION
// ============================================================
class _TopPlayersSection extends StatelessWidget {
  final List<Player> players;
  const _TopPlayersSection({required this.players});

  @override
  Widget build(BuildContext context) {
    final sorted = List<Player>.from(players)
      ..sort((a, b) {
        final ra = double.tryParse(a.rating) ?? 0;
        final rb = double.tryParse(b.rating) ?? 0;
        return rb.compareTo(ra);
      });
    final top = sorted.take(3).toList();

    if (top.isEmpty) return const SizedBox();

    final colors = [AppColors.green, AppColors.blue, AppColors.purple];

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.gold.withOpacity(0.15),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.gold,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'أبرز اللاعبين',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              for (int i = 0; i < top.length; i++) ...[
                _TopPlayerRow(
                  player: top[i],
                  color: colors[i % colors.length],
                  rank: i + 1,
                ),
                if (i != top.length - 1)
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

class _TopPlayerRow extends StatelessWidget {
  final Player player;
  final Color color;
  final int rank;

  const _TopPlayerRow({
    required this.player,
    required this.color,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(
                color: color.withOpacity(0.5),
              ),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: NetImage(
                url: player.photo,
                fallbackIcon: Icons.person,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  player.teamName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.green.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.green,
                  size: 12,
                ),
                const SizedBox(width: 3),
                Text(
                  player.rating,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
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
// TEAM PLAYERS SHEET  (يظهر لما تدوس على كارد الفريق)
// ============================================================
void _showTeamPlayers(BuildContext context, Team team) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0F1B2D),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, scroll) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, color: team.color, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'لاعبو ${team.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Player>>(
                future: PlayerService.getPlayersByTeam(team.id),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.green),
                    );
                  }
                  final players = snap.data ?? const <Player>[];
                  if (players.isEmpty) {
                    return const Center(
                      child: Text(
                        'مفيش لاعبين في الفريق ده لسه',
                        style: TextStyle(color: Colors.white60),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: players.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final p = players[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlayerDetailScreen(player: p),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    team.color.withOpacity(0.25),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(p.position,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.star_rounded,
                                  color: AppColors.gold, size: 16),
                              const SizedBox(width: 4),
                              Text(p.rating,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_left,
                                  color: Colors.white38),
                            ],
                          ),
                        ),
                      );
                    },
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
