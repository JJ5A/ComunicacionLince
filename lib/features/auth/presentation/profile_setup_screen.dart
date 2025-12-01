import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/user_profile.dart';
import '../../../state/providers.dart';
import '../../../theme/design_tokens.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late final TextEditingController _specialtyController;
  UserRole _role = UserRole.student;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
    _specialtyController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _avatarPath = file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    
    // Mostrar errores en SnackBar
    ref.listen(appControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _submit,
            ),
          ),
        );
      }
    });
    
    return Scaffold(
      appBar: AppBar(title: const Text('Completa tu perfil')),
      body: DecoratedBox(
        decoration: AppDecorations.surfaceBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: <Widget>[
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: <Widget>[
                              GestureDetector(
                                onTap: _pickAvatar,
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundImage: _avatarPath != null 
                                    ? (_avatarPath!.startsWith('http://') || _avatarPath!.startsWith('https://'))
                                        ? NetworkImage(_avatarPath!) as ImageProvider
                                        : FileImage(File(_avatarPath!))
                                    : null,
                                  child: _avatarPath == null
                                      ? const Icon(Icons.add_a_photo_outlined, size: 32)
                                      : null,
                                ),
                              ),
                              FloatingActionButton.small(
                                heroTag: 'edit-avatar',
                                onPressed: _pickAvatar,
                                child: const Icon(Icons.edit),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Personaliza tu presencia en los canales oficiales TecNM.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Datos básicos',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Nombre completo'),
                            validator: (value) => value == null || value.isEmpty ? 'Ingresa tu nombre' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Correo institucional'),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Ingresa tu correo';
                              if (!value.endsWith('@itcelaya.edu.mx')) {
                                return 'Usa tu correo institucional';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SegmentedButton<UserRole>(
                            style: SegmentedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            ),
                            segments: const <ButtonSegment<UserRole>>[
                              ButtonSegment(value: UserRole.student, label: Text('Alumno')),
                              ButtonSegment(value: UserRole.professor, label: Text('Profesor')),
                            ],
                            selected: <UserRole>{_role},
                            onSelectionChanged: (selection) => setState(() => _role = selection.first),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Tu rol en la comunidad',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _specialtyController,
                            decoration: const InputDecoration(labelText: 'Especialidad / Academia'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _bioController,
                            maxLines: 4,
                            decoration: const InputDecoration(labelText: 'Bio (intereses, proyectos, tutorías)'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton.icon(
                            onPressed: appState.isLoading ? null : _submit,
                            icon: appState.isLoading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_circle_outline),
                            label: const Text('Guardar y continuar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _ProfileTipList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    String? avatarUrl;

    // Si hay una imagen seleccionada, subirla a Supabase Storage primero
    if (_avatarPath != null) {
      final controller = ref.read(appControllerProvider.notifier);
      final imageFile = File(_avatarPath!);
      
      // Subir imagen y obtener URL
      avatarUrl = await controller.uploadAvatar(imageFile);
      
      if (avatarUrl == null) {
        // Mostrar error si falla la carga de imagen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo subir la imagen. Intenta nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Guardar perfil con la URL de Supabase (o null si no hay imagen)
    ref.read(appControllerProvider.notifier).completeProfile(
          displayName: _nameController.text,
          email: _emailController.text,
          role: _role,
          avatarPath: avatarUrl, // Ahora es la URL de Supabase, no ruta local
          bio: _bioController.text,
          specialty: _specialtyController.text,
        );
  }
}

class _ProfileTipList extends StatelessWidget {
  const _ProfileTipList();

  @override
  Widget build(BuildContext context) {
    final tips = <(IconData, String)>[
      (Icons.verified_user_outlined, 'Los docentes confían en perfiles completos antes de añadir contactos.'),
      (Icons.calendar_month_outlined, 'Tu rol define qué grupos y avisos recibirás primero.'),
      (Icons.image_outlined, 'Puedes actualizar tu avatar cuando quieras desde la pestaña de Perfil.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips
          .map(
            (tip) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: <Widget>[
                  Icon(tip.$1, size: 18, color: AppColors.brandPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(tip.$2, style: Theme.of(context).textTheme.bodySmall)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
