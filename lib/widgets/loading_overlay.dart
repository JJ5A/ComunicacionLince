import 'package:flutter/material.dart';

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.08),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
