import '../repositories/ledger_repository.dart';
import '../services/balance_calculator.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/money.dart';

/// حالة استخدام: إعادة بناء الرصيد من القيود.
class RebuildBalance {
  final LedgerRepository _ledgerRepository;
  final BalanceCalculator _balanceCalculator;

  const RebuildBalance({
    required LedgerRepository ledgerRepository,
    BalanceCalculator balanceCalculator = const BalanceCalculator(),
  })  : _ledgerRepository = ledgerRepository,
        _balanceCalculator = balanceCalculator;

  Future<Money> call(DebtId debtId) async {
    final entries = await _ledgerRepository.findByDebtId(debtId);
    return _balanceCalculator.calculateBalance(entries);
  }
}