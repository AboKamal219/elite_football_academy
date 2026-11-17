// lib/my_reports_screen.dart

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
import 'models/player.dart';
import 'services/auth_service.dart';
import 'services/player_service.dart';

// ============================================================
// MY REPORTS SCREEN — تقرير اللاعب الشامل
// ============================================================

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  Player? _player;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    final user = AuthService.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final me = await PlayerService.getPlayerByUserId(user.id);

    if (!mounted) return;
    setState(() {
      _player = me;
      _loading = false;
    });
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
                    : LayoutBuilder(
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16)
                                        .copyWith(top: 20, bottom: 32),
                                child: _MyReportsBody(
                                  device: device,
                                  player: _player,
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
class _MyReportsBody extends StatelessWidget {
  final DeviceType device;
  final Player? player;

  const _MyReportsBody({
    required this.device,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = device == DeviceType.tablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(playerName: player?.name ?? ''),
        const SizedBox(height: 14),
        _MyReportsHero(player: player),
        const SizedBox(height: 18),
        _KpiRow(player: player),
        const SizedBox(height: 18),
        if (isTablet)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _PerformanceChartCard(player: player),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: _SkillsCard(player: player),
                ),
              ],
            ),
          )
        else ...[
          _PerformanceChartCard(player: player),
          const SizedBox(height: 16),
          _SkillsCard(player: player),
        ],
        const SizedBox(height: 18),
        _AchievementsCard(player: player),
        const SizedBox(height: 18),
        _SummaryCard(player: player),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ============================================================
// TOP BAR
// ============================================================
class _TopBar extends StatelessWidget {
  final String playerName;
  const _TopBar({required this.playerName});

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
                'تقريري',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'تقرير شامل لأدائي',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
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
// HERO
// ============================================================
class _MyReportsHero extends StatelessWidget {
  final Player? player;
  const _MyReportsHero({required this.player});

  @override
  Widget build(BuildContext context) {
    final name = player?.name ?? 'لاعب';
    final rating = player?.rating ?? '0.0';

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
                      AppColors.purple.withOpacity(0.35),
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
                          'تقريري',
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
                    'ملخص شامل لأدائي في الملعب',
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
                    icon: Icons.star_rounded,
                    value: rating,
                    label: 'تقييمي',
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  _HeroStat(
                    icon: Icons.sports_soccer_rounded,
                    value: '${player?.goals ?? 0}',
                    label: 'أهدافي',
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 8),
                  _HeroStat(
                    icon: Icons.calendar_month_rounded,
                    value: '${player?.matches ?? 0}',
                    label: 'مبارياتي',
                    color: AppColors.blue,
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
// KPI ROW
// ============================================================
class _KpiRow extends StatelessWidget {
  final Player? player;
  const _KpiRow({required this.player});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'أهداف',
        '${player?.goals ?? 0}',
        Icons.sports_soccer_rounded,
        AppColors.green,
      ),
      (
        'صناعة',
        '${player?.assists ?? 0}',
        Icons.handshake_outlined,
        AppColors.blue,
      ),
      (
        'مباريات',
        '${player?.matches ?? 0}',
        Icons.calendar_month_rounded,
        AppColors.purple,
      ),
      (
        'بطاقات',
        '${(player?.yellowCards ?? 0) + (player?.redCards ?? 0)}',
        Icons.sports_score_rounded,
        AppColors.gold,
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(
            child: _KpiCard(
              title: items[i].$1,
              value: items[i].$2,
              icon: items[i].$3,
              color: items[i].$4,
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(
                color: color.withOpacity(0.4),
              ),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PERFORMANCE CHART
// ============================================================
class _PerformanceChartCard extends StatelessWidget {
  final Player? player;
  const _PerformanceChartCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final base = double.tryParse(player?.rating ?? '7.0') ?? 7.0;
    final values = [
      (base - 1.2).clamp(5.0, 10.0),
      (base - 0.9).clamp(5.0, 10.0),
      (base - 0.6).clamp(5.0, 10.0),
      (base - 0.3).clamp(5.0, 10.0),
      (base - 0.5).clamp(5.0, 10.0),
      (base - 0.2).clamp(5.0, 10.0),
      (base + 0.2).clamp(5.0, 10.0),
      (base - 0.1).clamp(5.0, 10.0),
      (base + 0.1).clamp(5.0, 10.0),
      (base + 0.4).clamp(5.0, 10.0),
      (base + 0.6).clamp(5.0, 10.0),
      (base + 0.8).clamp(5.0, 10.0),
      base.clamp(5.0, 10.0),
    ];

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
          SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _LineChartPainter(
                values: values,
                lastLabel: base.toStringAsFixed(1),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final String lastLabel;

  _LineChartPainter({
    required this.values,
    required this.lastLabel,
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
// SKILLS CARD
// ============================================================
class _SkillsCard extends StatelessWidget {
  final Player? player;
  const _SkillsCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final skills = _skillsForPosition(player?.position ?? '');

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(
                Icons.bolt,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (skills.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد بيانات مهارات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            )
          else
            for (int i = 0; i < skills.length; i++) ...[
              _SkillBar(
                label: skills[i].$1,
                value: skills[i].$2,
                color: skills[i].$3,
              ),
              if (i != skills.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  List<(String, double, Color)> _skillsForPosition(String position) {
    switch (position) {
      case 'مهاجم':
        return [
          ('السرعة', 0.92, AppColors.green),
          ('التسديد', 0.88, AppColors.orange),
          ('التمرير', 0.80, AppColors.blue),
          ('المراوغة', 0.85, AppColors.purple),
          ('اللياقة', 0.90, AppColors.gold),
        ];
      case 'وسط ميدان':
        return [
          ('التمرير', 0.90, AppColors.green),
          ('الرؤية', 0.88, AppColors.orange),
          ('اللياقة', 0.85, AppColors.blue),
          ('المراوغة', 0.78, AppColors.purple),
          ('التسديد', 0.70, AppColors.gold),
        ];
      case 'مدافع':
        return [
          ('الدفاع', 0.92, AppColors.green),
          ('الالتحام', 0.85, AppColors.orange),
          ('التمرير', 0.75, AppColors.blue),
          ('السرعة', 0.70, AppColors.purple),
          ('اللياقة', 0.88, AppColors.gold),
        ];
      case 'حارس مرمى':
        return [
          ('التصديات', 0.93, AppColors.green),
          ('الخروج', 0.85, AppColors.orange),
          ('التمرير', 0.78, AppColors.blue),
          ('الردة', 0.82, AppColors.purple),
          ('اللياقة', 0.86, AppColors.gold),
        ];
      default:
        return [
          ('السرعة', 0.75, AppColors.green),
          ('التسديد', 0.70, AppColors.orange),
          ('التمرير', 0.72, AppColors.blue),
          ('المراوغة', 0.68, AppColors.purple),
          ('اللياقة', 0.74, AppColors.gold),
        ];
    }
  }
}

class _SkillBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _SkillBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: color,
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
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.7),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
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
// ACHIEVEMENTS
// ============================================================
class _AchievementsCard extends StatelessWidget {
  final Player? player;
  const _AchievementsCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final achievements = _buildAchievements();

    if (achievements.isEmpty) return const SizedBox();

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
                color: AppColors.gold,
                size: 20,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'إنجازاتي',
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
          const SizedBox(height: 14),
          for (int i = 0; i < achievements.length; i++) ...[
            _AchievementRow(
              icon: achievements[i].$1,
              title: achievements[i].$2,
              subtitle: achievements[i].$3,
              color: achievements[i].$4,
            ),
            if (i != achievements.length - 1)
              Divider(
                color: Colors.white.withOpacity(0.05),
                height: 16,
              ),
          ],
        ],
      ),
    );
  }

  List<(IconData, String, String, Color)> _buildAchievements() {
    final p = player;
    if (p == null) return [];

    final list = <(IconData, String, String, Color)>[];

    if (p.goals >= 10) {
      list.add((
        Icons.emoji_events,
        'هدّاف الأكاديمية',
        '${p.goals} هدف',
        AppColors.gold,
      ));
    }

    final rating = double.tryParse(p.rating) ?? 0.0;
    if (rating >= 9.0) {
      list.add((
        Icons.star,
        'أفضل لاعب',
        'تقييم ${p.rating}',
        AppColors.orange,
      ));
    }

    if (p.assists >= 5) {
      list.add((
        Icons.trending_up,
        'صنّاع الأهداف',
        '${p.assists} صناعة',
        AppColors.green,
      ));
    }

    if (p.matches >= 10) {
      list.add((
        Icons.calendar_month,
        'لاعب منتظم',
        '${p.matches} مباراة',
        AppColors.blue,
      ));
    }

    return list;
  }
}

class _AchievementRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AchievementRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(
              color: color.withOpacity(0.5),
            ),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.verified_rounded,
          color: color,
          size: 18,
        ),
      ],
    );
  }
}

// ============================================================
// SUMMARY
// ============================================================
class _SummaryCard extends StatelessWidget {
  final Player? player;
  const _SummaryCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final p = player;
    final rating = double.tryParse(p?.rating ?? '0') ?? 0.0;
    final attendanceRate = (p?.matches ?? 0) > 0
        ? ((p!.matches / (p.matches + 2)) * 100).clamp(0, 100).round()
        : 0;

    final items = [
      (
        'تقييمي الحالي',
        p?.rating ?? '0.0',
        AppColors.gold,
      ),
      (
        'نسبة حضوري',
        '$attendanceRate%',
        AppColors.blue,
      ),
      (
        'معدل الأداء',
        '${((rating / 10) * 100).round()}%',
        AppColors.green,
      ),
    ];

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(
                Icons.local_fire_department,
                color: AppColors.orange,
                size: 20,
              ),
              SizedBox(width: 6),
              Text(
                'ملخص سريع',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < items.length; i++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  items[i].$2,
                  style: TextStyle(
                    color: items[i].$3,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    items[i].$1,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            if (i != items.length - 1)
              Divider(
                color: Colors.white.withOpacity(0.08),
                height: 18,
              ),
          ],
          const SizedBox(height: 8),
          const Text(
            '"الالتزام اليوم يصنع الأبطال غداً"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}