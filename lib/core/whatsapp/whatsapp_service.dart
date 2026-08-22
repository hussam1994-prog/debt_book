import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<void> sendReminder({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

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

    // ✅ فتح مباشر بدون canLaunchUrl
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}