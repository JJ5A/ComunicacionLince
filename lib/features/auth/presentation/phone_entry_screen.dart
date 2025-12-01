import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/providers.dart';
import '../../../theme/design_tokens.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: AppDecorations.heroBackground,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Chip(
                      avatar: const Icon(Icons.bolt, color: AppColors.brandSecondary),
                      label: Text('TecNM Celaya', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Comunicación Lince',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Mensajería segura entre docentes, tutores y estudiantes. Comienza verificando tu número institucional.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.lg * 2),
                      topRight: Radius.circular(AppRadius.lg * 2),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Verifica tu identidad',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Solo números institucionales autorizados reciben avisos oficiales y acceso al directorio TecNM.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Número celular TecNM',
                                    helperText: 'Formato: +52 461 123 4567 (10 dígitos)',
                                    hintText: '+52 461 123 4567',
                                    prefixIcon: Icon(Icons.phone_android_outlined),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                FilledButton.icon(
                                  onPressed: appState.isLoading
                                      ? null
                                      : () => ref.read(appControllerProvider.notifier).sendVerificationCode(_phoneController.text),
                                  icon: appState.isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.sms_outlined),
                                  label: const Text('Enviar código de verificación'),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: const <Widget>[
                                    Icon(Icons.verified_user, color: AppColors.brandSecondary, size: 18),
                                    SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Protegido con Firebase Auth y App Check. Los códigos expiran en 60 segundos.',
                                        style: TextStyle(color: AppColors.textMuted),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: const <Widget>[
                            _BenefitChip(icon: Icons.forum_outlined, label: 'Chats cifrados'),
                            _BenefitChip(icon: Icons.groups_3_outlined, label: 'Grupos académicos'),
                            _BenefitChip(icon: Icons.campaign_outlined, label: 'Avisos oficiales'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppColors.brandPrimary),
      label: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.08),
    );
  }
}
