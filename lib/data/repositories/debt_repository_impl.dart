import 'package:domain/domain.dart';
import '../../core/database/app_database.dart';
import 'package:drift/drift.dart';
import '../mappers/debt_mapper.dart';

// ⚠️ ملاحظة: كل كود sync_queue محذوف مؤقتاً من هذا الملف.
// السبب: يعتمد على SyncOperationType و toJsonForSync() من حزمة
// packages/contracts غير المبنية بعد. سيُعاد بمرحلة 6-7 بخارطة الطريق.
// UuidGenerator أبقيناه بالكونستركتور لأنه هيُستخدم وقتها.

class DebtRepositoryImpl implements DebtRepository {
  final AppDatabase _db;
  final UuidGenerator _uuidGenerator;

  DebtRepositoryImpl(this._db, this._uuidGenerator);

  @override
  Future<void> createDebt(Debt debt, LedgerEntry initialEntry) async {
    await _db.transaction(() async {
      await _db.into(_db.debts).insert(
            DebtsCompanion.insert(
              id: debt.id.value,
              personId: debt.personId.value,
              description: Value(debt.description),
              amount: debt.amount.amount,
              currency: Value(debt.amount.currency),
              dueDate: Value(debt.dueDate?.millisecondsSinceEpoch),
              status: Value(debt.status.name),
              createdAt: debt.createdAt.millisecondsSinceEpoch,
              updatedAt: debt.updatedAt.millisecondsSinceEpoch,
              version: Value(debt.version),
              isDeleted: Value(debt.isDeleted),
              deletedAt: Value(debt.deletedAt?.millisecondsSinceEpoch),
            ),
          );

      await _db.into(_db.ledgerEntries).insert(
            LedgerEntriesCompanion.insert(
              id: initialEntry.id.value,
              debtId: initialEntry.debtId.value,
              entryType: initialEntry.entryType.name,
              amount: initialEntry.amount.amount,
              currency: Value(initialEntry.amount.currency),
              correlationId: Value(initialEntry.correlationId?.value),
              sourceEntryId: Value(initialEntry.sourceEntryId?.value),
              paymentId: Value(initialEntry.paymentId?.value),
              createdAt: initialEntry.createdAt.millisecondsSinceEpoch,
              serverSequence: Value(initialEntry.serverSequence),
            ),
          );

      // TODO(Phase 6-7): إضافة قيد sync_queue هنا بعد بناء packages/contracts
    });
  }

  @override
  Future<Debt?> findById(DebtId id) async {
    final row = await (_db.select(_db.debts)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    if (row == null) return null;
    return DebtMapper.fromRow(row);
  }

  @override
  Future<List<Debt>> findByPersonId(PersonId personId) async {
    final rows = await (_db.select(_db.debts)
          ..where((t) => t.personId.equals(personId.value)))
        .get();
    return rows.map(DebtMapper.fromRow).toList();
  }

  @override
  Future<void> updateDebt(Debt debt) async {
    await _db.transaction(() async {
      await (_db.update(_db.debts)
            ..where((t) => t.id.equals(debt.id.value)))
          .write(
        DebtsCompanion(
          personId: Value(debt.personId.value),
          description: Value(debt.description),
          amount: Value(debt.amount.amount),
          currency: Value(debt.amount.currency),
          dueDate: Value(debt.dueDate?.millisecondsSinceEpoch),
          status: Value(debt.status.name),
          updatedAt: Value(debt.updatedAt.millisecondsSinceEpoch),
          version: Value(debt.version),
          isDeleted: Value(debt.isDeleted),
          deletedAt: Value(debt.deletedAt?.millisecondsSinceEpoch),
        ),
      );

      // TODO(Phase 6-7): إضافة قيد sync_queue هنا بعد بناء packages/contracts
    });
  }

  @override
  Future<List<Debt>> findAll() async {
    final rows = await _db.select(_db.debts).get();
    return rows.map(DebtMapper.fromRow).toList();
  }
}