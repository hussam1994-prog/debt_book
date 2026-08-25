import 'package:domain/domain.dart';
import '../../core/database/app_database.dart';

class InstallmentMapper {
  static Installment fromRow(InstallmentRow row) {
    return Installment(
      id: InstallmentId(row.id),
      debtId: DebtId(row.debtId),
      number: row.number,
      amount: Money(amount: row.amount, currency: row.currency),
      dueDate: DateTime.fromMillisecondsSinceEpoch(row.dueDate),
      status: InstallmentStatus.fromString(row.status),
      paidAt: row.paidAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.paidAt!)
          : null,
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