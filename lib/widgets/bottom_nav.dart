// lib/widgets/bottom_nav.dart

import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import '../l10n/app_text.dart';
import '../academy_dashboard_screen.dart' show AppColors;
import '../services/auth_service.dart';
import '../models/app_user.dart';

// ============================================================
// BOTTOM NAV — موحّد بس التابات بتتغير حسب الدور
// ============================================================
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // ✅ التابات حسب الدور
  List<_NavItem> get _items {
    final user = AuthService.currentUser;

    if (user == null) {
      // fallback (مش المفروض يحصل)
      return const [
        _NavItem(Icons.home, 'الرئيسية'),
        _NavItem(Icons.groups, 'اللاعبين'),
        _NavItem(Icons.sports_soccer, 'التدريبات'),
        _NavItem(Icons.bar_chart, 'الإحصائيات'),
        _NavItem(Icons.menu, 'المزيد'),
      ];
    }

    switch (user.role) {
      case UserRole.admin:
        // المدير: كل حاجة
        return const [
          _NavItem(Icons.home, 'الرئيسية'),
          _NavItem(Icons.groups, 'اللاعبين'),
          _NavItem(Icons.shield, 'الفرق'),
          _NavItem(Icons.bar_chart, 'الإحصائيات'),
          _NavItem(Icons.menu, 'المزيد'),
        ];

      case UserRole.coach:
        // المدرب: فريقه
        return const [
          _NavItem(Icons.home, 'الرئيسية'),
          _NavItem(Icons.groups, 'فريقي'),
          _NavItem(Icons.sports_soccer, 'التدريبات'),
          _NavItem(Icons.bar_chart, 'الإحصائيات'),
          _NavItem(Icons.menu, 'المزيد'),
        ];

      case UserRole.player:
        // اللاعب: بياناته الشخصية
        return const [
          _NavItem(Icons.home, 'الرئيسية'),
          _NavItem(Icons.sports_soccer, 'مبارياتي'),
          _NavItem(Icons.fitness_center, 'تدريباتي'),
          _NavItem(Icons.bar_chart, 'إحصائياتي'),
          _NavItem(Icons.menu, 'المزيد'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return AppDirectionality(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.75),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final active = i == currentIndex;
                  final color =
                      active ? AppColors.green : AppColors.textSecondary;
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(items[i].icon, color: color, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            items[i].label,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NAV ITEM
// ============================================================
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}