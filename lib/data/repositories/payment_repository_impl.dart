import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../mappers/payment_mapper.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final AppDatabase _db;

  PaymentRepositoryImpl(this._db);

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

  @override
  Future<void> softDeletePayment(PaymentId id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.payments)
          ..where((t) => t.id.equals(id.value)))
        .write(PaymentsCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
          updatedAt: Value(now),
          version: const Value(1),
        ));
  }
}