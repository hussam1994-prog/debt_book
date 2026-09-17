import 'dart:async';   // ✅ لـ unawaited
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/observability/logging_service.dart';
import '../core/observability/metrics_service.dart';
import '../core/backup/backup_service.dart';
import '../core/security/security_service.dart';
import '../core/export/export_service.dart';
import '../core/export/excel_export_service.dart'; // ✅ جديد
import '../core/database/app_database.dart';
import '../core/database/outbox_repository.dart';
import '../core/notifications/notification_service.dart';
import '../core/cloud/cloud_sync_service.dart';
import '../core/cloud/realtime_service.dart';
import '../core/cloud/sync_service.dart';
import '../core/sync/sync_status_provider.dart';
import '../core/export/pdf_export_service.dart';
import '../core/auth/google_auth_service.dart';
import '../core/backup/cloud_backup_service.dart';
import '../core/voice/voice_search_service.dart';

import '../data/repositories/person_repository_impl.dart';
import '../data/repositories/debt_repository_impl.dart';
import '../data/repositories/payment_repository_impl.dart';
import '../data/repositories/ledger_repository_impl.dart';
import '../data/repositories/installment_repository_impl.dart';

// ─── Core ───
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

// ─── Auth ───
final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

// ─── SyncService ───
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final supabase = Supabase.instance.client;
  return SyncService(
    db: db,
    supabase: supabase,
    logger: ref.watch(loggingServiceProvider),
  );
});

// ─── OutboxRepository ───
final outboxRepositoryProvider = Provider<OutboxRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return OutboxRepository(
    db,
    onEnqueue: () => syncService.scheduleSyncNow(),
  );
});

// ─── Repositories ───
final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return PersonRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(outboxRepositoryProvider),
  );
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(outboxRepositoryProvider),
  );
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(outboxRepositoryProvider),
  );
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(outboxRepositoryProvider),
  );
});

final installmentRepositoryProvider = Provider<InstallmentRepository>((ref) {
  return InstallmentRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(outboxRepositoryProvider),
  );
});

// ─── UseCases ───
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

final createInstallmentsProvider = Provider<CreateInstallments>((ref) {
  return CreateInstallments(
    repository: ref.watch(installmentRepositoryProvider),
    uuidGenerator: ref.watch(uuidGeneratorProvider),
  );
});

final markInstallmentsPaidProvider = Provider<MarkInstallmentsPaid>((ref) {
  return MarkInstallmentsPaid(ref.watch(installmentRepositoryProvider));
});

// ─── Services ───
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

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

// ✅ خدمة تصدير Excel
final excelExportServiceProvider = Provider<ExcelExportService>((ref) {
  return ExcelExportService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  unawaited(service.initialize());
  return service;
});

final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportService();
});

final paymentPredictionServiceProvider =
    Provider<PaymentPredictionService>((ref) {
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

// ─── Cloud / Sync ───
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(
    ref.watch(appDatabaseProvider),
    ref.read(syncStatusProvider.notifier),
  );
});

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService(ref);
});

final cloudBackupServiceProvider = Provider<CloudBackupService>((ref) {
  return CloudBackupService();
});

final voiceSearchServiceProvider = Provider<VoiceSearchService>((ref) {
  return VoiceSearchService();
});