import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../mappers/installment_mapper.dart';

class InstallmentRepositoryImpl implements InstallmentRepository {
  final AppDatabase _db;

  InstallmentRepositoryImpl(this._db);

  @override
  Future<void> save(Installment installment) async {
    await _db.into(_db.installments).insert(
          InstallmentsCompanion.insert(
            id: installment.id.value,                    // ✅ بدون Value
            debtId: installment.debtId.value,            // ✅ بدون Value
            number: installment.number,                  // ✅ بدون Value
            amount: installment.amount.amount,           // ✅ بدون Value
            dueDate: installment.dueDate.millisecondsSinceEpoch, // ✅ بدون Value
            createdAt: installment.createdAt.millisecondsSinceEpoch, // ✅ بدون Value
            updatedAt: installment.updatedAt.millisecondsSinceEpoch, // ✅ بدون Value

            currency: Value(installment.amount.currency), // ✅ اختياري/default
            status: Value(installment.status.name),       // ✅ اختياري/default
            paidAt: Value(installment.paidAt?.millisecondsSinceEpoch),
            notes: Value(installment.notes),
            version: Value(installment.version),
            isDeleted: Value(installment.isDeleted),
            deletedAt: Value(installment.deletedAt?.millisecondsSinceEpoch),
          ),
        );
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
  }
}