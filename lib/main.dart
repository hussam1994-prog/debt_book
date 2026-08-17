import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/notifications/notification_provider.dart';
import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/dashboard/providers/analytics_providers.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DebtBookApp()));
}

class DebtBookApp extends ConsumerWidget {
  const DebtBookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final notificationService = ref.read(notificationServiceProvider);

    // جدولة أو إلغاء الإشعارات حسب التفعيل
    Future.microtask(() async {
      if (notificationsEnabled) {
        try {
          final debts = await ref.read(allDebtsProvider.future);
          final balances = await ref.read(balancesByDebtProvider.future);
          await notificationService.scheduleUpcomingDebtReminders(
            debts: debts,
            balances: balances,
          );
        } catch (_) {}
      } else {
        await notificationService.cancelAllReminders();
      }
    });

    return MaterialApp.router(
      title: 'Debt Book',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}