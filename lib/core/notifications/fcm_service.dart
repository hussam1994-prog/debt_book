import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../observability/logging_service.dart';

/// Handler للرسائل في الخلفية (top-level function — يعمل في isolate منفصل).
///
/// ⚠️ لا يمكنه الوصول إلى [LoggingService] — يبقى صامتاً.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // لا debugPrint — Firebase يتولى التسجيل عند الحاجة.
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final LoggingService _logger = LoggingService();

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  void Function(String? route)? onNotificationTap;
  void Function(String action, Map<String, String> data)? onNotificationAction;

  // ─────────────────────────────────────────────
  // التهيئة
  // ─────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      _logger.info('FCM permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        _logger.info('FCM permission denied');
        return;
      }

      await _initLocalNotifications();

      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }

      _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
        _logger.info('FCM token refreshed');
        await _saveTokenToSupabase(newToken);
      });

      _foregroundSub =
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp
          .listen(_handleNotificationTap);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      _logger.info('FCMService initialized');
    } catch (e, st) {
      _logger.error('FCMService init failed', error: e, stackTrace: st);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        'debt_notifications',
        'إشعارات دفتر الديون',
        description: 'إشعارات من السحابة',
        importance: Importance.high,
      ),
    );

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        'debt_actions',
        'إجراءات الإشعارات',
        description: 'أزرار الإجراءات السريعة',
        importance: Importance.high,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // معالجة النقر على الإجراءات
  // ─────────────────────────────────────────────

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload ?? '';
    if (payload.isEmpty) return;

    try {
      if (payload.startsWith('{')) {
        final data = Map<String, String>.from(jsonDecode(payload));
        _handleAction(response.actionId ?? '', data);
      } else {
        onNotificationTap?.call(payload);
      }
    } catch (e) {
      _logger.error('Failed to parse FCM payload', error: e);
      onNotificationTap?.call(payload);
    }
  }

  void _handleAction(String action, Map<String, String> data) {
    switch (action) {
      case 'whatsapp':
      case 'view':
      case 'mark_paid':
        onNotificationAction?.call(action, data);
        break;
      default:
        final route = data['route'];
        if (route != null && route.isNotEmpty) {
          onNotificationTap?.call(route);
        }
    }
  }

  // ─────────────────────────────────────────────
  // معالجة الرسائل
  // ─────────────────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final route = data['route'] as String? ?? '';

    final actions = _buildActions(data);

    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'دفتر الديون',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'debt_notifications',
          'إشعارات دفتر الديون',
          channelDescription: 'إشعارات من السحابة',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          actions: actions,
          autoCancel: true,
          ongoing: false,
        ),
      ),
      payload: jsonEncode({
        ...data,
        'route': route,
      }),
    );
  }

  /// بناء الأزرار حسب نوع الإشعار.
  ///
  /// ✅ تم إصلاح bug سابق: كان `payment_received` يظهر في حالتي switch.
  List<AndroidNotificationAction> _buildActions(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final actions = <AndroidNotificationAction>[];

    switch (type) {
      case 'payment_received':
        actions.add(const AndroidNotificationAction(
          'whatsapp',
          '💬 واتساب',
          showsUserInterface: false,
          cancelNotification: false,
        ));
        actions.add(const AndroidNotificationAction(
          'view',
          '👁️ عرض',
          showsUserInterface: false,
          cancelNotification: true,
        ));
        actions.add(const AndroidNotificationAction(
          'mark_paid',
          '✅ تم',
          showsUserInterface: false,
          cancelNotification: true,
        ));
        break;

      case 'debt_created':
        actions.add(const AndroidNotificationAction(
          'whatsapp',
          '💬 واتساب',
          showsUserInterface: false,
          cancelNotification: false,
        ));
        actions.add(const AndroidNotificationAction(
          'view',
          '👁️ عرض',
          showsUserInterface: false,
          cancelNotification: true,
        ));
        break;

      default:
        actions.add(const AndroidNotificationAction(
          'view',
          'عرض',
          showsUserInterface: false,
          cancelNotification: true,
        ));
    }

    return actions;
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    onNotificationTap?.call(route);
  }

  // ─────────────────────────────────────────────
  // Supabase Token
  // ─────────────────────────────────────────────

  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('device_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': 'android',
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'token',
      );

      _logger.info('FCM token saved');
    } catch (e) {
      _logger.error('Failed to save FCM token', error: e);
    }
  }

  Future<void> removeToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _supabase.from('device_tokens').delete().eq('token', token);
      }
      await _messaging.deleteToken();
    } catch (e) {
      _logger.error('Failed to remove FCM token', error: e);
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _onMessageOpenedSub?.cancel();
    _initialized = false;
  }
}