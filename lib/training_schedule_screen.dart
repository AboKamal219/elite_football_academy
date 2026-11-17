// lib/training_schedule_screen.dart

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
import 'widgets/top_header.dart';
import 'widgets/training_form_dialog.dart';
import 'models/app_user.dart';
import 'models/training.dart';
import 'services/auth_service.dart';
import 'services/attendance_service.dart';
import 'services/player_service.dart';
import 'services/training_service.dart';

// ============================================================
// TRAINING SCHEDULE SCREEN
// ============================================================
class TrainingScheduleScreen extends StatefulWidget {
  const TrainingScheduleScreen({super.key});

  @override
  State<TrainingScheduleScreen> createState() =>
      _TrainingScheduleScreenState();
}

class _TrainingScheduleScreenState extends State<TrainingScheduleScreen> {
  int _filterIndex = 0;
  List<Training> _trainings = [];
  String _coachNotes = '';
  bool _loading = true;
  DateTime _selectedMonth = DateTime.now();
  Map<DateTime, int> _attendanceStats = {};

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  Future<void> _loadTrainings() async {
    final list = await TrainingService.getAllTrainings();

    // ✅ جيب آخر ملاحظة من المدرب
    String notes = '';
    final user = AuthService.currentUser;
    if (user != null && user.teamId != null && user.teamId!.isNotEmpty) {
      notes = await TrainingService.getLatestCoachNote(user.teamId!);
    }

    // ✅ جيب إحصائيات الحضور الحقيقية
    final attendance = await AttendanceService.getAll();
    final attendanceStats = <DateTime, int>{};
    attendance.forEach((key, status) {
      final parsed = AttendanceService.parseKey(key);
      if (parsed != null && status.name == 'present') {
        final dateOnly = DateTime(parsed.date.year, parsed.date.month, parsed.date.day);
        attendanceStats[dateOnly] = (attendanceStats[dateOnly] ?? 0) + 1;
      }
    });

    if (!mounted) return;
    setState(() {
      _trainings = list;
      _coachNotes = notes;
      _attendanceStats = attendanceStats;
      _loading = false;
    });
  }

  // ============================================================
  // ➕ إضافة تدريب
  // ============================================================
  Future<void> _addTraining() async {
    final saved = await TrainingFormDialog.show(context);
    if (saved == true && mounted) {
      await _loadTrainings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تمت إضافة التدريب ✅',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // ✏️ تعديل
  // ============================================================
  Future<void> _editTraining(Training t) async {
    final saved = await TrainingFormDialog.show(context, training: t);
    if (saved == true && mounted) {
      await _loadTrainings();
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
  // 🗑️ حذف
  // ============================================================
  Future<void> _deleteTraining(Training t) async {
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
            'متأكد إنك عايز تحذف "${t.title}"؟',
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

    await TrainingService.deleteTraining(t.id);
    if (!mounted) return;
    await _loadTrainings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حذف التدريب 🗑️',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final device = deviceTypeOf(constraints.maxWidth);

        if (_loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.green),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          child: _TrainingBody(
            device: device,
            filterIndex: _filterIndex,
            onFilterChanged: (i) => setState(() => _filterIndex = i),
            trainings: _trainings,
            coachNotes: _coachNotes,
            selectedMonth: _selectedMonth,
            onMonthChanged: (m) => setState(() => _selectedMonth = m),
            attendanceStats: _attendanceStats,
            onAdd: _addTraining,
            onEdit: _editTraining,
            onDelete: _deleteTraining,
          ),
        );
      },
    );
  }
}

// ============================================================
// BODY
// ============================================================
class _TrainingBody extends StatelessWidget {
  final DeviceType device;
  final int filterIndex;
  final ValueChanged<int> onFilterChanged;
  final List<Training> trainings;
  final String coachNotes;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final Map<DateTime, int> attendanceStats;
  final VoidCallback onAdd;
  final ValueChanged<Training> onEdit;
  final ValueChanged<Training> onDelete;

  const _TrainingBody({
    required this.device,
    required this.filterIndex,
    required this.onFilterChanged,
    required this.trainings,
    required this.coachNotes,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.attendanceStats,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = device == DeviceType.tablet;
    final user = AuthService.currentUser;
    final canEdit = user?.role == UserRole.admin || user?.role == UserRole.coach;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopHeader(onAdd: canEdit ? onAdd : null),
        const SizedBox(height: 16),
        const _TrainingHero(),
        const SizedBox(height: 14),
        _StatsRow(trainings: trainings),
        const SizedBox(height: 18),
        _MainContent(
          isTablet: isTablet,
          filterIndex: filterIndex,
          onFilterChanged: onFilterChanged,
          trainings: trainings,
          coachNotes: coachNotes,
          selectedMonth: selectedMonth,
          onMonthChanged: onMonthChanged,
          attendanceStats: attendanceStats,
          canEdit: canEdit,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ============================================================
// HERO
// ============================================================
class _TrainingHero extends StatelessWidget {
  const _TrainingHero();

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
                        'جدول التدريبات',
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
                        Icons.calendar_month,
                        color: AppColors.green,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تنظيم أفضل .. أداء أعلى',
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
                width: 205,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المدرب الناجح',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'لا يصنع لاعبين جيدين فقط، بل يصنع أبطالًا!',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white.withOpacity(0.94),
                        fontSize: 15,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      width: 105,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green.withOpacity(0.45),
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
// STATS
// ============================================================
class _StatsRow extends StatelessWidget {
  final List<Training> trainings;
  const _StatsRow({required this.trainings});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = trainings.where((t) => t.isUpcoming).toList();
    final practices = trainings.where((t) => t.type == 'تدريب').length;
    final matches = trainings.where((t) => t.type == 'مباراة').length;
    final thisWeek = trainings.where((t) {
      final diff = t.date.difference(now).inDays;
      return diff >= 0 && diff <= 7;
    }).length;

    final cards = [
      (
        'إجمالي التدريبات',
        '$practices',
        Icons.fitness_center,
        AppColors.purple,
      ),
      (
        'تدريبات هذا الأسبوع',
        '$thisWeek',
        Icons.calendar_month,
        AppColors.green,
      ),
      (
        'مباريات قادمة',
        '$matches',
        Icons.emoji_events,
        AppColors.orange,
      ),
      (
        'تدريبات قادمة',
        '${upcoming.length}',
        Icons.schedule,
        AppColors.blue,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final count = width < 700 ? 2 : 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 82,
          ),
          itemBuilder: (_, index) {
            final card = cards[index];
            return _StatCard(
              title: card.$1,
              value: card.$2,
              icon: card.$3,
              color: card.$4,
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.30)),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
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
// MAIN CONTENT
// ============================================================
class _MainContent extends StatelessWidget {
  final bool isTablet;
  final int filterIndex;
  final ValueChanged<int> onFilterChanged;
  final List<Training> trainings;
  final String coachNotes;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final Map<DateTime, int> attendanceStats;
  final bool canEdit;
  final ValueChanged<Training> onEdit;
  final ValueChanged<Training> onDelete;

  const _MainContent({
    required this.isTablet,
    required this.filterIndex,
    required this.onFilterChanged,
    required this.trainings,
    required this.coachNotes,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.attendanceStats,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final upcoming = _UpcomingTrainings(
      filterIndex: filterIndex,
      onFilterChanged: onFilterChanged,
      trainings: trainings,
      canEdit: canEdit,
      onEdit: onEdit,
      onDelete: onDelete,
    );

    if (!isTablet) {
      return Column(
        children: [
          _CalendarSection(
            trainings: trainings,
            selectedMonth: selectedMonth,
            onMonthChanged: onMonthChanged,
          ),
          const SizedBox(height: 16),
          upcoming,
          const SizedBox(height: 16),
          _AttendanceCard(
            trainings: trainings,
            attendanceStats: attendanceStats,
          ),
          const SizedBox(height: 16),
          const _ResourcesCard(),
          const SizedBox(height: 16),
          _CoachNotesCard(notes: coachNotes),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _CalendarSection(
                trainings: trainings,
                selectedMonth: selectedMonth,
                onMonthChanged: onMonthChanged,
              ),
              const SizedBox(height: 16),
              upcoming,
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _AttendanceCard(
                trainings: trainings,
                attendanceStats: attendanceStats,
              ),
              const SizedBox(height: 16),
              const _ResourcesCard(),
              const SizedBox(height: 16),
              _CoachNotesCard(notes: coachNotes),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CALENDAR (ديناميكي)
// ============================================================
class _CalendarSection extends StatelessWidget {
  final List<Training> trainings;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const _CalendarSection({
    required this.trainings,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

    final year = selectedMonth.year;
    final month = selectedMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7;

    // ✅ الأيام اللي فيها تدريبات حقيقية في الشهر المختار
    final eventDays = trainings
        .where((t) => t.date.year == year && t.date.month == month)
        .map((t) => t.date.day)
        .toSet();

    final monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                color: AppColors.green,
                size: 21,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'التقويم الشهري',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _CalendarArrow(
                icon: Icons.chevron_left,
                onTap: () => onMonthChanged(DateTime(year, month - 1)),
              ),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.035),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Text(
                  '${monthNames[month - 1]}   $year',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _CalendarArrow(
                icon: Icons.chevron_right,
                onTap: () => onMonthChanged(DateTime(year, month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: days.map((day) {
                    return Expanded(
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.025),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                        ),
                        child: Text(
                          day,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                _buildCalendarGrid(startWeekday, daysInMonth, eventDays, DateTime.now().day, month, year),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
    int startWeekday,
    int daysInMonth,
    Set<int> eventDays,
    int today,
    int month,
    int year,
  ) {
    final now = DateTime.now();
    final isCurrentMonth = now.month == month && now.year == year;

    final cells = <Widget>[];
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final isToday = isCurrentMonth && d == today;
      final hasEvent = eventDays.contains(d);

      cells.add(
        Container(
          decoration: BoxDecoration(
            color: isToday ? AppColors.green : Colors.transparent,
            border: Border(
              right: BorderSide(color: Colors.white.withOpacity(0.05)),
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$d',
                style: TextStyle(
                  color: isToday ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
              if (hasEvent) ...[
                const SizedBox(height: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isToday ? Colors.white : AppColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    while (cells.length % 7 != 0) {
      cells.add(const SizedBox());
    }

    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      rows.add(
        SizedBox(
          height: 54,
          child: Row(
            children: cells
                .sublist(i, i + 7)
                .map((c) => Expanded(child: c))
                .toList(),
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

class _CalendarArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CalendarArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.025),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.green.withOpacity(0.45),
          ),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }
}

// ============================================================
// UPCOMING TRAININGS
// ============================================================
class _UpcomingTrainings extends StatelessWidget {
  final int filterIndex;
  final ValueChanged<int> onFilterChanged;
  final List<Training> trainings;
  final bool canEdit;
  final ValueChanged<Training> onEdit;
  final ValueChanged<Training> onDelete;

  const _UpcomingTrainings({
    required this.filterIndex,
    required this.onFilterChanged,
    required this.trainings,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  List<Training> get _filtered {
    final sorted = List<Training>.from(trainings)
      ..sort((a, b) => a.date.compareTo(b.date));

    switch (filterIndex) {
      case 1:
        return sorted.where((t) => t.type == 'تدريب').toList();
      case 2:
        return sorted.where((t) => t.type == 'مباراة').toList();
      case 3:
        return sorted.where((t) => t.type == 'اجتماع').toList();
      default:
        return sorted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fitness_center,
                color: AppColors.green,
                size: 19,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'جدول التدريبات القادم',
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
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                for (int i = 0; i < _tabs.length; i++) ...[
                  _TrainingTab(
                    title: _tabs[i].$1,
                    active: i == filterIndex,
                    onTap: () => onFilterChanged(i),
                  ),
                  if (i != _tabs.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'مفيش تدريبات',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...filtered.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TrainingListItem(
                  training: t,
                  onEdit: canEdit ? () => onEdit(t) : null,
                  onDelete: canEdit ? () => onDelete(t) : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const _tabs = [
    ('الكل', Icons.apps_rounded),
    ('تدريبات', Icons.fitness_center),
    ('مباريات', Icons.emoji_events),
    ('اجتماعات', Icons.groups),
  ];
}

class _TrainingTab extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _TrainingTab({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.green
                : Colors.white.withOpacity(0.025),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? AppColors.green
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrainingListItem extends StatelessWidget {
  final Training training;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TrainingListItem({
    required this.training,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: training.typeColor.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          if (onEdit != null || onDelete != null) ...[
            if (onEdit != null)
              _IconBtn(
                icon: Icons.edit_outlined,
                color: AppColors.green,
                onTap: onEdit!,
              ),
            if (onEdit != null && onDelete != null) const SizedBox(width: 5),
            if (onDelete != null)
              _IconBtn(
                icon: Icons.delete_outline,
                color: AppColors.red,
                onTap: onDelete!,
              ),
            const SizedBox(width: 8),
          ] else
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.chevron_left,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            decoration: BoxDecoration(
              color: training.statusColor.withOpacity(0.80),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              training.statusLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                training.time.isEmpty ? '—' : training.time,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                training.dateString,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  training.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  training.location.isEmpty ? '—' : training.location,
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
          const SizedBox(width: 10),

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: training.typeColor.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: training.typeColor.withOpacity(0.45),
              ),
            ),
            child: Icon(
              training.typeIcon,
              color: training.typeColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({
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
// ATTENDANCE CARD (ديناميكي من الداتابيز)
// ============================================================
class _AttendanceCard extends StatelessWidget {
  final List<Training> trainings;
  final Map<DateTime, int> attendanceStats;

  const _AttendanceCard({
    required this.trainings,
    required this.attendanceStats,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int totalPlayers = 0;
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        if (user.role == UserRole.admin) {
          // في المستقبل ممكن نجيب كل اللاعبين هنا
        }
      }
    } catch (_) {}

    // إحصائيات الحضور الفعلية
    int totalPresent = 0;
    int totalSessions = 0;
    attendanceStats.forEach((date, count) {
      totalPresent += count;
      totalSessions += 1;
    });

    final pastTrainings = trainings.where((t) {
      final target = DateTime(t.date.year, t.date.month, t.date.day);
      return target.isBefore(today) || target == today;
    }).length;

    final totalTrainings = trainings.length;
    final percentage = totalTrainings == 0
        ? 0.0
        : (pastTrainings / totalTrainings).clamp(0.0, 1.0);

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'حضور اللاعبين',
            textAlign: TextAlign.start,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 105,
                height: 105,
                child: CustomPaint(
                  painter: _ProgressPainter(
                    progress: percentage,
                    color: AppColors.green,
                  ),
                  child: Center(
                    child: Text(
                      '${(percentage * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _AttendanceLine(
                      title: 'حضور مسجل',
                      value: '$totalPresent',
                      color: AppColors.green,
                    ),
                    const SizedBox(height: 10),
                    _AttendanceLine(
                      title: 'جلسات حضور',
                      value: '$totalSessions',
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 10),
                    _AttendanceLine(
                      title: 'إجمالي التدريبات',
                      value: '$totalTrainings',
                      color: Colors.blueGrey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceLine extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _AttendanceLine({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.08);

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      6.283 * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// RESOURCES
// ============================================================
class _ResourcesCard extends StatelessWidget {
  const _ResourcesCard();

  @override
  Widget build(BuildContext context) {
    final resources = <(IconData, String, String, Color)>[];

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'الموارد والتجهيزات',
            textAlign: TextAlign.start,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (resources.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد موارد مسجلة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            )
          else
            Row(
              children: resources.map((r) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _ResourceItem(
                      icon: r.$1,
                      title: r.$2,
                      value: r.$3,
                      color: r.$4,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _ResourceItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COACH NOTES
// ============================================================
class _CoachNotesCard extends StatelessWidget {
  final String notes;
  const _CoachNotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final displayNotes = notes.trim().isEmpty
        ? 'لا توجد ملاحظات من المدرب حاليًا.'
        : notes;

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.assignment_outlined, color: AppColors.green, size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ملاحظات المدرب',
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
          const SizedBox(height: 12),
          Text(
            displayNotes,
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}