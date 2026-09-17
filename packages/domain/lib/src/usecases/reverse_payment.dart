import '../entities/ledger_entry.dart';
import '../entities/payment.dart';
import '../enums/ledger_entry_type.dart';
import '../enums/debt_status.dart';
import '../repositories/payment_repository.dart';
import '../repositories/ledger_repository.dart';
import '../repositories/debt_repository.dart';
import '../services/balance_calculator.dart';
import '../services/debt_status_calculator.dart';
import '../services/uuid_generator.dart';
import '../value_objects/payment_id.dart';
import '../value_objects/ledger_entry_id.dart';
import '../value_objects/money.dart';
import '../value_objects/correlation_id.dart';
import '../entities/debt.dart';


/// حالة استخدام: عكس دفعة.
class ReversePayment {
  final PaymentRepository _paymentRepository;
  final LedgerRepository _ledgerRepository;
  final DebtRepository _debtRepository;
  final UuidGenerator _uuidGenerator;
  final BalanceCalculator _balanceCalculator;
  final DebtStatusCalculator _statusCalculator;

  ReversePayment({
    required PaymentRepository paymentRepository,
    required LedgerRepository ledgerRepository,
    required DebtRepository debtRepository,
    required UuidGenerator uuidGenerator,
    BalanceCalculator balanceCalculator = const BalanceCalculator(),
    DebtStatusCalculator statusCalculator = const DebtStatusCalculator(),
  })  : _paymentRepository = paymentRepository,
        _ledgerRepository = ledgerRepository,
        _debtRepository = debtRepository,
        _uuidGenerator = uuidGenerator,
        _balanceCalculator = balanceCalculator,
        _statusCalculator = statusCalculator;

  /// ينفذ عملية العكس ويرجع القيد العكسي.
  Future<LedgerEntry> call(PaymentId paymentId, {CorrelationId? correlationId}) async {
    final payment = await _paymentRepository.findById(paymentId);
    if (payment == null) {
      throw ArgumentError('Payment not found: $paymentId');
    }
    if (payment.isDeleted) {
      throw StateError('Payment already reversed');
    }

    final now = DateTime.now();
    final reversalEntry = LedgerEntry(
      id: LedgerEntryId(_uuidGenerator.generateUuidV7()),
      debtId: payment.debtId,
      entryType: LedgerEntryType.reversal,
      amount: Money(amount: payment.amount.amount, currency: payment.amount.currency),
      correlationId: correlationId,
      sourceEntryId: LedgerEntryId(payment.id.value),  // ربط بالدفعة
      paymentId: payment.id,
      createdAt: now,
    );

    // حفظ القيد العكسي وتحديث حالة الدفعة إلى محذوفة (soft delete)
    await _ledgerRepository.append(reversalEntry);
    await _paymentRepository.softDeletePayment(paymentId); // نحتاج لهذه الدالة

    // تحديث حالة الدين بناءً على الرصيد الجديد
    final debt = await _debtRepository.findById(payment.debtId);
    if (debt != null) {
      final entries = await _ledgerRepository.findByDebtId(debt.id);
      final balance = _balanceCalculator.calculateBalance(entries);
      final newStatus = _statusCalculator.calculate(
        currentBalance: balance,
        dueDate: debt.dueDate,
        now: now,
        isCancelled: debt.status == DebtStatus.cancelled,
      );
      if (newStatus != debt.status) {
        final updatedDebt = Debt(
          id: debt.id,
          personId: debt.personId,
          description: debt.description,
          amount: debt.amount,
          dueDate: debt.dueDate,
          status: newStatus,
          createdAt: debt.createdAt,
          updatedAt: now,
          version: debt.version + 1,
          isDeleted: debt.isDeleted,
          deletedAt: debt.deletedAt,
        );
        await _debtRepository.updateDebt(updatedDebt);
      }
    }

    return reversalEntry;
  }
}