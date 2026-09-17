import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:collection/collection.dart';

// Fake implementations for repositories
class FakeDebtRepository implements DebtRepository {
  final List<Debt> debts = [];
  final FakeLedgerRepository ledgerRepo;

  FakeDebtRepository(this.ledgerRepo);

  @override
  Future<void> createDebt(Debt debt, LedgerEntry initialEntry) async {
    debts.add(debt);
    await ledgerRepo.append(initialEntry);
  }

  @override
  Future<Debt?> findById(DebtId id) async =>
      debts.where((d) => d.id == id).firstOrNull;

  @override
  Future<List<Debt>> findByPersonId(PersonId personId) async =>
      debts.where((d) => d.personId == personId).toList();

  @override
  Future<List<Debt>> findAll() async => debts;

  @override
  Future<List<(Debt, String)>> findAllPaginatedWithPersonName({
    int limit = 50,
    int offset = 0,
  }) async {
    // تنفيذ بسيط للاختبارات
    return debts.map((d) => (d, '')).toList();
  }

  @override
  Future<void> updateDebt(Debt debt) async {
    final index = debts.indexWhere((d) => d.id == debt.id);
    if (index != -1) debts[index] = debt;
  }

  @override
  Future<void> softDelete(DebtId id) async {
    debts.removeWhere((d) => d.id == id);
  }
}

class FakeLedgerRepository implements LedgerRepository {
  final List<LedgerEntry> entries = [];

  @override
  Future<void> append(LedgerEntry entry) async => entries.add(entry);

  @override
  Future<List<LedgerEntry>> findByDebtId(DebtId debtId) async =>
      entries.where((e) => e.debtId == debtId).toList();

  @override
  Future<List<LedgerEntry>> findAll() async => entries;

  @override
  Future<void> hardDeleteEntry(LedgerEntryId id) async {
    entries.removeWhere((e) => e.id == id);
  }
}

class FakePaymentRepository implements PaymentRepository {
  final List<Payment> payments = [];
  final FakeLedgerRepository ledgerRepo;

  FakePaymentRepository(this.ledgerRepo);

  @override
  Future<void> recordPayment(Payment payment, LedgerEntry paymentEntry) async {
    payments.add(payment);
    await ledgerRepo.append(paymentEntry);
  }

  @override
  Future<List<Payment>> findByDebtId(DebtId debtId) async =>
      payments.where((p) => p.debtId == debtId).toList();

  @override
  Future<Payment?> findById(PaymentId id) async =>
      payments.where((p) => p.id == id).firstOrNull;

  @override
  Future<List<Payment>> findAll() async => payments;

  @override
  Future<void> softDeletePayment(PaymentId id) async {
    payments.removeWhere((p) => p.id == id);
  }
}

void main() {
  late FakeDebtRepository debtRepo;
  late FakeLedgerRepository ledgerRepo;
  late FakePaymentRepository paymentRepo;
  late LedgerIntegrityChecker checker;

  setUp(() {
    ledgerRepo = FakeLedgerRepository();
    debtRepo = FakeDebtRepository(ledgerRepo);
    paymentRepo = FakePaymentRepository(ledgerRepo);
    checker = LedgerIntegrityChecker(
      debtRepository: debtRepo,
      ledgerRepository: ledgerRepo,
      paymentRepository: paymentRepo,
    );
  });

  test('no violations when data is consistent', () async {
    final debtId = DebtId('d1');
    final debt = Debt(
      id: debtId,
      personId: PersonId('p1'),
      amount: Money(amount: 1000),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await debtRepo.createDebt(debt, LedgerEntry(
      id: LedgerEntryId('e1'),
      debtId: debtId,
      entryType: LedgerEntryType.debt_creation,
      amount: Money(amount: 1000),
      createdAt: DateTime.now(),
    ));

    final violations = await checker.check();
    expect(violations, isEmpty);
  });

  test('detects missing ledger', () async {
    final debtId = DebtId('d1');
    final debt = Debt(
      id: debtId,
      personId: PersonId('p1'),
      amount: Money(amount: 1000),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    debtRepo.debts.add(debt); // add debt without ledger

    final violations = await checker.check();
    expect(violations.any((v) => v.type == IntegrityViolationType.missingLedger), true);
  });

  test('detects broken reversal', () async {
    final debtId = DebtId('d1');
    final debt = Debt(
      id: debtId,
      personId: PersonId('p1'),
      amount: Money(amount: 1000),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    debtRepo.debts.add(debt);
    ledgerRepo.entries.add(LedgerEntry(
      id: LedgerEntryId('reversal1'),
      debtId: debtId,
      entryType: LedgerEntryType.reversal,
      amount: Money(amount: 500),
      sourceEntryId: LedgerEntryId('nonexistent'),
      createdAt: DateTime.now(),
    ));

    final violations = await checker.check();
    expect(violations.any((v) => v.type == IntegrityViolationType.brokenReversal), true);
  });
}