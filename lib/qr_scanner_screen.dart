// lib/qr_scanner_screen.dart
//
// QR scanner (mobile_scanner 5.x) — continuous scanning with on-screen feedback.
//
// Camera start is now the library's default path (autoStart): the widget starts
// the camera itself and mobile_scanner asks for the permission itself. Any
// failure is shown WITH its real error code so it can be diagnosed, and a
// "pick QR image from gallery" fallback is offered.

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'academy_dashboard_screen.dart' show AppColors;
import 'app_settings.dart';
import 'l10n/app_text.dart';
import 'services/camera_permission_service.dart';

/// Result shown on the scanner after each scan.
enum ScanTone { success, info, error }

class ScanFeedback {
  final ScanTone tone;
  final String message;
  const ScanFeedback(this.tone, this.message);
}

class QrScannerScreen extends StatefulWidget {
  /// Called for every scanned code. The screen stays open (continuous
  /// scanning) and shows the returned feedback, then scans the next player.
  final Future<ScanFeedback> Function(String raw) onScan;
  const QrScannerScreen({super.key, required this.onScan});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 600,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _busy = false;
  bool _wentToSettings = false;
  ScanFeedback? _feedback;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (_wentToSettings || !_controller.value.isRunning) {
          _wentToSettings = false;
          unawaited(_restart());
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (_controller.value.isRunning) unawaited(_controller.stop());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _restart() async {
    try {
      await _controller.stop();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    try {
      await _controller.start();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _openSettings() async {
    _wentToSettings = true;
    final ok = await CameraPermissionService.openSettings();
    if (!ok) _wentToSettings = false;
  }

  Future<void> _pickImage() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x == null) return;
      final cap = await _controller.analyzeImage(x.path);
      if (cap == null || cap.barcodes.isEmpty) {
        if (!mounted) return;
        setState(() => _feedback =
            const ScanFeedback(ScanTone.error, 'مفيش QR واضح في الصورة دي'));
        return;
      }
      await _onDetect(cap);
    } catch (_) {
      if (!mounted) return;
      setState(() => _feedback =
          const ScanFeedback(ScanTone.error, 'تعذّر قراءة الصورة'));
    }
  }

  // ------------------------------------------------------------------
  // scan result
  // ------------------------------------------------------------------
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || !mounted) return;
    String? raw;
    for (final b in capture.barcodes) {
      final v = b.rawValue?.trim();
      if (v != null && v.isNotEmpty) {
        raw = v;
        break;
      }
    }
    if (raw == null) return;

    _busy = true;
    ScanFeedback fb;
    try {
      fb = await widget.onScan(raw);
    } catch (_) {
      fb = const ScanFeedback(ScanTone.error, 'حصل خطأ غير متوقع');
    }
    if (!mounted) return;
    if (AppSettings.instance.hapticFeedback && !kIsWeb) {
      if (fb.tone == ScanTone.error) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
    setState(() {
      _feedback = fb;
      if (fb.tone == ScanTone.success) _count++;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _feedback = null);
    _busy = false;
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return AppDirectionality(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'مسح كود اللاعب',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, v, _) {
                if (!v.isRunning || v.torchState == TorchState.unavailable) {
                  return const SizedBox.shrink();
                }
                final on = v.torchState == TorchState.on;
                return IconButton(
                  tooltip: 'الفلاش',
                  onPressed: () => _controller.toggleTorch(),
                  icon: Icon(
                    on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: on ? AppColors.green : Colors.white,
                  ),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) => _errorPanel(error),
            ),
            // overlay + frame only while the camera is healthy
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, v, _) =>
                  v.error != null ? const SizedBox.shrink() : _frame(),
            ),
            if (_feedback != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _FeedbackBanner(feedback: _feedback!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _errorPanel(MobileScannerException error) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    final detail =
        '${error.errorCode.name}${error.errorDetails?.message != null ? ' — ${error.errorDetails!.message}' : ''}';
    return _Message(
      icon: denied ? Icons.no_photography_rounded : Icons.videocam_off_rounded,
      text: denied
          ? 'صلاحية الكاميرا مقفولة. افتح إعدادات التطبيق واسمح بالكاميرا، وبعدين ارجع هنا'
          : 'مش قادرين نشغّل الكاميرا. اقفل أي تطبيق تاني بيستخدمها وحاول تاني',
      detail: detail,
      primaryLabel: denied ? 'فتح الإعدادات' : 'إعادة المحاولة',
      onPrimary: denied ? _openSettings : _restart,
      secondaryLabel: 'اختيار صورة الكود من المعرض',
      onSecondary: _pickImage,
      onBack: () => Navigator.of(context).pop(),
    );
  }

  Widget _frame() {
    return Stack(
      children: [
        const _ScannerOverlay(),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.green, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Stack(
              children: [
                _Corner(top: true, left: true),
                _Corner(top: true, left: false),
                _Corner(top: false, left: true),
                _Corner(top: false, left: false),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.green.withOpacity(0.5)),
                ),
                child: Text(
                  _count == 0
                      ? 'وجّه الكاميرا نحو كود اللاعب'
                      : 'تم تسجيل $_count — وجّه للاعب اللي بعده',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'التسجيل بيتم تلقائياً بمجرد قراءة الكود',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final ScanFeedback feedback;
  const _FeedbackBanner({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final Color c;
    final IconData icon;
    switch (feedback.tone) {
      case ScanTone.success:
        c = AppColors.green;
        icon = Icons.check_circle_rounded;
        break;
      case ScanTone.info:
        c = AppColors.orange;
        icon = Icons.info_rounded;
        break;
      case ScanTone.error:
        c = AppColors.red;
        icon = Icons.error_rounded;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feedback.message,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Message panel (permission / error states)
// ============================================================
class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? detail;
  final String primaryLabel;
  final Future<void> Function() onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback onBack;

  const _Message({
    required this.icon,
    required this.text,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onBack,
    this.detail,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 60),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white70,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.ltr,
                child: SelectableText(
                  detail!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => onPrimary(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(primaryLabel,
                  style: const TextStyle(fontFamily: 'Cairo')),
            ),
            if (onSecondary != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
                child: Text(secondaryLabel ?? '',
                    style: const TextStyle(fontFamily: 'Cairo')),
              ),
            ],
            const SizedBox(height: 10),
            TextButton(
              onPressed: onBack,
              child: const Text('رجوع',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// OVERLAY + CORNERS (unchanged design)
// ============================================================
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(color: Colors.black.withOpacity(0.4)),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool top;
  final bool left;

  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AppColors.green, width: 4);
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: top ? side : BorderSide.none,
            bottom: !top ? side : BorderSide.none,
            left: left ? side : BorderSide.none,
            right: !left ? side : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
