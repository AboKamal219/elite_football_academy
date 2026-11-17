// lib/players_list_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import 'l10n/app_text.dart';
import 'academy_dashboard_screen.dart'
    show AppColors, AppImages, GlassCard, NetImage, DeviceType, deviceTypeOf;
import 'player_detail_screen.dart';
import 'widgets/top_header.dart';
import 'widgets/player_form_dialog.dart';
import 'models/app_user.dart';
import 'models/player.dart';
import 'services/auth_service.dart';
import 'services/player_service.dart';

// ============================================================
// ENTRY WIDGET
// ============================================================
class PlayersListScreen extends StatefulWidget {
  const PlayersListScreen({super.key});

  @override
  State<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends State<PlayersListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'الكل';
  String _sortBy = 'rating';

  List<Player> _allLoadedPlayers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final user = AuthService.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        _allLoadedPlayers = [];
        _loading = false;
      });
      return;
    }

    List<Player> players;

    switch (user.role) {
      case UserRole.admin:
        players = await PlayerService.getAllPlayers();
        break;

      case UserRole.coach:
        if (user.teamId != null && user.teamId!.isNotEmpty) {
          players = await PlayerService.getPlayersByTeam(user.teamId!);
        } else {
          players = [];
        }
        break;

      case UserRole.player:
        final me = await PlayerService.getPlayerByUserId(user.id);
        players = me != null ? [me] : [];
        break;
    }

    if (!mounted) return;
    setState(() {
      _allLoadedPlayers = players;
      _loading = false;
    });
  }

  List<Player> get _filteredPlayers {
    var players = List<Player>.from(_allLoadedPlayers);

    if (_searchQuery.isNotEmpty) {
      players = players.where((p) => p.name.contains(_searchQuery)).toList();
    }

    if (_selectedFilter != 'الكل') {
      players = players.where((p) => p.position == _selectedFilter).toList();
    }

    if (_sortBy == 'rating') {
      players.sort((a, b) {
        final ra = double.tryParse(a.rating) ?? 0.0;
        final rb = double.tryParse(b.rating) ?? 0.0;
        return rb.compareTo(ra);
      });
    } else {
      players.sort((a, b) => a.name.compareTo(b.name));
    }

    return players;
  }

  Future<void> _addPlayer() async {
    final saved = await PlayerFormDialog.show(context);
    if (saved == true && mounted) {
      await _loadPlayers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تمت إضافة اللاعب ✅',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editPlayer(Player player) async {
    final saved = await PlayerFormDialog.show(context, player: player);
    if (saved == true && mounted) {
      await _loadPlayers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C192F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Color(0xFF0C192F),
            ],
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 0,
              bottom: 100,
            ),
            child: _PlayersBody(
              device: deviceTypeOf(MediaQuery.of(context).size.width),
              players: _filteredPlayers,
              loading: _loading,
              searchQuery: _searchQuery,
              selectedFilter: _selectedFilter,
              sortBy: _sortBy,
              onSearchChanged: (v) => setState(() => _searchQuery = v),
              onFilterChanged: (v) => setState(() => _selectedFilter = v),
              onSortChanged: (v) => setState(() => _sortBy = v),
              onAddPlayer: _addPlayer,
              onEditPlayer: _editPlayer,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BODY
// ============================================================
class _PlayersBody extends StatelessWidget {
  final DeviceType device;
  final List<Player> players;
  final bool loading;
  final String searchQuery;
  final String selectedFilter;
  final String sortBy;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onAddPlayer;
  final ValueChanged<Player> onEditPlayer;

  const _PlayersBody({
    required this.device,
    required this.players,
    required this.loading,
    required this.searchQuery,
    required this.selectedFilter,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onAddPlayer,
    required this.onEditPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = device == DeviceType.tablet;
    final user = AuthService.currentUser;
    final canEdit = user?.role == UserRole.admin || user?.role == UserRole.coach;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TopHeader(),
        const SizedBox(height: 16),
        _PlayersHero(
          searchQuery: searchQuery,
          onSearchChanged: onSearchChanged,
        ),
        const SizedBox(height: 18),
        _FiltersRow(
          selectedFilter: selectedFilter,
          onFilterChanged: onFilterChanged,
          sortBy: sortBy,
          onSortChanged: onSortChanged,
          onAddPlayer: canEdit ? onAddPlayer : null,
        ),
        const SizedBox(height: 16),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.green),
            ),
          )
        else if (players.isEmpty)
          const _EmptyState()
        else
          _PlayersGrid(
            isTablet: isTablet,
            players: players,
            onEditPlayer: canEdit ? onEditPlayer : null,
          ),
        const SizedBox(height: 16),
        if (!loading) _PaginationFooter(total: players.length),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ============================================================
// HERO
// ============================================================
class _PlayersHero extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _PlayersHero({
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    String title;
    switch (user?.role) {
      case UserRole.admin:
        title = 'قائمة اللاعبين';
        break;
      case UserRole.coach:
        title = 'فريقي';
        break;
      case UserRole.player:
        title = 'بياناتي';
        break;
      default:
        title = 'اللاعبين';
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
                    AppColors.background.withOpacity(0.6),
                    AppColors.background.withOpacity(0.4),
                    AppColors.background.withOpacity(0.8),
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
                    Text(
                      title,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'تعرف على اللاعبين وتابع تطورهم',
                      style: TextStyle(
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    onChanged: onSearchChanged,
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      hintText: L10n.tr('البحث عن لاعب بالاسم ...'),
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
// FILTER CHIPS + SORT + ADD
// ============================================================
class _FiltersRow extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final VoidCallback? onAddPlayer;

  const _FiltersRow({
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.sortBy,
    required this.onSortChanged,
    this.onAddPlayer,
  });

  static const chips = [
    ('الكل', Icons.groups),
    ('مهاجم', Icons.gps_fixed),
    ('وسط ميدان', Icons.add_circle_outline),
    ('مدافع', Icons.shield_outlined),
    ('حارس مرمى', Icons.front_hand_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips.map((c) {
            final active = c.$1 == selectedFilter;
            return _ChipButton(
              label: c.$1,
              icon: c.$2,
              active: active,
              onTap: () => onFilterChanged(c.$1),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _SortDropdown(
                  sortBy: sortBy,
                  onChanged: onSortChanged,
                ),
              ),
            ),
            if (onAddPlayer != null) ...[
              const SizedBox(width: 8),
              _AddButton(onTap: onAddPlayer!),
            ],
          ],
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text(
                'إضافة لاعب',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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

class _ChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ChipButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (active) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(icon, color: Colors.white, size: 15),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(icon, color: AppColors.textSecondary, size: 15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String sortBy;
  final ValueChanged<String> onChanged;

  const _SortDropdown({
    required this.sortBy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: PopupMenuButton<String>(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: AppColors.green.withOpacity(0.3),
            ),
          ),
          onSelected: onChanged,
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'rating',
              child: Text(
                'حسب التقييم',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            const PopupMenuItem(
              value: 'name',
              child: Text(
                'حسب الاسم',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tune, color: AppColors.textSecondary, size: 15),
                const SizedBox(width: 6),
                Text(
                  sortBy == 'rating' ? 'الترتيب: التقييم' : 'الترتيب: الاسم',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                  size: 16,
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
// PLAYERS GRID (الحل النهائي - FittedBox)
// ============================================================
class _PlayersGrid extends StatelessWidget {
  final bool isTablet;
  final List<Player> players;
  final ValueChanged<Player>? onEditPlayer;

  const _PlayersGrid({
    required this.isTablet,
    required this.players,
    this.onEditPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // ✅ تم زيادة طول الكارت شوية عشان ياخد راحته
        childAspectRatio: isTablet ? 0.85 : 0.68,
      ),
      itemBuilder: (context, i) => _PlayerCard(
        player: players[i],
        onEdit: onEditPlayer != null
            ? () => onEditPlayer!(players[i])
            : null,
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onEdit;

  const _PlayerCard({
    required this.player,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('أهداف', '${player.goals}'),
      ('مباريات', '${player.matches}'),
      ('صناعة', '${player.assists}'),
    ];

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      // ✅ الحل السحري: بنحط المحتوى جوه FittedBox عشان يتظبط على المساحة المتاحة
      // ومستحيل يعمل Overflow مهما كان حجم الشاشة
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 150, // العرض الثابت للكارت
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (onEdit != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onEdit,
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.green.withOpacity(0.12),
                            border: Border.all(
                              color: AppColors.green.withOpacity(0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.green,
                            size: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 26),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: player.positionColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: player.positionColor.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      player.position,
                      style: TextStyle(
                        color: player.positionColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.green, width: 2),
                      ),
                      child: ClipOval(
                        child: NetImage(
                          url: player.photo,
                          fallbackIcon: Icons.person,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.background,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          player.rating,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                player.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                player.position,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield, color: AppColors.green, size: 12),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      player.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              const SizedBox(height: 8),
              Row(
                children: stats
                    .map(
                      (s) => Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.$2,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.$1,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerDetailScreen(player: player),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chevron_left, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'عرض التفاصيل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
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
// EMPTY STATE
// ============================================================
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
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
              Icons.person_off_rounded,
              color: AppColors.textSecondary,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'مفيش لاعبين',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'مفيش نتائج مطابقة للفلتر أو البحث',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAGINATION FOOTER
// ============================================================
class _PaginationFooter extends StatelessWidget {
  final int total;
  const _PaginationFooter({required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 6),
            const Text(
              'إجمالي اللاعبين: ',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            Text(
              '$total',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}