import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt Book'**
  String get appTitle;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @allDebts.
  ///
  /// In en, this message translates to:
  /// **'All Debts'**
  String get allDebts;

  /// No description provided for @addPerson.
  ///
  /// In en, this message translates to:
  /// **'Add Person'**
  String get addPerson;

  /// No description provided for @addDebt.
  ///
  /// In en, this message translates to:
  /// **'Add Debt'**
  String get addDebt;

  /// No description provided for @addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add Payment'**
  String get addPayment;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @noDebts.
  ///
  /// In en, this message translates to:
  /// **'No Debts'**
  String get noDebts;

  /// No description provided for @noPeople.
  ///
  /// In en, this message translates to:
  /// **'No People'**
  String get noPeople;

  /// No description provided for @noOverdue.
  ///
  /// In en, this message translates to:
  /// **'No overdue debts'**
  String get noOverdue;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @originalAmount.
  ///
  /// In en, this message translates to:
  /// **'Original Amount'**
  String get originalAmount;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone...'**
  String get searchHint;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @debts.
  ///
  /// In en, this message translates to:
  /// **'debts'**
  String get debts;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @paymentsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Payments (Last 7 Days)'**
  String get paymentsLast7Days;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @totalDebts.
  ///
  /// In en, this message translates to:
  /// **'Total Debts'**
  String get totalDebts;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @noLedgerEntries.
  ///
  /// In en, this message translates to:
  /// **'No Ledger Entries'**
  String get noLedgerEntries;

  /// No description provided for @noPayments.
  ///
  /// In en, this message translates to:
  /// **'No Payments'**
  String get noPayments;

  /// No description provided for @addAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Add Adjustment'**
  String get addAdjustment;

  /// No description provided for @cancelDebt.
  ///
  /// In en, this message translates to:
  /// **'Cancel Debt'**
  String get cancelDebt;

  /// No description provided for @deleteDebt.
  ///
  /// In en, this message translates to:
  /// **'Delete Debt'**
  String get deleteDebt;

  /// No description provided for @confirmDeleteDebt.
  ///
  /// In en, this message translates to:
  /// **'This will cancel the debt and zero out balance. Are you sure?'**
  String get confirmDeleteDebt;

  /// No description provided for @confirmCancelDebt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this debt?'**
  String get confirmCancelDebt;

  /// No description provided for @confirmDeletePerson.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will hide the person and all related data.'**
  String get confirmDeletePerson;

  /// No description provided for @wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get wrongPin;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get newPin;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// No description provided for @noBackups.
  ///
  /// In en, this message translates to:
  /// **'No backups'**
  String get noBackups;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @csvExported.
  ///
  /// In en, this message translates to:
  /// **'CSV exported to:'**
  String get csvExported;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed:'**
  String get exportFailed;

  /// No description provided for @adjustmentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount (IQD)'**
  String get adjustmentAmount;

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increase;

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decrease;

  /// No description provided for @submitPayment.
  ///
  /// In en, this message translates to:
  /// **'Submit Payment'**
  String get submitPayment;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get enterName;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @dueDateHint.
  ///
  /// In en, this message translates to:
  /// **'Due Date (YYYY-MM-DD)'**
  String get dueDateHint;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @debtDetails.
  ///
  /// In en, this message translates to:
  /// **'Debt Details'**
  String get debtDetails;

  /// No description provided for @debtCancelled.
  ///
  /// In en, this message translates to:
  /// **'Debt cancelled'**
  String get debtCancelled;

  /// No description provided for @adjustmentAdded.
  ///
  /// In en, this message translates to:
  /// **'Adjustment added'**
  String get adjustmentAdded;

  /// No description provided for @paymentReversed.
  ///
  /// In en, this message translates to:
  /// **'Payment reversed'**
  String get paymentReversed;

  /// No description provided for @smartInsights.
  ///
  /// In en, this message translates to:
  /// **'Smart Insights'**
  String get smartInsights;

  /// No description provided for @noInsights.
  ///
  /// In en, this message translates to:
  /// **'No insights'**
  String get noInsights;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created'**
  String get backupCreated;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get backupFailed;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get restoreFailed;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored. Restart the app to apply changes.'**
  String get backupRestored;

  /// No description provided for @deleteBackup.
  ///
  /// In en, this message translates to:
  /// **'Delete backup'**
  String get deleteBackup;

  /// No description provided for @confirmRestore.
  ///
  /// In en, this message translates to:
  /// **'This will replace all current data. Are you sure?'**
  String get confirmRestore;

  /// No description provided for @confirmDeleteBackup.
  ///
  /// In en, this message translates to:
  /// **'Delete this backup?'**
  String get confirmDeleteBackup;

  /// No description provided for @allGood.
  ///
  /// In en, this message translates to:
  /// **'All good! No violations found.'**
  String get allGood;

  /// No description provided for @runIntegrity.
  ///
  /// In en, this message translates to:
  /// **'Run Ledger Integrity Check'**
  String get runIntegrity;

  /// No description provided for @pinSetSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN set successfully'**
  String get pinSetSuccess;

  /// No description provided for @personDetails.
  ///
  /// In en, this message translates to:
  /// **'Person Details'**
  String get personDetails;

  /// No description provided for @rejectOverpayment.
  ///
  /// In en, this message translates to:
  /// **'Reject overpayment'**
  String get rejectOverpayment;

  /// No description provided for @capAtZero.
  ///
  /// In en, this message translates to:
  /// **'Cap at zero'**
  String get capAtZero;

  /// No description provided for @allowOverpayment.
  ///
  /// In en, this message translates to:
  /// **'Allow overpayment'**
  String get allowOverpayment;

  /// No description provided for @debtCreation.
  ///
  /// In en, this message translates to:
  /// **'Debt Creation'**
  String get debtCreation;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @reversal.
  ///
  /// In en, this message translates to:
  /// **'Reversal'**
  String get reversal;

  /// No description provided for @adjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get adjustment;

  /// No description provided for @whatsappTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send WhatsApp message'**
  String get whatsappTooltip;

  /// No description provided for @whatsappGeneralMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello, this is a reminder from Debt Book.'**
  String get whatsappGeneralMessage;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloudSync;

  /// No description provided for @cloudSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Synced persons count:'**
  String get cloudSyncSuccess;

  /// No description provided for @cloudSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String cloudSyncFailed(Object error);

  /// No description provided for @cloudSyncResult.
  ///
  /// In en, this message translates to:
  /// **'Synced: {persons} persons, {debts} debts, {payments} payments, {ledger} ledger, {installments} installments'**
  String cloudSyncResult(
    Object debts,
    Object installments,
    Object ledger,
    Object payments,
    Object persons,
  );

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please login first'**
  String get pleaseLoginFirst;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable debt due reminders'**
  String get notificationsSubtitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @installments.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get installments;

  /// No description provided for @installment.
  ///
  /// In en, this message translates to:
  /// **'Installment'**
  String get installment;

  /// No description provided for @installmentPlan.
  ///
  /// In en, this message translates to:
  /// **'Installment Plan'**
  String get installmentPlan;

  /// No description provided for @numberOfInstallments.
  ///
  /// In en, this message translates to:
  /// **'Number of Installments'**
  String get numberOfInstallments;

  /// No description provided for @firstInstallmentDate.
  ///
  /// In en, this message translates to:
  /// **'First Installment Date'**
  String get firstInstallmentDate;

  /// No description provided for @noInstallments.
  ///
  /// In en, this message translates to:
  /// **'No installments found'**
  String get noInstallments;

  /// No description provided for @pdfReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt Book Report'**
  String get pdfReportTitle;

  /// No description provided for @pdfPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get pdfPerson;

  /// No description provided for @pdfDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get pdfDescription;

  /// No description provided for @pdfOriginalAmount.
  ///
  /// In en, this message translates to:
  /// **'Original Amount'**
  String get pdfOriginalAmount;

  /// No description provided for @pdfBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get pdfBalance;

  /// No description provided for @pdfStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pdfStatus;

  /// No description provided for @pdfDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get pdfDueDate;

  /// No description provided for @newDebtNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'New Debt'**
  String get newDebtNotificationTitle;

  /// No description provided for @newDebtNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'A debt of {amount} IQD was added'**
  String newDebtNotificationBody(Object amount);

  /// No description provided for @dueSoonNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get dueSoonNotificationTitle;

  /// No description provided for @dueSoonNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your debt is due soon'**
  String get dueSoonNotificationBody;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @noReminder.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get noReminder;

  /// No description provided for @beforeDays.
  ///
  /// In en, this message translates to:
  /// **'{days} day(s) before'**
  String beforeDays(Object days);

  /// No description provided for @confirmSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm Save'**
  String get confirmSave;

  /// No description provided for @saveDebt.
  ///
  /// In en, this message translates to:
  /// **'Save Debt'**
  String get saveDebt;

  /// No description provided for @attachImage.
  ///
  /// In en, this message translates to:
  /// **'Attach Image'**
  String get attachImage;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @nameExists.
  ///
  /// In en, this message translates to:
  /// **'Name Already Exists'**
  String get nameExists;

  /// No description provided for @nameExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'A person with this name already exists. Do you want to add a debt to them?'**
  String get nameExistsMessage;

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNew;

  /// No description provided for @addDebtToExisting.
  ///
  /// In en, this message translates to:
  /// **'Add Debt to Existing'**
  String get addDebtToExisting;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhone;

  /// No description provided for @nameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name is too long (max 50 characters)'**
  String get nameTooLong;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @checkEmailToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Account created. Check your email to confirm.'**
  String get checkEmailToConfirm;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Reset email sent. Check your inbox.'**
  String get resetEmailSent;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @totalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total Outstanding'**
  String get totalOutstanding;

  /// No description provided for @statementFor.
  ///
  /// In en, this message translates to:
  /// **'Statement for'**
  String get statementFor;

  /// No description provided for @sendWhatsAppStatement.
  ///
  /// In en, this message translates to:
  /// **'Send via WhatsApp'**
  String get sendWhatsAppStatement;

  /// No description provided for @exportStatementPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportStatementPdf;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @cleanupViolations.
  ///
  /// In en, this message translates to:
  /// **'Clean Violations'**
  String get cleanupViolations;

  /// No description provided for @cleanupConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will fix duplicate payments, broken reversals, and invalid foreign keys. Continue?'**
  String get cleanupConfirm;

  /// No description provided for @cleanupYes.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get cleanupYes;

  /// No description provided for @personDeleted.
  ///
  /// In en, this message translates to:
  /// **'Person deleted successfully'**
  String get personDeleted;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @pleaseFillFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillFields;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @installmentPaid.
  ///
  /// In en, this message translates to:
  /// **'Installment paid'**
  String get installmentPaid;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @notificationSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize reminders and quiet hours'**
  String get notificationSettingsSubtitle;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @enableNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn all notifications on/off'**
  String get enableNotificationsSubtitle;

  /// No description provided for @quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get quietHours;

  /// No description provided for @quietHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t send notifications during these hours'**
  String get quietHoursSubtitle;

  /// No description provided for @quietHoursFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get quietHoursFrom;

  /// No description provided for @quietHoursTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get quietHoursTo;

  /// No description provided for @dueReminders.
  ///
  /// In en, this message translates to:
  /// **'Due Reminders'**
  String get dueReminders;

  /// No description provided for @remind7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days before'**
  String get remind7Days;

  /// No description provided for @remind3Days.
  ///
  /// In en, this message translates to:
  /// **'3 days before'**
  String get remind3Days;

  /// No description provided for @remind1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get remind1Day;

  /// No description provided for @remindOverdueDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily overdue reminder'**
  String get remindOverdueDaily;

  /// No description provided for @remindOverdueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify every day for overdue debts'**
  String get remindOverdueSubtitle;

  /// No description provided for @otherNotifications.
  ///
  /// In en, this message translates to:
  /// **'Other Notifications'**
  String get otherNotifications;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get weeklySummary;

  /// No description provided for @weeklySummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every Sunday morning'**
  String get weeklySummarySubtitle;

  /// No description provided for @paymentNotifications.
  ///
  /// In en, this message translates to:
  /// **'Payment Notifications'**
  String get paymentNotifications;

  /// No description provided for @paymentNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a new payment is received (from other devices)'**
  String get paymentNotificationsSubtitle;

  /// No description provided for @notificationInfo.
  ///
  /// In en, this message translates to:
  /// **'Notifications are sent automatically based on your settings. They will be updated when you open the app or modify debts.'**
  String get notificationInfo;

  /// No description provided for @syncDashboard.
  ///
  /// In en, this message translates to:
  /// **'Sync Dashboard'**
  String get syncDashboard;

  /// No description provided for @syncDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync status and statistics'**
  String get syncDashboardSubtitle;

  /// No description provided for @syncedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Synced successfully'**
  String get syncedSuccessfully;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingSync;

  /// No description provided for @failedSync.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedSync;

  /// No description provided for @syncedSync.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncedSync;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get lastSync;

  /// No description provided for @neverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get neverSynced;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @retryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry Failed'**
  String get retryFailed;

  /// No description provided for @clearSynced.
  ///
  /// In en, this message translates to:
  /// **'Clear Synced'**
  String get clearSynced;

  /// No description provided for @deleteSyncedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Synced Records'**
  String get deleteSyncedTitle;

  /// No description provided for @deleteSyncedMessage.
  ///
  /// In en, this message translates to:
  /// **'All synced records will be removed from the Outbox queue.'**
  String get deleteSyncedMessage;

  /// No description provided for @howSyncWorks.
  ///
  /// In en, this message translates to:
  /// **'How Sync Works'**
  String get howSyncWorks;

  /// No description provided for @howSyncWorksBody.
  ///
  /// In en, this message translates to:
  /// **'• Automatic sync every 30 seconds.\n• Operations are batched for speed.\n• Syncs automatically when internet returns.\n• Failed attempts retry with increasing intervals.'**
  String get howSyncWorksBody;

  /// No description provided for @clearDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearDataTitle;

  /// No description provided for @clearDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all local data? This cannot be undone.'**
  String get clearDataMessage;

  /// No description provided for @paymentReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get paymentReceivedTitle;

  /// No description provided for @paymentReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'{personName} paid {amount} IQD'**
  String paymentReceivedBody(String personName, int amount);

  /// No description provided for @debtDueInWeek.
  ///
  /// In en, this message translates to:
  /// **'Debt due in a week'**
  String get debtDueInWeek;

  /// No description provided for @debtDueInThreeDays.
  ///
  /// In en, this message translates to:
  /// **'Debt due in 3 days'**
  String get debtDueInThreeDays;

  /// No description provided for @debtDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Debt due tomorrow'**
  String get debtDueTomorrow;

  /// No description provided for @debtOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Overdue Debt'**
  String get debtOverdueTitle;

  /// No description provided for @weeklySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get weeklySummaryTitle;

  /// No description provided for @weeklySummaryBody.
  ///
  /// In en, this message translates to:
  /// **'You have {active} active debts, {overdue} overdue, total {total} IQD'**
  String weeklySummaryBody(int active, int overdue, int total);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorGeneric(String message);

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(String error);

  /// No description provided for @signupFailed.
  ///
  /// In en, this message translates to:
  /// **'Signup failed: {error}'**
  String signupFailed(String error);

  /// No description provided for @noPaymentsInWeek.
  ///
  /// In en, this message translates to:
  /// **'No payments in the last 7 days.'**
  String get noPaymentsInWeek;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(String error);

  /// No description provided for @exportFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailedGeneric(String error);

  /// No description provided for @amountWithCurrency.
  ///
  /// In en, this message translates to:
  /// **'{amount} IQD'**
  String amountWithCurrency(String amount);

  /// No description provided for @amountWithDinar.
  ///
  /// In en, this message translates to:
  /// **'{amount} IQD'**
  String amountWithDinar(String amount);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @excelExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Excel export failed: {error}'**
  String excelExportFailed(String error);

  /// No description provided for @pdfStatement.
  ///
  /// In en, this message translates to:
  /// **'PDF Statement'**
  String get pdfStatement;

  /// No description provided for @sendPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send PDF: {error}'**
  String sendPdfFailed(String error);

  /// No description provided for @installmentsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} installment(s)'**
  String installmentsUpdated(int count);

  /// No description provided for @switchGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch Google Account'**
  String get switchGoogleAccount;

  /// No description provided for @switchGoogleAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with a different Google account'**
  String get switchGoogleAccountSubtitle;

  /// No description provided for @switchAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Switch account failed: {error}'**
  String switchAccountFailed(String error);

  /// No description provided for @resetSettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset settings: {error}'**
  String resetSettingsFailed(String error);

  /// No description provided for @top5Debtors.
  ///
  /// In en, this message translates to:
  /// **'Top 5 Debtors'**
  String get top5Debtors;

  /// No description provided for @monthlyStats.
  ///
  /// In en, this message translates to:
  /// **'Monthly Statistics'**
  String get monthlyStats;

  /// No description provided for @newDebtsAndPayments.
  ///
  /// In en, this message translates to:
  /// **'{debts} new debt(s) • {payments} payment(s)'**
  String newDebtsAndPayments(int debts, int payments);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
