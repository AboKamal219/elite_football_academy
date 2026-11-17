// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'academy_dashboard_screen.dart' show AppColors;
import 'auth/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'routes.dart';
import 'app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  AuthService.init(); // ✅ اربط الـ resolver بـ SupabaseService
  await AppSettings.instance.load(); // ✅ حمّل الإعدادات قبل التشغيل
  runApp(const AcademyApp());
}

class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'أكاديمية النخبة',

          // ✅ اللغة الحالية
          locale: s.currentLocale,
          supportedLocales: const [
            Locale('ar', 'EG'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ✅ الوضع الحالي (فاتح/غامق)
          themeMode: s.currentThemeMode,

          // ✅ الوضع الفاتح
          theme: ThemeData(
            fontFamily: 'Cairo',
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
            colorScheme: ColorScheme.light(
              primary: AppColors.green,
              secondary: AppColors.blue,
              surface: Colors.white,
              error: AppColors.red,
            ),
            snackBarTheme: const SnackBarThemeData(
              contentTextStyle:
                  TextStyle(fontFamily: 'Cairo', fontSize: 14),
              behavior: SnackBarBehavior.floating,
            ),
          ),

          // ✅ الوضع الغامق
          darkTheme: ThemeData(
            fontFamily: 'Cairo',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.dark(
              primary: AppColors.green,
              secondary: AppColors.blue,
              surface: AppColors.surface,
              error: AppColors.red,
            ),
            snackBarTheme: const SnackBarThemeData(
              contentTextStyle:
                  TextStyle(fontFamily: 'Cairo', fontSize: 14),
              behavior: SnackBarBehavior.floating,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
              titleTextStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              contentTextStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: AppColors.surface,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontFamily: 'Cairo'),
              displayMedium: TextStyle(fontFamily: 'Cairo'),
              displaySmall: TextStyle(fontFamily: 'Cairo'),
              headlineLarge: TextStyle(fontFamily: 'Cairo'),
              headlineMedium: TextStyle(fontFamily: 'Cairo'),
              headlineSmall: TextStyle(fontFamily: 'Cairo'),
              titleLarge: TextStyle(fontFamily: 'Cairo'),
              titleMedium: TextStyle(fontFamily: 'Cairo'),
              titleSmall: TextStyle(fontFamily: 'Cairo'),
              bodyLarge: TextStyle(fontFamily: 'Cairo'),
              bodyMedium: TextStyle(fontFamily: 'Cairo'),
              bodySmall: TextStyle(fontFamily: 'Cairo'),
              labelLarge: TextStyle(fontFamily: 'Cairo'),
              labelMedium: TextStyle(fontFamily: 'Cairo'),
              labelSmall: TextStyle(fontFamily: 'Cairo'),
            ),
          ),

          // ✅ FIX: إعداد "حجم الخط" كان بيتحفظ بس ومفيش أي شاشة بتطبّقه.
          // الافتراضي (متوسط = 1.0) مش بيغيّر شكل التطبيق إطلاقاً.
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler:
                    TextScaler.linear(mq.textScaler.scale(1.0) * s.fontScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },

          home: const SplashScreen(),
          routes: AppRoutes.routes,
        );
      },
    );
  }
}