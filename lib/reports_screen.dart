// lib/reports_screen.dart

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
import 'models/report.dart';
import 'services/auth_service.dart';
import 'services/report_service.dart';

// ============================================================
// REPORTS SCREEN
// ============================================================

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _filterIndex = 0;

  List<Report> _reports = [];
  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final reports = await ReportService.getSorted();
    final stats = await ReportService.getStats();

    if (!mounted) return;
    setState(() {
      _reports = reports;
      _stats = stats;
      _loading = false;
    });
  }

  // ============================================================
  // ✅ إضافة تقرير جديد
  // ============================================================
  Future<void> _addReport() async {
    final saved = await _ReportFormDialog.show(context);
    if (saved == true && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تمت إضافة التقرير ✅',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Report> get _filteredReports {
    switch (_filterIndex) {
      case 1:
        return _reports
            .where((r) => r.category == ReportCategory.performance)
            .toList();
      case 2:
        return _reports
            .where((r) => r.category == ReportCategory.attendance)
            .toList();
      case 3:
        return _reports
            .where((r) => r.category == ReportCategory.financial)
            .toList();
      default:
        return _reports;
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
                        child: _ReportsBody(
                          filterIndex: _filterIndex,
                          onFilterChanged: (i) =>
                              setState(() => _filterIndex = i),
                          reports: _filteredReports,
                          stats: _stats,
                          onAddReport: _addReport,
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
class _ReportsBody extends StatelessWidget {
  final int filterIndex;
  final ValueChanged<int> onFilterChanged;
  final List<Report> reports;
  final Map<String, int> stats;
  final VoidCallback onAddReport;

  const _ReportsBody({
    required this.filterIndex,
    required this.onFilterChanged,
    required this.reports,
    required this.stats,
    required this.onAddReport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(onAddReport: onAddReport),
        const SizedBox(height: 14),

        _ReportsHero(stats: stats),
        const SizedBox(height: 18),

        _QuickStats(stats: stats),
        const SizedBox(height: 18),

        const _SectionTitle(
          title: 'جميع التقارير',
          icon: Icons.description_rounded,
          color: AppColors.purple,
        ),
        const SizedBox(height: 12),

        _FilterTabs(
          currentIndex: filterIndex,
          onChanged: onFilterChanged,
        ),
        const SizedBox(height: 14),

        _ReportsList(reports: reports),
      ],
    );
  }
}

// ============================================================
// TOP BAR
// ============================================================
class _TopBar extends StatelessWidget {
  final VoidCallback onAddReport;

  const _TopBar({required this.onAddReport});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final canAdd =
        user?.role == UserRole.admin || user?.role == UserRole.coach;

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

        const Spacer(),

        const Text(
          'التقارير',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        const Spacer(),

        if (canAdd) ...[
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: AppColors.green.withOpacity(0.20),
                shape: CircleBorder(
                  side: BorderSide(
                    color: AppColors.green.withOpacity(0.6),
                  ),
                ),
                child: InkWell(
                  onTap: onAddReport,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.add_rounded,
                      color: AppColors.green,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: AppColors.green.withOpacity(0.15),
              shape: CircleBorder(
                side: BorderSide(
                  color: AppColors.green.withOpacity(0.4),
                ),
              ),
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'قريبًا: تصدير التقارير',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      backgroundColor: AppColors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.ios_share_rounded,
                    color: AppColors.green,
                    size: 18,
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
class _ReportsHero extends StatelessWidget {
  final Map<String, int> stats;
  const _ReportsHero({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats['total'] ?? 0;
    final thisMonth = stats['thisMonth'] ?? 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 200,
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
                    AppColors.purple.withOpacity(0.35),
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
                      AppColors.purple.withOpacity(0.4),
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
                          'التقارير',
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
                          color: AppColors.purple.withOpacity(0.25),
                          border: Border.all(
                            color: AppColors.purple.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: AppColors.purple,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تقارير الأداء والإحصائيات',
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
                    icon: Icons.description_rounded,
                    value: '$total',
                    label: 'تقرير',
                    color: AppColors.purple,
                  ),
                  const SizedBox(width: 8),
                  _HeroStat(
                    icon: Icons.calendar_month_rounded,
                    value: '$thisMonth',
                    label: 'هذا الشهر',
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 8),
                  // ⚠️ التقييم العام للتقارير — محتاج جدول ratings
                  const _HeroStat(
                    icon: Icons.star_rounded,
                    value: '0.0',
                    label: 'التقييم',
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
// QUICK STATS
// ============================================================
class _QuickStats extends StatelessWidget {
  final Map<String, int> stats;
  const _QuickStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final performance = stats['performance'] ?? 0;
    final attendance = stats['attendance'] ?? 0;
    final financial = stats['financial'] ?? 0;
    final total = stats['total'] ?? 0;

    final avg = total > 0
        ? ((performance + attendance + financial) / total * 100).round()
        : 0;

    final items = [
      (Icons.trending_up_rounded, '$performance', 'تقارير أداء', AppColors.purple),
      (Icons.fact_check_rounded, '$attendance', 'تقارير حضور', AppColors.blue),
      (Icons.attach_money_rounded, '$financial', 'تقارير مالية', AppColors.orange),
      (Icons.bar_chart_rounded, '$avg%', 'التغطية', AppColors.green),
    ];

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(
            child: _StatCard(
              icon: items[i].$1,
              value: items[i].$2,
              label: items[i].$3,
              color: items[i].$4,
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  border: Border.all(
                    color: color.withOpacity(0.5),
                  ),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    height: 1.0,
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
    ('أداء', Icons.trending_up_rounded, AppColors.purple),
    ('حضور', Icons.fact_check_rounded, AppColors.blue),
    ('مالي', Icons.attach_money_rounded, AppColors.orange),
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
// REPORTS LIST
// ============================================================
class _ReportsList extends StatelessWidget {
  final List<Report> reports;

  const _ReportsList({required this.reports});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        alignment: Alignment.center,
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
                Icons.folder_off_rounded,
                color: AppColors.textSecondary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد تقارير',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'لم يتم إنشاء أي تقارير في هذه الفئة',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < reports.length; i++) ...[
          _ReportCard(report: reports[i]),
          if (i != reports.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    // ✅ نستخدم الحجم والنوع من الداتابيز لو موجودين، وإلا نعرض —
    final sizeText = report.size.isEmpty ? '—' : report.size;
    final typeText = report.type.isEmpty ? '—' : report.type;

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
                report.color.withOpacity(0.10),
                Colors.white.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: report.color.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: report.color.withOpacity(0.15),
                        border: Border.all(
                          color: report.color.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        report.icon,
                        color: report.color,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            report.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _InfoChip(
                                icon: Icons.calendar_today_rounded,
                                text: report.date,
                              ),
                              const SizedBox(width: 8),
                              _InfoChip(
                                icon: Icons.storage_rounded,
                                text: sizeText,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: report.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  typeText,
                                  style: TextStyle(
                                    color: report.color,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
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
                      child: _ActionButton(
                        icon: Icons.download_rounded,
                        label: 'تحميل',
                        color: report.color,
                        onTap: () => _showSnack(context, 'قريبًا: تحميل التقرير'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.ios_share_rounded,
                        label: 'مشاركة',
                        color: AppColors.green,
                        onTap: () => _showSnack(context, 'قريبًا: مشاركة التقرير'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.visibility_rounded,
                      label: '',
                      color: AppColors.blue,
                      isIconOnly: true,
                      onTap: () => _showSnack(context, 'قريبًا: عرض التقرير'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 10),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isIconOnly;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isIconOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 9,
            horizontal: isIconOnly ? 12 : 10,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: isIconOnly ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(icon, color: color, size: 14),
              if (!isIconOnly) ...[
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REPORT FORM DIALOG
// ============================================================
class _ReportFormDialog extends StatefulWidget {
  const _ReportFormDialog();

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ReportFormDialog(),
    );
  }

  @override
  State<_ReportFormDialog> createState() => _ReportFormDialogState();
}

class _ReportFormDialogState extends State<_ReportFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;

  ReportCategory _category = ReportCategory.performance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _subtitleCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('مفيش مستخدم مسجل');

      final id = 'report_${const Uuid().v4().substring(0, 8)}';
      final now = DateTime.now();
      final y = now.year.toString().padLeft(4, '0');
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      final dateStr = '$y/$m/$d';

      final report = Report(
        id: id,
        title: _titleCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim(),
        date: dateStr,
        // ⚠️ الحجم والنوع مش هيتبعتوا، لأنهم لسه من غير رفع ملف حقيقي
        size: '',
        type: '',
        category: _category,
        academyId: user.academyId,
      );

      await ReportService.addReport(report);

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
                  color: AppColors.purple.withOpacity(0.5),
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
                      _Header(onClose: () => Navigator.pop(context)),
                      const Divider(color: Colors.white12, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(
                              icon: Icons.title_rounded,
                              text: 'عنوان التقرير *',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _titleCtrl,
                              hint: 'مثال: تقرير أداء الفريق',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'لازم تكتب عنوان';
                                }
                                if (v.trim().length < 2) {
                                  return 'العنوان قصير جدًا';
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
                              hint: 'مثال: تحليل شامل لأداء الفريق',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.category_rounded,
                              text: 'الفئة *',
                            ),
                            const SizedBox(height: 6),
                            _CategoryPicker(
                              value: _category,
                              onChanged: (v) =>
                                  setState(() => _category = v),
                            ),
                            const SizedBox(height: 22),

                            _Buttons(
                              saving: _saving,
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
// HEADER
// ============================================================
class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

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
              color: AppColors.purple.withOpacity(0.15),
              border: Border.all(color: AppColors.purple),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إضافة تقرير جديد',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'املأ بيانات التقرير',
                  style: TextStyle(
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

// ============================================================
// FIELD LABEL
// ============================================================
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

// ============================================================
// TEXT FIELD
// ============================================================
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

// ============================================================
// CATEGORY PICKER
// ============================================================
class _CategoryPicker extends StatelessWidget {
  final ReportCategory value;
  final ValueChanged<ReportCategory> onChanged;

  const _CategoryPicker({
    required this.value,
    required this.onChanged,
  });

  static const _options = [
    (ReportCategory.performance, 'أداء', Icons.trending_up_rounded, AppColors.purple),
    (ReportCategory.attendance, 'حضور', Icons.fact_check_rounded, AppColors.blue),
    (ReportCategory.financial, 'مالي', Icons.attach_money_rounded, AppColors.orange),
    (ReportCategory.other, 'أخرى', Icons.description_rounded, AppColors.gray),
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
                        ? opt.$4.withOpacity(0.15)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? opt.$4
                          : Colors.white.withOpacity(0.10),
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        opt.$3,
                        color: active
                            ? opt.$4
                            : AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opt.$2,
                        style: TextStyle(
                          color: active
                              ? opt.$4
                              : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w600,
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

// ============================================================
// BUTTONS
// ============================================================
class _Buttons extends StatelessWidget {
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _Buttons({
    required this.saving,
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
                        : [AppColors.purple, AppColors.purple.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: saving
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.purple.withOpacity(0.4),
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'حفظ التقرير',
                              style: TextStyle(
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