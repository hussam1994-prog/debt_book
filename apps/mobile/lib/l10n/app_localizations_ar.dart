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
  String get debts => 'ديون';

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
  String get reversal => 'عكس دفعة';

  @override
  String get adjustment => 'تسوية';

  @override
  String get whatsappTooltip => 'إرسال رسالة واتساب';

  @override
  String get whatsappGeneralMessage => 'مرحباً، هذا تذكير من دفتر الديون.';

  @override
  String get cloudSync => 'مزامنة سحابية';

  @override
  String get cloudSyncSuccess => 'عدد الأشخاص المزامنين:';

  @override
  String cloudSyncFailed(Object error) {
    return 'فشلت المزامنة: $error';
  }

  @override
  String cloudSyncResult(
    Object debts,
    Object installments,
    Object ledger,
    Object payments,
    Object persons,
  ) {
    return 'تمت المزامنة: $persons أشخاص، $debts ديون، $payments دفعات، $ledger قيود، $installments أقساط';
  }

  @override
  String get pleaseLoginFirst => 'يرجى تسجيل الدخول أولاً';

  @override
  String get logoutConfirm => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notificationsSubtitle => 'تفعيل تذكيرات الديون المستحقة';

  @override
  String get refresh => 'تحديث';

  @override
  String get enterPin => 'أدخل PIN';

  @override
  String get unlock => 'فتح';

  @override
  String get no => 'لا';

  @override
  String get yes => 'نعم';

  @override
  String get installments => 'الأقساط';

  @override
  String get installment => 'قسط';

  @override
  String get installmentPlan => 'خطة تقسيط';

  @override
  String get numberOfInstallments => 'عدد الأقساط';

  @override
  String get firstInstallmentDate => 'تاريخ أول قسط';

  @override
  String get noInstallments => 'لا توجد أقساط';

  @override
  String get pdfReportTitle => 'تقرير دفتر الديون';

  @override
  String get pdfPerson => 'الشخص';

  @override
  String get pdfDescription => 'الوصف';

  @override
  String get pdfOriginalAmount => 'المبلغ الأصلي';

  @override
  String get pdfBalance => 'الرصيد';

  @override
  String get pdfStatus => 'الحالة';

  @override
  String get pdfDueDate => 'تاريخ الاستحقاق';

  @override
  String get newDebtNotificationTitle => 'دين جديد';

  @override
  String newDebtNotificationBody(Object amount) {
    return 'تمت إضافة دين بقيمة $amount دينار';
  }

  @override
  String get dueSoonNotificationTitle => 'تذكير';

  @override
  String get dueSoonNotificationBody => 'دينك يستحق قريبًا';

  @override
  String get invalidAmount => 'يرجى إدخال مبلغ صحيح';

  @override
  String get optional => 'اختياري';

  @override
  String get reminder => 'تذكير';

  @override
  String get noReminder => 'بدون تذكير';

  @override
  String beforeDays(Object days) {
    return 'قبل $days يوم';
  }

  @override
  String get confirmSave => 'تأكيد الحفظ';

  @override
  String get saveDebt => 'حفظ الدين';

  @override
  String get attachImage => 'إرفاق صورة';

  @override
  String get changeImage => 'تغيير الصورة';

  @override
  String get nameExists => 'الاسم موجود مسبقًا';

  @override
  String get nameExistsMessage => 'يوجد شخص بهذا الاسم. هل تريد إضافة دين له؟';

  @override
  String get createNew => 'إنشاء جديد';

  @override
  String get addDebtToExisting => 'إضافة دين للشخص الموجود';

  @override
  String get invalidPhone => 'رقم الهاتف غير صالح';

  @override
  String get nameTooLong => 'الاسم طويل جداً (الحد الأقصى 50 حرف)';

  @override
  String get passwordTooShort => 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';

  @override
  String get checkEmailToConfirm => 'تم إنشاء الحساب. تحقق من بريدك للتأكيد.';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get send => 'إرسال';

  @override
  String get resetEmailSent => 'تم إرسال رابط إعادة التعيين. تحقق من بريدك.';

  @override
  String get passwordChanged => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountConfirm =>
      'هل أنت متأكد من حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get totalOutstanding => 'إجمالي المستحقات';

  @override
  String get statementFor => 'كشف حساب';

  @override
  String get sendWhatsAppStatement => 'إرسال عبر واتساب';

  @override
  String get exportStatementPdf => 'تصدير PDF';

  @override
  String get status => 'الحالة';

  @override
  String get cleanupViolations => 'تنظيف المخالفات';

  @override
  String get cleanupConfirm =>
      'سيتم إصلاح الدفعات المكررة والقيود العكسية المكسورة والمفاتيح الأجنبية غير الصالحة. متابعة؟';

  @override
  String get cleanupYes => 'تنظيف';

  @override
  String get personDeleted => 'تم حذف الشخص بنجاح';

  @override
  String get invalidEmail => 'بريد إلكتروني غير صالح';

  @override
  String get pleaseFillFields => 'يرجى ملء جميع الحقول';

  @override
  String get password => 'كلمة المرور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get installmentPaid => 'تم دفع القسط';

  @override
  String get notificationSettings => 'إعدادات الإشعارات';

  @override
  String get notificationSettingsSubtitle => 'تخصيص التذكيرات وساعات الهدوء';

  @override
  String get enableNotifications => 'تفعيل الإشعارات';

  @override
  String get enableNotificationsSubtitle => 'تشغيل/إيقاف جميع الإشعارات';

  @override
  String get quietHours => 'ساعات الهدوء';

  @override
  String get quietHoursSubtitle => 'لا ترسل إشعارات في هذه الأوقات';

  @override
  String get quietHoursFrom => 'من';

  @override
  String get quietHoursTo => 'إلى';

  @override
  String get dueReminders => 'تذكيرات الاستحقاق';

  @override
  String get remind7Days => 'قبل 7 أيام';

  @override
  String get remind3Days => 'قبل 3 أيام';

  @override
  String get remind1Day => 'قبل يوم واحد';

  @override
  String get remindOverdueDaily => 'تذكير يومي بالمتأخرة';

  @override
  String get remindOverdueSubtitle => 'إشعار كل يوم للديون التي تجاوزت موعدها';

  @override
  String get otherNotifications => 'أنواع أخرى';

  @override
  String get weeklySummary => 'ملخص أسبوعي';

  @override
  String get weeklySummarySubtitle => 'كل يوم أحد صباحًا';

  @override
  String get paymentNotifications => 'إشعارات الدفعات';

  @override
  String get paymentNotificationsSubtitle =>
      'عند استلام دفعة جديدة (من أجهزة أخرى)';

  @override
  String get notificationInfo =>
      'الإشعارات تُرسل تلقائيًا حسب إعداداتك. ستُحدَّث عند فتح التطبيق أو تعديل الديون.';

  @override
  String get syncDashboard => 'لوحة المزامنة';

  @override
  String get syncDashboardSubtitle => 'حالة المزامنة والإحصائيات';

  @override
  String get syncedSuccessfully => 'تمت المزامنة بنجاح';

  @override
  String get syncFailed => 'فشلت المزامنة';

  @override
  String get pendingSync => 'معلّقة';

  @override
  String get failedSync => 'فاشلة';

  @override
  String get syncedSync => 'متزامنة';

  @override
  String get lastSync => 'آخر مزامنة';

  @override
  String get neverSynced => 'لم تتم بعد';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get retryFailed => 'إعادة المحاولة';

  @override
  String get clearSynced => 'تنظيف المتزامنة';

  @override
  String get deleteSyncedTitle => 'حذف السجلات المتزامنة';

  @override
  String get deleteSyncedMessage =>
      'سيتم حذف جميع السجلات المتزامنة من طابور Outbox.';

  @override
  String get howSyncWorks => 'كيف تعمل المزامنة؟';

  @override
  String get howSyncWorksBody =>
      '• المزامنة تلقائية كل 30 ثانية.\n• تُجمع العمليات في دفعة واحدة.\n• عند عودة الإنترنت، تُزامن تلقائيًا.\n• المحاولات الفاشلة تُعاد بفاصل متزايد.';

  @override
  String get clearDataTitle => 'مسح جميع البيانات';

  @override
  String get clearDataMessage =>
      'هل أنت متأكد من مسح جميع البيانات المحلية؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get paymentReceivedTitle => 'تم استلام دفعة';

  @override
  String paymentReceivedBody(String personName, int amount) {
    return '$personName دفع $amount دينار';
  }

  @override
  String get debtDueInWeek => 'دين يستحق بعد أسبوع';

  @override
  String get debtDueInThreeDays => 'دين يستحق بعد 3 أيام';

  @override
  String get debtDueTomorrow => 'دين يستحق غدًا';

  @override
  String get debtOverdueTitle => 'دين متأخر';

  @override
  String get weeklySummaryTitle => 'الملخص الأسبوعي';

  @override
  String weeklySummaryBody(int active, int overdue, int total) {
    return 'لديك $active دين نشط، $overdue متأخر، إجمالي $total دينار';
  }

  @override
  String errorGeneric(String message) {
    return 'خطأ: $message';
  }

  @override
  String loginFailed(String error) {
    return 'فشل تسجيل الدخول: $error';
  }

  @override
  String signupFailed(String error) {
    return 'فشل إنشاء الحساب: $error';
  }

  @override
  String get noPaymentsInWeek => 'لا توجد دفعات في آخر 7 أيام.';

  @override
  String uploadFailed(String error) {
    return 'فشل الرفع: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'فشل التنزيل: $error';
  }

  @override
  String deleteFailed(String error) {
    return 'فشل الحذف: $error';
  }

  @override
  String exportFailedGeneric(String error) {
    return 'فشل التصدير: $error';
  }

  @override
  String amountWithCurrency(String amount) {
    return '$amount د.ع';
  }

  @override
  String amountWithDinar(String amount) {
    return '$amount دينار';
  }

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String excelExportFailed(String error) {
    return 'فشل تصدير Excel: $error';
  }

  @override
  String get pdfStatement => 'كشف PDF';

  @override
  String sendPdfFailed(String error) {
    return 'فشل إرسال PDF: $error';
  }

  @override
  String installmentsUpdated(int count) {
    return 'تم تحديث $count قسط';
  }

  @override
  String get switchGoogleAccount => 'تبديل حساب Google';

  @override
  String get switchGoogleAccountSubtitle => 'تسجيل دخول بحساب Google آخر';

  @override
  String switchAccountFailed(String error) {
    return 'فشل تبديل الحساب: $error';
  }

  @override
  String resetSettingsFailed(String error) {
    return 'فشلت إعادة التعيين: $error';
  }

  @override
  String get top5Debtors => 'أعلى 5 مدينين';

  @override
  String get monthlyStats => 'الإحصائيات الشهرية';

  @override
  String newDebtsAndPayments(int debts, int payments) {
    return '$debts دين جديد • $payments دفعة';
  }

  @override
  String get debtDistribution => 'توزيع الديون';

  @override
  String backupFailedWithError(String error) {
    return 'فشل النسخ الاحتياطي: $error';
  }

  @override
  String restoreFailedWithError(String error) {
    return 'فشلت الاستعادة: $error';
  }

  @override
  String get debtFallback => 'دين';

  @override
  String get unknownPerson => 'غير معروف';

  @override
  String get exportPdfTooltip => 'تصدير PDF';

  @override
  String get switchAccountConfirm =>
      'سيتم تسجيل خروجك من الحساب الحالي. هل تريد المتابعة؟';

  @override
  String get resetSettingsSubtitle =>
      'سيتم إعادة المظهر واللغة إلى الوضع الافتراضي.\n\nبياناتك (الأشخاص، الديون، الدفعات) لن تتأثر إطلاقاً.';

  @override
  String get resetAction => 'إعادة تعيين';

  @override
  String get resetSettingsDone => 'تمت إعادة الإعدادات للوضع الافتراضي';

  @override
  String get showTutorialAgain => 'إعادة عرض الشرح';

  @override
  String get showTutorialAgainSubtitle => 'مشاهدة الجولة التعريفية مرة أخرى';

  @override
  String get tutorialWillAppear => 'سيظهر الشرح عند إعادة فتح التطبيق';

  @override
  String cleanupSuccess(int count) {
    return 'تم تصحيح $count مخالفة';
  }

  @override
  String get resetSettingsShort => 'استرجاع المظهر واللغة للوضع الافتراضي';

  @override
  String offlineDataSaved(int count) {
    return 'لا يوجد اتصال بالإنترنت حاليًا. البيانات المحفوظة محليًا: $count شخص. ستتم المزامنة تلقائيًا عند عودة الاتصال.';
  }

  @override
  String get resetSettings => 'إعادة تعيين الإعدادات';

  @override
  String get switchAccount => 'تبديل';

  @override
  String get databaseFileNotFound => 'ملف قاعدة البيانات غير موجود';

  @override
  String uploadSuccess(String size) {
    return '✅ تم الرفع بنجاح ($size KB)';
  }

  @override
  String downloadSuccess(String size) {
    return '✅ تم التنزيل ($size KB). يمكنك استعادتها من القائمة المحلية.';
  }

  @override
  String get backupDeleted => '✅ تم الحذف';

  @override
  String get restoreFromCloud => 'استعادة من السحابة';

  @override
  String get restoreFromCloudConfirm =>
      'سيتم تنزيل النسخة من السحابة. يمكنك استعادتها لاحقاً من النسخ المحلية. متابعة؟';

  @override
  String get download => 'تنزيل';

  @override
  String get deleteCloudBackup => 'حذف نسخة سحابية';

  @override
  String get deleteCloudBackupConfirm =>
      'هل أنت متأكد من حذف هذه النسخة من السحابة؟';

  @override
  String get localTab => 'محلي';

  @override
  String get cloudTab => 'سحابي';

  @override
  String get uploadBackup => 'رفع نسخة';

  @override
  String get share => 'مشاركة';

  @override
  String get noCloudBackups => 'لا توجد نسخ سحابية';

  @override
  String get noCloudBackupsHint =>
      'اضغط \"رفع نسخة\" لإنشاء أول نسخة احتياطية سحابية';

  @override
  String get deleteFromCloud => 'حذف من السحابة';

  @override
  String get encrypted => 'مشفر 🔒';

  @override
  String get aggregateReportTooltip => 'تصدير تقرير مجمّع';

  @override
  String get multiPersonReportTooltip => 'تقرير متعدد';

  @override
  String get excelExportTooltip => 'تصدير Excel';

  @override
  String get activeLabel => 'نشط';

  @override
  String get overdueLabel => 'متأخر';

  @override
  String get completedLabel => 'مكتمل';

  @override
  String get monthlyDebtTrend => 'تطور الديون الشهري';

  @override
  String get reportsRefreshed => 'تم تحديث التقارير محليًا';

  @override
  String get exportDone => 'تم التصدير';

  @override
  String get shareFileQuestion => 'هل تريد مشاركة الملف؟';

  @override
  String get close => 'إغلاق';

  @override
  String get noDataToExport => 'لا توجد بيانات للتصدير';

  @override
  String get exportReport => 'تصدير التقرير';

  @override
  String get simpleTextFile => 'ملف نصي بسيط';

  @override
  String get officialReport => 'تقرير رسمي';

  @override
  String get professionalTable => 'جدول بتنسيق احترافي';

  @override
  String get groupedDebtsReport => 'تقرير الديون المجمّع';

  @override
  String get individualView => 'عرض فردي';

  @override
  String get groupedView => 'عرض مجمّع';

  @override
  String get voiceSearchUnavailable =>
      'البحث الصوتي غير متاح. تأكد من منح الإذن وتثبيت حزمة اللغة.';

  @override
  String get voiceNoMatch => 'لم يتم التعرف على الكلام. حاول مرة أخرى.';

  @override
  String get voiceSearchTooltip => 'بحث صوتي';

  @override
  String get voiceListening => '🎤 جارٍ الاستماع...';

  @override
  String get quickAdd => 'إضافة سريعة';

  @override
  String get newPerson => 'شخص جديد';

  @override
  String get newDebt => 'دين جديد';

  @override
  String get add => 'إضافة';

  @override
  String get dataRefreshed => 'تم تحديث البيانات محليًا';

  @override
  String get choosePersonColor => 'اختر لون الشخص';

  @override
  String get removeColor => 'إزالة اللون';

  @override
  String get noPhoneForPerson => 'لا يوجد رقم هاتف لهذا الشخص';

  @override
  String get sendStatement => 'إرسال كشف الحساب';

  @override
  String get textMessage => 'رسالة نصية';

  @override
  String get balanceSummaryInMessage => 'ملخص الأرصدة في رسالة';

  @override
  String get fullPdfFile => 'ملف كامل يمكن مشاركته';

  @override
  String mrMrs(String name) {
    return 'السيد/ة $name';
  }

  @override
  String get outstandingAmounts => 'المستحقات المالية:';

  @override
  String statementTotal(int total) {
    return 'الإجمالي: $total دينار';
  }

  @override
  String get statementTitle => 'كشف حساب';

  @override
  String statementShareText(String name, int total) {
    return 'كشف حساب - $name\nالإجمالي: $total دينار';
  }

  @override
  String fromAmount(String amount) {
    return 'من $amount';
  }

  @override
  String get statusPaid => 'مدفوع';

  @override
  String get statusOverdue => 'متأخر';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get statusActive => 'نشط';

  @override
  String get changeColorTooltip => 'تغيير اللون';

  @override
  String get totalOutstandingLabel => 'إجمالي المستحقات';

  @override
  String get totalPaymentsLabel => 'إجمالي الدفعات';

  @override
  String get debtsAndPayments6Months => 'الديون والدفعات (آخر 6 أشهر)';

  @override
  String get monthlyDetails => 'التفاصيل الشهرية';

  @override
  String get paymentReceivedTitleEn => 'تم استلام دفعة';

  @override
  String get noPhoneNumber => 'لا يوجد رقم هاتف لهذا الشخص';

  @override
  String get detailsRefreshed => 'تم تحديث التفاصيل محليًا';

  @override
  String get noPhoneForWhatsApp => 'لا يوجد رقم هاتف للإرسال عبر واتساب';

  @override
  String get offlineLabel => 'غير متصل';

  @override
  String get syncingNow => 'جار المزامنة...';

  @override
  String get syncReady => 'جاهز للمزامنة';

  @override
  String lastSyncAt(String time) {
    return 'آخر مزامنة: $time';
  }

  @override
  String secondsAgo(int count) {
    return 'قبل $count ثانية';
  }

  @override
  String minutesAgo(int count) {
    return 'قبل $count دقيقة';
  }

  @override
  String hoursAgo(int count) {
    return 'قبل $count ساعة';
  }

  @override
  String lastSyncWithCounts(String time, int persons, int debts) {
    return 'آخر مزامنة: $time • $persons أشخاص، $debts ديون';
  }

  @override
  String get continueWithGoogle => 'المتابعة بحساب Google';

  @override
  String get orDivider => 'أو';

  @override
  String get invalidCredentials => 'البريد أو كلمة المرور خاطئة';

  @override
  String get emailNotConfirmed => 'يرجى تأكيد بريدك الإلكتروني';

  @override
  String get networkError => 'تحقق من اتصالك بالإنترنت';

  @override
  String daysAgo(int count) {
    return 'قبل $count يوم';
  }

  @override
  String whatsappReminder(String name, int amount) {
    return 'مرحبًا $name،\nهذا تذكير لطيف بالمبلغ المستحق: $amount دينار.\nشكرًا لتعاونك. 🙏';
  }

  @override
  String whatsappReminderUrgent(String name, int amount) {
    return 'عزيزي $name،\nالمبلغ المستحق: $amount دينار.\nيرجى التسديد في أقرب وقت ممكن.\nشكرًا.';
  }

  @override
  String whatsappReminderOverdue(String name, int amount, String dueDate) {
    return '$name،\nالمبلغ المتأخر: $amount دينار.\nكان موعد الاستحقاق: $dueDate.\nنرجو التسديد بأسرع وقت.';
  }

  @override
  String whatsappThankYou(String name) {
    return 'شكرًا جزيلًا $name! 🙏\nتم استلام دفعتك بنجاح.\nنتطلع للتعامل معك مرة أخرى.';
  }

  @override
  String whatsappPostpone(String name) {
    return '$name،\nتم تأجيل موعد استحقاقك.\nشكرًا لتعاونك.';
  }

  @override
  String whatsappCongratulations(String name) {
    return '🎉 تهانينا $name!\nلقد سددت جميع ديونك.\nشكرًا لكونك عميلًا رائعًا. ⭐';
  }

  @override
  String whatsappDefault(String name) {
    return 'مرحبًا $name،\nهذا تذكير من دفتر الديون.';
  }

  @override
  String get multiPersonReportTitle => 'تقرير متعدد الأشخاص';

  @override
  String get clearSelection => 'إلغاء التحديد';

  @override
  String personsSelected(int count) {
    return '$count شخص محدد';
  }

  @override
  String get noPeopleForReport => 'لا يوجد أشخاص';

  @override
  String get generating => 'جارٍ التوليد...';

  @override
  String get generatePdf => 'توليد PDF';

  @override
  String reportsForCount(int count) {
    return 'تقارير $count أشخاص';
  }

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get sendWhatsappMessage => 'إرسال رسالة واتساب';

  @override
  String get templateReminder => 'تذكير عادي';

  @override
  String get templateUrgent => 'تذكير عاجل';

  @override
  String get templateOverdue => 'تذكير بالمتأخر';

  @override
  String get templateThankYou => 'شكر';

  @override
  String get templatePostpone => 'تأجيل';

  @override
  String get templateCongratulations => 'تهنئة';

  @override
  String get loginCancelled => 'تم إلغاء تسجيل الدخول';

  @override
  String get accountDataFailed =>
      'فشل في الحصول على بيانات الحساب. حاول مرة أخرى';

  @override
  String get configError => 'خطأ في إعداد التطبيق. تواصل مع الدعم';

  @override
  String get unexpectedError => 'حدث خطأ غير متوقع. حاول مرة أخرى';
}
