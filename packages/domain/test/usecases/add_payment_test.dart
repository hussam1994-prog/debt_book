import 'package:domain/domain.dart';
import 'package:test/test.dart';

// --- Fake Repositories ---

class FakeDebtRepository implements DebtRepository {
  final Map<String, Debt> _debts = {};

  @override
  Future<void> createDebt(Debt debt, LedgerEntry initialEntry) async {
    _debts[debt.id.value] = debt;
  }

  @override
  Future<List<Debt>> findAll() async {
    return _debts.values.toList();
  }

  @override
  Future<void> updateDebt(Debt debt) async {
    _debts[debt.id.value] = debt;
  }

  @override
  Future<Debt?> findById(DebtId id) async {
    return _debts[id.value];
  }

  @override
  Future<List<Debt>> findByPersonId(PersonId personId) async {
    return _debts.values.where((d) => d.personId == personId).toList();
  }

  @override
  Future<List<(Debt, String)>> findAllPaginatedWithPersonName({
    int limit = 50,
    int offset = 0,
  }) async {
    // تنفيذ بسيط للاختبارات
    return _debts.values.map((d) => (d, '')).toList();
  }

  @override
  Future<void> softDelete(DebtId id) async {
    _debts.remove(id.value);
  }

  // Helper to seed a debt
  void addDebt(Debt debt) {
    _debts[debt.id.value] = debt;
  }
}

class FakeLedgerRepository implements LedgerRepository {
  final List<LedgerEntry> _entries = [];

  @override
  Future<void> append(LedgerEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<LedgerEntry>> findAll() async {
    return List.of(_entries);
  }

  @override
  Future<List<LedgerEntry>> findByDebtId(DebtId debtId) async {
    return _entries.where((e) => e.debtId == debtId).toList();
  }

  @override
  Future<void> hardDeleteEntry(LedgerEntryId id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  // Helper to seed initial entry
  void addEntry(LedgerEntry entry) {
    _entries.add(entry);
  }
}

class FakePaymentRepository implements PaymentRepository {
  final List<Payment> _payments = [];
  final FakeLedgerRepository _ledgerRepo;

  FakePaymentRepository(this._ledgerRepo);

  @override
  Future<void> recordPayment(Payment payment, LedgerEntry paymentEntry) async {
    _payments.add(payment);
    await _ledgerRepo.append(paymentEntry);
  }

  @override
  Future<List<Payment>> findAll() async {
    return List.of(_payments);
  }

  @override
  Future<Payment?> findById(PaymentId id) async {
    for (final p in _payments) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<void> softDeletePayment(PaymentId id) async {
    final index = _payments.indexWhere((p) => p.id == id);
    if (index != -1) {
      _payments[index] = Payment(
        id: _payments[index].id,
        debtId: _payments[index].debtId,
        amount: _payments[index].amount,
        paymentDate: _payments[index].paymentDate,
        method: _payments[index].method,
        notes: _payments[index].notes,
        createdAt: _payments[index].createdAt,
        updatedAt: _payments[index].updatedAt,
        version: _payments[index].version,
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<Payment>> findByDebtId(DebtId debtId) async {
    return _payments.where((p) => p.debtId == debtId).toList();
  }
}

class FixedUuidGenerator implements UuidGenerator {
  int counter = 0;
  @override
  String generateUuidV7() {
    counter++;
    return 'uuid-${counter.toString().padLeft(6, '0')}';
  }
}

void main() {
  late FakeDebtRepository debtRepo;
  late FakeLedgerRepository ledgerRepo;
  late FakePaymentRepository paymentRepo;
  late FixedUuidGenerator uuidGen;
  late AddPayment addPayment;

  setUp(() {
    debtRepo = FakeDebtRepository();
    ledgerRepo = FakeLedgerRepository();
    paymentRepo = FakePaymentRepository(ledgerRepo);
    uuidGen = FixedUuidGenerator();

    addPayment = AddPayment(
      debtRepository: debtRepo,
      ledgerRepository: ledgerRepo,
      paymentRepository: paymentRepo,
      uuidGenerator: uuidGen,
    );

    // Create a test debt and its opening entry
    final debtId = DebtId('debt-1');
    final debt = Debt(
      id: debtId,
      personId: PersonId('person-1'),
      amount: Money(amount: 1000),
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
    debtRepo.addDebt(debt);
    ledgerRepo.addEntry(
      LedgerEntry(
        id: LedgerEntryId('opening-entry'),
        debtId: debtId,
        entryType: LedgerEntryType.debt_creation,
        amount: Money(amount: 1000),
        createdAt: DateTime(2026, 8, 1),
      ),
    );
  });

  group('AddPayment', () {
    test('successful payment reduces balance', () async {
      final debtId = DebtId('debt-1');
      final payment = await addPayment(
        debtId: debtId,
        amount: Money(amount: 200),
        policy: OverpaymentPolicy.reject,
      );

      expect(payment.amount.amount, 200);
      expect(paymentRepo.findByDebtId(debtId), completion(hasLength(1)));
      final entries = await ledgerRepo.findByDebtId(debtId);
      expect(entries.length, 2); // opening + payment
      final balance = entries.fold<int>(0, (sum, e) => sum + e.amount.amount);
      expect(balance, 800);
    });

    test('overpayment with reject policy throws', () async {
      expect(
        () => addPayment(
          debtId: DebtId('debt-1'),
          amount: Money(amount: 1200),
          policy: OverpaymentPolicy.reject,
        ),
        throwsArgumentError,
      );
    });

    test('overpayment with cap_at_zero caps amount', () async {
      final payment = await addPayment(
        debtId: DebtId('debt-1'),
        amount: Money(amount: 1200),
        policy: OverpaymentPolicy.cap_at_zero,
      );

      expect(payment.amount.amount, 1000);
      final entries = await ledgerRepo.findByDebtId(DebtId('debt-1'));
      final balance = entries.fold<int>(0, (sum, e) => sum + e.amount.amount);
      expect(balance, 0);
    });

    test('overpayment with allow policy creates negative balance', () async {
      final payment = await addPayment(
        debtId: DebtId('debt-1'),
        amount: Money(amount: 1200),
        policy: OverpaymentPolicy.allow,
      );

      expect(payment.amount.amount, 1200);
      final entries = await ledgerRepo.findByDebtId(DebtId('debt-1'));
      final balance = entries.fold<int>(0, (sum, e) => sum + e.amount.amount);
      expect(balance, -200);
    });
  });
}