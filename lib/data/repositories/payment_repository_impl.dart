import 'package:domain/domain.dart';
import '../../core/database/app_database.dart';
import 'package:drift/drift.dart';
import '../mappers/payment_mapper.dart';

// ⚠️ ملاحظة: كل كود sync_queue محذوف مؤقتاً من هذا الملف — نفس سبب
// debt_repository_impl.dart (يعتمد على packages/contracts غير المبنية بعد).

class PaymentRepositoryImpl implements PaymentRepository {
  final AppDatabase _db;
  final UuidGenerator _uuidGenerator;

  PaymentRepositoryImpl(this._db, this._uuidGenerator);

  @override
  Future<void> recordPayment(Payment payment, LedgerEntry paymentEntry) async {
    await _db.transaction(() async {
      await _db.into(_db.payments).insert(
            PaymentsCompanion.insert(
              id: payment.id.value,
              debtId: payment.debtId.value,
              amount: payment.amount.amount,
              currency: Value(payment.amount.currency),
              paymentDate: payment.paymentDate.millisecondsSinceEpoch,
              method: Value(payment.method.name),
              notes: Value(payment.notes),
              createdAt: payment.createdAt.millisecondsSinceEpoch,
              updatedAt: payment.updatedAt.millisecondsSinceEpoch,
              version: Value(payment.version),
              isDeleted: Value(payment.isDeleted),
              deletedAt: Value(payment.deletedAt?.millisecondsSinceEpoch),
            ),
          );

      await _db.into(_db.ledgerEntries).insert(
            LedgerEntriesCompanion.insert(
              id: paymentEntry.id.value,
              debtId: paymentEntry.debtId.value,
              entryType: paymentEntry.entryType.name,
              amount: paymentEntry.amount.amount,
              currency: Value(paymentEntry.amount.currency),
              correlationId: Value(paymentEntry.correlationId?.value),
              sourceEntryId: Value(paymentEntry.sourceEntryId?.value),
              paymentId: Value(paymentEntry.paymentId?.value),
              createdAt: paymentEntry.createdAt.millisecondsSinceEpoch,
              serverSequence: Value(paymentEntry.serverSequence),
            ),
          );

      // TODO(Phase 6-7): إضافة قيد sync_queue هنا بعد بناء packages/contracts
    });
  }

  @override
  Future<Payment?> findById(PaymentId id) async {
    final row = await (_db.select(_db.payments)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    if (row == null) return null;
    return PaymentMapper.fromRow(row);
  }

  @override
  Future<void> softDeletePayment(PaymentId id) async {
    await _db.transaction(() async {
      final paymentRow = await (_db.select(_db.payments)
            ..where((t) => t.id.equals(id.value)))
          .getSingleOrNull();

      if (paymentRow == null) {
        return;
      }
      final payment = PaymentMapper.fromRow(paymentRow);
      final now = DateTime.now();
      final newVersion = payment.version + 1;

      await (_db.update(_db.payments)..where((t) => t.id.equals(id.value)))
          .write(
        PaymentsCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
          version: Value(newVersion),
        ),
      );

      // TODO(Phase 6-7): إضافة قيد sync_queue هنا بعد بناء packages/contracts
    });
  }

  @override
  Future<List<Payment>> findByDebtId(DebtId debtId) async {
    final rows = await (_db.select(_db.payments)
          ..where((t) => t.debtId.equals(debtId.value)))
        .get();
    return rows.map(PaymentMapper.fromRow).toList();
  }

  @override
  Future<List<Payment>> findAll() async {
    final rows = await _db.select(_db.payments).get();
    return rows.map(PaymentMapper.fromRow).toList();
  }
}