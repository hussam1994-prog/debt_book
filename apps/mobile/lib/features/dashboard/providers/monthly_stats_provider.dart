import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

/// إحصائيات شهر واحد
class MonthlyStats {
  final DateTime month;
  final int newDebts;          // ديون جديدة هذا الشهر
  final int payments;          // دفعات هذا الشهر
  final int newDebtsAmount;    // مبلغ الديون الجديدة
  final int paymentsAmount;    // مبلغ الدفعات
  final int adjustmentsAmount; // التسويات

  const MonthlyStats({
    required this.month,
    required this.newDebts,
    required this.payments,
    required this.newDebtsAmount,
    required this.paymentsAmount,
    required this.adjustmentsAmount,
  });

  int get netChange => newDebtsAmount - paymentsAmount + adjustmentsAmount;
}

/// مزود الإحصائيات الشهرية (آخر 6 أشهر)
final monthlyStatsProvider = FutureProvider<List<MonthlyStats>>((ref) async {
  final ledgerRepo = ref.watch(ledgerRepositoryProvider);
  final debtRepo = ref.watch(debtRepositoryProvider);

  final allEntries = await ledgerRepo.findAll();
  final allDebts = await debtRepo.findAll();

  final now = DateTime.now();
  final result = <MonthlyStats>[];

  for (int i = 5; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);

    // قيود الشهر
    final monthEntries = allEntries.where((e) =>
        !e.createdAt.isBefore(month) && e.createdAt.isBefore(nextMonth));

    int newDebts = 0;
    int payments = 0;
    int adjustmentsAmount = 0;
    int newDebtsAmount = 0;
    int paymentsAmount = 0;

    for (final e in monthEntries) {
      switch (e.entryType) {
        case LedgerEntryType.debt_creation:
          newDebts++;
          newDebtsAmount += e.amount.amount.abs();
          break;
        case LedgerEntryType.payment:
          payments++;
          paymentsAmount += e.amount.amount.abs();
          break;
        case LedgerEntryType.adjustment:
          adjustmentsAmount += e.amount.amount;
          break;
        case LedgerEntryType.reversal:
          // العكس يُحسب ضمن الدفعات
          payments++;
          paymentsAmount += e.amount.amount.abs();
          break;
      }
    }

    result.add(MonthlyStats(
      month: month,
      newDebts: newDebts,
      payments: payments,
      newDebtsAmount: newDebtsAmount,
      paymentsAmount: paymentsAmount,
      adjustmentsAmount: adjustmentsAmount,
    ));
  }

  return result;
});

/// إجمالي الديون
final totalDebtsAmountProvider = FutureProvider<int>((ref) async {
  final debtRepo = ref.watch(debtRepositoryProvider);
  final ledgerRepo = ref.watch(ledgerRepositoryProvider);

  final debts = await debtRepo.findAll();
  final entries = await ledgerRepo.findAll();

  final calculator = const BalanceCalculator();
  int total = 0;

  for (final debt in debts) {
    if (debt.isDeleted) continue;
    final debtEntries = entries.where((e) => e.debtId == debt.id).toList();
    final balance = calculator.calculateBalance(debtEntries);
    if (balance.amount > 0) total += balance.amount;
  }

  return total;
});

/// إجمالي الدفعات
final totalPaymentsAmountProvider = FutureProvider<int>((ref) async {
  final ledgerRepo = ref.watch(ledgerRepositoryProvider);
  final entries = await ledgerRepo.findAll();

  return entries
      .where((e) => e.entryType == LedgerEntryType.payment)
      .fold<int>(0, (sum, e) => sum + e.amount.amount.abs());
});

/// أعلى 5 مدينين
final topDebtorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final debtRepo = ref.watch(debtRepositoryProvider);
  final personRepo = ref.watch(personRepositoryProvider);
  final ledgerRepo = ref.watch(ledgerRepositoryProvider);

  final debts = await debtRepo.findAll();
  final entries = await ledgerRepo.findAll();
  final calculator = const BalanceCalculator();

  final balancesByPerson = <String, int>{};
  final namesByPerson = <String, String>{};

  for (final debt in debts) {
    if (debt.isDeleted) continue;
    final debtEntries = entries.where((e) => e.debtId == debt.id).toList();
    final balance = calculator.calculateBalance(debtEntries);
    if (balance.amount <= 0) continue;

    final personId = debt.personId.value;
    balancesByPerson[personId] =
        (balancesByPerson[personId] ?? 0) + balance.amount;

    if (!namesByPerson.containsKey(personId)) {
      final person = await personRepo.findById(debt.personId);
      namesByPerson[personId] = person?.name ?? 'غير معروف';
    }
  }

  final sorted = balancesByPerson.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.take(5).map((e) {
    return {
      'name': namesByPerson[e.key] ?? 'غير معروف',
      'amount': e.value,
    };
  }).toList();
});