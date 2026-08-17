import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  List<IntegrityViolation>? _violations;
  bool _isLoading = false;

  Future<void> _runIntegrityCheck() async {
    final logger = ref.read(loggingServiceProvider);
    logger.info('Starting ledger integrity check');

    setState(() {
      _isLoading = true;
      _violations = null;
    });

    final checker = ref.read(ledgerIntegrityCheckerProvider);
    try {
      final result = await checker.check();
      logger.info('Integrity check completed. Violations: ${result.length}');
      setState(() {
        _violations = result;
      });
    } catch (e) {
      logger.error('Integrity check failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSetPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set PIN'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'New PIN'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = pinController.text;
                if (pin.length < 4) return;
                final security = ref.read(securityServiceProvider);
                await security.setPin(pin);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN set successfully')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change PIN'),
              onTap: () => _showSetPinDialog(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup & Restore'),
              onTap: () => context.go('/backup'),
            ),
            const Divider(),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runIntegrityCheck,
              icon: const Icon(Icons.fact_check),
              label: const Text('Run Ledger Integrity Check'),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_violations != null)
              Expanded(
                child: _violations!.isEmpty
                    ? const Center(
                        child: Text(
                          'All good! No violations found.',
                          style: TextStyle(fontSize: 16, color: Colors.green),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _violations!.length,
                        itemBuilder: (context, index) {
                          final v = _violations![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              title: Text(v.type.name),
                              subtitle: Text(v.message),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}