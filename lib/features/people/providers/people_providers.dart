import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

final peopleProvider = FutureProvider<List<Person>>((ref) async {
  final repo = ref.watch(personRepositoryProvider);
  return repo.findAll();
});

final debtsForPersonProvider =
    FutureProvider.family<List<Debt>, PersonId>((ref, personId) async {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.findByPersonId(personId);
});

/// ✅ الأرصدة لكل الديون مرة واحدة
final balancesForDebtsProvider =
    FutureProvider.family<Map<DebtId, Money>, List<Debt>>((ref, debts) async {
  if (debts.isEmpty) return {};

  final ledgerRepo = ref.watch(ledgerRepositoryProvider);
  final allEntries = await ledgerRepo.findAll();
  final calculator = const BalanceCalculator();

  final balances = <DebtId, Money>{};
  for (final debt in debts) {
    final entries = allEntries.where((e) => e.debtId == debt.id).toList();
    balances[debt.id] = calculator.calculateBalance(entries);
  }
  return balances;
});

/// ✅ مجموع المبالغ المستحقة لشخص (الأرصدة الموجبة فقط)
final totalOutstandingForPersonProvider =
    FutureProvider.family<Money, PersonId>((ref, personId) async {
  final debts = await ref.watch(debtsForPersonProvider(personId).future);
  final balances = await ref.watch(balancesForDebtsProvider(debts).future);

  var total = 0;
  for (final debt in debts) {
    final balance = balances[debt.id] ?? Money.zero;
    if (balance.amount > 0) total += balance.amount;
  }
  return Money(amount: total);
});

final ledgerEntriesForDebtProvider =
    FutureProvider.family<List<LedgerEntry>, DebtId>((ref, debtId) async {
  final repo = ref.watch(ledgerRepositoryProvider);
  return repo.findByDebtId(debtId);
});

final paymentsForDebtProvider =
    FutureProvider.family<List<Payment>, DebtId>((ref, debtId) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.findByDebtId(debtId);
});

// للتوافق مع الاستخدامات القديمة
final balanceForDebtProvider =
    FutureProvider.family<Money, DebtId>((ref, debtId) async {
  final ledgerRepo = ref.watch(ledgerRepositoryProvider);
  final calculator = const BalanceCalculator();
  final entries = await ledgerRepo.findByDebtId(debtId);
  return calculator.calculateBalance(entries);
});