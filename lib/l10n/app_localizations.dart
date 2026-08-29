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

  /// No description provided for @whatsappMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello, you owe {amount} IQD. Please settle your debt. Thank you'**
  String whatsappMessage(Object amount);

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

  /// No description provided for @nameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name is too long (max 50 characters)'**
  String get nameTooLong;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhone;

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

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloudSync;

  /// No description provided for @cloudSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Fetched persons from cloud:'**
  String get cloudSyncSuccess;

  /// No description provided for @cloudSyncResult.
  ///
  /// In en, this message translates to:
  /// **'Synced: {persons} persons, {debts} debts, {payments} payments, {ledger} ledger entries'**
  String cloudSyncResult(
    Object debts,
    Object ledger,
    Object payments,
    Object persons,
  );

  /// No description provided for @cloudSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String cloudSyncFailed(Object error);

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

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @pleaseFillFields.
  ///
  /// In en, this message translates to:
  /// **'Please enter email and password'**
  String get pleaseFillFields;

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

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please login first'**
  String get pleaseLoginFirst;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

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

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

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

  /// No description provided for @personDeleted.
  ///
  /// In en, this message translates to:
  /// **'Person deleted successfully'**
  String get personDeleted;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

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

  /// No description provided for @installmentPlan.
  ///
  /// In en, this message translates to:
  /// **'Installment Plan'**
  String get installmentPlan;

  /// No description provided for @installment.
  ///
  /// In en, this message translates to:
  /// **'Installment'**
  String get installment;

  /// No description provided for @installments.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get installments;

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

  /// No description provided for @noInstallments.
  ///
  /// In en, this message translates to:
  /// **'No installments found'**
  String get noInstallments;

  /// No description provided for @installmentDueDate.
  ///
  /// In en, this message translates to:
  /// **'Installment Due Date'**
  String get installmentDueDate;

  /// No description provided for @installmentAmount.
  ///
  /// In en, this message translates to:
  /// **'Installment Amount'**
  String get installmentAmount;

  /// No description provided for @installmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Installment Status'**
  String get installmentStatus;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @installmentPaid.
  ///
  /// In en, this message translates to:
  /// **'Installment marked as paid'**
  String get installmentPaid;

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
