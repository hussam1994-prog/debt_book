import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../observability/logging_service.dart';

/// ─── قنوات الإشعارات (Android) ───
///
/// ⚠️ ملاحظة: أسماء القنوات تظهر في إعدادات Android مرة واحدة فقط.
/// نستخدم أسماء ثنائية اللغة (عربي + إنجليزي) لتوضيح الغرض.
class NotificationChannels {
  static const dueSoon = 'due_soon_v2';
  static const overdue = 'overdue_v2';
  static const payments = 'payments_v2';
  static const summary = 'summary_v2';
  static const general = 'general_v2';

  // أسماء القنوات (ثابتة — لا تتغير بعد التثبيت)
  static const dueSoonName = 'تذكيرات الاستحقاق / Due Reminders';
  static const overdueName = 'الديون المتأخرة / Overdue Debts';
  static const paymentsName = 'الدفعات / Payments';
  static const summaryName = 'الملخصات / Summaries';
  static const generalName = 'عام / General';
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

/// Helper للحصول على نص مترجم بدون BuildContext.
///
/// يستخدم [Locale] لعرض النصوص العربية أو الإنجليزية.
class NotificationTexts {
  NotificationTexts._();

  static bool _isAr(Locale locale) => locale.languageCode == 'ar';

  static String paymentReceivedTitle(Locale locale) =>
      _isAr(locale) ? '💰 تم استلام دفعة' : '💰 Payment Received';

  static String paymentReceivedBody(Locale locale, String name, int amount) =>
      _isAr(locale)
          ? '$name دفع $amount دينار'
          : '$name paid $amount IQD';

  static String newDebtTitle(Locale locale) =>
      _isAr(locale) ? 'دين جديد' : 'New Debt';

  static String newDebtBody(Locale locale, int amount) => _isAr(locale)
      ? 'تمت إضافة دين بقيمة $amount دينار'
      : 'A debt of $amount IQD was added';

  static String debtDueInWeek(Locale locale) =>
      _isAr(locale) ? '⏰ دين يستحق بعد أسبوع' : '⏰ Debt due in a week';

  static String debtDueInThreeDays(Locale locale) =>
      _isAr(locale) ? '⏰ دين يستحق بعد 3 أيام' : '⏰ Debt due in 3 days';

  static String debtDueTomorrow(Locale locale) =>
      _isAr(locale) ? '🔔 دين يستحق غدًا' : '🔔 Debt due tomorrow';

  static String debtOverdueTitle(Locale locale) =>
      _isAr(locale) ? '⚠️ دين متأخر' : '⚠️ Overdue Debt';

  static String weeklySummaryTitle(Locale locale) =>
      _isAr(locale) ? '📊 الملخص الأسبوعي' : '📊 Weekly Summary';

  static String weeklySummaryBody(
    Locale locale, {
    required int active,
    required int overdue,
    required int total,
  }) =>
      _isAr(locale)
          ? 'لديك $active دين نشط، $overdue متأخر، إجمالي $total دينار'
          : 'You have $active active debts, $overdue overdue, total $total IQD';

  static String debtFallback(Locale locale) =>
      _isAr(locale) ? 'دين' : 'Debt';

  static String amountWithDinar(Locale locale, int amount) => _isAr(locale)
      ? '$amount دينار'
      : '$amount IQD';
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
      NotificationChannels.dueSoonName,
      description: 'تنبيهات قبل موعد استحقاق الديون / Due reminders',
      importance: Importance.high,
    ));

    await androidImpl.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.overdue,
      NotificationChannels.overdueName,
      description: 'تنبيهات للديون المتأخرة / Overdue notifications',
      importance: Importance.max,
    ));

    await androidImpl.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.payments,
      NotificationChannels.paymentsName,
      description: 'إشعارات عند استلام دفعات جديدة / New payment alerts',
      importance: Importance.defaultImportance,
    ));

    await androidImpl.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.summary,
      NotificationChannels.summaryName,
      description: 'ملخصات أسبوعية / Weekly summaries',
      importance: Importance.low,
    ));

    await androidImpl.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.general,
      NotificationChannels.generalName,
      description: 'إشعارات عامة / General notifications',
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
      NotificationChannels.generalName,
      channelDescription: 'إشعارات عامة / General notifications',
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

  /// إشعار استلام دفعة جديدة.
  ///
  /// ⚠️ يستخدم [NotificationTexts] لأن هذا service لا يملك BuildContext.
  Future<void> showPaymentReceivedNotification({
    required int id,
    required String personName,
    required int amount,
    required Locale locale,
  }) async {
    if (!_isSupported) return;
    if (!await _isEnabled()) return;
    if (await _isInQuietHours()) return;
    await _ensureInitialized();
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      NotificationChannels.payments,
      NotificationChannels.paymentsName,
      channelDescription: 'إشعارات عند استلام دفعات / Payment alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    try {
      await _plugin.show(
        id,
        NotificationTexts.paymentReceivedTitle(locale),
        NotificationTexts.paymentReceivedBody(locale, personName, amount),
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
      NotificationChannels.dueSoonName,
      channelDescription: 'تنبيهات قبل موعد استحقاق الديون / Due reminders',
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

  /// جدولة تذكيرات الديون القادمة.
  ///
  /// ⚠️ يتطلب [locale] لتوليد النصوص المترجمة.
  Future<void> scheduleUpcomingDebtReminders({
    required List<Debt> debts,
    required Map<DebtId, Money> balances,
    required Locale locale,
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
      final desc = debt.description ?? NotificationTexts.debtFallback(locale);
      final baseId = debt.id.value.hashCode;
      final amountText = NotificationTexts.amountWithDinar(locale, balance.amount);

      if (dueDate.isAfter(now)) {
        if (remind7) {
          await scheduleReminderBeforeDays(
            id: baseId + 7,
            title: NotificationTexts.debtDueInWeek(locale),
            body: '$desc - $amountText',
            dueDate: dueDate,
            daysBefore: 7,
          );
        }
        if (remind3) {
          await scheduleReminderBeforeDays(
            id: baseId + 3,
            title: NotificationTexts.debtDueInThreeDays(locale),
            body: '$desc - $amountText',
            dueDate: dueDate,
            daysBefore: 3,
          );
        }
        if (remind1) {
          await scheduleReminderBeforeDays(
            id: baseId + 1,
            title: NotificationTexts.debtDueTomorrow(locale),
            body: '$desc - $amountText',
            dueDate: dueDate,
            daysBefore: 1,
          );
        }
      } else if (remindOverdue) {
        await _scheduleDailyOverdue(
          id: baseId,
          description: desc,
          balance: balance.amount,
          locale: locale,
        );
      }
    }
  }

  Future<void> _scheduleDailyOverdue({
    required int id,
    required String description,
    required int balance,
    required Locale locale,
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
      NotificationChannels.overdueName,
      channelDescription: 'تنبيهات للديون المتأخرة / Overdue alerts',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
    );

    final amountText = NotificationTexts.amountWithDinar(locale, balance);

    try {
      await _plugin.zonedSchedule(
        id,
        NotificationTexts.debtOverdueTitle(locale),
        '$description - $amountText',
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
    required Locale locale,
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
      NotificationChannels.summaryName,
      channelDescription: 'ملخصات أسبوعية / Weekly summaries',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
    );

    try {
      await _plugin.zonedSchedule(
        999999,
        NotificationTexts.weeklySummaryTitle(locale),
        NotificationTexts.weeklySummaryBody(
          locale,
          active: activeDebts,
          overdue: overdueDebts,
          total: totalOutstanding,
        ),
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