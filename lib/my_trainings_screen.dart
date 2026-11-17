// lib/my_trainings_screen.dart

import 'package:flutter/material.dart' hide Text;
import 'l10n/app_text.dart';
import 'academy_dashboard_screen.dart'
    show AppColors, AppImages, GlassCard, DeviceType, deviceTypeOf;
import 'widgets/top_header.dart';
import 'models/player.dart';
import 'models/training.dart';
import 'services/auth_service.dart';
import 'services/player_service.dart';
import 'services/training_service.dart';

// ============================================================
// MY TRAININGS SCREEN
// ============================================================

class MyTrainingsScreen extends StatefulWidget {
  const MyTrainingsScreen({super.key});

  @override
  State<MyTrainingsScreen> createState() => _MyTrainingsScreenState();
}

class _MyTrainingsScreenState extends State<MyTrainingsScreen> {
  Player? _player;
  List<Training> _allTrainings = [];
  String _coachNotes = '';
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

    List<Training> trainings = [];
    String notes = '';

    if (me != null && me.teamId.isNotEmpty) {
      trainings = await TrainingService.getByTeam(me.teamId);
      notes = await TrainingService.getLatestCoachNote(me.teamId);
    }

    if (!mounted) return;
    setState(() {
      _player = me;
      _allTrainings = trainings;
      _coachNotes = notes;
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          child: _MyTrainingsBody(
            device: device,
            player: _player,
            trainings: _allTrainings,
            coachNotes: _coachNotes,
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

class _MyTrainingsBody extends StatelessWidget {
  final DeviceType device;
  final Player? player;
  final List<Training> trainings;
  final String coachNotes;
  final bool loading;

  const _MyTrainingsBody({
    required this.device,
    required this.player,
    required this.trainings,
    required this.coachNotes,
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
        const _MyTrainingsHero(),
        const SizedBox(height: 14),
        _MyStatsRow(player: player),
        const SizedBox(height: 18),
        _MainContent(
          isTablet: isTablet,
          trainings: trainings,
          coachNotes: coachNotes,
          loading: loading,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _MyTrainingsHero extends StatelessWidget {
  const _MyTrainingsHero();

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
                        'تدريباتي',
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
                        Icons.fitness_center,
                        color: AppColors.green,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تابع تدريباتك .. وطوّر مستواك',
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
                      'اللاعب الناجح',
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
                      'مش بس موهبة، لكن التزام واستمرارية!',
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
// STATS ROW
// ============================================================

class _MyStatsRow extends StatelessWidget {
  final Player? player;
  const _MyStatsRow({required this.player});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        'مبارياتي',
        '${player?.matches ?? 0}',
        Icons.emoji_events,
        Colors.orange,
      ),
      (
        'أهدافي',
        '${player?.goals ?? 0}',
        Icons.sports_soccer,
        AppColors.green,
      ),
      (
        'صناعتي',
        '${player?.assists ?? 0}',
        Icons.handshake_outlined,
        Colors.purpleAccent,
      ),
      (
        'تقييمي',
        player?.rating ?? '0.0',
        Icons.star,
        Colors.lightBlue,
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
              border: Border.all(
                color: color.withOpacity(0.30),
              ),
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
  final List<Training> trainings;
  final String coachNotes;
  final bool loading;

  const _MainContent({
    required this.isTablet,
    required this.trainings,
    required this.coachNotes,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.green),
        ),
      );
    }

    if (!isTablet) {
      return Column(
        children: [
          const _CalendarSection(),
          const SizedBox(height: 16),
          _UpcomingTrainings(trainings: trainings),
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
              const _CalendarSection(),
              const SizedBox(height: 16),
              _UpcomingTrainings(trainings: trainings),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _CoachNotesCard(notes: coachNotes),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CALENDAR
// ============================================================

class _CalendarSection extends StatelessWidget {
  const _CalendarSection();

  @override
  Widget build(BuildContext context) {
    const days = [
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];

    const numbers = [
      ['30', '31', '1', '2', '3', '4', '5'],
      ['6', '7', '8', '9', '10', '11', '12'],
      ['13', '14', '15', '16', '17', '18', '19'],
      ['20', '21', '22', '23', '24', '25', '26'],
      ['27', '28', '29', '30', '1', '2', '3'],
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
              _CalendarArrow(icon: Icons.chevron_left),
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
                child: const Text(
                  'أبريل   2026',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _CalendarArrow(icon: Icons.chevron_right),
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
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ...List.generate(
                  numbers.length,
                  (rowIndex) {
                    return SizedBox(
                      height: 54,
                      child: Row(
                        children: List.generate(
                          7,
                          (colIndex) {
                            final number = numbers[rowIndex][colIndex];

                            final isSelected =
                                rowIndex == 3 && colIndex == 5;

                            final isMuted =
                                (rowIndex == 0 && colIndex < 2) ||
                                (rowIndex == 4 && colIndex > 3);

                            final hasDot =
                                !isMuted &&
                                (number == '2' ||
                                    number == '6' ||
                                    number == '9' ||
                                    number == '11' ||
                                    number == '14' ||
                                    number == '17' ||
                                    number == '20' ||
                                    number == '24' ||
                                    number == '27' ||
                                    number == '29');

                            return Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.green
                                      : Colors.transparent,
                                  border: Border(
                                    right: BorderSide(
                                      color: Colors.white
                                          .withOpacity(0.05),
                                    ),
                                    bottom: BorderSide(
                                      color: Colors.white
                                          .withOpacity(0.05),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      number,
                                      style: TextStyle(
                                        color: isMuted
                                            ? AppColors.textMuted
                                            : isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (hasDot)
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarArrow extends StatelessWidget {
  final IconData icon;

  const _CalendarArrow({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.green.withOpacity(0.45),
        ),
      ),
      child: Icon(
        icon,
        color: AppColors.textPrimary,
        size: 18,
      ),
    );
  }
}

// ============================================================
// UPCOMING TRAININGS
// ============================================================

class _UpcomingTrainings extends StatefulWidget {
  final List<Training> trainings;
  const _UpcomingTrainings({required this.trainings});

  @override
  State<_UpcomingTrainings> createState() => _UpcomingTrainingsState();
}

class _UpcomingTrainingsState extends State<_UpcomingTrainings> {
  int _filterIndex = 0;
  static const _tabs = ['الكل', 'تدريبات', 'مباريات', 'اجتماعات'];

  List<Training> get _filtered {
    switch (_filterIndex) {
      case 1:
        return widget.trainings
            .where((t) => t.type == TrainingType.training)
            .toList();
      case 2:
        return widget.trainings
            .where((t) => t.type == TrainingType.match)
            .toList();
      case 3:
        return widget.trainings
            .where((t) => t.type == TrainingType.meeting)
            .toList();
      default:
        return widget.trainings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

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
                  'جدول تدريباتي القادم',
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
              children: List.generate(_tabs.length, (i) {
                return _TrainingTab(
                  title: _tabs[i],
                  active: i == _filterIndex,
                  onTap: () => setState(() => _filterIndex = i),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد تدريبات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...list.map(
              (training) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TrainingListItem(training: training),
              ),
            ),
        ],
      ),
    );
  }
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
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
    );
  }
}

class _TrainingListItem extends StatelessWidget {
  final Training training;

  const _TrainingListItem({required this.training});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.green.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.chevron_left,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 5,
            ),
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
                training.time,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                training.dateString,  // ✅ String
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
                  training.location,
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
              color: training.iconColor.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: training.iconColor.withOpacity(0.45),
              ),
            ),
            child: Icon(
              training.icon,
              color: training.iconColor,
              size: 20,
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
              Icon(
                Icons.assignment_outlined,
                color: AppColors.green,
                size: 20,
              ),
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