import '../value_objects/person_id.dart';
import '../value_objects/money.dart';

class PersonDebtSummary {
  final PersonId personId;
  final String personName;
  final Money totalOutstanding;
  final int debtCount;
  final DateTime? lastDueDate;

  const PersonDebtSummary({
    required this.personId,
    required this.personName,
    required this.totalOutstanding,
    required this.debtCount,
    this.lastDueDate,
  });
}