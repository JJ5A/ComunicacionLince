import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/user_profile.dart';
import '../../../state/providers.dart';
import '../../../theme/design_tokens.dart';
import '../../../widgets/user_avatar.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sin sesión activa')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: DecoratedBox(
        decoration: AppDecorations.surfaceBackground,
        child: ListView(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: 100,
          ),
          children: <Widget>[
            _ProfileHeader(user: user),
            const SizedBox(height: AppSpacing.lg),
            _InfoCard(
              icon: Icons.phone_enabled_outlined,
              label: 'Celular',
              value: user.phoneNumber,
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoCard(
              icon: Icons.email_outlined,
              label: 'Correo institucional',
              value: user.email,
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoCard(
              icon: Icons.badge_outlined,
              label: 'Especialidad / academia',
              value: user.specialty ?? 'Pendiente',
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoCard(
              icon: Icons.info_outline,
              label: 'Bio',
              value: user.bio?.isNotEmpty == true ? user.bio! : 'Agrega una breve descripción.',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => _showEditDialog(context, ref, user),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar datos'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => ref.read(appControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, UserProfile user) async {
    final bioController = TextEditingController(text: user.bio ?? '');
    final specialtyController = TextEditingController(text: user.specialty ?? '');
    String? newAvatarPath;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Actualizar perfil'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Avatar con botón para cambiar
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 512,
                          maxHeight: 512,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          setState(() {
                            newAvatarPath = image.path;
                          });
                        }
                      },
                      child: Stack(
                        children: [
                          UserAvatar(
                            avatarPath: newAvatarPath ?? user.avatarPath,
                            initials: user.initials(),
                            radius: 50,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.brandPrimary,
                              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: specialtyController,
                      decoration: const InputDecoration(labelText: 'Especialidad'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Bio'),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () async {
                    await ref.read(appControllerProvider.notifier).updateProfile(
                          bio: bioController.text,
                          specialty: specialtyController.text,
                          avatarPath: newAvatarPath,
                        );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              UserAvatar(
                avatarPath: user.avatarPath,
                initials: user.initials(),
                radius: 40,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(user.displayName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
                    Text(user.role.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              Chip(
                avatar: const Icon(Icons.verified_user, color: AppColors.brandPrimary),
                label: const Text('Cuenta verificada'),
              ),
              Chip(label: Text(user.specialty ?? 'Sin especialidad')),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.label, required this.value, this.maxLines = 1});

  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.brandPrimary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(value, maxLines: maxLines, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
