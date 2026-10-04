import 'package:flutter/material.dart';

/// Se muestra mientras se restaura la sesión (AuthInitial).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 72,
              color: scheme.onPrimary,
              semanticLabel: 'Logo',
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: scheme.onPrimary),
          ],
        ),
      ),
    );
  }
}
