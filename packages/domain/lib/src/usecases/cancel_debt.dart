import '../entities/debt.dart';
import '../entities/ledger_entry.dart';
import '../enums/debt_status.dart';
import '../enums/ledger_entry_type.dart';
import '../repositories/debt_repository.dart';
import '../repositories/ledger_repository.dart';
import '../services/balance_calculator.dart';
import '../services/uuid_generator.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/ledger_entry_id.dart';
import '../value_objects/money.dart';
import '../value_objects/correlation_id.dart';

/// حالة استخدام: إلغاء دين.
class CancelDebt {
  final DebtRepository _debtRepository;
  final LedgerRepository _ledgerRepository;
  final BalanceCalculator _balanceCalculator;
  final UuidGenerator _uuidGenerator;

  const CancelDebt({
    required DebtRepository debtRepository,
    required LedgerRepository ledgerRepository,
    required BalanceCalculator balanceCalculator,
    required UuidGenerator uuidGenerator,
  })  : _debtRepository = debtRepository,
        _ledgerRepository = ledgerRepository,
        _balanceCalculator = balanceCalculator,
        _uuidGenerator = uuidGenerator;

  /// يقوم بإلغاء الدين وضبط الرصيد إلى صفر عبر قيد تسوية إذا لزم.
  Future<void> call(DebtId debtId, {CorrelationId? correlationId}) async {
    final debt = await _debtRepository.findById(debtId);
    if (debt == null) {
      throw ArgumentError('Debt not found: $debtId');
    }
    if (debt.status == DebtStatus.cancelled) {
      return; // ملغى مسبقًا
    }

    final entries = await _ledgerRepository.findByDebtId(debtId);
    final currentBalance = _balanceCalculator.calculateBalance(entries);

    // إذا كان هناك رصيد متبقٍ، نضيف قيد تسوية سالب لتصفيره
    if (!currentBalance.isZero) {
      final adjustment = LedgerEntry(
        id: LedgerEntryId(_uuidGenerator.generateUuidV7()),
        debtId: debtId,
        entryType: LedgerEntryType.adjustment,
        amount: Money(amount: -currentBalance.amount, currency: currentBalance.currency),
        correlationId: correlationId,
        createdAt: DateTime.now(),
      );
      await _ledgerRepository.append(adjustment);
    }

    // تحديث حالة الدين إلى ملغي
    final updatedDebt = Debt(
      id: debt.id,
      personId: debt.personId,
      description: debt.description,
      amount: debt.amount,
      dueDate: debt.dueDate,
      status: DebtStatus.cancelled,
      createdAt: debt.createdAt,
      updatedAt: DateTime.now(),
      version: debt.version + 1,
      isDeleted: debt.isDeleted,
      deletedAt: debt.deletedAt,
    );
    await _debtRepository.updateDebt(updatedDebt);
  }
}