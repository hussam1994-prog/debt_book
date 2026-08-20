import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/observability/logging_service.dart';
import '../core/observability/metrics_service.dart';
import '../core/backup/backup_service.dart';
import '../core/security/security_service.dart';
import '../core/export/export_service.dart';
import '../core/database/app_database.dart';
import '../core/notifications/notification_service.dart';
import '../core/cloud/cloud_sync_service.dart';
import '../core/cloud/realtime_service.dart';

import '../data/repositories/person_repository_impl.dart';
import '../data/repositories/debt_repository_impl.dart';
import '../data/repositories/payment_repository_impl.dart';
import '../data/repositories/ledger_repository_impl.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final uuidGeneratorProvider = Provider<UuidGenerator>((ref) {
  return DefaultUuidGenerator();
});

final balanceCalculatorProvider = Provider<BalanceCalculator>((ref) {
  return const BalanceCalculator();
});

final overpaymentValidatorProvider = Provider<OverpaymentValidator>((ref) {
  return const OverpaymentValidator();
});

final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return PersonRepositoryImpl(ref.watch(appDatabaseProvider));
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(ref.watch(appDatabaseProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.watch(appDatabaseProvider));
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepositoryImpl(ref.watch(appDatabaseProvider));
});

final createPersonProvider = Provider<CreatePerson>((ref) {
  return CreatePerson(
    personRepository: ref.watch(personRepositoryProvider),
    uuidGenerator: ref.watch(uuidGeneratorProvider),
  );
});

final createDebtProvider = Provider<CreateDebt>((ref) {
  return CreateDebt(
    debtRepository: ref.watch(debtRepositoryProvider),
    personRepository: ref.watch(personRepositoryProvider),
    uuidGenerator: ref.watch(uuidGeneratorProvider),
  );
});

final addPaymentProvider = Provider<AddPayment>((ref) {
  return AddPayment(
    debtRepository: ref.watch(debtRepositoryProvider),
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    paymentRepository: ref.watch(paymentRepositoryProvider),
    uuidGenerator: ref.watch(uuidGeneratorProvider),
    balanceCalculator: ref.watch(balanceCalculatorProvider),
    overpaymentValidator: ref.watch(overpaymentValidatorProvider),
  );
});

final getBalanceProvider = Provider<GetBalance>((ref) {
  return GetBalance(
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    balanceCalculator: ref.watch(balanceCalculatorProvider),
  );
});

final reversePaymentProvider = Provider<ReversePayment>((ref) {
  return ReversePayment(
    paymentRepository: ref.watch(paymentRepositoryProvider),
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    debtRepository: ref.watch(debtRepositoryProvider),
    uuidGenerator: ref.watch(uuidGeneratorProvider),
  );
});

final addAdjustmentProvider = Provider<AddAdjustment>((ref) {
  return AddAdjustment(
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    uuidGenerator: ref.watch(uuidGeneratorProvider),
  );
});

final cancelDebtProvider = Provider<CancelDebt>((ref) {
  return CancelDebt(
    debtRepository: ref.watch(debtRepositoryProvider),
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    balanceCalculator: ref.watch(balanceCalculatorProvider),
    uuidGenerator: ref.watch(uuidGeneratorProvider),
  );
});

final getStatementProvider = Provider<GetStatement>((ref) {
  return GetStatement(
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    paymentRepository: ref.watch(paymentRepositoryProvider),
  );
});

final rebuildBalanceProvider = Provider<RebuildBalance>((ref) {
  return RebuildBalance(
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    balanceCalculator: ref.watch(balanceCalculatorProvider),
  );
});

final ledgerIntegrityCheckerProvider = Provider<LedgerIntegrityChecker>((ref) {
  return LedgerIntegrityChecker(
    debtRepository: ref.watch(debtRepositoryProvider),
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    paymentRepository: ref.watch(paymentRepositoryProvider),
  );
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

final loggingServiceProvider = Provider<LoggingService>((ref) {
  return LoggingService();
});

final metricsServiceProvider = Provider<MetricsService>((ref) {
  return MetricsService();
});

final paymentPredictionServiceProvider = Provider<PaymentPredictionService>((ref) {
  return PaymentPredictionService(ref.watch(paymentRepositoryProvider));
});

final debtRiskAnalyzerProvider = Provider<DebtRiskAnalyzer>((ref) {
  return const DebtRiskAnalyzer();
});

final smartInsightsServiceProvider = Provider<SmartInsightsService>((ref) {
  return SmartInsightsService(
    riskAnalyzer: ref.watch(debtRiskAnalyzerProvider),
    predictionService: ref.watch(paymentPredictionServiceProvider),
  );
});

final updatePersonProvider = Provider<UpdatePerson>((ref) {
  return UpdatePerson(ref.watch(personRepositoryProvider));
});

final deletePersonProvider = Provider<DeletePerson>((ref) {
  return DeletePerson(ref.watch(personRepositoryProvider));
});

final deleteDebtProvider = Provider<DeleteDebt>((ref) {
  return DeleteDebt(
    debtRepository: ref.watch(debtRepositoryProvider),
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    balanceCalculator: ref.watch(balanceCalculatorProvider),
    uuidGenerator: ref.watch(uuidGeneratorProvider),
  );
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(ref.watch(appDatabaseProvider));
});

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService(ref);
});
