import '../entities/ledger_entry.dart';
import '../entities/debt.dart';
import '../enums/debt_status.dart';
import '../enums/ledger_entry_type.dart';
import '../repositories/debt_repository.dart';
import '../repositories/ledger_repository.dart';
import '../services/balance_calculator.dart';
import '../services/uuid_generator.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/ledger_entry_id.dart';
import '../value_objects/money.dart';

class DeleteDebt {
  final DebtRepository _debtRepository;
  final LedgerRepository _ledgerRepository;
  final BalanceCalculator _balanceCalculator;
  final UuidGenerator _uuidGenerator;

  const DeleteDebt({
    required DebtRepository debtRepository,
    required LedgerRepository ledgerRepository,
    required BalanceCalculator balanceCalculator,
    required UuidGenerator uuidGenerator,
  })  : _debtRepository = debtRepository,
        _ledgerRepository = ledgerRepository,
        _balanceCalculator = balanceCalculator,
        _uuidGenerator = uuidGenerator;

  Future<void> call(DebtId debtId) async {
    final debt = await _debtRepository.findById(debtId);
    if (debt == null) throw ArgumentError('Debt not found');
    if (debt.isDeleted) return;

    final entries = await _ledgerRepository.findByDebtId(debtId);
    final currentBalance = _balanceCalculator.calculateBalance(entries);

    if (!currentBalance.isZero) {
      final adjustment = LedgerEntry(
        id: LedgerEntryId(_uuidGenerator.generateUuidV7()),
        debtId: debtId,
        entryType: LedgerEntryType.adjustment,
        amount: Money(amount: -currentBalance.amount, currency: currentBalance.currency),
        createdAt: DateTime.now(),
      );
      await _ledgerRepository.append(adjustment);
    }

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
      isDeleted: true,
      deletedAt: DateTime.now(),
    );
    await _debtRepository.updateDebt(updatedDebt);
  }
}