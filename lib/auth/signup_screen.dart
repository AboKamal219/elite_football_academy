// lib/auth/signup_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import '../l10n/app_text.dart';
import '../academy_dashboard_screen.dart'
    show AppColors, AcademyDashboardScreen;
import '../services/auth_service.dart';
import '../utils/validators.dart';
import 'verify_email_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _academyCodeCtrl = TextEditingController();
  final _newAcademyNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _academyCodeFocus = FocusNode();
  final _newAcademyNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isNewAcademy = false;
  String? _error;

  late final AnimationController _entryCtrl;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
    _academyCodeFocus.addListener(() => setState(() {}));
    _newAcademyNameFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));
    _addressFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _shakeCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _academyCodeCtrl.dispose();
    _newAcademyNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    _academyCodeFocus.dispose();
    _newAcademyNameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    final nameError = Validators.name(name);
    if (nameError != null) { _showError(nameError); return; }

    final emailError = Validators.email(email);
    if (emailError != null) { _showError(emailError); return; }

    final phoneError = Validators.phone(_phoneCtrl.text);
    if (phoneError != null) { _showError(phoneError); return; }

    final passError = Validators.password(pass);
    if (passError != null) { _showError(passError); return; }

    final notEmailError = Validators.passwordNotEmail(pass, email);
    if (notEmailError != null) { _showError(notEmailError); return; }

    final notNameError = Validators.passwordNotName(pass, name);
    if (notNameError != null) { _showError(notNameError); return; }

    final confirmError = Validators.confirmPassword(_confirmCtrl.text, pass);
    if (confirmError != null) { _showError(confirmError); return; }

    if (!_isNewAcademy) {
      if (_academyCodeCtrl.text.trim().isEmpty) {
        _showError('كود الأكاديمية مطلوب');
        return;
      }
    } else {
      if (_newAcademyNameCtrl.text.trim().isEmpty) {
        _showError('اسم الأكاديمية مطلوب');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.signup(
      name: name,
      email: email,
      password: pass,
      academyCode: _isNewAcademy ? '' : _academyCodeCtrl.text.trim(),
      newAcademyName: _isNewAcademy ? _newAcademyNameCtrl.text.trim() : '',
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.result == SignupResult.emailVerificationRequired) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email)),
      );
      return;
    }

    if (result.user == null) {
      String errorMsg;
      switch (result.result) {
        case SignupResult.emailAlreadyExists:
          errorMsg = 'الإيميل ده مسجل بالفعل. جرب تسجل دخول.';
          break;
        case SignupResult.invalidAcademyCode:
          errorMsg = 'كود الأكاديمية غلط أو مش تابع لأي أكاديمية.';
          break;
        case SignupResult.academyNameTaken:
          errorMsg = 'فيه أكاديمية بنفس الاسم ده. اختار اسم تاني.';
          break;
        case SignupResult.unknownError:
          errorMsg = 'حصل خطأ. حاول تاني أو اتأكد من النت.';
          break;
        case SignupResult.success:
        case SignupResult.emailVerificationRequired:
          errorMsg = '';
          break;
      }
      _showError(errorMsg);
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
      MaterialPageRoute(
        builder: (_) => const AcademyDashboardScreen(),
      ),
      (route) => false,
    );
  }

  void _showError(String msg) {
    setState(() => _error = msg);
    _shakeCtrl.forward(from: 0);
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
              const _AnimatedBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      _FadeSlideIn(
                        controller: _entryCtrl,
                        delay: 0.0,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _CircleIconButton(
                            icon: Icons.arrow_forward,
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _FadeSlideIn(
                        controller: _entryCtrl,
                        delay: 0.1,
                        child: const _LogoWidget(),
                      ),

                      const SizedBox(height: 24),

                      _FadeSlideIn(
                        controller: _entryCtrl,
                        delay: 0.2,
                        child: const Text(
                          'حساب جديد',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      _FadeSlideIn(
                        controller: _entryCtrl,
                        delay: 0.25,
                        child: const Text(
                          'انضم لأكاديمية النخبة ⚽',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      _FadeSlideIn(
                        controller: _entryCtrl,
                        delay: 0.3,
                        child: AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (context, child) {
                            final dx = _shakeCtrl.isAnimating
                                ? (1 - _shakeAnim.value) *
                                    10 *
                                    (_shakeAnim.value * 10 % 2 == 0
                                        ? 1
                                        : -1)
                                : 0.0;
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: child,
                            );
                          },
                          child: _GlassForm(
                            nameCtrl: _nameCtrl,
                            emailCtrl: _emailCtrl,
                            passCtrl: _passCtrl,
                            confirmCtrl: _confirmCtrl,
                            academyCodeCtrl: _academyCodeCtrl,
                            newAcademyNameCtrl: _newAcademyNameCtrl,
                            phoneCtrl: _phoneCtrl,
                            addressCtrl: _addressCtrl,
                            nameFocus: _nameFocus,
                            emailFocus: _emailFocus,
                            passFocus: _passFocus,
                            confirmFocus: _confirmFocus,
                            academyCodeFocus: _academyCodeFocus,
                            newAcademyNameFocus: _newAcademyNameFocus,
                            phoneFocus: _phoneFocus,
                            addressFocus: _addressFocus,
                            obscurePass: _obscurePass,
                            obscureConfirm: _obscureConfirm,
                            isNewAcademy: _isNewAcademy,
                            loading: _loading,
                            error: _error,
                            onTogglePass: () => setState(
                                () => _obscurePass = !_obscurePass),
                            onToggleConfirm: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            onAcademyModeChanged: (v) => setState(
                                () => _isNewAcademy = v),
                            onSubmit: _signup,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _FadeSlideIn(
                        controller: _entryCtrl,
                        delay: 0.5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'عندك حساب بالفعل؟',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'سجل دخول',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
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
// ANIMATED BACKGROUND
// ============================================================
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF000000),
                Color.lerp(
                  const Color(0xFF0A1428),
                  const Color(0xFF0D2B1F),
                  _ctrl.value,
                )!,
                const Color(0xFF0D1B33),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
                child: _GlowOrb(
                  color: AppColors.green.withOpacity(0.15),
                  size: 300,
                ),
              ),
              Positioned(
                bottom: -120,
                left: -120,
                child: _GlowOrb(
                  color: AppColors.blue.withOpacity(0.1),
                  size: 350,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}

// ============================================================
// LOGO
// ============================================================
class _LogoWidget extends StatelessWidget {
  const _LogoWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.green, AppColors.greenDark],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withOpacity(0.5),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.sports_soccer,
                color: AppColors.green,
                size: 44,
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
  const _CircleIconButton({required this.icon, required this.onTap});

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
              child: Icon(icon, color: AppColors.textPrimary, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GLASS FORM
// ============================================================
class _GlassForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final TextEditingController academyCodeCtrl;
  final TextEditingController newAcademyNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController addressCtrl;
  final FocusNode nameFocus;
  final FocusNode emailFocus;
  final FocusNode passFocus;
  final FocusNode confirmFocus;
  final FocusNode academyCodeFocus;
  final FocusNode newAcademyNameFocus;
  final FocusNode phoneFocus;
  final FocusNode addressFocus;
  final bool obscurePass;
  final bool obscureConfirm;
  final bool isNewAcademy;
  final bool loading;
  final String? error;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;
  final ValueChanged<bool> onAcademyModeChanged;
  final VoidCallback onSubmit;

  const _GlassForm({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.academyCodeCtrl,
    required this.newAcademyNameCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.nameFocus,
    required this.emailFocus,
    required this.passFocus,
    required this.confirmFocus,
    required this.academyCodeFocus,
    required this.newAcademyNameFocus,
    required this.phoneFocus,
    required this.addressFocus,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.isNewAcademy,
    required this.loading,
    required this.error,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onAcademyModeChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
              _GlassField(
                controller: nameCtrl,
                focusNode: nameFocus,
                hint: 'الاسم الكامل',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),

              _GlassField(
                controller: emailCtrl,
                focusNode: emailFocus,
                hint: 'gmail.com@  الإيميل',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              _GlassField(
                controller: phoneCtrl,
                focusNode: phoneFocus,
                hint: 'رقم التليفون (اختياري)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              _GlassField(
                controller: addressCtrl,
                focusNode: addressFocus,
                hint: 'العنوان (اختياري)',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 14),

              _GlassField(
                controller: passCtrl,
                focusNode: passFocus,
                hint: 'الباسورد',
                icon: Icons.lock_outline,
                obscure: obscurePass,
                suffix: IconButton(
                  onPressed: onTogglePass,
                  icon: Icon(
                    obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),

              if (passCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                _PasswordStrength(password: passCtrl.text),
              ],

              const SizedBox(height: 14),

              _GlassField(
                controller: confirmCtrl,
                focusNode: confirmFocus,
                hint: 'تأكيد الباسورد',
                icon: Icons.lock_outline,
                obscure: obscureConfirm,
                suffix: IconButton(
                  onPressed: onToggleConfirm,
                  icon: Icon(
                    obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ============ نوع الأكاديمية ============
              const Text(
                'الأكاديمية',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _AcademyModeCard(
                      label: 'أكاديمية جديدة',
                      subtitle: 'أنت المدير (Admin)',
                      icon: Icons.add_business_rounded,
                      selected: isNewAcademy,
                      color: AppColors.gold,
                      onTap: () => onAcademyModeChanged(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AcademyModeCard(
                      label: 'انضم لأكاديمية',
                      subtitle: 'بكود الدعوة',
                      icon: Icons.login_rounded,
                      selected: !isNewAcademy,
                      color: AppColors.blue,
                      onTap: () => onAcademyModeChanged(false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (isNewAcademy) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.gold,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'أنت هتكون المدير (Admin) لهذه الأكاديمية. مينفعش يكون فيه أكتر من أدمن واحد لنفس الأكاديمية.',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 11,
                            fontFamily: 'Cairo',
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _GlassField(
                  controller: newAcademyNameCtrl,
                  focusNode: newAcademyNameFocus,
                  hint: 'اسم الأكاديمية الجديدة',
                  icon: Icons.business_rounded,
                ),
              ] else ...[
                _GlassField(
                  controller: academyCodeCtrl,
                  focusNode: academyCodeFocus,
                  hint: 'كود الأكاديمية (مدرب أو لاعب)',
                  icon: Icons.qr_code_rounded,
                ),
              ],

              if (error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.red.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error!,
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

              _GradientButton(
                label: isNewAcademy ? 'إنشاء الأكاديمية والحساب' : 'إنشاء الحساب',
                loading: loading,
                onTap: loading ? null : onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GLASS FIELD
// ============================================================
class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  const _GlassField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.green.withOpacity(0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Cairo',
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: L10n.trN(hint),
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontFamily: 'Cairo',
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            color: focused
                ? AppColors.green
                : AppColors.textSecondary,
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
      ),
    );
  }
}

// ============================================================
// PASSWORD STRENGTH
// ============================================================
class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = Validators.passwordStrength(password);
    final label = Validators.passwordLabel(password);

    Color color;
    if (strength < 0.5) {
      color = AppColors.red;
    } else if (strength < 0.8) {
      color = AppColors.orange;
    } else {
      color = AppColors.green;
    }

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 4,
                  color: Colors.white.withOpacity(0.06),
                ),
                FractionallySizedBox(
                  widthFactor: strength.clamp(0.1, 1.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ACADEMY MODE CARD
// ============================================================
class _AcademyModeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _AcademyModeCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.15)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : Colors.white.withOpacity(0.10),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? color.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                ),
                child: Icon(
                  icon,
                  color: selected ? color : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: (selected ? color : AppColors.textSecondary)
                      .withOpacity(0.7),
                  fontSize: 8,
                  fontFamily: 'Cairo',
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
// GRADIENT BUTTON
// ============================================================
class _GradientButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _GradientButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineCtrl;

  @override
  void initState() {
    super.initState();
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
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
                color: AppColors.green.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (!widget.loading)
                AnimatedBuilder(
                  animation: _shineCtrl,
                  builder: (context, _) {
                    return Positioned(
                      left: -100 + (_shineCtrl.value * 500),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0),
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              Center(
                child: widget.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
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
// FADE + SLIDE IN
// ============================================================
class _FadeSlideIn extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;
  const _FadeSlideIn({
    required this.controller,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = delay;
    final end = (delay + 0.4).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}