import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/google_auth_service.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/notifications/fcm_service.dart';
import '../../../core/providers.dart';
import '../../../core/sync/background_sync.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../../dashboard/providers/analytics_providers.dart';
import '../../onboarding/providers/onboarding_provider.dart';
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
          SnackBar(content: Text(context.l10n.errorGeneric(e.toString()))),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runCleanup() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cleanupViolations),
        content: Text(l10n.cleanupConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.cleanupYes),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final checker = ref.read(ledgerIntegrityCheckerProvider);
    try {
      final fixed = await checker.cleanupViolations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cleanupSuccess(fixed))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric(e.toString()))),
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

  // ─── تبديل حساب Google ───
  Future<void> _confirmSwitchAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.switchGoogleAccount),
        content: Text(context.l10n.switchAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.switchAccount),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(googleAuthServiceProvider).switchAccount();
    } on GoogleAuthException catch (e) {
      if (e.type == GoogleAuthErrorType.cancelled) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.localizedMessage(context.l10n))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.switchAccountFailed(e.toString())),
          ),
        );
      }
    }
  }

  // ─── إعادة تعيين الإعدادات (بدون حذف البيانات) ───
  Future<void> _confirmResetSettings() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.resetSettings),
        content: Text(context.l10n.resetSettingsSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.resetAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      // 1) الثيم → فاتح (افتراضي)
      await ref.read(themeModeProvider.notifier).setDark(false);

      // 2) اللغة → العربية (افتراضي التطبيق)
      await ref.read(localeProvider.notifier).setLocale(const Locale('ar'));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.resetSettingsDone),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.resetSettingsFailed(e.toString())),
        ),
      );
    }
  }

  // ─── المزامنة السحابية ───
  Future<void> _runCloudSync() async {
    final l10n = context.l10n;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseLoginFirst)),
      );
      return;
    }

    final service = ref.read(cloudSyncServiceProvider);
    final syncService = ref.read(syncServiceProvider);
    try {
      final result = await service.fullManualSync(
        pushOutbox: () => syncService.syncNow(),
      );

      if (!mounted) return;
      if (result.wasOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.cloudSyncResult(
                result.localCounts['debts'] ?? 0,
                result.localCounts['installments'] ?? 0,
                result.localCounts['ledger'] ?? 0,
                result.localCounts['payments'] ?? 0,
                result.localCounts['persons'] ?? 0,
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.offlineDataSaved(result.localCounts['persons'] ?? 0),
            ),
          ),
        );
      }
      ref.invalidate(peopleProvider);
      ref.invalidate(allDebtsProvider);
      ref.invalidate(allPaymentsProvider);
      ref.invalidate(balancesByDebtProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cloudSyncFailed(e.toString()))),
      );
    }
  }

  // ─── تسجيل الخروج ───
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

    // ✅ إزالة FCM token قبل تسجيل الخروج
    try {
      await FCMService().removeToken();
    } catch (_) {}

    // ✅ إلغاء المزامنة في الخلفية
    try {
      await BackgroundSync.cancel();
    } catch (_) {}

    // ✅ تسجيل خروج كامل
    await ref.read(googleAuthServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

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
                  // ─── المظهر ───
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

                  // ─── الإشعارات ───
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(l10n.notificationSettings),
                    subtitle: Text(l10n.notificationSettingsSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/notification-settings'),
                  ),
                  const Divider(),

                  // ─── لوحة المزامنة ───
                  ListTile(
                    leading: const Icon(Icons.sync_alt),
                    title: Text(l10n.syncDashboard),
                    subtitle: Text(l10n.syncDashboardSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/sync-dashboard'),
                  ),
                  const Divider(),

                  // ─── المزامنة السحابية ───
                  ListTile(
                    leading: const Icon(Icons.cloud_sync),
                    title: Text(l10n.cloudSync),
                    onTap: _runCloudSync,
                  ),
                  const Divider(),

                  // ✅ تبديل حساب Google
                  ListTile(
                    leading: const Icon(Icons.switch_account),
                    title: Text(l10n.switchGoogleAccount),
                    subtitle: Text(l10n.switchGoogleAccountSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _confirmSwitchAccount,
                  ),
                  const Divider(),

                  // ✅ إعادة عرض الشرح
                  ListTile(
                    leading: const Icon(Icons.school),
                    title: Text(l10n.showTutorialAgain),
                    subtitle: Text(l10n.showTutorialAgainSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await ref
                          .read(onboardingCompletedProvider.notifier)
                          .reset();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.tutorialWillAppear),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                  const Divider(),

                  // ✅ إعادة تعيين الإعدادات
                  ListTile(
                    leading: const Icon(
                      Icons.settings_backup_restore,
                      color: Colors.orange,
                    ),
                    title: Text(l10n.resetSettings),
                    subtitle: Text(l10n.resetSettingsShort),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _confirmResetSettings,
                  ),
                  const Divider(),

                  // ─── الملف الشخصي ───
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(l10n.profile),
                    onTap: () => context.go('/profile'),
                  ),
                  const Divider(),

                  // ─── PIN ───
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: Text(l10n.setPin),
                    onTap: () => _showSetPinDialog(context),
                  ),
                  const Divider(),

                  // ─── النسخ الاحتياطي ───
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: Text(l10n.backupRestore),
                    onTap: () => context.go('/backup'),
                  ),
                  const Divider(),

                  // ─── فحص سلامة الدفتر ───
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runIntegrityCheck,
                    icon: const Icon(Icons.fact_check),
                    label: Text(l10n.runIntegrity),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _runCleanup,
                    icon: const Icon(Icons.cleaning_services),
                    label: Text(l10n.cleanupViolations),
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

                  // ─── تسجيل الخروج ───
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