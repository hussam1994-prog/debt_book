import 'dart:async';
import 'dart:io';

import 'package:domain/domain.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/lock_screen.dart';
import 'app/router.dart';
import 'core/auth/user_id_store.dart';
import 'core/cloud/supabase_config.dart';
import 'core/database/tables/outbox_table.dart';
import 'core/notifications/fcm_service.dart';
import 'core/notifications/notification_action_handler.dart';
import 'core/notifications/notification_provider.dart';
import 'core/providers.dart';
import 'core/sync/background_sync.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/auth_page.dart';
import 'features/dashboard/providers/analytics_providers.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/people/providers/people_providers.dart';
import 'features/people/providers/person_tag_provider.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await BackgroundSync.initialize();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const ProviderScope(child: DebtBookApp()));
}

class DebtBookApp extends ConsumerStatefulWidget {
  const DebtBookApp({super.key});

  @override
  ConsumerState<DebtBookApp> createState() => _DebtBookAppState();
}

class _DebtBookAppState extends ConsumerState<DebtBookApp>
    with WidgetsBindingObserver {
  bool _showSplash = true;
  bool _isLocked = false;
  bool _isHandlingUserData = false;
  bool? _onboardingCompleted;
  String? _lastSyncedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _loadOnboardingState();

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSplash = false);
        _refreshLockState();
        _handleUserData();
      }
    });
  }

  Future<void> _loadOnboardingState() async {
    final completed = await isOnboardingCompleted();
    if (mounted) {
      setState(() => _onboardingCompleted = completed);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(syncServiceProvider).stop();
    FCMService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    ref.read(syncServiceProvider).updateLifecycle(state);
  }

  Future<void> _refreshLockState() async {
    final hasPin = await ref.read(securityServiceProvider).hasPin();
    if (mounted) {
      setState(() => _isLocked = hasPin);
    }
  }

  Future<bool> _createSafetyBackup() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(docsDir.path, 'debt_book.sqlite');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) return true;

      final backupDir = Directory(p.join(docsDir.path, 'backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath =
          p.join(backupDir.path, 'safety_backup_$timestamp.sqlite');

      await dbFile.copy(backupPath);
      return true;
    } catch (e) {
      ref.read(loggingServiceProvider).error('Safety backup failed', error: e);
      return false;
    }
  }

  Future<bool> _isOnline() async {
    try {
      await Supabase.instance.client
          .from('persons')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isOutboxEmpty() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final all = await db.select(db.outboxTable).get();
      return !all.any((item) =>
          item.status == OutboxStatus.pending ||
          item.status == OutboxStatus.failed);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeClearData({
    required String oldUserId,
    required String newUserId,
  }) async {
    final logger = ref.read(loggingServiceProvider);
    logger.info('User changed: ${oldUserId.substring(0, 8)} → '
        '${newUserId.substring(0, 8)}');

    final backupOk = await _createSafetyBackup();
    if (!backupOk) return false;

    final online = await _isOnline();
    if (!online) {
      logger.info('Safe clear skipped: offline');
      return false;
    }

    final outboxEmpty = await _isOutboxEmpty();
    if (!outboxEmpty) {
      logger.info('Safe clear skipped: pending outbox items');
      return false;
    }

    logger.info('Clearing local data...');
    final db = ref.read(appDatabaseProvider);
    await db.clearAllData();

    try {
      final syncService = ref.read(syncServiceProvider);
      await ref.read(cloudSyncServiceProvider).fullManualSync(
            pushOutbox: () => syncService.syncNow(),
          );
      logger.info('Safe clear + pull completed');
      return true;
    } catch (e) {
      logger.error('Pull after clear failed', error: e);
      return false;
    }
  }

  Future<void> _handleUserData() async {
    if (_isHandlingUserData) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    _isHandlingUserData = true;
    try {
      final userIdStore = UserIdStore();
      final storedUserId = await userIdStore.getLastUserId();

      // حالة 1: أول تسجيل دخول
      if (storedUserId == null) {
        await userIdStore.saveUserId(currentUserId);
        _lastSyncedUserId = currentUserId;
        _startSyncService();
        await _loadTags();
        await _initFCM();
        return;
      }

      // حالة 2: نفس المستخدم
      if (storedUserId == currentUserId) {
        _lastSyncedUserId = currentUserId;
        _startSyncService();
        await _loadTags();
        await _initFCM();
        return;
      }

      // حالة 3: مستخدم مختلف
      final clearOk = await _safeClearData(
        oldUserId: storedUserId,
        newUserId: currentUserId,
      );

      if (clearOk) {
        await userIdStore.saveUserId(currentUserId);
        _lastSyncedUserId = currentUserId;
        ref.invalidate(peopleProvider);
        ref.invalidate(allDebtsProvider);
      }

      _startSyncService();
      await _loadTags();
      await _initFCM();
    } finally {
      _isHandlingUserData = false;
    }
  }

  Future<void> _loadTags() async {
    try {
      await ref.read(personTagProvider.notifier).load();
    } catch (e) {
      ref.read(loggingServiceProvider).error('Failed to load tags', error: e);
    }
  }

  void _startSyncService() {
    try {
      ref.read(syncServiceProvider).start();
    } catch (_) {}

    try {
      BackgroundSync.registerPeriodicSync();
    } catch (_) {}
  }

  Future<void> _initFCM() async {
    try {
      final fcmService = FCMService();
      final logger = ref.read(loggingServiceProvider);

      fcmService.onNotificationTap = (route) {
        if (route != null && route.isNotEmpty) {
          try {
            router.go(route);
          } catch (e) {
            logger.error('FCM navigation error', error: e);
          }
        }
      };

      fcmService.onNotificationAction = (action, data) {
        NotificationActionHandler.handle(
          action: action,
          data: data,
          ref: ref,
        );
      };

      await fcmService.initialize();
    } catch (e) {
      ref.read(loggingServiceProvider).error('FCM init failed', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final notificationService = ref.read(notificationServiceProvider);

    Future.microtask(() async {
      if (notificationsEnabled) {
        try {
          final debts = await ref.read(allDebtsProvider.future);
          final balances = await ref.read(balancesByDebtProvider.future);

          await notificationService.scheduleUpcomingDebtReminders(
            debts: debts,
            balances: balances,
            locale: locale,
          );

          final now = DateTime.now();
          int active = 0, overdue = 0, totalOutstanding = 0;
          for (final debt in debts) {
            final balance = balances[debt.id] ?? Money.zero;
            if (balance.amount <= 0) continue;
            totalOutstanding += balance.amount;
            if (debt.dueDate != null && debt.dueDate!.isBefore(now)) {
              overdue++;
            } else {
              active++;
            }
          }
          await notificationService.scheduleWeeklySummary(
            activeDebts: active,
            overdueDebts: overdue,
            totalOutstanding: totalOutstanding,
            locale: locale,
          );
        } catch (_) {}
      } else {
        await notificationService.cancelAllReminders();
      }
    });

    if (_onboardingCompleted == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (_onboardingCompleted == false) {
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
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: OnboardingPage(
          onComplete: () => setState(() => _onboardingCompleted = true),
        ),
      );
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final isLoggedIn =
            Supabase.instance.client.auth.currentUser != null;

        if (!isLoggedIn) {
          ref.read(syncServiceProvider).stop();
          _isHandlingUserData = false;
          _lastSyncedUserId = null;

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
            supportedLocales: const [Locale('en'), Locale('ar')],
            home: const AuthPage(),
          );
        }

        final currentUserId =
            Supabase.instance.client.auth.currentUser?.id;
        if (_lastSyncedUserId != currentUserId) {
          Future.microtask(() => _handleUserData());
        }

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
            supportedLocales: const [Locale('en'), Locale('ar')],
            home: LockScreen(
              onUnlocked: () => setState(() => _isLocked = false),
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
          supportedLocales: const [Locale('en'), Locale('ar')],
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}