// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'دفتر الديون';

  @override
  String get people => 'الأشخاص';

  @override
  String get dashboard => 'لوحة المعلومات';

  @override
  String get reports => 'التقارير';

  @override
  String get settings => 'الإعدادات';

  @override
  String get allDebts => 'جميع الديون';

  @override
  String get addPerson => 'إضافة شخص';

  @override
  String get addDebt => 'إضافة دين';

  @override
  String get addPayment => 'إضافة دفعة';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get noDebts => 'لا توجد ديون';

  @override
  String get noPeople => 'لا يوجد أشخاص';

  @override
  String get noOverdue => 'لا توجد ديون متأخرة';

  @override
  String get balance => 'الرصيد';

  @override
  String get originalAmount => 'المبلغ الأصلي';

  @override
  String get dueDate => 'تاريخ الاستحقاق';

  @override
  String get description => 'الوصف';

  @override
  String get searchHint => 'ابحث بالاسم أو رقم الهاتف...';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get language => 'اللغة';

  @override
  String get paid => 'المدفوع';

  @override
  String get paymentsLast7Days => 'دفعات آخر 7 أيام';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get totalDebts => 'إجمالي الديون';

  @override
  String get ledger => 'دفتر الأستاذ';

  @override
  String get payments => 'الدفعات';

  @override
  String get noLedgerEntries => 'لا توجد قيود';

  @override
  String get noPayments => 'لا توجد دفعات';

  @override
  String get addAdjustment => 'إضافة تسوية';

  @override
  String get cancelDebt => 'إلغاء الدين';

  @override
  String get deleteDebt => 'حذف الدين';

  @override
  String get confirmDeleteDebt =>
      'سيتم إلغاء الدين وتصفية الرصيد. هل أنت متأكد؟';

  @override
  String get confirmCancelDebt => 'هل أنت متأكد من إلغاء هذا الدين؟';

  @override
  String get confirmDeletePerson =>
      'هل أنت متأكد؟ سيتم إخفاء الشخص وجميع البيانات المرتبطة.';

  @override
  String get wrongPin => 'رقم PIN خاطئ';

  @override
  String get locked => 'مقفل';

  @override
  String get setPin => 'تعيين PIN';

  @override
  String get newPin => 'PIN جديد';

  @override
  String get backupRestore => 'النسخ الاحتياطي والاستعادة';

  @override
  String get createBackup => 'إنشاء نسخة احتياطية';

  @override
  String get noBackups => 'لا توجد نسخ احتياطية';

  @override
  String get restore => 'استعادة';

  @override
  String get backup => 'نسخة احتياطية';

  @override
  String get exportCsv => 'تصدير CSV';

  @override
  String get csvExported => 'تم التصدير إلى:';

  @override
  String get exportFailed => 'فشل التصدير:';

  @override
  String get adjustmentAmount => 'المبلغ (دينار)';

  @override
  String get increase => 'زيادة';

  @override
  String get decrease => 'تخفيض';

  @override
  String get submitPayment => 'إرسال الدفعة';

  @override
  String get amount => 'المبلغ';

  @override
  String get phone => 'الهاتف';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get notes => 'ملاحظات';

  @override
  String get name => 'الاسم';

  @override
  String get enterName => 'الاسم';

  @override
  String get phoneOptional => 'الهاتف (اختياري)';

  @override
  String get dueDateHint => 'تاريخ الاستحقاق (YYYY-MM-DD)';

  @override
  String get descriptionOptional => 'الوصف (اختياري)';

  @override
  String get debtDetails => 'تفاصيل الدين';

  @override
  String get debtCancelled => 'تم إلغاء الدين';

  @override
  String get adjustmentAdded => 'تمت إضافة التسوية';

  @override
  String get paymentReversed => 'تم عكس الدفعة';

  @override
  String get smartInsights => 'رؤى ذكية';

  @override
  String get noInsights => 'لا توجد رؤى';

  @override
  String get backupCreated => 'تم إنشاء النسخة الاحتياطية';

  @override
  String get backupFailed => 'فشل إنشاء النسخة الاحتياطية';

  @override
  String get restoreFailed => 'فشلت الاستعادة';

  @override
  String get backupRestored =>
      'تمت الاستعادة. أعد تشغيل التطبيق لتطبيق التغييرات.';

  @override
  String get deleteBackup => 'حذف النسخة الاحتياطية';

  @override
  String get confirmRestore =>
      'سيتم استبدال جميع البيانات الحالية. هل أنت متأكد؟';

  @override
  String get confirmDeleteBackup => 'حذف هذه النسخة الاحتياطية؟';

  @override
  String get allGood => 'كل شيء تمام! لا توجد مخالفات.';

  @override
  String get runIntegrity => 'تشغيل فحص سلامة الدفتر';

  @override
  String get pinSetSuccess => 'تم تعيين PIN بنجاح';

  @override
  String get personDetails => 'تفاصيل الشخص';

  @override
  String get rejectOverpayment => 'رفض الدفع الزائد';

  @override
  String get capAtZero => 'تغطية عند الصفر';

  @override
  String get allowOverpayment => 'السماح بالدفع الزائد';

  @override
  String get debtCreation => 'إنشاء دين';

  @override
  String get payment => 'دفعة';

  @override
  String get reversal => 'عكس';

  @override
  String get adjustment => 'تسوية';

  @override
  String get enterPin => 'أدخل PIN';

  @override
  String get unlock => 'فتح';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notificationsSubtitle => 'تفعيل تذكيرات الديون المستحقة';

  @override
  String whatsappMessage(Object amount) {
    return 'مرحباً، المطلوب منك تسديد مبلغ $amount دينار عراقي. شكراً';
  }

  @override
  String get whatsappTooltip => 'إرسال رسالة واتساب';

  @override
  String get whatsappGeneralMessage => 'مرحباً، هذا تذكير من دفتر الديون.';

  @override
  String get nameTooLong => 'الاسم طويل جداً (الحد الأقصى 50 حرف)';

  @override
  String get invalidPhone => 'رقم الهاتف غير صالح';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';
}
