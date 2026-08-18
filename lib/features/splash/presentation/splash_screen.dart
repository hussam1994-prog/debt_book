import 'package:flutter/material.dart';

import '../../../core/localization/l10n_extension.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.appTitle,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}