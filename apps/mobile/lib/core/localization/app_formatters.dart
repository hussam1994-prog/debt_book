import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Helper لتنسيق الأرقام والتواريخ حسب اللغة الحالية.
///
/// ⚠️ نستخدم Latin digits (0-9) دائماً — حتى في العربية —
/// لأن المستخدمين في العراق والمنطقة يفضّلونها على الأرقام العربية.
class AppFormatters {
  AppFormatters._();

  /// تنسيق مبلغ مالي حسب اللغة.
  ///
  /// - EN: `1,234 IQD`
  /// - AR: `1,234 د.ع`
  static String money(BuildContext context, int amount, {String? currency}) {
    final locale = Localizations.localeOf(context).toString();
    // ⚠️ استخدم 'en' دائماً للأرقام (Latin digits)
    final formatted = NumberFormat.decimalPattern('en').format(amount);
    final cur = currency ?? (locale.startsWith('ar') ? 'د.ع' : 'IQD');
    return '$formatted $cur';
  }

  /// تنسيق رقم عادي (بدون عملة).
  static String number(BuildContext context, num value) {
    // ⚠️ Latin digits دائماً
    return NumberFormat.decimalPattern('en').format(value);
  }

  /// تنسيق تاريخ حسب اللغة.
  ///
  /// - EN: `Sep 17, 2026`
  /// - AR: `١٧ سبتمبر ٢٠٢٦` (مع Latin digits: `17 سبتمبر 2026`)
  static String date(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    final formatted = DateFormat.yMMMd(locale).format(date);
    // ⚠️ حوّل الأرقام العربية إلى لاتينية
    return _toLatinDigits(formatted);
  }

  /// تنسيق تاريخ ووقت.
  static String dateTime(BuildContext context, DateTime dt) {
    final locale = Localizations.localeOf(context).toString();
    final formatted = DateFormat.yMMMd(locale).add_jm().format(dt);
    return _toLatinDigits(formatted);
  }

  /// تنسيق نسبة مئوية.
  static String percent(BuildContext context, double value) {
    final formatted = NumberFormat.percentPattern('en').format(value);
    return formatted;
  }

  /// تحويل الأرقام العربية (٠-٩) إلى لاتينية (0-9).
  ///
  /// مفيد لتوحيد عرض التواريخ والأرقام عبر كل اللغات.
  static String _toLatinDigits(String input) {
    const arabicToLatin = {
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    };
    var result = input;
    arabicToLatin.forEach((ar, lat) {
      result = result.replaceAll(ar, lat);
    });
    return result;
  }
}