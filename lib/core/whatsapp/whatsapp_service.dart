import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// يرسل رسالة تذكير عبر واتساب.
  /// [phone] رقم الهاتف بدون + أو مسافات، مثلاً 07701234567.
  /// [message] نص الرسالة.
  static Future<void> sendReminder({
    required String phone,
    required String message,
  }) async {
    // تنظيف الرقم من أي رموز
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    // تحويل الرقم العراقي إلى صيغة دولية
    String intlPhone = cleanPhone;
    if (cleanPhone.startsWith('0')) {
      intlPhone = '964${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('9640')) {
      intlPhone = '964${cleanPhone.substring(4)}';
    } else if (cleanPhone.startsWith('964')) {
      intlPhone = cleanPhone;
    } else {
      intlPhone = '964$cleanPhone';
    }

    final uri = Uri.parse(
      'https://wa.me/$intlPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('WhatsApp not available');
    }
  }
}