import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    // نحدد المنطقة الزمنية يدويًا (بغداد) — يمكن تغييرها لاحقًا حسب الدولة
    tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  Future<void> scheduleDebtReminder({
    required int id,
    required String title,
    required String body,
    required DateTime dueDate,
  }) async {
    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.from(dueDate.subtract(const Duration(days: 2)), tz.local);

    const androidDetails = AndroidNotificationDetails(
      'debt_reminders',
      'Debt Reminders',
      channelDescription: 'Reminders for upcoming debt due dates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

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
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }
}