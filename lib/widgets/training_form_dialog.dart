// lib/widgets/training_form_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart' hide Text;
import '../l10n/app_text.dart';
import 'package:uuid/uuid.dart';
import '../academy_dashboard_screen.dart' show AppColors;
import '../models/training.dart';
import '../models/team.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';
import '../services/training_service.dart';

// ============================================================
// TRAINING FORM DIALOG
// ============================================================
class TrainingFormDialog extends StatefulWidget {
  final Training? training;

  const TrainingFormDialog({super.key, this.training});

  static Future<bool?> show(BuildContext context, {Training? training}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TrainingFormDialog(training: training),
    );
  }

  @override
  State<TrainingFormDialog> createState() => _TrainingFormDialogState();
}

class _TrainingFormDialogState extends State<TrainingFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _notesCtrl;

  String _type = TrainingTypes.practice;
  DateTime _date = DateTime.now();
  String? _teamId;
  String? _teamName;

  bool _loadingTeams = true;
  bool _saving = false;

  List<({String id, String name})> _teams = [];

  bool get _isEdit => widget.training != null;

  // ============================================================
  // initState
  // ============================================================
  @override
  void initState() {
    super.initState();
    final t = widget.training;

    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _locationCtrl = TextEditingController(text: t?.location ?? '');
    _timeCtrl = TextEditingController(text: t?.time ?? '');
    _durationCtrl = TextEditingController(
      text: (t?.durationMinutes ?? 60).toString(),
    );
    _notesCtrl = TextEditingController(text: t?.notes ?? '');

    if (t != null && TrainingTypes.all.contains(t.type)) {
      _type = t.type;
    }

    if (t != null) {
      _date = t.date;
      _teamId = t.teamId.isEmpty ? null : t.teamId;
      _teamName = t.teamName.isEmpty ? null : t.teamName;
    }

    _loadTeams();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _timeCtrl.dispose();
    _durationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // تحميل الفرق
  // ============================================================
  Future<void> _loadTeams() async {
    try {
      final teams = await TeamService.getAllTeams();
      if (!mounted) return;
      setState(() {
        _teams = teams.map((t) => (id: t.id, name: t.name)).toList();
        _loadingTeams = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTeams = false);
    }
  }

  // ============================================================
  // فتح Date Picker
  // ============================================================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.green,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: AppColors.surface,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  // ============================================================
  // فتح Time Picker (بسيط - بيحفظ النص)
  // ============================================================
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.green,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final h = picked.hour == 0
          ? 12
          : (picked.hour > 12 ? picked.hour - 12 : picked.hour);
      final ampm = picked.hour >= 12 ? 'م' : 'ص';
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() => _timeCtrl.text = '$h:$m $ampm');
    }
  }

  // ============================================================
  // حفظ
  // ============================================================
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('مفيش مستخدم مسجل');

      final id = _isEdit
          ? widget.training!.id
          : 'tr_${const Uuid().v4().substring(0, 8)}';

      final training = Training(
        id: id,
        title: _titleCtrl.text.trim(),
        type: _type,
        location: _locationCtrl.text.trim(),
        date: _date,
        time: _timeCtrl.text.trim(),
        durationMinutes: int.tryParse(_durationCtrl.text.trim()) ?? 60,
        teamId: _teamId ?? '',
        teamName: _teamName ?? '',
        coachId: widget.training?.coachId ?? user.id,
        coachName: widget.training?.coachName ?? user.name,
        notes: _notesCtrl.text.trim(),
        academyId: widget.training?.academyId ?? user.academyId ?? '',
      );

      if (_isEdit) {
        await TrainingService.updateTraining(training);
      } else {
        await TrainingService.addTraining(training);
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
                  color: AppColors.green.withOpacity(0.5),
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
                            _FieldLabel(
                              icon: Icons.title_rounded,
                              text: 'عنوان التدريب *',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _titleCtrl,
                              hint: 'مثال: تدريب الفريق الأول',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'لازم تكتب عنوان';
                                }
                                if (v.trim().length < 2) {
                                  return 'العنوان قصير جدًا';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.category_rounded,
                              text: 'النوع *',
                            ),
                            const SizedBox(height: 6),
                            _TypePicker(
                              value: _type,
                              onChanged: (v) => setState(() => _type = v),
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.calendar_today_rounded,
                              text: 'التاريخ *',
                            ),
                            const SizedBox(height: 6),
                            _DateField(
                              date: _date,
                              onTap: _pickDate,
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.access_time_rounded,
                              text: 'الوقت',
                            ),
                            const SizedBox(height: 6),
                            _TimeField(
                              controller: _timeCtrl,
                              onPick: _pickTime,
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.timer_rounded,
                              text: 'المدة (دقيقة)',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _durationCtrl,
                              hint: '60',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.location_on_rounded,
                              text: 'المكان',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _locationCtrl,
                              hint: 'مثال: ملعب الأكاديمية',
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.shield_rounded,
                              text: 'الفريق',
                            ),
                            const SizedBox(height: 6),
                            _TeamDropdown(
                              teams: _teams,
                              loading: _loadingTeams,
                              selectedId: _teamId,
                              onChanged: (id, name) {
                                setState(() {
                                  _teamId = id;
                                  _teamName = name;
                                });
                              },
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(
                              icon: Icons.notes_rounded,
                              text: 'ملاحظات',
                            ),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _notesCtrl,
                              hint: 'ملاحظات إضافية عن التدريب',
                              maxLines: 3,
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
              color: AppColors.green.withOpacity(0.15),
              border: Border.all(color: AppColors.green),
            ),
            child: Icon(
              isEdit ? Icons.edit_rounded : Icons.add_rounded,
              color: AppColors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'تعديل التدريب' : 'إضافة تدريب جديد',
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
                      : 'املأ بيانات التدريب أو المباراة',
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
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator == null ? null : (v) => L10n.trN(validator!(v)),
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
// TYPE PICKER
// ============================================================
class _TypePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _TypePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TrainingTypes.all.map((t) {
        final active = t == value;
        final c = _colorFor(t);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(t),
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
                      t,
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

  Color _colorFor(String t) {
    switch (t) {
      case 'مباراة':
        return AppColors.orange;
      case 'اجتماع':
        return AppColors.purple;
      default:
        return AppColors.green;
    }
  }
}

// ============================================================
// DATE FIELD
// ============================================================
class _DateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DateField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.green,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                '$y/$m/$d',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.edit_rounded,
                color: AppColors.textMuted,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TIME FIELD
// ============================================================
class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPick;
  const _TimeField({required this.controller, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            readOnly: true,
            onTap: onPick,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontFamily: 'Cairo',
            ),
            decoration: InputDecoration(
              hintText: L10n.tr('اختر الوقت'),
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: const Icon(
                Icons.access_time_rounded,
                color: AppColors.green,
                size: 18,
              ),
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
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TEAM DROPDOWN
// ============================================================
class _TeamDropdown extends StatelessWidget {
  final List<({String id, String name})> teams;
  final bool loading;
  final String? selectedId;
  final void Function(String? id, String? name) onChanged;

  const _TeamDropdown({
    required this.teams,
    required this.loading,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: AppColors.green,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedId,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.green),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Cairo',
          ),
          hint: const Text(
            'كل الفرق',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.public_rounded, color: AppColors.gray, size: 16),
                  SizedBox(width: 8),
                  Text('كل الفرق'),
                ],
              ),
            ),
            ...teams.map((t) {
              return DropdownMenuItem<String?>(
                value: t.id,
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: AppColors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (id) {
            if (id == null) {
              onChanged(null, null);
              return;
            }
            final team = teams.firstWhere((t) => t.id == id);
            onChanged(team.id, team.name);
          },
        ),
      ),
    );
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
                        : [AppColors.green, AppColors.greenDark],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: saving
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.green.withOpacity(0.4),
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
                              isEdit ? 'حفظ التعديلات' : 'إضافة التدريب',
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