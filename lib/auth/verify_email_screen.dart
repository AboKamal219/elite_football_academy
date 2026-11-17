// lib/auth/verify_email_screen.dart
//
// NEW — step 2 of sign-up when Supabase "Confirm email" is ON.
// The user types the 6-digit code that Supabase e-mailed (Gmail / any inbox);
// on success the profile is created on the server (RPC complete_signup)
// and the user lands on the dashboard. Layout = clone of ResetPasswordScreen.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import '../l10n/app_text.dart';
import '../academy_dashboard_screen.dart'
    show AppColors, AcademyDashboardScreen;
import '../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  /// true when we arrive from the login screen (code not sent yet in this session)
  final bool sendOnOpen;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.sendOnOpen = false,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();

  bool _loading = false;
  bool _resending = false;
  int _cooldown = 0;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _codeFocus.addListener(() => setState(() {}));
    if (widget.sendOnOpen) {
      _resend();
    } else {
      _startCooldown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _timer?.cancel();
    setState(() => _cooldown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    final ok = await AuthService.resendSignupCode(widget.email);
    if (!mounted) return;
    setState(() => _resending = false);
    if (ok) {
      _startCooldown();
    } else {
      setState(() => _error = 'مقدرناش نبعت الكود. اتأكد من النت وحاول تاني.');
    }
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'الكود لازم يكون 6 أرقام على الأقل');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final r = await AuthService.verifySignupCode(widget.email, code);

    if (!mounted) return;
    setState(() => _loading = false);

    if (r.user == null) {
      setState(() {
        switch (r.error) {
          case 'invalid_code':
            _error = 'الكود غلط أو منتهي. اطلب كود جديد.';
            break;
          case 'academy_name_taken':
            _error = 'فيه أكاديمية بنفس الاسم ده. اختار اسم تاني.';
            break;
          case 'invalid_academy_code':
            _error = 'كود الأكاديمية غلط أو مش تابع لأي أكاديمية.';
            break;
          default:
            _error = 'حصل خطأ. حاول تاني أو اتأكد من النت.';
        }
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم إنشاء الحساب بنجاح ',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AcademyDashboardScreen()),
      (route) => false,
    );
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

              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _CircleIconButton(
                          icon: Icons.arrow_forward,
                          onTap: () => Navigator.pop(context),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.green,
                                AppColors.greenDark,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withOpacity(0.35),
                                blurRadius: 24,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.background,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.green.withOpacity(0.15),
                              ),
                              child: const Icon(
                                Icons.mark_email_read_rounded,
                                color: AppColors.green,
                                size: 42,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'تأكيد الإيميل',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'بعتنا كود التحقق على\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 36),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SimpleField(
                                  controller: _codeCtrl,
                                  focusNode: _codeFocus,
                                  hint: 'الكود (6 أرقام)',
                                  icon: Icons.pin_outlined,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 8,
                                ),


                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.red.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.red.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: AppColors.red,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(
                                              color: AppColors.red,
                                              fontSize: 12,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 18),

                                _SimpleGradientButton(
                                  label: 'تأكيد الإيميل',
                                  loading: _loading,
                                  onTap: _loading ? null : _verify,
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: TextButton(
                                    onPressed: (_cooldown > 0 || _resending)
                                        ? null
                                        : _resend,
                                    child: Text(
                                      _cooldown > 0
                                          ? 'إعادة إرسال الكود ($_cooldown)'
                                          : 'إعادة إرسال الكود',
                                      style: TextStyle(
                                        color: _cooldown > 0
                                            ? AppColors.textMuted
                                            : AppColors.green,
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
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
// SIMPLE GLASS FIELD
// ============================================================
class _SimpleField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final TextAlign textAlign;
  final int? maxLength; // ✅ ضفنا maxLength

  const _SimpleField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.textAlign = TextAlign.start,
    this.maxLength, // ✅ ضفناها في الـ Constructor
  });

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscure,
      textAlign: textAlign,
      maxLength: maxLength, // ✅ تفعيل الـ maxLength
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Cairo',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 4,
      ),
      decoration: InputDecoration(
        counterText: "", // ✅ نخفي العداد اللي تحت
        hintText: L10n.trN(hint),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontFamily: 'Cairo',
          fontSize: 13,
          letterSpacing: 0,
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Icon(
          icon,
          color: focused ? AppColors.green : AppColors.textSecondary,
          size: 20,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.green,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SIMPLE GRADIENT BUTTON
// ============================================================
class _SimpleGradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _SimpleGradientButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppColors.green, AppColors.greenDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CIRCLE ICON BUTTON
// ============================================================
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.06),
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white12),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                icon,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}