import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

class WhatsAppService {
  // ─────────────────────────────────────────────
  // 1. إرسال رسالة نصية
  // ─────────────────────────────────────────────

  static Future<void> sendReminder({
    required String phone,
    required String message,
  }) async {
    final intlPhone = normalizeIraqiPhone(phone);
    if (intlPhone == null) {
      if (kDebugMode) {
        debugPrint('Invalid phone: $phone');
      }
      return;
    }

    final uri = Uri.parse(
      'https://wa.me/$intlPhone?text=${Uri.encodeComponent(message)}',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ─────────────────────────────────────────────
  // 2. إرسال PDF عبر واتساب (مشاركة)
  // ─────────────────────────────────────────────

  /// إرسال ملف PDF مع رسالة عبر تطبيق المشاركة
  /// (سيظهر واتساب كخيار).
  static Future<void> sendPdfFile({
    required String filePath,
    required String message,
    String? phone,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      if (kDebugMode) {
        debugPrint('File not found: $filePath');
      }
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        files: [XFile(filePath)],
      ),
    );
  }

  /// إرسال PDF مباشرة لرقم محدد.
  ///
  /// ⚠️ واتساب لا يدعم إرسال الملفات عبر wa.me مباشرة —
  /// نستخدم share_plus مع توجيه المستخدم.
  ///
  /// [phoneLabel] هو نص اختياري لعرض الرقم داخل الرسالة
  /// (مترجم من الاستدعاء — مثال: "Phone" / "الرقم").
  static Future<void> sendPdfToNumber({
    required String phone,
    required String filePath,
    required String message,
    required String phoneLabel,
  }) async {
    final intlPhone = normalizeIraqiPhone(phone);
    if (intlPhone == null) {
      if (kDebugMode) {
        debugPrint('Invalid phone: $phone');
      }
      return;
    }

    await sendPdfFile(
      filePath: filePath,
      message: '$message\n\n$phoneLabel: +$intlPhone',
    );
  }

  // ─────────────────────────────────────────────
  // 3. التحقق من صحة الرقم
  // ─────────────────────────────────────────────

  /// التحقق من صحة رقم عراقي.
  /// يرجع `true` إذا كان الرقم صالحًا.
  static bool isValidIraqiPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');

    // الصيغ المقبولة:
    // 07XXXXXXXXX (11 رقم)  → 07501234567
    // 964XXXXXXXXX (12 رقم) → 9647501234567
    // 9640XXXXXXXXX (13 رقم)
    if (clean.startsWith('964')) {
      final withoutCode = clean.substring(3);
      return withoutCode.length >= 10 && withoutCode.startsWith('7');
    }

    if (clean.startsWith('0')) {
      return clean.length == 11 && clean.startsWith('07');
    }

    return clean.length == 10 && clean.startsWith('7');
  }

  // ─────────────────────────────────────────────
  // 4. تحويل الرقم إلى صيغة دولية
  // ─────────────────────────────────────────────

  /// تحويل رقم عراقي إلى الصيغة الدولية (964XXXXXXXXXX).
  /// يرجع `null` إذا كان الرقم غير صالح.
  static String? normalizeIraqiPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return null;

    String intlPhone;

    if (clean.startsWith('9640')) {
      // 9640750123456 → 964750123456
      intlPhone = '964${clean.substring(4)}';
    } else if (clean.startsWith('964')) {
      // 964750123456 → كما هي
      intlPhone = clean;
    } else if (clean.startsWith('0')) {
      // 07501234567 → 9647501234567
      intlPhone = '964${clean.substring(1)}';
    } else if (clean.startsWith('7')) {
      // 7501234567 → 9647501234567
      intlPhone = '964$clean';
    } else {
      // غير معروف
      intlPhone = '964$clean';
    }

    // التحقق من الطول
    if (intlPhone.length < 13 || intlPhone.length > 14) {
      if (kDebugMode) {
        debugPrint('Unusual phone length: $intlPhone (${intlPhone.length})');
      }
    }

    return intlPhone;
  }

  // ─────────────────────────────────────────────
  // 5. رسائل قوالب جاهزة
  // ─────────────────────────────────────────────

  /// قوالب رسائل جاهزة للاستخدام.
  ///
  /// ⚠️ يتطلب [l10n] من `AppLocalizations.of(context)!`
  /// لأنه service ثابت لا يملك `BuildContext`.
  static String getTemplate({
    required AppLocalizations l10n,
    required String template,
    required String personName,
    int? amount,
    String? dueDate,
  }) {
    switch (template) {
      case 'reminder':
        return l10n.whatsappReminder(personName, amount ?? 0);

      case 'reminder_urgent':
        return l10n.whatsappReminderUrgent(personName, amount ?? 0);

      case 'reminder_overdue':
        return l10n.whatsappReminderOverdue(
          personName,
          amount ?? 0,
          dueDate ?? '',
        );

      case 'thank_you':
        return l10n.whatsappThankYou(personName);

      case 'postpone':
        return l10n.whatsappPostpone(personName);

      case 'congratulations':
        return l10n.whatsappCongratulations(personName);

      default:
        return l10n.whatsappDefault(personName);
    }
  }
}