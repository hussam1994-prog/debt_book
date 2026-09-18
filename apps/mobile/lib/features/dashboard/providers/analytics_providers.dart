import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

final allDebtsProvider = FutureProvider<List<Debt>>((ref) async {
  final repo = ref.watch(debtRepositoryProvider);
  final debts = await repo.findAll();
  return debts.where((d) => !d.isDeleted).toList();
});

final allPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final repo = ref.watch(paymentRepositoryProvider);
  final payments = await repo.findAll();
  return payments.where((p) => !p.isDeleted).toList();
});

/// ✅ إضافة المزود المفقود: يجمع كل الديون مع اسم الشخص.
///
/// ⚠️ الاسم قد يكون `null` إذا لم يُعثر على الشخص.
/// الترجمة (Unknown) تتم في UI عبر `l10n.unknownPerson`.
final allDebtsWithPersonNameProvider =
    FutureProvider<List<(Debt, String?)>>((ref) async {
  final debts = await ref.watch(allDebtsProvider.future);
  final personRepo = ref.watch(personRepositoryProvider);

  final result = <(Debt, String?)>[];
  for (final debt in debts) {
    final person = await personRepo.findById(debt.personId);
    result.add((debt, person?.name));
  }
  return result;
});

/// ✅ تحسين: جلب جميع القيود مرة واحدة بدلاً من استعلام لكل دين
final balancesByDebtProvider = FutureProvider<Map<DebtId, Money>>((ref) async {
  final debts = await ref.watch(allDebtsProvider.future);
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

final totalOutstandingProvider = FutureProvider<Money>((ref) async {
  final balances = await ref.watch(balancesByDebtProvider.future);
  var total = 0;
  for (final balance in balances.values) {
    if (balance.amount > 0) total += balance.amount;
  }
  return Money(amount: total);
});

final totalPaidProvider = FutureProvider<Money>((ref) async {
  final payments = await ref.watch(allPaymentsProvider.future);
  var total = 0;
  for (final p in payments) {
    total += p.amount.amount;
  }
  return Money(amount: total);
});

final peopleWithDebtsCountProvider = FutureProvider<int>((ref) async {
  final debts = await ref.watch(allDebtsProvider.future);
  final balances = await ref.watch(balancesByDebtProvider.future);
  final activePersonIds = <PersonId>{};
  for (final debt in debts) {
    final balance = balances[debt.id] ?? Money.zero;
    if (balance.amount > 0) {
      activePersonIds.add(debt.personId);
    }
  }
  return activePersonIds.length;
});

final overdueDebtsProvider = FutureProvider<List<Debt>>((ref) async {
  final debts = await ref.watch(allDebtsProvider.future);
  final balances = await ref.watch(balancesByDebtProvider.future);
  final now = DateTime.now();
  return debts.where((debt) {
    final balance = balances[debt.id] ?? Money.zero;
    if (balance.amount <= 0) return false;
    if (debt.dueDate == null) return false;
    return debt.dueDate!.isBefore(now);
  }).toList();
});

final last7DaysPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final payments = await ref.watch(allPaymentsProvider.future);
  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(days: 7));
  return payments.where((p) => p.paymentDate.isAfter(cutoff)).toList();
});

final insightsProvider = FutureProvider<List<Insight>>((ref) async {
  final debts = await ref.watch(allDebtsProvider.future);
  final balances = await ref.watch(balancesByDebtProvider.future);
  final paymentsByDebt = <DebtId, List<Payment>>{};

  final allPayments = await ref.watch(allPaymentsProvider.future);
  for (final payment in allPayments) {
    paymentsByDebt.putIfAbsent(payment.debtId, () => []).add(payment);
  }

  final service = ref.read(smartInsightsServiceProvider);
  return service.generateInsights(
    debts: debts,
    balances: balances,
    paymentsByDebt: paymentsByDebt,
  );
});

final debtStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(debtRepositoryProvider);
  final debts = await repo.findAll();
  final now = DateTime.now();

  int active = 0, overdue = 0, completed = 0;
  for (final d in debts) {
    if (d.isDeleted) continue;

    if (d.status == DebtStatus.cancelled) {
      continue; // تجاهل الملغاة
    }

    // إذا كان الدين "مكتمل" (رصيده صفر)، احسبه كمكتمل
    final balance = await ref.read(getBalanceProvider).call(d.id);

    if (balance.amount <= 0) {
      completed++;
    } else if (d.dueDate != null && d.dueDate!.isBefore(now)) {
      overdue++;
    } else {
      active++;
    }
  }
  return {'active': active, 'overdue': overdue, 'completed': completed};
});

final monthlyTrendProvider =
    FutureProvider<List<MapEntry<DateTime, double>>>((ref) async {
  final ledgerRepo = ref.watch(ledgerRepositoryProvider);
  final entries = await ledgerRepo.findAll();

  final now = DateTime.now();
  final months = List.generate(6, (i) {
    final date = DateTime(now.year, now.month - (5 - i), 1);
    return date;
  });

  final result = <MapEntry<DateTime, double>>[];
  for (final month in months) {
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    final monthTotal = entries
        .where((e) =>
            !e.createdAt.isBefore(month) && e.createdAt.isBefore(nextMonth))
        .fold<int>(0, (sum, e) => sum + e.amount.amount);
    result.add(MapEntry(month, monthTotal.toDouble()));
  }
  return result;
});