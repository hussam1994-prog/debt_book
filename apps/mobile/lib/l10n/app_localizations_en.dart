// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Debt Book';

  @override
  String get people => 'People';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get allDebts => 'All Debts';

  @override
  String get addPerson => 'Add Person';

  @override
  String get addDebt => 'Add Debt';

  @override
  String get addPayment => 'Add Payment';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get noDebts => 'No Debts';

  @override
  String get noPeople => 'No People';

  @override
  String get noOverdue => 'No overdue debts';

  @override
  String get balance => 'Balance';

  @override
  String get originalAmount => 'Original Amount';

  @override
  String get dueDate => 'Due Date';

  @override
  String get description => 'Description';

  @override
  String get searchHint => 'Search by name or phone...';

  @override
  String get logout => 'Logout';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get debts => 'debts';

  @override
  String get paid => 'Paid';

  @override
  String get paymentsLast7Days => 'Payments (Last 7 Days)';

  @override
  String get overview => 'Overview';

  @override
  String get totalDebts => 'Total Debts';

  @override
  String get ledger => 'Ledger';

  @override
  String get payments => 'Payments';

  @override
  String get noLedgerEntries => 'No Ledger Entries';

  @override
  String get noPayments => 'No Payments';

  @override
  String get addAdjustment => 'Add Adjustment';

  @override
  String get cancelDebt => 'Cancel Debt';

  @override
  String get deleteDebt => 'Delete Debt';

  @override
  String get confirmDeleteDebt =>
      'This will cancel the debt and zero out balance. Are you sure?';

  @override
  String get confirmCancelDebt => 'Are you sure you want to cancel this debt?';

  @override
  String get confirmDeletePerson =>
      'Are you sure? This will hide the person and all related data.';

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String get locked => 'Locked';

  @override
  String get setPin => 'Set PIN';

  @override
  String get newPin => 'New PIN';

  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get noBackups => 'No backups';

  @override
  String get restore => 'Restore';

  @override
  String get backup => 'Backup';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get csvExported => 'CSV exported to:';

  @override
  String get exportFailed => 'Export failed:';

  @override
  String get adjustmentAmount => 'Amount (IQD)';

  @override
  String get increase => 'Increase';

  @override
  String get decrease => 'Decrease';

  @override
  String get submitPayment => 'Submit Payment';

  @override
  String get amount => 'Amount';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get notes => 'Notes';

  @override
  String get name => 'Name';

  @override
  String get enterName => 'Name';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get dueDateHint => 'Due Date (YYYY-MM-DD)';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get debtDetails => 'Debt Details';

  @override
  String get debtCancelled => 'Debt cancelled';

  @override
  String get adjustmentAdded => 'Adjustment added';

  @override
  String get paymentReversed => 'Payment reversed';

  @override
  String get smartInsights => 'Smart Insights';

  @override
  String get noInsights => 'No insights';

  @override
  String get backupCreated => 'Backup created';

  @override
  String get backupFailed => 'Backup failed';

  @override
  String get restoreFailed => 'Restore failed';

  @override
  String get backupRestored =>
      'Backup restored. Restart the app to apply changes.';

  @override
  String get deleteBackup => 'Delete backup';

  @override
  String get confirmRestore =>
      'This will replace all current data. Are you sure?';

  @override
  String get confirmDeleteBackup => 'Delete this backup?';

  @override
  String get allGood => 'All good! No violations found.';

  @override
  String get runIntegrity => 'Run Ledger Integrity Check';

  @override
  String get pinSetSuccess => 'PIN set successfully';

  @override
  String get personDetails => 'Person Details';

  @override
  String get rejectOverpayment => 'Reject overpayment';

  @override
  String get capAtZero => 'Cap at zero';

  @override
  String get allowOverpayment => 'Allow overpayment';

  @override
  String get debtCreation => 'Debt Creation';

  @override
  String get payment => 'Payment';

  @override
  String get reversal => 'Reversal';

  @override
  String get adjustment => 'Adjustment';

  @override
  String get whatsappTooltip => 'Send WhatsApp message';

  @override
  String get whatsappGeneralMessage =>
      'Hello, this is a reminder from Debt Book.';

  @override
  String get cloudSync => 'Cloud Sync';

  @override
  String get cloudSyncSuccess => 'Synced persons count:';

  @override
  String cloudSyncFailed(Object error) {
    return 'Sync failed: $error';
  }

  @override
  String cloudSyncResult(
    Object debts,
    Object installments,
    Object ledger,
    Object payments,
    Object persons,
  ) {
    return 'Synced: $persons persons, $debts debts, $payments payments, $ledger ledger, $installments installments';
  }

  @override
  String get pleaseLoginFirst => 'Please login first';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Enable debt due reminders';

  @override
  String get refresh => 'Refresh';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get unlock => 'Unlock';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get installments => 'Installments';

  @override
  String get installment => 'Installment';

  @override
  String get installmentPlan => 'Installment Plan';

  @override
  String get numberOfInstallments => 'Number of Installments';

  @override
  String get firstInstallmentDate => 'First Installment Date';

  @override
  String get noInstallments => 'No installments found';

  @override
  String get pdfReportTitle => 'Debt Book Report';

  @override
  String get pdfPerson => 'Person';

  @override
  String get pdfDescription => 'Description';

  @override
  String get pdfOriginalAmount => 'Original Amount';

  @override
  String get pdfBalance => 'Balance';

  @override
  String get pdfStatus => 'Status';

  @override
  String get pdfDueDate => 'Due Date';

  @override
  String get newDebtNotificationTitle => 'New Debt';

  @override
  String newDebtNotificationBody(Object amount) {
    return 'A debt of $amount IQD was added';
  }

  @override
  String get dueSoonNotificationTitle => 'Reminder';

  @override
  String get dueSoonNotificationBody => 'Your debt is due soon';

  @override
  String get invalidAmount => 'Please enter a valid amount';

  @override
  String get optional => 'Optional';

  @override
  String get reminder => 'Reminder';

  @override
  String get noReminder => 'No reminder';

  @override
  String beforeDays(Object days) {
    return '$days day(s) before';
  }

  @override
  String get confirmSave => 'Confirm Save';

  @override
  String get saveDebt => 'Save Debt';

  @override
  String get attachImage => 'Attach Image';

  @override
  String get changeImage => 'Change Image';

  @override
  String get nameExists => 'Name Already Exists';

  @override
  String get nameExistsMessage =>
      'A person with this name already exists. Do you want to add a debt to them?';

  @override
  String get createNew => 'Create New';

  @override
  String get addDebtToExisting => 'Add Debt to Existing';

  @override
  String get invalidPhone => 'Invalid phone number';

  @override
  String get nameTooLong => 'Name is too long (max 50 characters)';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get checkEmailToConfirm =>
      'Account created. Check your email to confirm.';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get send => 'Send';

  @override
  String get resetEmailSent => 'Reset email sent. Check your inbox.';

  @override
  String get passwordChanged => 'Password changed successfully';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirm =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get changePassword => 'Change Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get profile => 'Profile';

  @override
  String get totalOutstanding => 'Total Outstanding';

  @override
  String get statementFor => 'Statement for';

  @override
  String get sendWhatsAppStatement => 'Send via WhatsApp';

  @override
  String get exportStatementPdf => 'Export PDF';

  @override
  String get status => 'Status';

  @override
  String get cleanupViolations => 'Clean Violations';

  @override
  String get cleanupConfirm =>
      'This will fix duplicate payments, broken reversals, and invalid foreign keys. Continue?';

  @override
  String get cleanupYes => 'Clean';

  @override
  String get personDeleted => 'Person deleted successfully';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get pleaseFillFields => 'Please fill all fields';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get installmentPaid => 'Installment paid';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get notificationSettingsSubtitle =>
      'Customize reminders and quiet hours';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get enableNotificationsSubtitle => 'Turn all notifications on/off';

  @override
  String get quietHours => 'Quiet Hours';

  @override
  String get quietHoursSubtitle =>
      'Don\'t send notifications during these hours';

  @override
  String get quietHoursFrom => 'From';

  @override
  String get quietHoursTo => 'To';

  @override
  String get dueReminders => 'Due Reminders';

  @override
  String get remind7Days => '7 days before';

  @override
  String get remind3Days => '3 days before';

  @override
  String get remind1Day => '1 day before';

  @override
  String get remindOverdueDaily => 'Daily overdue reminder';

  @override
  String get remindOverdueSubtitle => 'Notify every day for overdue debts';

  @override
  String get otherNotifications => 'Other Notifications';

  @override
  String get weeklySummary => 'Weekly Summary';

  @override
  String get weeklySummarySubtitle => 'Every Sunday morning';

  @override
  String get paymentNotifications => 'Payment Notifications';

  @override
  String get paymentNotificationsSubtitle =>
      'When a new payment is received (from other devices)';

  @override
  String get notificationInfo =>
      'Notifications are sent automatically based on your settings. They will be updated when you open the app or modify debts.';

  @override
  String get syncDashboard => 'Sync Dashboard';

  @override
  String get syncDashboardSubtitle => 'Sync status and statistics';

  @override
  String get syncedSuccessfully => 'Synced successfully';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get pendingSync => 'Pending';

  @override
  String get failedSync => 'Failed';

  @override
  String get syncedSync => 'Synced';

  @override
  String get lastSync => 'Last Sync';

  @override
  String get neverSynced => 'Never synced';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get retryFailed => 'Retry Failed';

  @override
  String get clearSynced => 'Clear Synced';

  @override
  String get deleteSyncedTitle => 'Delete Synced Records';

  @override
  String get deleteSyncedMessage =>
      'All synced records will be removed from the Outbox queue.';

  @override
  String get howSyncWorks => 'How Sync Works';

  @override
  String get howSyncWorksBody =>
      '• Automatic sync every 30 seconds.\n• Operations are batched for speed.\n• Syncs automatically when internet returns.\n• Failed attempts retry with increasing intervals.';

  @override
  String get clearDataTitle => 'Clear All Data';

  @override
  String get clearDataMessage =>
      'Are you sure you want to clear all local data? This cannot be undone.';

  @override
  String get paymentReceivedTitle => 'Payment Received';

  @override
  String paymentReceivedBody(String personName, int amount) {
    return '$personName paid $amount IQD';
  }

  @override
  String get debtDueInWeek => 'Debt due in a week';

  @override
  String get debtDueInThreeDays => 'Debt due in 3 days';

  @override
  String get debtDueTomorrow => 'Debt due tomorrow';

  @override
  String get debtOverdueTitle => 'Overdue Debt';

  @override
  String get weeklySummaryTitle => 'Weekly Summary';

  @override
  String weeklySummaryBody(int active, int overdue, int total) {
    return 'You have $active active debts, $overdue overdue, total $total IQD';
  }

  @override
  String errorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String loginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String signupFailed(String error) {
    return 'Signup failed: $error';
  }

  @override
  String get noPaymentsInWeek => 'No payments in the last 7 days.';

  @override
  String uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String exportFailedGeneric(String error) {
    return 'Export failed: $error';
  }

  @override
  String amountWithCurrency(String amount) {
    return '$amount IQD';
  }

  @override
  String amountWithDinar(String amount) {
    return '$amount IQD';
  }

  @override
  String get noData => 'No data';

  @override
  String excelExportFailed(String error) {
    return 'Excel export failed: $error';
  }

  @override
  String get pdfStatement => 'PDF Statement';

  @override
  String sendPdfFailed(String error) {
    return 'Failed to send PDF: $error';
  }

  @override
  String installmentsUpdated(int count) {
    return 'Updated $count installment(s)';
  }

  @override
  String get switchGoogleAccount => 'Switch Google Account';

  @override
  String get switchGoogleAccountSubtitle =>
      'Sign in with a different Google account';

  @override
  String switchAccountFailed(String error) {
    return 'Switch account failed: $error';
  }

  @override
  String resetSettingsFailed(String error) {
    return 'Failed to reset settings: $error';
  }

  @override
  String get top5Debtors => 'Top 5 Debtors';

  @override
  String get monthlyStats => 'Monthly Statistics';

  @override
  String newDebtsAndPayments(int debts, int payments) {
    return '$debts new debt(s) • $payments payment(s)';
  }

  @override
  String get debtDistribution => 'Debt Distribution';

  @override
  String backupFailedWithError(String error) {
    return 'Backup failed: $error';
  }

  @override
  String restoreFailedWithError(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get debtFallback => 'Debt';

  @override
  String get unknownPerson => 'Unknown';

  @override
  String get exportPdfTooltip => 'Export PDF';

  @override
  String get switchAccountConfirm =>
      'You will be signed out of the current account. Continue?';

  @override
  String get resetSettingsSubtitle =>
      'Theme and language will return to defaults.\n\nYour data (people, debts, payments) will NOT be affected.';

  @override
  String get resetAction => 'Reset';

  @override
  String get resetSettingsDone => 'Settings reset to defaults';

  @override
  String get showTutorialAgain => 'Show Tutorial Again';

  @override
  String get showTutorialAgainSubtitle => 'Watch the onboarding tour again';

  @override
  String get tutorialWillAppear =>
      'The tutorial will appear when you reopen the app';

  @override
  String cleanupSuccess(int count) {
    return 'Fixed $count violation(s)';
  }

  @override
  String get resetSettingsShort => 'Restore theme and language to defaults';

  @override
  String offlineDataSaved(int count) {
    return 'No internet connection. Local data: $count people. Will sync automatically when connection returns.';
  }

  @override
  String get resetSettings => 'Reset Settings';

  @override
  String get switchAccount => 'Switch';

  @override
  String get databaseFileNotFound => 'Database file not found';

  @override
  String uploadSuccess(String size) {
    return '✅ Uploaded successfully ($size KB)';
  }

  @override
  String downloadSuccess(String size) {
    return '✅ Downloaded ($size KB). You can restore it from the local list.';
  }

  @override
  String get backupDeleted => '✅ Deleted';

  @override
  String get restoreFromCloud => 'Restore from Cloud';

  @override
  String get restoreFromCloudConfirm =>
      'The backup will be downloaded from cloud. You can restore it later from local backups. Continue?';

  @override
  String get download => 'Download';

  @override
  String get deleteCloudBackup => 'Delete Cloud Backup';

  @override
  String get deleteCloudBackupConfirm =>
      'Are you sure you want to delete this backup from the cloud?';

  @override
  String get localTab => 'Local';

  @override
  String get cloudTab => 'Cloud';

  @override
  String get uploadBackup => 'Upload Backup';

  @override
  String get share => 'Share';

  @override
  String get noCloudBackups => 'No cloud backups';

  @override
  String get noCloudBackupsHint =>
      'Tap \"Upload Backup\" to create your first cloud backup';

  @override
  String get deleteFromCloud => 'Delete from cloud';

  @override
  String get encrypted => 'Encrypted 🔒';

  @override
  String get aggregateReportTooltip => 'Export Aggregate Report';

  @override
  String get multiPersonReportTooltip => 'Multi-Person Report';

  @override
  String get excelExportTooltip => 'Export Excel';

  @override
  String get activeLabel => 'Active';

  @override
  String get overdueLabel => 'Overdue';

  @override
  String get completedLabel => 'Completed';

  @override
  String get monthlyDebtTrend => 'Monthly Debt Trend';

  @override
  String get reportsRefreshed => 'Reports refreshed locally';

  @override
  String get exportDone => 'Export Complete';

  @override
  String get shareFileQuestion => 'Do you want to share the file?';

  @override
  String get close => 'Close';

  @override
  String get noDataToExport => 'No data to export';

  @override
  String get exportReport => 'Export Report';

  @override
  String get simpleTextFile => 'Simple text file';

  @override
  String get officialReport => 'Official report';

  @override
  String get professionalTable => 'Professional formatted table';

  @override
  String get groupedDebtsReport => 'Grouped Debts Report';

  @override
  String get individualView => 'Individual View';

  @override
  String get groupedView => 'Grouped View';

  @override
  String get voiceSearchUnavailable =>
      'Voice search unavailable. Please grant permission and install the language pack.';

  @override
  String get voiceNoMatch => 'Speech not recognized. Please try again.';

  @override
  String get voiceSearchTooltip => 'Voice Search';

  @override
  String get voiceListening => '🎤 Listening...';

  @override
  String get quickAdd => 'Quick Add';

  @override
  String get newPerson => 'New Person';

  @override
  String get newDebt => 'New Debt';

  @override
  String get add => 'Add';

  @override
  String get dataRefreshed => 'Data refreshed locally';

  @override
  String get choosePersonColor => 'Choose Person Color';

  @override
  String get removeColor => 'Remove Color';

  @override
  String get noPhoneForPerson => 'This person has no phone number';

  @override
  String get sendStatement => 'Send Statement';

  @override
  String get textMessage => 'Text Message';

  @override
  String get balanceSummaryInMessage => 'Balance summary in a message';

  @override
  String get fullPdfFile => 'Full file you can share';

  @override
  String mrMrs(String name) {
    return 'Mr./Ms. $name';
  }

  @override
  String get outstandingAmounts => 'Outstanding amounts:';

  @override
  String statementTotal(int total) {
    return 'Total: $total IQD';
  }

  @override
  String get statementTitle => 'Statement';

  @override
  String statementShareText(String name, int total) {
    return 'Statement - $name\nTotal: $total IQD';
  }

  @override
  String fromAmount(String amount) {
    return 'from $amount';
  }

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusActive => 'Active';

  @override
  String get changeColorTooltip => 'Change Color';
}
