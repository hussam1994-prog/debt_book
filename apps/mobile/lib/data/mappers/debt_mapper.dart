import 'package:domain/domain.dart';
import '../../core/database/app_database.dart';

class DebtMapper {
  static Debt fromRow(DebtRow row) {
    return Debt(
      id: DebtId(row.id),
      personId: PersonId(row.personId),
      description: row.description,
      amount: Money(amount: row.amount, currency: row.currency),
      dueDate: row.dueDate != null
          ? DateTime.fromMillisecondsSinceEpoch(row.dueDate!)
          : null,
      status: DebtStatus.fromString(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      version: row.version,
      isDeleted: row.isDeleted,
      deletedAt: row.deletedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!)
          : null,
      attachmentPath: row.attachmentPath,
    );
  }
}