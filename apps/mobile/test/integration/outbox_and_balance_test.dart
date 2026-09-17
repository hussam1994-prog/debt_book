import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/outbox_repository.dart';
import 'package:mobile/core/database/tables/outbox_table.dart';
import 'package:mobile/data/repositories/debt_repository_impl.dart';
import 'package:mobile/data/repositories/ledger_repository_impl.dart';
import 'package:mobile/data/repositories/payment_repository_impl.dart';
import 'package:mobile/data/repositories/person_repository_impl.dart';

void main() {
  late AppDatabase db;
  late OutboxRepository outboxRepo;
  late PersonRepositoryImpl personRepo;
  late DebtRepositoryImpl debtRepo;
  late PaymentRepositoryImpl paymentRepo;
  late LedgerRepositoryImpl ledgerRepo;

  setUp(() {
    db = AppDatabase.memory();
    outboxRepo = OutboxRepository(db);
    personRepo = PersonRepositoryImpl(db, outboxRepo);
    debtRepo = DebtRepositoryImpl(db, outboxRepo);
    paymentRepo = PaymentRepositoryImpl(db, outboxRepo);
    ledgerRepo = LedgerRepositoryImpl(db, outboxRepo);
  });

  tearDown(() async {
    await db.close();
  });


  test('full workflow: create person, debt, payment, check balance and outbox', () async {
    // 1. إنشاء شخص
    final person = Person(
      id: PersonId('p1'),
      name: 'Test Person',
      phone: '123456789',
      email: null,
      notes: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      isDeleted: false,
      deletedAt: null,
    );
    await personRepo.save(person);

    // 2. إنشاء دين مع قيد أولي
    final debt = Debt(
      id: DebtId('d1'),
      personId: person.id,
      description: 'Test debt',
      amount: Money(amount: 1000, currency: 'IQD'),
      dueDate: null,
      status: DebtStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      isDeleted: false,
      deletedAt: null,
      attachmentPath: null,
    );
    final initialEntry = LedgerEntry(
      id: LedgerEntryId('e1'),
      debtId: debt.id,
      entryType: LedgerEntryType.debt_creation,
      amount: Money(amount: 1000, currency: 'IQD'),
      correlationId: null,
      sourceEntryId: null,
      paymentId: null,
      createdAt: DateTime.now(),
      serverSequence: null,
    );
    await debtRepo.createDebt(debt, initialEntry);

    // 3. إضافة دفعة 300
    final payment = Payment(
      id: PaymentId('pay1'),
      debtId: debt.id,
      amount: Money(amount: 300, currency: 'IQD'),
      paymentDate: DateTime.now(),
      method: PaymentMethod.cash,
      notes: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      isDeleted: false,
      deletedAt: null,
    );
    final paymentEntry = LedgerEntry(
      id: LedgerEntryId('e2'),
      debtId: debt.id,
      entryType: LedgerEntryType.payment,
      amount: Money(amount: -300, currency: 'IQD'),
      correlationId: null,
      sourceEntryId: null,
      paymentId: payment.id,
      createdAt: DateTime.now(),
      serverSequence: null,
    );
    await paymentRepo.recordPayment(payment, paymentEntry);

    // 4. التحقق من الرصيد (1000 - 300 = 700)
    final entries = await ledgerRepo.findByDebtId(debt.id);
    final balance = BalanceCalculator().calculateBalance(entries);
    expect(balance.amount, 700);

    // 5. التحقق من تسجيل Outbox
    final outboxItems = await outboxRepo.getDueItems();
    // يجب أن يكون لدينا 3 عناصر: person insert, debt insert, payment insert + ledger entry insert (لأن recordPayment يسجل payment و ledger_entry في نفس المعاملة)
    expect(outboxItems.length, 5);

    final entityTypes = outboxItems.map((e) => e.entityType).toSet();
    expect(entityTypes.contains('person'), true);
    expect(entityTypes.contains('debt'), true);
    expect(entityTypes.contains('payment'), true);
    expect(entityTypes.contains('ledger_entry'), true);

    final operations = outboxItems.map((e) => e.operation).toSet();
    expect(operations.every((op) => op == OutboxOperation.insert), true);
  });
}