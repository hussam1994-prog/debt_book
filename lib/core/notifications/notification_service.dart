import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:domain/domain.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// هل المنصة الحالية تدعم الإشعارات المحلية؟
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
      _initialized = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
      _initialized = false;
    }
  }

  Future<void> scheduleDebtReminder({
    required int id,
    required String title,
    required String body,
    required DateTime dueDate,
  }) async {
    if (!_isSupported) return;
    await initialize();
    if (!_initialized) return;

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      dueDate.subtract(const Duration(days: 2)),
      tz.local,
    );

    const androidDetails = AndroidNotificationDetails(
      'debt_reminders',
      'Debt Reminders',
      channelDescription: 'Reminders for upcoming debt due dates',
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
      debugPrint('Schedule failed: $e');
    }
  }

  Future<void> scheduleUpcomingDebtReminders({
    required List<Debt> debts,
    required Map<DebtId, Money> balances,
  }) async {
    if (!_isSupported) return;
    await initialize();
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
      await scheduleDebtReminder(
        id: debt.hashCode,
        title: 'Debt Due Soon',
        body: debt.description ?? 'Debt #${debt.id.value.substring(0, 8)}',
        dueDate: debt.dueDate!,
      );
    }
  }

  Future<void> cancelAllReminders() async {
    if (!_isSupported) return;
    await initialize();
    if (!_initialized) return;

    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Cancel all failed: $e');
    }
  }

  Future<void> cancelReminder(int id) async {
    if (!_isSupported) return;
    await initialize();
    if (!_initialized) return;

    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('Cancel failed: $e');
    }
  }
}