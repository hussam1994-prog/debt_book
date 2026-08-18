import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/l10n_extension.dart';
import '../core/providers.dart';

class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback? onUnlocked;
  const LockScreen({super.key, this.onUnlocked});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final security = ref.read(securityServiceProvider);
    final pin = _pinController.text;

    final verified = await security.verifyPin(pin);
    if (!mounted) return;

    if (verified) {
      widget.onUnlocked?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.wrongPin)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.locked)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(labelText: l10n.enterPin),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _unlock,
              child: Text(l10n.unlock),
            ),
          ],
        ),
      ),
    );
  }
}