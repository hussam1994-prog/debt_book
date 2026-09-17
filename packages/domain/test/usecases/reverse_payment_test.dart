import 'package:domain/domain.dart';
import 'package:test/test.dart';

class FakePaymentRepository implements PaymentRepository {
  final Map<String, Payment> _payments = {};
  final FakeLedgerRepository _ledgerRepo;

  FakePaymentRepository(this._ledgerRepo);

  @override
  Future<void> recordPayment(Payment payment, LedgerEntry paymentEntry) async {
    _payments[payment.id.value] = payment;
    await _ledgerRepo.append(paymentEntry);
  }

  @override
  Future<List<Payment>> findByDebtId(DebtId debtId) async =>
      _payments.values.where((p) => p.debtId == debtId).toList();

  @override
  Future<Payment?> findById(PaymentId id) async => _payments[id.value];

  @override
  Future<List<Payment>> findAll() async => _payments.values.toList();

  @override
  Future<void> softDeletePayment(PaymentId id) async {
    final p = _payments[id.value];
    if (p != null) {
      _payments[id.value] = Payment(
        id: p.id,
        debtId: p.debtId,
        amount: p.amount,
        paymentDate: p.paymentDate,
        method: p.method,
        notes: p.notes,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        version: p.version,
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
    }
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

class FakeDebtRepository implements DebtRepository {
  final Map<String, Debt> _debts = {};

  @override
  Future<void> createDebt(Debt debt, LedgerEntry initialEntry) async {
    _debts[debt.id.value] = debt;
  }

  @override
  Future<Debt?> findById(DebtId id) async => _debts[id.value];

  @override
  Future<List<Debt>> findByPersonId(PersonId personId) async =>
      _debts.values.where((d) => d.personId == personId).toList();

  @override
  Future<List<Debt>> findAll() async => _debts.values.toList();

  @override
  Future<void> updateDebt(Debt debt) async => _debts[debt.id.value] = debt;

  @override
  Future<List<(Debt, String)>> findAllPaginatedWithPersonName({
    int limit = 50,
    int offset = 0,
  }) async {
    return _debts.values.map((d) => (d, '')).toList();
  }

  @override
  Future<void> softDelete(DebtId id) async {
    _debts.remove(id.value);
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
  late FakePaymentRepository paymentRepo;
  late FakeLedgerRepository ledgerRepo;
  late FakeDebtRepository debtRepo;
  late ReversePayment reversePayment;

  setUp(() {
    ledgerRepo = FakeLedgerRepository();
    paymentRepo = FakePaymentRepository(ledgerRepo);
    debtRepo = FakeDebtRepository();
    reversePayment = ReversePayment(
      paymentRepository: paymentRepo,
      ledgerRepository: ledgerRepo,
      debtRepository: debtRepo,
      uuidGenerator: FixedUuidGenerator(),
    );
  });

  test('reverse payment appends reversal entry and soft-deletes payment', () async {
    final debtId = DebtId('debt-1');
    final payment = Payment(
      id: PaymentId('payment-1'),
      debtId: debtId,
      amount: Money(amount: 500),
      paymentDate: DateTime(2026, 8, 10),
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
    );
    await paymentRepo.recordPayment(payment, LedgerEntry(
      id: LedgerEntryId('entry-payment'),
      debtId: debtId,
      entryType: LedgerEntryType.payment,
      amount: Money(amount: -500),
      paymentId: payment.id,
      createdAt: DateTime(2026, 8, 10),
    ));

    final reversal = await reversePayment(payment.id, correlationId: CorrelationId('corr-1'));

    expect(reversal.entryType, LedgerEntryType.reversal);
    expect(reversal.amount.amount, 500);
    expect(reversal.sourceEntryId, LedgerEntryId('payment-1'));
    final storedPayment = await paymentRepo.findById(payment.id);
    expect(storedPayment!.isDeleted, true);
    final entries = await ledgerRepo.findByDebtId(debtId);
    expect(entries.length, 2);
  });
}