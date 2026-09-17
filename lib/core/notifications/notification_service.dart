import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../observability/logging_service.dart';

/// ─── قنوات الإشعارات (Android) ───
class NotificationChannels {
  static const dueSoon = 'due_soon_v2';
  static const overdue = 'overdue_v2';
  static const payments = 'payments_v2';
  static const summary = 'summary_v2';
  static const general = 'general_v2';
}

/// ─── مفاتيح التخزين ───
class NotifPrefs {
  static const enabled = 'notifications_enabled';
  static const quietHoursEnabled = 'notif_quiet_hours_enabled';
  static const quietStart = 'notif_quiet_start';
  static const quietEnd = 'notif_quiet_end';
  static const remind7Days = 'notif_remind_7_days';
  static const remind3Days = 'notif_remind_3_days';
  static const remind1Day = 'notif_remind_1_day';
  static const remindOverdue = 'notif_remind_overdue';
  static const weeklySummary = 'notif_weekly_summary';
  static const paymentAlerts = 'notif_payment_alerts';
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final LoggingService _logger = LoggingService();
  bool _initialized = false;

  bool get _isSupported =>
      !Platform.isWindows &&
      !Platform.isLinux &&
      !Platform.isMacOS &&
      !kIsWeb;

  // ─── التهيئة ───

  Future<void> initialize() async {
    if (!_isSupported) {
      _initialized = false;
      return;
    }
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _plugin.initialize(initSettings);
      await _createChannels();
      await _requestPermissions();
      _initialized = true;
      _logger.info('NotificationService initialized');
    } catch (e) {
      _logger.error('Notification init failed', error: e);
      _initialized = false;
    }
  }

  Future<void> _createChannels() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;

    await androidImpl.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.dueSoon,
      'تذكيرات الاستحقاق',
      description: 'تنبيهات قبل موعد استحقاق الديون',
      importance: Importance.high,
    ));

    await androidImpl.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.overdue,
      'الديون المتأخرة',
      description: 'تنبيهات للديون التي تجاوزت موعد استحقاقها',
      importance: Importance.max,
    ));

    await androidImpl.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.payments,
      'الدفعات',
      description: 'إشعارات عند استلام دفعات جديدة',
      importance: Importance.defaultImportance,
    ));

    await androidImpl.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.summary,
      'الملخصات',
      description: 'ملخصات أسبوعية وشهرية',
      importance: Importance.low,
    ));

    await androidImpl.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.general,
      'عام',
      description: 'إشعارات عامة',
      importance: Importance.defaultImportance,
    ));
  }

  Future<void> _requestPermissions() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  // ─── قراءة التفضيلات ───

  Future<bool> _isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(NotifPrefs.enabled) ?? true;
  }

  Future<bool> _isQuietHoursEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(NotifPrefs.quietHoursEnabled) ?? false;
  }

  Future<int> _quietStart() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(NotifPrefs.quietStart) ?? (23 * 60);
  }

  Future<int> _quietEnd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(NotifPrefs.quietEnd) ?? (7 * 60);
  }

  Future<bool> _isInQuietHours() async {
    if (!await _isQuietHoursEnabled()) return false;

    final now = tz.TZDateTime.now(tz.local);
    final current = now.hour * 60 + now.minute;
    final start = await _quietStart();
    final end = await _quietEnd();

    if (start <= end) {
      return current >= start && current < end;
    } else {
      return current >= start || current < end;
    }
  }

  // ─── إشعار فوري ───

  Future<void> showNewDebtNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isSupported) return;
    if (!await _isEnabled()) return;
    if (await _isInQuietHours()) return;
    await _ensureInitialized();
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      NotificationChannels.general,
      'عام',
      channelDescription: 'إشعارات عامة',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      _logger.error('showNewDebtNotification failed', error: e);
    }
  }

  Future<void> showPaymentReceivedNotification({
    required int id,
    required String personName,
    required int amount,
  }) async {
    if (!_isSupported) return;
    if (!await _isEnabled()) return;
    if (await _isInQuietHours()) return;
    await _ensureInitialized();
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      NotificationChannels.payments,
      'الدفعات',
      channelDescription: 'إشعارات عند استلام دفعات',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    try {
      await _plugin.show(
        id,
        '💰 تم استلام دفعة',
        '$personName دفع $amount دينار',
        const NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      _logger.error('showPaymentReceivedNotification failed', error: e);
    }
  }

  // ─── الجدولة ───

  Future<void> scheduleReminderBeforeDays({
    required int id,
    required String title,
    required String body,
    required DateTime dueDate,
    required int daysBefore,
  }) async {
    if (!_isSupported) return;
    if (!await _isEnabled()) return;
    await _ensureInitialized();
    if (!_initialized) return;

    final target = dueDate.subtract(Duration(days: daysBefore));
    final scheduled = tz.TZDateTime(
      tz.local,
      target.year,
      target.month,
      target.day,
      9,
      0,
    );

    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      NotificationChannels.dueSoon,
      'تذكيرات الاستحقاق',
      channelDescription: 'تنبيهات قبل موعد استحقاق الديون',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      _logger.error('scheduleReminderBeforeDays failed', error: e);
    }
  }

  Future<void> scheduleUpcomingDebtReminders({
    required List<Debt> debts,
    required Map<DebtId, Money> balances,
  }) async {
    if (!_isSupported) return;
    if (!await _isEnabled()) return;
    await _ensureInitialized();
    if (!_initialized) return;

    await cancelAllReminders();

    final prefs = await SharedPreferences.getInstance();
    final remind7 = prefs.getBool(NotifPrefs.remind7Days) ?? false;
    final remind3 = prefs.getBool(NotifPrefs.remind3Days) ?? true;
    final remind1 = prefs.getBool(NotifPrefs.remind1Day) ?? true;
    final remindOverdue = prefs.getBool(NotifPrefs.remindOverdue) ?? true;

    final now = DateTime.now();

    for (final debt in debts) {
      final balance = balances[debt.id] ?? Money.zero;
      if (balance.amount <= 0) continue;
      if (debt.dueDate == null) continue;

      final dueDate = debt.dueDate!;
      final desc = debt.description ?? 'دين';
      final baseId = debt.id.value.hashCode;

      if (dueDate.isAfter(now)) {
        if (remind7) {
          await scheduleReminderBeforeDays(
            id: baseId + 7,
            title: '⏰ دين يستحق بعد أسبوع',
            body: '$desc - ${balance.amount} دينار',
            dueDate: dueDate,
            daysBefore: 7,
          );
        }
        if (remind3) {
          await scheduleReminderBeforeDays(
            id: baseId + 3,
            title: '⏰ دين يستحق بعد 3 أيام',
            body: '$desc - ${balance.amount} دينار',
            dueDate: dueDate,
            daysBefore: 3,
          );
        }
        if (remind1) {
          await scheduleReminderBeforeDays(
            id: baseId + 1,
            title: '🔔 دين يستحق غدًا',
            body: '$desc - ${balance.amount} دينار',
            dueDate: dueDate,
            daysBefore: 1,
          );
        }
      } else if (remindOverdue) {
        await _scheduleDailyOverdue(
          id: baseId,
          description: desc,
          balance: balance.amount,
        );
      }
    }
  }

  Future<void> _scheduleDailyOverdue({
    required int id,
    required String description,
    required int balance,
  }) async {
    if (!_isSupported || !_initialized) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10,
      0,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      NotificationChannels.overdue,
      'الديون المتأخرة',
      channelDescription: 'تنبيهات للديون المتأخرة',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
    );

    try {
      await _plugin.zonedSchedule(
        id,
        '⚠️ دين متأخر',
        '$description - $balance دينار',
        scheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      _logger.error('scheduleDailyOverdue failed', error: e);
    }
  }

  Future<void> scheduleWeeklySummary({
    required int activeDebts,
    required int overdueDebts,
    required int totalOutstanding,
  }) async {
    if (!_isSupported) return;
    if (!await _isEnabled()) return;
    await _ensureInitialized();
    if (!_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(NotifPrefs.weeklySummary) ?? true)) return;

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;

    await _plugin.cancel(999999);

    const androidDetails = AndroidNotificationDetails(
      NotificationChannels.summary,
      'الملخصات',
      channelDescription: 'ملخصات أسبوعية',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
    );

    try {
      await _plugin.zonedSchedule(
        999999,
        '📊 الملخص الأسبوعي',
        'لديك $activeDebts دين نشط، $overdueDebts متأخر، إجمالي $totalOutstanding دينار',
        _nextSunday9AM(),
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      _logger.error('scheduleWeeklySummary failed', error: e);
    }
  }

  tz.TZDateTime _nextSunday9AM() {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);
    while (next.weekday != DateTime.sunday || next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  // ─── الإلغاء ───

  Future<void> cancelAllReminders() async {
    if (!_isSupported) return;
    await _ensureInitialized();
    if (!_initialized) return;

    try {
      await _plugin.cancelAll();
    } catch (e) {
      _logger.error('cancelAllReminders failed', error: e);
    }
  }

  Future<void> cancelReminder(int id) async {
    if (!_isSupported) return;
    await _ensureInitialized();
    if (!_initialized) return;

    try {
      await _plugin.cancel(id);
    } catch (e) {
      _logger.error('cancelReminder failed', error: e);
    }
  }
}