import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/database/outbox_repository.dart';
import '../../core/database/tables/outbox_table.dart';
import '../mappers/installment_mapper.dart';

class InstallmentRepositoryImpl implements InstallmentRepository {
  final AppDatabase _db;
  final OutboxRepository _outboxRepo;

  // ✅ استقبل OutboxRepository من الخارج
  InstallmentRepositoryImpl(this._db, this._outboxRepo);

  Map<String, dynamic> _installmentToSupabaseMap(Installment installment) {
    return {
      'id': installment.id.value,
      'debt_id': installment.debtId.value,
      'number': installment.number,
      'amount': installment.amount.amount,
      'currency': installment.amount.currency,
      'due_date': installment.dueDate.toIso8601String(),
      'status': installment.status.name,
      'paid_at': installment.paidAt?.toIso8601String(),
      'notes': installment.notes,
      'created_at': installment.createdAt.toIso8601String(),
      'updated_at': installment.updatedAt.toIso8601String(),
      'version': installment.version,
      'is_deleted': installment.isDeleted,
      'deleted_at': installment.deletedAt?.toIso8601String(),
    };
  }

  @override
  Future<void> save(Installment installment) async {
    await _db.transaction(() async {
      await _db.into(_db.installments).insert(
            InstallmentsCompanion.insert(
              id: installment.id.value,
              debtId: installment.debtId.value,
              number: installment.number,
              amount: installment.amount.amount,
              dueDate: installment.dueDate.millisecondsSinceEpoch,
              createdAt: installment.createdAt.millisecondsSinceEpoch,
              updatedAt: installment.updatedAt.millisecondsSinceEpoch,
              currency: Value(installment.amount.currency),
              status: Value(installment.status.name),
              paidAt: Value(installment.paidAt?.millisecondsSinceEpoch),
              notes: Value(installment.notes),
              version: Value(installment.version),
              isDeleted: Value(installment.isDeleted),
              deletedAt: Value(installment.deletedAt?.millisecondsSinceEpoch),
            ),
          );

      await _outboxRepo.enqueue(
        entityType: 'installment',
        entityId: installment.id.value,
        operation: OutboxOperation.insert,
        payload: _installmentToSupabaseMap(installment),
      );
    });
  }

  @override
  Future<List<Installment>> findByDebtId(DebtId debtId) async {
    final rows = await (_db.select(_db.installments)
          ..where((t) => t.debtId.equals(debtId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.number)]))
        .get();
    return rows.map(InstallmentMapper.fromRow).toList();
  }

  @override
  Future<void> update(Installment installment) async {
    await _db.transaction(() async {
      await (_db.update(_db.installments)
            ..where((t) => t.id.equals(installment.id.value)))
          .write(InstallmentsCompanion(
            number: Value(installment.number),
            amount: Value(installment.amount.amount),
            currency: Value(installment.amount.currency),
            dueDate: Value(installment.dueDate.millisecondsSinceEpoch),
            status: Value(installment.status.name),
            paidAt: Value(installment.paidAt?.millisecondsSinceEpoch),
            notes: Value(installment.notes),
            updatedAt: Value(installment.updatedAt.millisecondsSinceEpoch),
            version: Value(installment.version),
            isDeleted: Value(installment.isDeleted),
            deletedAt: Value(installment.deletedAt?.millisecondsSinceEpoch),
          ));

      await _outboxRepo.enqueue(
        entityType: 'installment',
        entityId: installment.id.value,
        operation: OutboxOperation.update,
        payload: _installmentToSupabaseMap(installment),
      );
    });
  }
}