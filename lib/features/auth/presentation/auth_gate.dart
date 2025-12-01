import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/app_state.dart';
import '../../../state/providers.dart';
import '../../home/presentation/home_shell.dart';
import 'otp_screen.dart';
import 'phone_entry_screen.dart';
import 'profile_setup_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(appControllerProvider.select((state) => state.errorMessage), (previous, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      });
    });

    final appState = ref.watch(appControllerProvider);
    switch (appState.step) {
      case AuthStep.phoneEntry:
        return const PhoneEntryScreen();
      case AuthStep.otp:
        return const OtpScreen();
      case AuthStep.profile:
        return const ProfileSetupScreen();
      case AuthStep.home:
        return const HomeShell();
    }
  }
}
