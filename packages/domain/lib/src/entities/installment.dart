import '../value_objects/installment_id.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/money.dart';

enum InstallmentStatus {
  pending,
  paid,
  overdue;

  static InstallmentStatus fromString(String value) {
    return InstallmentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown InstallmentStatus: $value'),
    );
  }
}

class Installment {
  final InstallmentId id;
  final DebtId debtId;
  final int number;
  final Money amount;
  final DateTime dueDate;
  final InstallmentStatus status;
  final DateTime? paidAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final bool isDeleted;
  final DateTime? deletedAt;

  const Installment({
    required this.id,
    required this.debtId,
    required this.number,
    required this.amount,
    required this.dueDate,
    this.status = InstallmentStatus.pending,
    this.paidAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.isDeleted = false,
    this.deletedAt,
  });

  Installment copyWith({
    InstallmentId? id,
    DebtId? debtId,
    int? number,
    Money? amount,
    DateTime? dueDate,
    InstallmentStatus? status,
    DateTime? paidAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Installment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      number: number ?? this.number,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}