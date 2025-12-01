import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/providers.dart';
import '../../../theme/design_tokens.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Autenticación en dos pasos')),
      body: DecoratedBox(
        decoration: AppDecorations.surfaceBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Introduce el código enviado',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Enviamos un SMS a ${appState.pendingPhone ?? 'tu número registrado'}. Este código expira en 60 segundos.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(letterSpacing: 8, fontSize: 28, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            counterText: '',
                            labelText: 'Código de 6 dígitos',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: appState.isLoading
                              ? null
                              : () => ref.read(appControllerProvider.notifier).verifyCode(_codeController.text),
                          icon: appState.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.verified_outlined),
                          label: const Text('Validar código'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton(
                          onPressed: appState.isLoading
                              ? null
                              : () => ref
                                  .read(appControllerProvider.notifier)
                                  .sendVerificationCode(appState.pendingPhone ?? ''),
                          child: const Text('Reenviar código'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.md,
                  children: const <Widget>[
                    _OtpTip(icon: Icons.lock_outline, message: 'Los códigos utilizan App Check para evitar fraude.'),
                    _OtpTip(icon: Icons.support_agent_outlined, message: 'Si no llega el SMS, verifica la señal o contacta soporte TecNM.'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpTip extends StatelessWidget {
  const _OtpTip({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppColors.brandPrimary),
      label: SizedBox(width: 220, child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      backgroundColor: Colors.white,
    );
  }
}
