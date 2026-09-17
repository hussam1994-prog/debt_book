import '../value_objects/debt_id.dart';
import '../value_objects/person_id.dart';
import '../value_objects/money.dart';
import '../enums/debt_status.dart';

class Debt {
  final DebtId id;
  final PersonId personId;
  final String? description;
  final Money amount;
  final DateTime? dueDate;
  final DebtStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? attachmentPath;

  
  Debt({
    required this.id,
    required this.personId,
    this.description,
    required this.amount,
    this.dueDate,
    this.status = DebtStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.isDeleted = false,
    this.deletedAt,
    this.attachmentPath,
  }) : assert(amount.amount > 0, 'Debt amount must be positive');

  Debt copyWith({
    DebtId? id,
    PersonId? personId,
    String? description,
    Money? amount,
    DateTime? dueDate,
    DebtStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    DateTime? deletedAt,
    String? attachmentPath,
  }) {
    return Debt(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      attachmentPath: attachmentPath ?? this.attachmentPath,
    );
  }
}