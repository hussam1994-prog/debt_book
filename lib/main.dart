import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/lock_screen.dart';
import 'app/router.dart';
import 'core/notifications/notification_provider.dart';
import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/dashboard/providers/analytics_providers.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DebtBookApp()));
}

class DebtBookApp extends ConsumerStatefulWidget {
  const DebtBookApp({super.key});

  @override
  ConsumerState<DebtBookApp> createState() => _DebtBookAppState();
}

class _DebtBookAppState extends ConsumerState<DebtBookApp> {
  bool _showSplash = true;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });

        // فحص وجود PIN بعد السبلاش
        _refreshLockState();

        // تشغيل النسخ الاحتياطي التلقائي في الخلفية
        Future.microtask(() async {
          try {
            await ref.read(backupServiceProvider).autoBackupIfNeeded();
          } catch (_) {}
        });
      }
    });
  }

  Future<void> _refreshLockState() async {
    final hasPin = await ref.read(securityServiceProvider).hasPin();
    if (mounted) {
      setState(() {
        _isLocked = hasPin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final notificationService = ref.read(notificationServiceProvider);

    // جدولة أو إلغاء الإشعارات حسب التفضيل
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

    // 1) السبلاش
    if (_showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: const SplashScreen(),
      );
    }

    // 2) قفل PIN
    if (_isLocked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
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
        home: LockScreen(
          onUnlocked: () {
            setState(() {
              _isLocked = false;
            });
          },
        ),
      );
    }

    // 3) التطبيق الرئيسي
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