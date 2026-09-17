import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

/// ─── حالة إعدادات الإشعارات ───
class NotificationPrefs {
  final bool enabled;
  final bool quietHoursEnabled;
  final int quietStart; // دقائق من منتصف الليل
  final int quietEnd;
  final bool remind7Days;
  final bool remind3Days;
  final bool remind1Day;
  final bool remindOverdue;
  final bool weeklySummary;
  final bool paymentAlerts;

  const NotificationPrefs({
    this.enabled = true,
    this.quietHoursEnabled = false,
    this.quietStart = 23 * 60,
    this.quietEnd = 7 * 60,
    this.remind7Days = false,
    this.remind3Days = true,
    this.remind1Day = true,
    this.remindOverdue = true,
    this.weeklySummary = true,
    this.paymentAlerts = true,
  });

  NotificationPrefs copyWith({
    bool? enabled,
    bool? quietHoursEnabled,
    int? quietStart,
    int? quietEnd,
    bool? remind7Days,
    bool? remind3Days,
    bool? remind1Day,
    bool? remindOverdue,
    bool? weeklySummary,
    bool? paymentAlerts,
  }) {
    return NotificationPrefs(
      enabled: enabled ?? this.enabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStart: quietStart ?? this.quietStart,
      quietEnd: quietEnd ?? this.quietEnd,
      remind7Days: remind7Days ?? this.remind7Days,
      remind3Days: remind3Days ?? this.remind3Days,
      remind1Day: remind1Day ?? this.remind1Day,
      remindOverdue: remindOverdue ?? this.remindOverdue,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      paymentAlerts: paymentAlerts ?? this.paymentAlerts,
    );
  }
}

/// ─── مزود حالة الإشعارات ───
final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
  (ref) => NotificationPrefsNotifier(),
);

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  NotificationPrefsNotifier() : super(const NotificationPrefs());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationPrefs(
      enabled: prefs.getBool(NotifPrefs.enabled) ?? true,
      quietHoursEnabled:
          prefs.getBool(NotifPrefs.quietHoursEnabled) ?? false,
      quietStart: prefs.getInt(NotifPrefs.quietStart) ?? (23 * 60),
      quietEnd: prefs.getInt(NotifPrefs.quietEnd) ?? (7 * 60),
      remind7Days: prefs.getBool(NotifPrefs.remind7Days) ?? false,
      remind3Days: prefs.getBool(NotifPrefs.remind3Days) ?? true,
      remind1Day: prefs.getBool(NotifPrefs.remind1Day) ?? true,
      remindOverdue: prefs.getBool(NotifPrefs.remindOverdue) ?? true,
      weeklySummary: prefs.getBool(NotifPrefs.weeklySummary) ?? true,
      paymentAlerts: prefs.getBool(NotifPrefs.paymentAlerts) ?? true,
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotifPrefs.enabled, value);
  }

  Future<void> setQuietHoursEnabled(bool value) async {
    state = state.copyWith(quietHoursEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotifPrefs.quietHoursEnabled, value);
  }

  Future<void> setQuietHours({required int start, required int end}) async {
    state = state.copyWith(quietStart: start, quietEnd: end);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(NotifPrefs.quietStart, start);
    await prefs.setInt(NotifPrefs.quietEnd, end);
  }

  Future<void> setRemind7Days(bool value) async {
    state = state.copyWith(remind7Days: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotifPrefs.remind7Days, value);
  }

  Future<void> setRemind3Days(bool value) async {
    state = state.copyWith(remind3Days: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotifPrefs.remind3Days, value);
  }

  Future<void> setRemind1Day(bool value) async {
    state = state.copyWith(remind1Day: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotifPrefs.remind1Day, value);
  }

  Future<void> setRemindOverdue(bool value) async {
    state = state.copyWith(remindOverdue: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotifPrefs.remindOverdue, value);
  }

  Future<void> setWeeklySummary(bool value) async {
    state = state.copyWith(weeklySummary: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotifPrefs.weeklySummary, value);
  }

  Future<void> setPaymentAlerts(bool value) async {
    state = state.copyWith(paymentAlerts: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotifPrefs.paymentAlerts, value);
  }
}

// ─── Backward Compatibility ───
// احتفظ بالمزود القديم للتوافق مع الكود الموجود.

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsNotifier, bool>(
  (ref) => NotificationsNotifier(),
);

class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(true);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(NotifPrefs.enabled) ?? true;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotifPrefs.enabled, value);
  }
}

Future<bool> loadNotificationsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(NotifPrefs.enabled) ?? true;
}

Future<void> saveNotificationsEnabled(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(NotifPrefs.enabled, value);
}