// lib/widgets/avatar_image.dart
import 'package:flutter/material.dart';
import '../services/avatar_service.dart';

/// Use instead of NetworkImage(player.photo).
class AvatarImage extends StatelessWidget {
  final String? stored;
  final double size;
  final IconData fallbackIcon;
  const AvatarImage({super.key, required this.stored, this.size = 48, this.fallbackIcon = Icons.person_rounded});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(fallbackIcon, size: size * 0.55, color: Colors.white54);
    return ClipOval(
      child: SizedBox(
        width: size, height: size,
        child: FutureBuilder<String?>(
          future: AvatarService.signedUrl(stored),
          builder: (c, s) => s.data == null
              ? Center(child: fallback)
              : Image.network(s.data!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: fallback)),
        ),
      ),
    );
  }
}
