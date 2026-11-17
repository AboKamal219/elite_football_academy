// lib/attendance_screen.dart

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
import 'models/player.dart';
import 'models/attendance_status.dart';
import 'services/attendance_service.dart';
import 'services/auth_service.dart';
import 'services/player_service.dart';
import 'qr_scanner_screen.dart';
import 'services/checkin_token_service.dart';

// ============================================================
// ATTENDANCE SCREEN
// ============================================================
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _filterIndex = 0;

  late DateTime _selectedDate;
  late DateTime _viewMonth;

  // ✅ الحضور بالشكل الموحّد من الـ Service
  Map<String, AttendanceStatus> _attendance = {};

  List<Player> _players = [];

  bool _loading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _viewMonth = DateTime(now.year, now.month);
    _loadData();
  }

  // ============================================================
  // تحميل البيانات
  // ============================================================
  Future<void> _loadData() async {
    final user = AuthService.currentUser;

    List<Player> players = [];
    if (user != null) {
      if (user.role == UserRole.admin) {
        players = await PlayerService.getAllPlayers();
      } else if (user.role == UserRole.coach && user.teamId != null) {
        players = await PlayerService.getPlayersByTeam(user.teamId!);
      }
    }

    // ✅ نقرأ من الـ Service الموحّد
    final attendance = await AttendanceService.getAll();

    if (!mounted) return;
    setState(() {
      _players = players;
      _attendance = attendance;
      _loading = false;
    });
  }

  // ============================================================
  // حفظ الحضور
  // ============================================================
  Future<void> _saveAttendance() async {
    // ✅ FIX: تمرير اللاعبين عشان team_id يتسجل مع كل صف حضور
    await AttendanceService.saveAll(_attendance, players: _players);

    if (!mounted) return;
    setState(() => _hasChanges = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حفظ الحضور ✅',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // مسح QR
  // ============================================================
  Future<void> _scanQr() async {
    // The scanner stays open (continuous scanning). For every code the server
    // verifies it AND records attendance immediately; we only mirror the result.
    final date = _selectedDate;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          onScan: (raw) async {
            final res = await CheckinTokenService.scan(raw, date);
            if (!res.ok) {
              return ScanFeedback(ScanTone.error, res.message);
            }
            if (mounted) {
              // already saved on the server -> update the screen WITHOUT "unsaved changes"
              final key = AttendanceService.buildKey(date, res.playerId!);
              setState(() {
                if (res.outcome == ScanOutcome.recorded) {
                  _attendance[key] = AttendanceStatus.present;
                }
              });
            }
            return ScanFeedback(
              res.outcome == ScanOutcome.recorded ? ScanTone.success : ScanTone.info,
              res.message,
            );
          },
        ),
      ),
    );
    if (!mounted) return;
    // make sure the list shows exactly what the database holds
    final fresh = await AttendanceService.getAll();
    if (!mounted) return;
    setState(() {
      if (!_hasChanges) {
        _attendance
          ..clear()
          ..addAll(fresh);
      }
    });
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

  // ============================================================
  // Helpers
  // ============================================================
  /// null == NOT MARKED (no row in the database).
  AttendanceStatus? _statusOf(String playerId, DateTime date) {
    final key = AttendanceService.buildKey(date, playerId);
    return _attendance[key];
  }

  void _setStatus(String playerId, DateTime date, AttendanceStatus status) {
    setState(() {
      final key = AttendanceService.buildKey(date, playerId);
      _attendance[key] = status;
      _hasChanges = true;
    });
  }

  Map<AttendanceStatus, int> _statsFor(DateTime date) {
    int present = 0, absent = 0, late = 0;
    for (final p in _players) {
      final s = _statusOf(p.id, date);
      if (s == null) continue; // not marked: counted in none of the three
      switch (s) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.late:
          late++;
          break;
      }
    }
    return {
      AttendanceStatus.present: present,
      AttendanceStatus.absent: absent,
      AttendanceStatus.late: late,
    };
  }

  // ============================================================
  // BUILD
  // ============================================================
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
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final device = deviceTypeOf(constraints.maxWidth);
                          final maxWidth = device == DeviceType.tablet
                              ? 900.0
                              : constraints.maxWidth;
                          return Center(
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: maxWidth),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                        horizontal: 16)
                                    .copyWith(top: 20, bottom: 32),
                                child: _AttendanceBody(
                                  device: device,
                                  filterIndex: _filterIndex,
                                  onFilterChanged: (i) =>
                                      setState(() => _filterIndex = i),
                                  selectedDate: _selectedDate,
                                  onDateSelected: (d) =>
                                      setState(() => _selectedDate = d),
                                  viewMonth: _viewMonth,
                                  onMonthChanged: (m) =>
                                      setState(() => _viewMonth = m),
                                  attendance: _attendance,
                                  statusOf: _statusOf,
                                  setStatus: _setStatus,
                                  statsFor: _statsFor,
                                  hasChanges: _hasChanges,
                                  onSave: _saveAttendance,
                                  onScan: _scanQr,
                                  players: _players,
                                ),
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
class _AttendanceBody extends StatelessWidget {
  final DeviceType device;
  final int filterIndex;
  final ValueChanged<int> onFilterChanged;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime viewMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final Map<String, AttendanceStatus> attendance;
  final AttendanceStatus? Function(String, DateTime) statusOf;
  final void Function(String, DateTime, AttendanceStatus) setStatus;
  final Map<AttendanceStatus, int> Function(DateTime) statsFor;
  final bool hasChanges;
  final VoidCallback onSave;
  final VoidCallback onScan;
  final List<Player> players;

  const _AttendanceBody({
    required this.device,
    required this.filterIndex,
    required this.onFilterChanged,
    required this.selectedDate,
    required this.onDateSelected,
    required this.viewMonth,
    required this.onMonthChanged,
    required this.attendance,
    required this.statusOf,
    required this.setStatus,
    required this.statsFor,
    required this.hasChanges,
    required this.onSave,
    required this.onScan,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    final stats = statsFor(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          hasChanges: hasChanges,
          onSave: onSave,
          onScan: onScan,
        ),
        const SizedBox(height: 14),
        _AttendanceHero(stats: stats),
        const SizedBox(height: 18),
        _CalendarSection(
          selectedDate: selectedDate,
          onDateSelected: onDateSelected,
          viewMonth: viewMonth,
          onMonthChanged: onMonthChanged,
          attendance: attendance,
        ),
        const SizedBox(height: 18),
        _SummarySection(stats: stats),
        const SizedBox(height: 18),
        const _SectionTitle(
          title: 'سجل الحضور',
          icon: Icons.people_alt_rounded,
          color: AppColors.green,
        ),
        const SizedBox(height: 12),
        _FilterTabs(
          currentIndex: filterIndex,
          onChanged: onFilterChanged,
        ),
        const SizedBox(height: 14),
        _PlayersList(
          filterIndex: filterIndex,
          selectedDate: selectedDate,
          statusOf: statusOf,
          setStatus: setStatus,
          players: players,
        ),
      ],
    );
  }
}

// ============================================================
// TOP BAR
// ============================================================
class _TopBar extends StatelessWidget {
  final bool hasChanges;
  final VoidCallback onSave;
  final VoidCallback onScan;

  const _TopBar({
    required this.hasChanges,
    required this.onSave,
    required this.onScan,
  });

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
              errorBuilder: (_, __, ___) => const Icon(
                Icons.sports_soccer,
                color: AppColors.green,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الحضور والغياب',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'متابعة حضور اللاعبين',
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
            child: Material(
              color: AppColors.green.withOpacity(0.15),
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.green),
              ),
              child: InkWell(
                onTap: onScan,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.green,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: hasChanges
                  ? AppColors.green.withOpacity(0.3)
                  : AppColors.green.withOpacity(0.1),
              shape: CircleBorder(
                side: BorderSide(
                  color: hasChanges
                      ? AppColors.green
                      : AppColors.green.withOpacity(0.3),
                ),
              ),
              child: InkWell(
                onTap: hasChanges ? onSave : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.check_rounded,
                    color: hasChanges
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
class _AttendanceHero extends StatelessWidget {
  final Map<AttendanceStatus, int> stats;
  const _AttendanceHero({required this.stats});

  @override
  Widget build(BuildContext context) {
    final present = stats[AttendanceStatus.present] ?? 0;
    final absent = stats[AttendanceStatus.absent] ?? 0;
    final late = stats[AttendanceStatus.late] ?? 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const NetImage(
              url: AppImages.coachStadium,
              fallbackIcon: Icons.sports_soccer,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.30),
                    AppColors.green.withOpacity(0.35),
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
                      AppColors.green.withOpacity(0.35),
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
                          'الحضور',
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
                          color: AppColors.green.withOpacity(0.25),
                          border: Border.all(
                            color: AppColors.green.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.fact_check_rounded,
                          color: AppColors.green,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تابع حضور اللاعبين يومياً',
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
                    icon: Icons.check_circle_rounded,
                    value: '$present',
                    label: 'حاضر',
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 8),
                  _HeroStat(
                    icon: Icons.cancel_rounded,
                    value: '$absent',
                    label: 'غائب',
                    color: AppColors.red,
                  ),
                  const SizedBox(width: 8),
                  _HeroStat(
                    icon: Icons.access_time_rounded,
                    value: '$late',
                    label: 'متأخر',
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
// CALENDAR SECTION
// ============================================================
class _CalendarSection extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime viewMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final Map<String, AttendanceStatus> attendance;

  const _CalendarSection({
    required this.selectedDate,
    required this.onDateSelected,
    required this.viewMonth,
    required this.onMonthChanged,
    required this.attendance,
  });

  static const days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

  static const monthNames = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysInMonth =
        DateTime(viewMonth.year, viewMonth.month + 1, 0).day;

    final firstDay = DateTime(viewMonth.year, viewMonth.month, 1);
    final startWeekday = firstDay.weekday % 7; // 0=السبت

    // ✅ الأيام اللي فيها حضور في الشهر ده (باستخدام الـ service)
    final eventDays = <int>{};
    attendance.forEach((key, _) {
      final parsed = AttendanceService.parseKey(key);
      if (parsed == null) return;
      if (parsed.date.year != viewMonth.year) return;
      if (parsed.date.month != viewMonth.month) return;
      eventDays.add(parsed.date.day);
    });

    final isCurrentMonth = viewMonth.year == today.year &&
        viewMonth.month == today.month;

    final totalCells =
        ((startWeekday + daysInMonth + 6) ~/ 7) * 7;

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
                      color: AppColors.green.withOpacity(0.15),
                      border: Border.all(
                        color: AppColors.green.withOpacity(0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.green,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${monthNames[viewMonth.month - 1]} ${viewMonth.year}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  _CalendarArrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => onMonthChanged(
                      DateTime(viewMonth.year, viewMonth.month - 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _CalendarArrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => onMonthChanged(
                      DateTime(viewMonth.year, viewMonth.month + 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: days
                    .map((day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final dayNumber = index - startWeekday + 1;

                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox();
                  }

                  final date = DateTime(
                    viewMonth.year,
                    viewMonth.month,
                    dayNumber,
                  );

                  final isSelected = _isSameDay(date, selectedDate);
                  final hasEvent = eventDays.contains(dayNumber);
                  final isToday = _isSameDay(date, today);

                  return GestureDetector(
                    onTap: () => onDateSelected(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.green
                            : isToday
                                ? AppColors.green.withOpacity(0.15)
                                : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.green
                              : isToday
                                  ? AppColors.green.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.06),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.green.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNumber',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                            ),
                          ),
                          if (hasEvent) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.orange,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              if (!isCurrentMonth ||
                  !_isSameDay(selectedDate, today)) ...[
                const SizedBox(height: 12),
                Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onMonthChanged(DateTime(today.year, today.month));
                        onDateSelected(today);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.green.withOpacity(0.4),
                          ),
                        ),
                        child: const Text(
                          'ارجع لليوم',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CalendarArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CalendarArrow({
    required this.icon,
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
            border: Border.all(
              color: AppColors.green.withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.green,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SUMMARY SECTION
// ============================================================
class _SummarySection extends StatelessWidget {
  final Map<AttendanceStatus, int> stats;
  const _SummarySection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final present = stats[AttendanceStatus.present] ?? 0;
    final absent = stats[AttendanceStatus.absent] ?? 0;
    final late = stats[AttendanceStatus.late] ?? 0;
    final total = present + absent + late;
    final percentage = total > 0 ? present / total : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.green.withOpacity(0.12),
                Colors.white.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.green.withOpacity(0.3),
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
                      color: AppColors.green.withOpacity(0.15),
                      border: Border.all(
                        color: AppColors.green.withOpacity(0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: AppColors.green,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ملخص اليوم',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CustomPaint(
                      painter: _CircularProgressPainter(
                        progress: percentage,
                        color: AppColors.green,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(percentage * 100).round()}%',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'حضور',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryDetail(
                          icon: Icons.check_circle_rounded,
                          label: 'حاضر',
                          value: '$present',
                          color: AppColors.green,
                        ),
                        const SizedBox(height: 10),
                        _SummaryDetail(
                          icon: Icons.cancel_rounded,
                          label: 'غائب',
                          value: '$absent',
                          color: AppColors.red,
                        ),
                        const SizedBox(height: 10),
                        _SummaryDetail(
                          icon: Icons.access_time_rounded,
                          label: 'متأخر',
                          value: '$late',
                          color: AppColors.orange,
                        ),
                      ],
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

class _SummaryDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryDetail({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(
              color: color.withOpacity(0.5),
            ),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 8;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.06);

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          color.withOpacity(0.7),
          color,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );

    canvas.drawCircle(center, radius, bgPaint);

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// SECTION TITLE
// ============================================================
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
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
    ('الكل', Icons.apps_rounded, AppColors.green),
    ('حاضر', Icons.check_circle_rounded, AppColors.green),
    ('غائب', Icons.cancel_rounded, AppColors.red),
    ('متأخر', Icons.access_time_rounded, AppColors.orange),
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
// PLAYERS LIST
// ============================================================
class _PlayersList extends StatelessWidget {
  final int filterIndex;
  final DateTime selectedDate;
  final AttendanceStatus? Function(String, DateTime) statusOf;
  final void Function(String, DateTime, AttendanceStatus) setStatus;
  final List<Player> players;

  const _PlayersList({
    required this.filterIndex,
    required this.selectedDate,
    required this.statusOf,
    required this.setStatus,
    required this.players,
  });

  List<Player> get _filteredPlayers {
    switch (filterIndex) {
      case 1:
        return players
            .where((p) =>
                statusOf(p.id, selectedDate) == AttendanceStatus.present)
            .toList();
      case 2:
        return players
            .where((p) =>
                statusOf(p.id, selectedDate) == AttendanceStatus.absent)
            .toList();
      case 3:
        return players
            .where((p) =>
                statusOf(p.id, selectedDate) == AttendanceStatus.late)
            .toList();
      default:
        return players;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPlayers;

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
                Icons.people_outline_rounded,
                color: AppColors.textSecondary,
                size: 40,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'لا يوجد لاعبين',
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
          _PlayerCard(
            player: filtered[i],
            selectedDate: selectedDate,
            status: statusOf(filtered[i].id, selectedDate),
            onStatusChanged: (s) =>
                setStatus(filtered[i].id, selectedDate, s),
          ),
          if (i != filtered.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  final DateTime selectedDate;
  final AttendanceStatus? status; // null = not marked
  final ValueChanged<AttendanceStatus> onStatusChanged;

  const _PlayerCard({
    required this.player,
    required this.selectedDate,
    required this.status,
    required this.onStatusChanged,
  });

  Color get _color => status?.color ?? AppColors.gray;
  String get _label => status?.label ?? 'لم يُسجَّل';
  IconData get _icon => status?.icon ?? Icons.radio_button_unchecked_rounded;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _color.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color,
                        width: 2,
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
                  const SizedBox(width: 12),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          player.position,
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
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _color.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _icon,
                          color: _color,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _label,
                          style: TextStyle(
                            color: _color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatusButton(
                      label: 'حاضر',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.green,
                      active: status == AttendanceStatus.present,
                      onTap: () =>
                          onStatusChanged(AttendanceStatus.present),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatusButton(
                      label: 'متأخر',
                      icon: Icons.access_time_rounded,
                      color: AppColors.orange,
                      active: status == AttendanceStatus.late,
                      onTap: () => onStatusChanged(AttendanceStatus.late),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatusButton(
                      label: 'غائب',
                      icon: Icons.cancel_rounded,
                      color: AppColors.red,
                      active: status == AttendanceStatus.absent,
                      onTap: () =>
                          onStatusChanged(AttendanceStatus.absent),
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

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? color.withOpacity(0.2)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? color : Colors.white.withOpacity(0.08),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? color : AppColors.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: active ? color : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}