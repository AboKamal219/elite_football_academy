// lib/widgets/player_form_dialog.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Text;
import '../l10n/app_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../academy_dashboard_screen.dart' show AppColors, NetImage;
import '../models/app_user.dart';
import '../models/player.dart';
import '../services/auth_service.dart';
import '../services/player_service.dart';
import '../services/supabase_service.dart';
import '../services/team_service.dart';

// ============================================================
// PLAYER FORM DIALOG
// ============================================================
class PlayerFormDialog extends StatefulWidget {
  final Player? player;

  const PlayerFormDialog({super.key, this.player});

  static Future<bool?> show(BuildContext context, {Player? player}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PlayerFormDialog(player: player),
    );
  }

  @override
  State<PlayerFormDialog> createState() => _PlayerFormDialogState();
}

class _PlayerFormDialogState extends State<PlayerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;

  // ✅ متغيرات الصورة
  final ImagePicker _picker = ImagePicker();
  String _currentPhotoUrl = '';
  bool _isUploading = false;

  String _position = PlayerPositions.forward;
  String? _teamId;
  String? _teamName;
  String _foot = 'قدم يمنى';

  bool _saving = false;
  bool _loadingTeams = true;

  List<({String id, String name})> _teams = [];

  bool get _isEdit => widget.player != null;

  @override
  void initState() {
    super.initState();

    final p = widget.player;

    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _ageCtrl = TextEditingController(
      text: (p?.age == '—') ? '' : (p?.age ?? ''),
    );
    _heightCtrl = TextEditingController(
      text: (p?.height == '—') ? '' : (p?.height ?? ''),
    );
    _weightCtrl = TextEditingController(
      text: (p?.weight == '—') ? '' : (p?.weight ?? ''),
    );

    _currentPhotoUrl = p?.photo ?? '';

    if (p != null && PlayerPositions.all.contains(p.position)) {
      _position = p.position;
    }

    if (p != null && p.foot != '—' && p.foot.isNotEmpty) {
      _foot = p.foot;
    }

    _teamId = (p?.teamId.isEmpty ?? true) ? null : p?.teamId;
    _teamName = (p?.teamName == 'بدون فريق') ? null : p?.teamName;

    _loadTeams();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

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
  // ✅ اختيار ورفع الصورة
  // ============================================================
    Future<void> _pickAndUploadImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AppDirectionality(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.green),
                title: const Text('الكاميرا', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.green),
                title: const Text('المعرض', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    setState(() => _isUploading = true);

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 500,
      );

      if (picked == null) {
        setState(() => _isUploading = false);
        return;
      }

      // ✅ التعديل هنا: استخراج الامتداد من الاسم بدل المسار
      final String ext = picked.name.split('.').last.toLowerCase();
      final String mimeType = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      
      final fileName = 'player_${const Uuid().v4().substring(0, 8)}.$ext';
      final storage = SupabaseService.client.storage;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await storage.from('avatars').uploadBinary(
          fileName, bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: mimeType, // ✅ استخدام المتغير اللي عملناه
          ),
        );
      } else {
        final file = File(picked.path);
        await storage.from('avatars').upload(
          fileName, file,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: mimeType, // ✅ استخدام المتغير اللي عملناه
          ),
        );
      }

      final publicUrl = storage.from('avatars').getPublicUrl(fileName);

      if (!mounted) return;
      setState(() {
        _currentPhotoUrl = publicUrl;
        _isUploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في رفع الصورة: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  // ============================================================
  // ✅ حفظ (إضافة أو تعديل)
  // ============================================================
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('مفيش مستخدم مسجل');

      String teamId = '';
      String teamName = 'بدون فريق';

      if (_teamId != null && _teamId!.isNotEmpty) {
        teamId = _teamId!;
        teamName = _teamName ?? 'بدون فريق';
      }

      final id = _isEdit ? widget.player!.id : 'pl_${const Uuid().v4().substring(0, 8)}';

      final newPlayer = Player(
        id: id,
        userId: widget.player?.userId ?? '',
        name: _nameCtrl.text.trim(),
        position: _position,
        teamId: teamId,
        teamName: teamName,
        photo: _currentPhotoUrl, // 👈 بنحفظ الرابط اللي طلع من الرفع
        rating: widget.player?.rating ?? '0.0',
        goals: widget.player?.goals ?? 0,
        assists: widget.player?.assists ?? 0,
        matches: widget.player?.matches ?? 0,
        yellowCards: widget.player?.yellowCards ?? 0,
        redCards: widget.player?.redCards ?? 0,
        age: _ageCtrl.text.trim().isEmpty ? '—' : _ageCtrl.text.trim(),
        height: _heightCtrl.text.trim().isEmpty ? '—' : _heightCtrl.text.trim(),
        weight: _weightCtrl.text.trim().isEmpty ? '—' : _weightCtrl.text.trim(),
        foot: _foot,
        nationality: widget.player?.nationality ?? '—',
        academyId: widget.player?.academyId ?? user.academyId ?? '',
      );

      if (_isEdit) {
        await PlayerService.updatePlayer(newPlayer);
      } else {
        await PlayerService.addPlayer(newPlayer);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حصل خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
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
                  color: AppColors.green.withOpacity(0.4),
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
                      _Header(isEdit: _isEdit, onClose: () => Navigator.pop(context)),
                      const Divider(color: Colors.white12, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            
                            // ✅ اختيار الصورة
                            Center(
                              child: GestureDetector(
                                onTap: _isUploading ? null : _pickAndUploadImage,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.green, width: 2),
                                        boxShadow: [
                                          BoxShadow(color: AppColors.green.withOpacity(0.3), blurRadius: 16),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: NetImage(
                                          url: _currentPhotoUrl,
                                          fallbackIcon: Icons.person,
                                        ),
                                      ),
                                    ),
                                    if (_isUploading)
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(color: AppColors.green),
                                        ),
                                      ),
                                    if (!_isUploading)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.green,
                                            border: Border.all(color: AppColors.surface, width: 2),
                                          ),
                                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _FieldLabel(icon: Icons.person_rounded, text: 'اسم اللاعب *'),
                            const SizedBox(height: 6),
                            _TextField(
                              controller: _nameCtrl,
                              hint: 'مثال: عمر خالد',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'لازم تكتب اسم اللاعب';
                                }
                                if (v.trim().length < 2) {
                                  return 'الاسم قصير جدًا';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(icon: Icons.sports_soccer_rounded, text: 'المركز *'),
                            const SizedBox(height: 6),
                            _PositionDropdown(
                              value: _position,
                              onChanged: (v) => setState(() => _position = v),
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(icon: Icons.shield_rounded, text: 'الفريق'),
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

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _FieldLabel(icon: Icons.cake_rounded, text: 'السن'),
                                      const SizedBox(height: 6),
                                      _TextField(
                                        controller: _ageCtrl,
                                        hint: '18',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _FieldLabel(icon: Icons.height_rounded, text: 'الطول (سم)'),
                                      const SizedBox(height: 6),
                                      _TextField(
                                        controller: _heightCtrl,
                                        hint: '178',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _FieldLabel(icon: Icons.monitor_weight_rounded, text: 'الوزن (كجم)'),
                                      const SizedBox(height: 6),
                                      _TextField(
                                        controller: _weightCtrl,
                                        hint: '72',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            _FieldLabel(icon: Icons.directions_walk_rounded, text: 'القدم المفضلة'),
                            const SizedBox(height: 6),
                            _FootPicker(
                              value: _foot,
                              onChanged: (v) => setState(() => _foot = v),
                            ),
                            const SizedBox(height: 20),

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
              isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
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
                  isEdit ? 'تعديل بيانات اللاعب' : 'إضافة لاعب جديد',
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
                      : 'املأ البيانات الأساسية للاعب',
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
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
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
// POSITION DROPDOWN
// ============================================================
class _PositionDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _PositionDropdown({required this.value, required this.onChanged});

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
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.green),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Cairo',
          ),
          items: PlayerPositions.all.map((p) {
            return DropdownMenuItem<String>(
              value: p,
              child: Row(
                children: [
                  Icon(_iconForPosition(p), color: _colorForPosition(p), size: 16),
                  const SizedBox(width: 8),
                  Text(p),
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

  IconData _iconForPosition(String p) {
    switch (p) {
      case 'مهاجم':
        return Icons.gps_fixed;
      case 'وسط ميدان':
        return Icons.add_circle_outline;
      case 'مدافع':
        return Icons.shield_outlined;
      case 'حارس مرمى':
        return Icons.front_hand_outlined;
      default:
        return Icons.sports_soccer;
    }
  }

  Color _colorForPosition(String p) {
    switch (p) {
      case 'مهاجم':
        return AppColors.orange;
      case 'وسط ميدان':
        return AppColors.blue;
      case 'مدافع':
        return AppColors.green;
      case 'حارس مرمى':
        return AppColors.purple;
      default:
        return AppColors.gray;
    }
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
            'بدون فريق',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.block_rounded, color: AppColors.gray, size: 16),
                  SizedBox(width: 8),
                  Text('بدون فريق'),
                ],
              ),
            ),
            ...teams.map((t) {
              return DropdownMenuItem<String?>(
                value: t.id,
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.green, size: 16),
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
// FOOT PICKER
// ============================================================
class _FootPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _FootPicker({required this.value, required this.onChanged});

  static const _options = ['قدم يمنى', 'قدم يسرى', 'القدمين'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final active = opt == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(opt),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.green.withOpacity(0.15)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? AppColors.green
                          : Colors.white.withOpacity(0.10),
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      opt,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active ? AppColors.green : AppColors.textSecondary,
                        fontSize: 11,
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
                              isEdit ? 'حفظ التعديلات' : 'إضافة اللاعب',
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