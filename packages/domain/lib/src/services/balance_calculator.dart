import '../value_objects/debt_id.dart';
import '../value_objects/money.dart';
import '../entities/ledger_entry.dart';

/// حاسبة الرصيد.
/// الرصيد = مجموع مبالغ قيود دفتر الأستاذ.
/// الموجب = زيادة الالتزام، السالب = تخفيض الالتزام.
class BalanceCalculator {
  const BalanceCalculator();

  /// حساب رصيد دين محدد من قائمة القيود.
  Money calculateBalanceForDebt(DebtId debtId, List<LedgerEntry> entries) {
    final filtered = entries.where((e) => e.debtId == debtId).toList();
    return calculateBalance(filtered);
  }

  /// حساب الرصيد الإجمالي من قائمة قيود.
  /// يفترض أن جميع القيود بنفس العملة.
  Money calculateBalance(List<LedgerEntry> entries) {
    if (entries.isEmpty) {
      return Money.zero;
    }

    final currency = entries.first.amount.currency;
    var total = 0;

    for (final entry in entries) {
      if (entry.amount.currency != currency) {
        throw ArgumentError(
          'Currency mismatch in ledger entries: ${entry.amount.currency} != $currency',
        );
      }
      total += entry.amount.amount;
    }

    return Money(amount: total, currency: currency);
  }
}