import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// يرسل رسالة تذكير عبر واتساب.
  /// [phone] رقم الهاتف بدون + أو مسافات، مثلاً 07701234567.
  /// [message] نص الرسالة.
  static Future<void> sendReminder({
    required String phone,
    required String message,
  }) async {
    // تحويل الرقم إلى صيغة دولية. نفترض أن الرقم عراقي ونضيف 964
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final intlPhone = cleanPhone.startsWith('0')
        ? '964${cleanPhone.substring(1)}'
        : cleanPhone;

    final uri = Uri.parse('https://wa.me/$intlPhone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('WhatsApp not available');
    }
  }
}