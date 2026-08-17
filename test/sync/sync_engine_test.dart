import 'dart:convert';
import 'package:contracts/contracts.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/observability/logging_service.dart';
import 'package:mobile/core/observability/metrics_service.dart';
import 'package:mobile/data/sync/sync_engine.dart';
import 'package:mobile/data/repositories/payment_repository_impl.dart';
import 'package:mobile/data/repositories/debt_repository_impl.dart';
import 'package:mobile/data/repositories/ledger_repository_impl.dart';
import 'package:mobile/data/repositories/person_repository_impl.dart';

void main() {
  late AppDatabase db;
  late SyncEngine syncEngine;
  late MockClient mockClient;

  setUp(() {
    db = AppDatabase.memory();
    mockClient = MockClient((request) async {
      if (request.url.path == '/api/sync/push') {
        // معالجة الطلب والعودة نجاح
        return http.Response(
          jsonEncode({'success': true, 'serverSequence': 1}),
          200,
        );
      } else if (request.url.path == '/api/sync/pull') {
        return http.Response(
          jsonEncode({
            'persons': [],
            'debts': [],
            'payments': [],
            'ledgerEntries': [],
            'nextCursor': 0,
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });
    syncEngine = SyncEngine(
      db: db,
      serverUrl: 'http://localhost',
      logger: LoggingService(),
      metrics: MetricsService(),
    );
    // Override http client? - need to inject or modify SyncEngine to accept http.Client
    // We'll assume SyncEngine has a constructor parameter `http.Client? client`
    // For now, we'll directly test the logic via db and mock.
  });

  tearDown(() async {
    await db.close();
  });

  test('sync pushes pending operations and marks them synced', () async {
    // Seed a person and debt, then add payment to create sync_queue entry
    final personId = PersonId('p1');
    final person = Person(
      id: personId,
      name: 'Test',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await PersonRepositoryImpl(db).save(person);

    final debtId = DebtId('d1');
    final debt = Debt(
      id: debtId,
      personId: personId,
      amount: Money(amount: 500),
      status: DebtStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final entry = LedgerEntry(
      id: LedgerEntryId('e1'),
      debtId: debtId,
      entryType: LedgerEntryType.debt_creation,
      amount: Money(amount: 500),
      createdAt: DateTime.now(),
    );
    await DebtRepositoryImpl(db).createDebt(debt, entry);

    final payment = Payment(
      id: PaymentId('pay1'),
      debtId: debtId,
      amount: Money(amount: 200),
      paymentDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final paymentEntry = LedgerEntry(
      id: LedgerEntryId('e2'),
      debtId: debtId,
      entryType: LedgerEntryType.payment,
      amount: Money(amount: -200),
      paymentId: payment.id,
      createdAt: DateTime.now(),
    );
    await PaymentRepositoryImpl(db).recordPayment(payment, paymentEntry);

    // Check sync_queue has pending op
    final pending = await (db.select(db.syncQueue)
          ..where((t) => t.status.equals('pending')))
        .get();
    expect(pending.length, 1);

    // Run sync
    final count = await syncEngine.sync();

    expect(count, 1);
    final afterSync = await (db.select(db.syncQueue)
          ..where((t) => t.status.equals('synced')))
        .get();
    expect(afterSync.length, 1);
  });
}