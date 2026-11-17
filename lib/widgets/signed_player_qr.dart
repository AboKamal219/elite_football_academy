// lib/widgets/signed_player_qr.dart
// Drop-in replacement for QrImageView(data: player.id) in player_qr_screen.dart.
// Fetches a signed token and refreshes it every 8 minutes (token lives 10).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/checkin_token_service.dart';

class SignedPlayerQr extends StatefulWidget {
  final String playerId;
  final double size;
  const SignedPlayerQr({super.key, required this.playerId, this.size = 220});

  @override
  State<SignedPlayerQr> createState() => _SignedPlayerQrState();
}

class _SignedPlayerQrState extends State<SignedPlayerQr> {
  String? _token;
  bool _failed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(minutes: 8), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final t = await CheckinTokenService.issue(widget.playerId);
      if (mounted) setState(() { _token = t; _failed = false; });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null) {
      return SizedBox(
        width: widget.size, height: widget.size,
        child: Center(
          child: _failed
              ? IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.black54), onPressed: _load)
              : const CircularProgressIndicator(),
        ),
      );
    }
    return QrImageView(
      data: _token!,
      version: QrVersions.auto,
      size: widget.size,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
    );
  }
}
