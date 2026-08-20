import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/lock_screen.dart';
import 'app/router.dart';
import 'core/cloud/supabase_config.dart';
import 'core/notifications/notification_provider.dart';
import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/auth_page.dart';
import 'features/dashboard/providers/analytics_providers.dart';
import 'features/people/providers/people_providers.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

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
  bool _autoSyncDone = false; // ✅ يمنع التكرار

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
        _refreshLockState();

        // ✅ نسخ احتياطي تلقائي مرة واحدة فقط
        Future.microtask(() async {
          try {
            await ref.read(backupServiceProvider).autoBackupIfNeeded();
          } catch (_) {}

          // ✅ مزامنة تلقائية مرة واحدة فقط
          if (!_autoSyncDone &&
              Supabase.instance.client.auth.currentUser != null) {
            _autoSyncDone = true;
            try {
              await ref.read(cloudSyncServiceProvider).syncAll();
              ref.invalidate(peopleProvider);
              ref.invalidate(allDebtsProvider);
            } catch (_) {}
          }
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

    // ✅ جدولة الإشعارات فقط عند الحاجة (بدون تكرار)
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

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final isLoggedIn =
            Supabase.instance.client.auth.currentUser != null;

        if (!isLoggedIn) {
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
            home: const AuthPage(),
          );
        }

        // ✅ بدء Realtime مرة واحدة فقط
        Future.microtask(() {
          try {
            ref.read(realtimeServiceProvider).start();
          } catch (_) {}
        });

        if (_showSplash) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            home: const SplashScreen(),
          );
        }

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
      },
    );
  }
}