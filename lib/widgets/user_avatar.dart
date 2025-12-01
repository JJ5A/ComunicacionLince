import 'dart:io';

import 'package:flutter/material.dart';

/// Widget para mostrar avatares de usuario que pueden ser:
/// - URLs de red (Supabase Storage)
/// - Archivos locales
/// - Iniciales del usuario (fallback)
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.avatarPath,
    required this.initials,
    this.radius = 20,
    super.key,
  });

  final String? avatarPath;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarPath != null && avatarPath!.isNotEmpty;
    final isNetworkImage = hasAvatar && 
        (avatarPath!.startsWith('http://') || avatarPath!.startsWith('https://'));
    final isLocalFile = hasAvatar && 
        !isNetworkImage && 
        File(avatarPath!).existsSync();
    
    ImageProvider? backgroundImage;
    if (isNetworkImage) {
      backgroundImage = NetworkImage(avatarPath!);
    } else if (isLocalFile) {
      backgroundImage = FileImage(File(avatarPath!));
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: backgroundImage,
      child: backgroundImage == null 
          ? Text(
              initials,
              style: TextStyle(
                fontSize: radius * 0.7,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
