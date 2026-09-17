import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final debtId = DebtId('debt-1');
  final calc = const BalanceCalculator();

  LedgerEntry entry(int amount) => LedgerEntry(
        id: LedgerEntryId('entry-${DateTime.now().microsecondsSinceEpoch}-$amount'),
        debtId: debtId,
        entryType: LedgerEntryType.payment,
        amount: Money(amount: amount),
        createdAt: DateTime.now(),
      );

  group('BalanceCalculator', () {
    test('empty list returns zero', () {
      expect(calc.calculateBalance([]), Money.zero);
    });

    test('sums positive and negative amounts', () {
      final entries = [
        entry(1000),
        entry(-200),
        entry(-100),
      ];
      final balance = calc.calculateBalance(entries);
      expect(balance.amount, 700);
    });

    test('sums entries for specific debt only', () {
      final otherDebtId = DebtId('debt-2');
      final entries = [
        entry(1000),
        LedgerEntry(
          id: LedgerEntryId('other-1'),
          debtId: otherDebtId,
          entryType: LedgerEntryType.debt_creation,
          amount: Money(amount: 500),
          createdAt: DateTime.now(),
        ),
        entry(-200),
      ];
      final balance = calc.calculateBalanceForDebt(debtId, entries);
      expect(balance.amount, 800);
    });

    test('throws on currency mismatch', () {
      final entries = [
        entry(1000),
        LedgerEntry(
          id: LedgerEntryId('usd-entry'),
          debtId: debtId,
          entryType: LedgerEntryType.payment,
          amount: Money(amount: 100, currency: 'USD'),
          createdAt: DateTime.now(),
        ),
      ];
      expect(() => calc.calculateBalance(entries), throwsArgumentError);
    });
  });
}