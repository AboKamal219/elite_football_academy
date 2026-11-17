// lib/player_qr_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import 'l10n/app_text.dart';
import 'academy_dashboard_screen.dart'
    show AppColors, AppImages, NetImage, DeviceType, deviceTypeOf;
import 'models/player.dart';
import 'widgets/signed_player_qr.dart';

// ============================================================
// PLAYER QR SCREEN
// ============================================================
class PlayerQrScreen extends StatelessWidget {
  final Player player;

  const PlayerQrScreen({super.key, required this.player});

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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final device = deviceTypeOf(constraints.maxWidth);
                    final maxWidth = device == DeviceType.tablet
                        ? 560.0
                        : constraints.maxWidth;

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20)
                              .copyWith(top: 20, bottom: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _TopBar(),
                              const SizedBox(height: 18),
                              _PlayerHeader(player: player),
                              const SizedBox(height: 22),
                              _QrCard(player: player),
                              const SizedBox(height: 18),
                              _InfoCard(player: player),
                              const SizedBox(height: 22),
                              const _HintFooter(),
                            ],
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
                'كود اللاعب',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'امسح الكود لتسجيل الحضور',
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
// PLAYER HEADER
// ============================================================
class _PlayerHeader extends StatelessWidget {
  final Player player;
  const _PlayerHeader({required this.player});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // الصورة
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.green, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withOpacity(0.35),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: ClipOval(
            child: NetImage(
              url: player.photo,
              fallbackIcon: Icons.person,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          player.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.green.withOpacity(0.5),
            ),
          ),
          child: Text(
            player.position,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// QR CARD
// ============================================================
class _QrCard extends StatelessWidget {
  final Player player;
  const _QrCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.green.withOpacity(0.15),
                Colors.white.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.green.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withOpacity(0.15),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // الخلفية البيضاء للـ QR (ضروري عشان يمسك صح)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                // ✅ QR موقّع من السيرفر (صالح 10 دقايق ويتجدد تلقائياً)
                child: SignedPlayerQr(playerId: player.id, size: 220),
              ),
              const SizedBox(height: 16),
              // ID تحت الـ QR
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_2_rounded,
                      color: AppColors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      player.id,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
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

// ============================================================
// INFO CARD
// ============================================================
class _InfoCard extends StatelessWidget {
  final Player player;
  const _InfoCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
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
              _InfoRow(
                icon: Icons.sports_soccer_rounded,
                label: 'الفريق',
                value: player.teamName.isEmpty
                    ? 'بدون فريق'
                    : player.teamName,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.badge_rounded,
                label: 'المركز',
                value: player.position,
              ),
              const SizedBox(height: 10),
              // ✅ تعديل: age بقى String → منعرضش "سنة" لو القيمة "—"
              _InfoRow(
                icon: Icons.cake_rounded,
                label: 'العمر',
                value: (player.age.isEmpty || player.age == '—')
                    ? '—'
                    : '${player.age} سنة',
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.flag_rounded,
                label: 'الجنسية',
                value: (player.nationality.isEmpty ||
                        player.nationality == '—')
                    ? '—'
                    : player.nationality,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.green.withOpacity(0.12),
            border: Border.all(
              color: AppColors.green.withOpacity(0.4),
            ),
          ),
          child: Icon(icon, color: AppColors.green, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// HINT FOOTER
// ============================================================
class _HintFooter extends StatelessWidget {
  const _HintFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.orange.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orange.withOpacity(0.18),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.orange,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'خلي الكوتش يمسح الكود ده عشان يسجّل حضورك',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}