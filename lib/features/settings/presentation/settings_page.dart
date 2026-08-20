import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../../dashboard/providers/analytics_providers.dart';
import '../../people/providers/people_providers.dart';

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
    final l10n = context.l10n;
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.setPin),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: InputDecoration(labelText: l10n.newPin),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
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
                    SnackBar(content: Text(l10n.pinSetSuccess)),
                  );
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  SwitchListTile(
                    title: Text(l10n.darkMode),
                    secondary: const Icon(Icons.dark_mode),
                    value: themeMode == ThemeMode.dark,
                    onChanged: (value) async {
                      await ref.read(themeModeProvider.notifier).setDark(value);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.language),
                    trailing: DropdownButton<Locale>(
                      value: locale,
                      items: [
                        DropdownMenuItem(
                          value: const Locale('en'),
                          child: Text(l10n.english),
                        ),
                        DropdownMenuItem(
                          value: const Locale('ar'),
                          child: Text(l10n.arabic),
                        ),
                      ],
                      onChanged: (value) async {
                        if (value != null) {
                          await ref
                              .read(localeProvider.notifier)
                              .setLocale(value);
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(l10n.notifications),
                    subtitle: Text(l10n.notificationsSubtitle),
                    secondary: const Icon(Icons.notifications),
                    value: notificationsEnabled,
                    onChanged: (value) async {
                      await ref
                          .read(notificationsEnabledProvider.notifier)
                          .set(value);
                      final notificationService =
                          ref.read(notificationServiceProvider);
                      if (value) {
                        final debts =
                            await ref.read(allDebtsProvider.future);
                        final balances =
                            await ref.read(balancesByDebtProvider.future);
                        await notificationService
                            .scheduleUpcomingDebtReminders(
                          debts: debts,
                          balances: balances,
                        );
                      } else {
                        await notificationService.cancelAllReminders();
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cloud_sync),
                    title: Text(l10n.cloudSync),
                    onTap: () async {
                      final userId =
                          Supabase.instance.client.auth.currentUser?.id;
                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.pleaseLoginFirst)),
                        );
                        return;
                      }

                      final service = ref.read(cloudSyncServiceProvider);
                      try {
                        final result = await service.syncAll();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.cloudSyncResult(
                                  result['persons'] ?? 0,
                                  result['debts'] ?? 0,
                                  result['payments'] ?? 0,
                                  result['ledger'] ?? 0,
                                ),
                              ),
                            ),
                          );
                        }
                        ref.invalidate(peopleProvider);
                        ref.invalidate(allDebtsProvider);
                        ref.invalidate(allPaymentsProvider);
                        ref.invalidate(balancesByDebtProvider);
                      } catch (e, st) {
                        if (mounted) {
                          showDialog<void>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text(
                                l10n.cloudSyncFailed(e.toString()),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$e'),
                                    const SizedBox(height: 12),
                                    Text(
                                      '$st',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext),
                                  child: Text(l10n.cancel),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(l10n.profile),
                    onTap: () => context.go('/profile'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: Text(l10n.setPin),
                    onTap: () => _showSetPinDialog(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: Text(l10n.backupRestore),
                    onTap: () => context.go('/backup'),
                  ),
                  const Divider(),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runIntegrityCheck,
                    icon: const Icon(Icons.fact_check),
                    label: Text(l10n.runIntegrity),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_violations != null)
                    if (_violations!.isEmpty)
                      Center(
                        child: Text(
                          l10n.allGood,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.green),
                        ),
                      )
                    else
                      ...(_violations!.map(
                        (v) => Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                            ),
                            title: Text(v.type.name),
                            subtitle: Text(v.message),
                          ),
                        ),
                      )),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(l10n.logout),
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}