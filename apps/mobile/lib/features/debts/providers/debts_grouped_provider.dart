import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

final debtsGroupedByPersonProvider = FutureProvider<List<PersonDebtSummary>>((ref) async {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.getDebtsGroupedByPerson();
});