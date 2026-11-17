// lib/widgets/team_form_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import '../l10n/app_text.dart';
import 'package:uuid/uuid.dart';
import '../academy_dashboard_screen.dart' show AppColors;
import '../models/team.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';

// ============================================================
// TEAM FORM DIALOG
// ============================================================
class TeamFormDialog extends StatefulWidget {
  /// لو موجود → وضع تعديل، لو null → وضع إضافة
  final Team? team;

  const TeamFormDialog({super.key, this.team});

  static Future<bool?> show(BuildContext context, {Team? team}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TeamFormDialog(team: team),
    );
  }

  @override
  State<TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends State<TeamFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _coachNameCtrl;
  late final TextEditingController _descriptionCtrl;

  String _category = 'U-12';
  Color _color = AppColors.green;

  bool _saving = false;

  bool get _isEdit => widget.team != null;

  // ============================================================
  // الفئات المتاحة
  // ============================================================
  static const _categories = [
    'U-8',
    'U-10',
    'U-12',
    'U-14',
    'U-16',
    'U-18',
    'فريق أول',
  ];

  // ============================================================
  // الألوان المتاحة
  // ============================================================
  static const _availableColors = [
    AppColors.green,
    AppColors.blue,
    AppColors.purple,
    AppColors.orange,
    AppColors.gold,
    AppColors.red,
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.team;

    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _coachNameCtrl = TextEditingController(
      text: (t?.coachName ?? '') == '—' ? '' : (t?.coachName ?? ''),
    );
    _descriptionCtrl = TextEditingController(text: t?.description ?? '');

    if (t != null && _categories.contains(t.category)) {
      _category = t.category;
    }

    if (t != null && _availableColors.contains(t.color)) {
      _color = t.color;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _coachNameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // حفظ (إضافة أو تعديل)
  // ============================================================
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('مفيش مستخدم مسجل');
      }

      final id = _isEdit
          ? widget.team!.id
          : 'team_${const Uuid().v4().substring(0, 8)}';

      final team = Team(
        id: id,
        name: _nameCtrl.text.trim(),
        category: _category,
        color: _color,
        coachId: widget.team?.coachId ?? '',
        coachName: _coachNameCtrl.text.trim().isEmpty
            ? '—'
            : _coachNameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        academyId: widget.team?.academyId ?? user.academyId ?? '',
      );

      if (_isEdit) {
        await TeamService.updateTeam(team);
      } else {
        await TeamService.addTeam(team);
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

  // ============================================================
  // BUILD
  // ============================================================
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
                  color: _color.withOpacity(0.5),
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
                        color: _color,
                        onClose: () => Navigator.pop(context),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ============ معاينة الفريق ============
                            _TeamPreview(
                              name: _nameCtrl.text,
                              category: _category,
                              color: _color,
                            ),
                            const SizedBox(height: 18),

                            // ============ اسم الفريق ============
                            _FieldLabel(
                              icon: Icons.shield_rounded,
                              text: 'اسم الفريق *',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _nameCtrl,
                              hint: 'مثال: الفريق الأول',
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'لازم تكتب اسم الفريق';
                                }
                                if (v.trim().length < 2) {
                                  return 'الاسم قصير جدًا';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // ============ الفئة ============
                            _FieldLabel(
                              icon: Icons.category_rounded,
                              text: 'الفئة العمرية *',
                            ),
                            const SizedBox(height: 6),
                            _CategoryDropdown(
                              value: _category,
                              color: _color,
                              categories: _categories,
                              onChanged: (v) =>
                                  setState(() => _category = v),
                            ),
                            const SizedBox(height: 14),

                            // ============ المدرب ============
                            _FieldLabel(
                              icon: Icons.sports_rounded,
                              text: 'اسم المدرب',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _coachNameCtrl,
                              hint: 'مثال: كابتن أحمد',
                            ),
                            const SizedBox(height: 14),

                            // ============ الوصف ============
                            _FieldLabel(
                              icon: Icons.notes_rounded,
                              text: 'وصف الفريق',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _descriptionCtrl,
                              hint: 'وصف مختصر للفريق...',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 14),

                            // ============ اللون ============
                            _FieldLabel(
                              icon: Icons.palette_rounded,
                              text: 'لون الفريق',
                            ),
                            const SizedBox(height: 8),
                            _ColorPicker(
                              colors: _availableColors,
                              selected: _color,
                              onChanged: (c) => setState(() => _color = c),
                            ),
                            const SizedBox(height: 22),

                            // ============ الأزرار ============
                            _Buttons(
                              isEdit: _isEdit,
                              saving: _saving,
                              color: _color,
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
  final Color color;
  final VoidCallback onClose;

  const _Header({
    required this.isEdit,
    required this.color,
    required this.onClose,
  });

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
              color: color.withOpacity(0.15),
              border: Border.all(color: color),
            ),
            child: Icon(
              isEdit ? Icons.edit_rounded : Icons.add_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'تعديل الفريق' : 'إضافة فريق جديد',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEdit
                      ? 'عدّل بيانات الفريق واضغط حفظ'
                      : 'املأ بيانات الفريق الجديد',
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
// TEAM PREVIEW
// ============================================================
class _TeamPreview extends StatelessWidget {
  final String name;
  final String category;
  final Color color;

  const _TeamPreview({
    required this.name,
    required this.category,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              Icons.shield_rounded,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.trim().isEmpty ? 'اسم الفريق' : name.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator == null ? null : (v) => L10n.trN(validator!(v)),
      onChanged: onChanged,
      maxLines: maxLines,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
// CATEGORY DROPDOWN
// ============================================================
class _CategoryDropdown extends StatelessWidget {
  final String value;
  final Color color;
  final List<String> categories;
  final ValueChanged<String> onChanged;

  const _CategoryDropdown({
    required this.value,
    required this.color,
    required this.categories,
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
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          icon: Icon(Icons.keyboard_arrow_down, color: color),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Cairo',
          ),
          items: categories.map((c) {
            return DropdownMenuItem<String>(
              value: c,
              child: Row(
                children: [
                  Icon(Icons.category_rounded, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(c),
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
// COLOR PICKER
// ============================================================
class _ColorPicker extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onChanged;

  const _ColorPicker({
    required this.colors,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((c) {
        final active = c == selected;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(c),
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withOpacity(0.18),
                border: Border.all(
                  color: active ? c : c.withOpacity(0.4),
                  width: active ? 2.5 : 1.5,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: c.withOpacity(0.5),
                          blurRadius: 14,
                        ),
                      ]
                    : [],
              ),
              child: active
                  ? Icon(Icons.check_rounded, color: c, size: 20)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================
// BUTTONS
// ============================================================
class _Buttons extends StatelessWidget {
  final bool isEdit;
  final bool saving;
  final Color color;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _Buttons({
    required this.isEdit,
    required this.saving,
    required this.color,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // إلغاء
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

        // حفظ
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
                        : [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: saving
                      ? []
                      : [
                          BoxShadow(
                            color: color.withOpacity(0.4),
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
                              isEdit
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isEdit ? 'حفظ التعديلات' : 'إضافة الفريق',
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