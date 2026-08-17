import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

final peopleProvider = FutureProvider<List<Person>>((ref) async {
  final repo = ref.watch(personRepositoryProvider);
  return repo.findAll();
});

final debtsForPersonProvider = FutureProvider.family<List<Debt>, PersonId>((ref, personId) async {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.findByPersonId(personId);
});

final ledgerEntriesForDebtProvider = FutureProvider.family<List<LedgerEntry>, DebtId>((ref, debtId) async {
  final repo = ref.watch(ledgerRepositoryProvider);
  return repo.findByDebtId(debtId);
});

final paymentsForDebtProvider = FutureProvider.family<List<Payment>, DebtId>((ref, debtId) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.findByDebtId(debtId);
});

final balanceForDebtProvider = FutureProvider.family<Money, DebtId>((ref, debtId) async {
  final ledgerRepo = ref.watch(ledgerRepositoryProvider);
  final calculator = const BalanceCalculator();
  final entries = await ledgerRepo.findByDebtId(debtId);
  return calculator.calculateBalance(entries);
});