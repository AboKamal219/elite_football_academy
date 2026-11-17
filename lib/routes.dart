// lib/routes.dart

import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'players_list_screen.dart';
import 'teams_screen.dart';
import 'statistics_screen.dart';
import 'more_screen.dart';
import 'academy_dashboard_screen.dart' show AppColors;

class AppRoutes {
  // ✅ أسماء الـ Routes
  static const String login = '/login';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String players = '/players';
  static const String teams = '/teams';
  static const String statistics = '/statistics';
  static const String more = '/more';

  // ✅ خريطة الـ Routes
  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        profile: (context) => const ProfileScreen(),
        settings: (context) => const SettingsScreen(),
        notifications: (context) => const NotificationsScreen(),
        players: (context) => const PlayersListScreen(),
        teams: (context) => const TeamsScreen(),
        statistics: (context) => const _Safe(StatisticsScreen()),
        more: (context) => const _Safe(MoreScreen()),
      };
}

/// Standalone pages opened by route name: keep them below the status bar.
class _Safe extends StatelessWidget {
  final Widget child;
  const _Safe(this.child);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(bottom: false, child: child),
      );
}
