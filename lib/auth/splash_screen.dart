import 'package:flutter/material.dart' hide Text;
import '../l10n/app_text.dart';
import '../academy_dashboard_screen.dart' show AppColors, AcademyDashboardScreen;
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    // استنى ثانيتين (عشان اللوجو يبان)
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      AuthService.loadUserFromStorage(), //  اقرأ من الذاكرة
    ]);

    //  FIX: الـ flag المحلي لوحده مش كفاية — لو جلسة Supabase انتهت
    // كانت كل الطلبات بتفشل بصمت والتطبيق بيعرض بيانات فاضية.
    if (AuthService.currentUser != null &&
        SupabaseService.isInitialized &&
        SupabaseService.authUser == null) {
      await AuthService.logout();
    }

    if (!mounted) return;

    //  لو فيه مستخدم محفوظ → Dashboard
    // لو لأ → Login
    if (AuthService.currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AcademyDashboardScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDirectionality(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Container(
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
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.green, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.sports_soccer,
                          color: AppColors.green,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Elite Football Academy',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Developing Future Champions',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 50),
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppColors.green,
                      strokeWidth: 3,
                    ),
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