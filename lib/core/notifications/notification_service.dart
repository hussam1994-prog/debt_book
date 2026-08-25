import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:domain/domain.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _isSupported =>
      !Platform.isWindows &&
      !Platform.isLinux &&
      !Platform.isMacOS &&
      !kIsWeb;

  Future<void> initialize() async {
    if (!_isSupported) {
      _initialized = false;
      return;
    }
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _plugin.initialize(initSettings);

      // ✅ طلب صلاحية الإشعارات على أندرويد 13+
      await _requestPermissions();

      _initialized = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
      _initialized = false;
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// إشعار فوري عند إضافة دين
  Future<void> showNewDebtNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isSupported) return;
    await _ensureInitialized();
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'debt_notifications',
      'Debt Notifications',
      channelDescription: 'Notifications for debts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Show new debt notification failed: $e');
    }
  }

  /// جدولة تذكير قبل يوم من الاستحقاق
  Future<void> scheduleDueSoonNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dueDate,
  }) async {
    await scheduleReminderBeforeDays(
      id: id,
      title: title,
      body: body,
      dueDate: dueDate,
      daysBefore: 1,
    );
  }

  /// جدولة تذكير قبل أيام محددة من الاستحقاق
  Future<void> scheduleReminderBeforeDays({
    required int id,
    required String title,
    required String body,
    required DateTime dueDate,
    required int daysBefore,
  }) async {
    if (!_isSupported) return;
    await _ensureInitialized();
    if (!_initialized) return;

    final scheduledDate = tz.TZDateTime.from(
      dueDate.subtract(Duration(days: daysBefore)),
      tz.local,
    );

    const androidDetails = AndroidNotificationDetails(
      'due_soon',
      'Due Soon Reminders',
      channelDescription: 'Reminders for upcoming debts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Schedule reminder before days failed: $e');
    }
  }

  /// جدولة تذكير للديون القادمة خلال 7 أيام
  Future<void> scheduleUpcomingDebtReminders({
    required List<Debt> debts,
    required Map<DebtId, Money> balances,
  }) async {
    if (!_isSupported) return;
    await _ensureInitialized();
    if (!_initialized) return;

    await cancelAllReminders();

    final now = DateTime.now();
    final upcoming = debts.where((debt) {
      final balance = balances[debt.id] ?? Money.zero;
      if (balance.amount <= 0) return false;
      if (debt.dueDate == null) return false;
      return debt.dueDate!.isAfter(now) &&
          debt.dueDate!.isBefore(now.add(const Duration(days: 7)));
    }).toList();

    for (var i = 0; i < upcoming.length; i++) {
      final debt = upcoming[i];
      await scheduleDueSoonNotification(
        id: debt.hashCode,
        title: 'Debt Due Soon',
        body: debt.description ?? 'Debt #${debt.id.value.substring(0, 8)}',
        dueDate: debt.dueDate!,
      );
    }
  }

  Future<void> cancelAllReminders() async {
    if (!_isSupported) return;
    await _ensureInitialized();
    if (!_initialized) return;

    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Cancel all reminders failed: $e');
    }
  }

  Future<void> cancelReminder(int id) async {
    if (!_isSupported) return;
    await _ensureInitialized();
    if (!_initialized) return;

    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('Cancel reminder failed: $e');
    }
  }
}