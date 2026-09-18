import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Helper لتنسيق الأرقام والتواريخ حسب اللغة الحالية.
class AppFormatters {
  AppFormatters._();

  /// تنسيق مبلغ مالي حسب اللغة.
  static String money(BuildContext context, int amount, {String? currency}) {
    final locale = Localizations.localeOf(context).toString();
    final formatted = NumberFormat.decimalPattern(locale).format(amount);
    final cur = currency ?? (locale.startsWith('ar') ? 'د.ع' : 'IQD');
    return '$formatted $cur';
  }

  static String number(BuildContext context, num value) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.decimalPattern(locale).format(value);
  }

  static String date(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  static String dateTime(BuildContext context, DateTime dt) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_jm().format(dt);
  }

  static String percent(BuildContext context, double value) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.percentPattern(locale).format(value);
  }
}