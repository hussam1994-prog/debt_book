import 'package:domain/domain.dart';
import '../../core/database/app_database.dart';

class PaymentMapper {
  static Payment fromRow(PaymentRow row) {
    return Payment(
      id: PaymentId(row.id),
      debtId: DebtId(row.debtId),
      amount: Money(amount: row.amount, currency: row.currency),
      paymentDate: DateTime.fromMillisecondsSinceEpoch(row.paymentDate),
      method: PaymentMethod.fromString(row.method),
      notes: row.notes,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      version: row.version,
      isDeleted: row.isDeleted,
      deletedAt: row.deletedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!)
          : null,
    );
  }
}