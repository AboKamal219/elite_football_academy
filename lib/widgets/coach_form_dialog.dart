// lib/widgets/coach_form_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import '../l10n/app_text.dart';
import 'package:uuid/uuid.dart';
import '../academy_dashboard_screen.dart' show AppColors, NetImage;
import '../models/coach.dart';
import '../services/auth_service.dart';
import '../services/coach_service.dart';

// ============================================================
// COACH FORM DIALOG
// ============================================================
class CoachFormDialog extends StatefulWidget {
  final Coach? coach;

  const CoachFormDialog({super.key, this.coach});

  static Future<bool?> show(BuildContext context, {Coach? coach}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CoachFormDialog(coach: coach),
    );
  }

  @override
  State<CoachFormDialog> createState() => _CoachFormDialogState();
}

class _CoachFormDialogState extends State<CoachFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _yearsCtrl;
  late final TextEditingController _photoCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  String _specialty = CoachSpecialties.headCoach;
  String _category = CoachCategories.technical;

  bool _saving = false;

  bool get _isEdit => widget.coach != null;

  @override
  void initState() {
    super.initState();
    final c = widget.coach;

    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _yearsCtrl = TextEditingController(
      text: (c?.years ?? 0) == 0 ? '' : '${c!.years}',
    );
    _photoCtrl = TextEditingController(text: c?.photo ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');

    if (c != null && CoachSpecialties.all.contains(c.specialty)) {
      _specialty = c.specialty;
    }
    if (c != null && CoachCategories.all.contains(c.category)) {
      _category = c.category;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _yearsCtrl.dispose();
    _photoCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('مفيش مستخدم مسجل');

      final id = _isEdit
          ? widget.coach!.id
          : 'coach_${const Uuid().v4().substring(0, 8)}';

      final coach = Coach(
        id: id,
        name: _nameCtrl.text.trim(),
        specialty: _specialty,
        category: _category,
        years: int.tryParse(_yearsCtrl.text.trim()) ?? 0,
        photo: _photoCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        academyId: widget.coach?.academyId ?? user.academyId ?? '',
      );

      if (_isEdit) {
        await CoachService.updateCoach(coach);
      } else {
        await CoachService.addCoach(coach);
      }

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
                      _Header(
                        isEdit: _isEdit,
                        onClose: () => Navigator.pop(context),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AvatarPreview(photoUrl: _photoCtrl.text),
                            const SizedBox(height: 18),

                            _FieldLabel(
                              icon: Icons.person_rounded,
                              text: 'اسم المدرب *',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _nameCtrl,
                              hint: 'مثال: كابتن أحمد',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'لازم تكتب اسم المدرب';
                                }
                                if (v.trim().length < 2) {
                                  return 'الاسم قصير جدًا';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.workspace_premium_rounded,
                              text: 'التخصص *',
                            ),
                            const SizedBox(height: 6),
                            _Dropdown<String>(
                              value: _specialty,
                              items: CoachSpecialties.all
                                  .map((s) => (value: s, label: s))
                                  .toList(),
                              icon: Icons.workspace_premium_rounded,
                              color: AppColors.purple,
                              onChanged: (v) => setState(() => _specialty = v),
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.category_rounded,
                              text: 'الفئة *',
                            ),
                            const SizedBox(height: 6),
                            _CategoryPicker(
                              value: _category,
                              onChanged: (v) => setState(() => _category = v),
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.calendar_today_rounded,
                              text: 'سنوات الخبرة',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _yearsCtrl,
                              hint: 'مثال: 10',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.image_rounded,
                              text: 'رابط الصورة',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _photoCtrl,
                              hint: 'https://...',
                              keyboardType: TextInputType.url,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.phone_rounded,
                              text: 'رقم الهاتف',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _phoneCtrl,
                              hint: '+20 100 000 0000',
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.email_rounded,
                              text: 'البريد الإلكتروني',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _emailCtrl,
                              hint: 'coach@elite.com',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 22),

                            _Buttons(
                              isEdit: _isEdit,
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
  final bool isEdit;
  final VoidCallback onClose;
  const _Header({required this.isEdit, required this.onClose});

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
            child: Icon(
              isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
              color: AppColors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'تعديل بيانات المدرب' : 'إضافة مدرب جديد',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEdit
                      ? 'عدّل البيانات واضغط حفظ'
                      : 'املأ بيانات المدرب الجديد',
                  style: const TextStyle(
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
// AVATAR PREVIEW
// ============================================================
class _AvatarPreview extends StatelessWidget {
  final String photoUrl;
  const _AvatarPreview({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 90,
        height: 90,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.purple, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withOpacity(0.3),
              blurRadius: 16,
            ),
          ],
        ),
        child: ClipOval(
          child: NetImage(url: photoUrl, fallbackIcon: Icons.person),
        ),
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
  final ValueChanged<String>? onChanged;

  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator == null ? null : (v) => L10n.trN(validator!(v)),
      onChanged: onChanged,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
// GENERIC DROPDOWN
// ============================================================
class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<({T value, String label})> items;
  final IconData icon;
  final Color color;
  final ValueChanged<T> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          icon: Icon(Icons.keyboard_arrow_down, color: color),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Cairo',
          ),
          items: items.map((it) {
            return DropdownMenuItem<T>(
              value: it.value,
              child: Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(it.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ============================================================
// CATEGORY PICKER
// ============================================================
class _CategoryPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _CategoryPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: CoachCategories.all.map((cat) {
        final active = cat == value;
        final c = _colorFor(cat);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(cat),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? c.withOpacity(0.15)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? c : Colors.white.withOpacity(0.10),
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: active ? c : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _colorFor(String cat) {
    switch (cat) {
      case 'فني':
        return AppColors.green;
      case 'بدني':
        return AppColors.orange;
      case 'حراس':
        return AppColors.blue;
      default:
        return AppColors.purple;
    }
  }
}

// ============================================================
// BUTTONS
// ============================================================
class _Buttons extends StatelessWidget {
  final bool isEdit;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _Buttons({
    required this.isEdit,
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEdit ? Icons.check_rounded : Icons.add_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isEdit ? 'حفظ التعديلات' : 'إضافة المدرب',
                              style: const TextStyle(
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