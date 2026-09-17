import '../value_objects/payment_id.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/money.dart';
import '../enums/payment_method.dart';

/// كيان الدفعة.
class Payment {
  final PaymentId id;
  final DebtId debtId;
  final Money amount;
  final DateTime paymentDate;
  final PaymentMethod method;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final bool isDeleted;
  final DateTime? deletedAt;

  Payment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.paymentDate,
    this.method = PaymentMethod.cash,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.isDeleted = false,
    this.deletedAt,
  }) : assert(amount.amount > 0, 'Payment amount must be positive');
}