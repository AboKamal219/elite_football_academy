import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import '../l10n/app_text.dart';
import '../academy_dashboard_screen.dart' show AppColors;
import '../services/auth_service.dart';
import '../utils/validators.dart'; // ✅ ضفنا الفاليديتورز هنا
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _codeFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _codeFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final code = _codeCtrl.text.trim();
    final pass = _passCtrl.text;

    // ✅ 1. the code e-mailed by Supabase (6 digits by default)
    if (code.length < 6) {
      setState(() => _error = 'الكود لازم يكون 6 أرقام على الأقل');
      return;
    }

    // ✅ 2. التحقق من الباسورد باستخدام Validators
    final passError = Validators.password(pass);
    if (passError != null) {
      setState(() => _error = passError); // هيطلع رسالة الخطأ بتاعة الباسورد
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // استدعاء الدالة الوهمية (Mock)
    final err = await AuthService.resetPasswordWithCode(
      email: widget.email,
      code: code,
      newPassword: pass,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err == null) {
      // نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم تغيير كلمة المرور بنجاح ✅',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // نرجع لشاشة اللوجن
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      // فشل
      setState(() => _error = err == 'same_password'
          ? 'الباسورد الجديد لازم يكون مختلف عن القديم'
          : err == 'weak_password'
              ? 'الباسورد ده ضعيف جدًا، اختار حاجة أقوى'
              : 'الكود غلط أو حصل خطأ، حاول تاني');
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
                                Icons.lock_reset_rounded,
                                color: AppColors.green,
                                size: 42,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'تعيين كلمة مرور جديدة',
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
                        'تم إرسال الكود إلى\n${widget.email}',
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

                                const SizedBox(height: 14),

                                _SimpleField(
                                  controller: _passCtrl,
                                  focusNode: _passFocus,
                                  hint: 'كلمة المرور الجديدة',
                                  icon: Icons.lock_outline,
                                  obscure: _obscure,
                                  suffix: IconButton(
                                    onPressed: () => setState(
                                        () => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                  ),
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
                                  label: 'حفظ كلمة المرور',
                                  loading: _loading,
                                  onTap: _loading ? null : _resetPassword,
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