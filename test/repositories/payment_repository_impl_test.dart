import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/data/repositories/payment_repository_impl.dart';
import 'package:mobile/data/repositories/debt_repository_impl.dart';
import 'package:mobile/data/repositories/ledger_repository_impl.dart';
import 'package:mobile/data/repositories/person_repository_impl.dart';

void main() {
  late AppDatabase db;
  late DebtRepositoryImpl debtRepo;
  late PaymentRepositoryImpl paymentRepo;
  late LedgerRepositoryImpl ledgerRepo;

  setUp(() {
    db = AppDatabase.memory();
    debtRepo = DebtRepositoryImpl(db);
    paymentRepo = PaymentRepositoryImpl(db);
    ledgerRepo = LedgerRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('recordPayment inserts payment and ledger entry atomically', () async {
    // Create a person
    final personId = PersonId('person-1');
    final person = Person(
      id: personId,
      name: 'Test Person',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await PersonRepositoryImpl(db).save(person);

    // Create a debt with opening entry
    final debtId = DebtId('debt-1');
    final debt = Debt(
      id: debtId,
      personId: personId,
      amount: Money(amount: 1000),
      status: DebtStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final openingEntry = LedgerEntry(
      id: LedgerEntryId('entry-1'),
      debtId: debtId,
      entryType: LedgerEntryType.debt_creation,
      amount: Money(amount: 1000),
      createdAt: DateTime.now(),
    );
    await debtRepo.createDebt(debt, openingEntry);

    // Record a payment
    final payment = Payment(
      id: PaymentId('payment-1'),
      debtId: debtId,
      amount: Money(amount: 300),
      paymentDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final paymentEntry = LedgerEntry(
      id: LedgerEntryId('entry-2'),
      debtId: debtId,
      entryType: LedgerEntryType.payment,
      amount: Money(amount: -300),
      paymentId: payment.id,
      createdAt: DateTime.now(),
    );
    await paymentRepo.recordPayment(payment, paymentEntry);

    // Verify
    final entries = await ledgerRepo.findByDebtId(debtId);
    expect(entries.length, 2);
    final balance = entries.fold<int>(0, (sum, e) => sum + e.amount.amount);
    expect(balance, 700);
    final payments = await paymentRepo.findByDebtId(debtId);
    expect(payments.length, 1);
    expect(payments.first.amount.amount, 300);
  });

  test('recordPayment rolls back on failure', () async {
    // Simulate failure by trying to insert payment with invalid debtId (FK violation)
    final payment = Payment(
      id: PaymentId('payment-2'),
      debtId: DebtId('non-existent-debt'),
      amount: Money(amount: 100),
      paymentDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final paymentEntry = LedgerEntry(
      id: LedgerEntryId('entry-3'),
      debtId: DebtId('non-existent-debt'),
      entryType: LedgerEntryType.payment,
      amount: Money(amount: -100),
      paymentId: payment.id,
      createdAt: DateTime.now(),
    );
    expect(() async => await paymentRepo.recordPayment(payment, paymentEntry),
        throwsA(anything));
    // لا يجب أن يوجد قيد
    final entries = await ledgerRepo.findAll();
    expect(entries, isEmpty);
  });
}