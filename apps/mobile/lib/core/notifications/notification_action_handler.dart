import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  // ✅ جديد
//import 'package:go_router/go_router.dart';  // ✅ جديد

import '../../app/router.dart';
import '../providers.dart';
import '../whatsapp/whatsapp_service.dart';

/// ✅ معالج إجراءات الإشعارات (واتساب، عرض، تم).
class NotificationActionHandler {
  static Future<void> handle({
    required String action,
    required Map<String, String> data,
    required WidgetRef ref,
  }) async {
    debugPrint('🎬 Handling action: $action');

    switch (action) {
      case 'whatsapp':
        await _handleWhatsApp(data, ref);
        break;
      case 'view':
        _handleView(data);
        break;
      case 'mark_paid':
        await _handleMarkPaid(data, ref);
        break;
      default:
        debugPrint('⚠️ Unknown action: $action');
    }
  }

  /// إرسال رسالة واتساب
  static Future<void> _handleWhatsApp(
      Map<String, String> data, WidgetRef ref) async {
    try {
      final debtId = data['debt_id'];
      if (debtId == null) return;

      final debt = await ref
          .read(debtRepositoryProvider)
          .findById(DebtId(debtId));
      if (debt == null) return;

      final person =
          await ref.read(personRepositoryProvider).findById(debt.personId);
      if (person?.phone == null || person!.phone!.isEmpty) return;

      final balance = await ref.read(getBalanceProvider).call(debt.id);

      final message = 'مرحبًا ${person.name}،\n'
          'المبلغ المستحق: ${balance.amount} دينار.\n'
          'شكرًا.';

      await WhatsAppService.sendReminder(
        phone: person.phone!,
        message: message,
      );
    } catch (e) {
      debugPrint('❌ WhatsApp action failed: $e');
    }
  }

  /// فتح صفحة الدين
  static void _handleView(Map<String, String> data) {
    final route = data['route'];
    if (route == null || route.isEmpty) return;
    try {
      router.go(route);
    } catch (e) {
      debugPrint('❌ Navigation failed: $e');
    }
  }

  /// علّم الدين كمدفوع
  static Future<void> _handleMarkPaid(
      Map<String, String> data, WidgetRef ref) async {
    try {
      final debtId = data['debt_id'];
      if (debtId == null) return;

      final debt = await ref
          .read(debtRepositoryProvider)
          .findById(DebtId(debtId));
      if (debt == null) return;

      final balance = await ref.read(getBalanceProvider).call(debt.id);
      if (balance.amount <= 0) return;

      final addPayment = ref.read(addPaymentProvider);
      await addPayment(
        debtId: debt.id,
        amount: Money(amount: balance.amount),
        policy: OverpaymentPolicy.reject,
      );

      debugPrint('✅ Debt marked as paid');
    } catch (e) {
      debugPrint('❌ Mark paid failed: $e');
    }
  }
}