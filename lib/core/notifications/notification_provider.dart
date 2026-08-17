import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مزود حالة تفعيل/إلغاء الإشعارات.
final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsNotifier, bool>(
  (ref) => NotificationsNotifier(),
);

class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(true);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }
}

Future<bool> loadNotificationsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('notifications_enabled') ?? true;
}

Future<void> saveNotificationsEnabled(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('notifications_enabled', value);
}