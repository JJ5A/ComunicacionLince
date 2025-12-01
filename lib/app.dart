import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/auth_gate.dart';
import 'theme/app_theme.dart';

class ComunicacionLinceApp extends ConsumerWidget {
  const ComunicacionLinceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Comunicacion Lince',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}
