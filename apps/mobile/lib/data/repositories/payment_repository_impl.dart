import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/database/outbox_repository.dart';
import '../../core/database/tables/outbox_table.dart';
import '../mappers/payment_mapper.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final AppDatabase _db;
  final OutboxRepository _outboxRepo;

  // ✅ استقبل OutboxRepository من الخارج
  PaymentRepositoryImpl(this._db, this._outboxRepo);

  Map<String, dynamic> _paymentToSupabaseMap(Payment payment) {
    return {
      'id': payment.id.value,
      'debt_id': payment.debtId.value,
      'amount': payment.amount.amount,
      'currency': payment.amount.currency,
      'payment_date': payment.paymentDate.toIso8601String(),
      'method': payment.method.name,
      'notes': payment.notes,
      'created_at': payment.createdAt.toIso8601String(),
      'updated_at': payment.updatedAt.toIso8601String(),
      'version': payment.version,
      'is_deleted': payment.isDeleted,
      'deleted_at': payment.deletedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> _ledgerEntryToSupabaseMap(LedgerEntry entry) {
    return {
      'id': entry.id.value,
      'debt_id': entry.debtId.value,
      'entry_type': entry.entryType.name,
      'amount': entry.amount.amount,
      'currency': entry.amount.currency,
      'correlation_id': entry.correlationId?.value,
      'source_entry_id': entry.sourceEntryId?.value,
      'payment_id': entry.paymentId?.value,
      'created_at': entry.createdAt.toIso8601String(),
      'server_sequence': entry.serverSequence,
    };
  }

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

      await _outboxRepo.enqueue(
        entityType: 'payment',
        entityId: payment.id.value,
        operation: OutboxOperation.insert,
        payload: _paymentToSupabaseMap(payment),
      );

      await _outboxRepo.enqueue(
        entityType: 'ledger_entry',
        entityId: paymentEntry.id.value,
        operation: OutboxOperation.insert,
        payload: _ledgerEntryToSupabaseMap(paymentEntry),
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
    await _db.transaction(() async {
      final now = DateTime.now();
      await (_db.update(_db.payments)
            ..where((t) => t.id.equals(id.value)))
          .write(PaymentsCompanion(
            isDeleted: const Value(true),
            deletedAt: Value(now.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            version: const Value(1),
          ));

      final updatedRow = await (_db.select(_db.payments)
            ..where((t) => t.id.equals(id.value)))
          .getSingle();
      final updatedPayment = PaymentMapper.fromRow(updatedRow);

      await _outboxRepo.enqueue(
        entityType: 'payment',
        entityId: id.value,
        operation: OutboxOperation.update,
        payload: _paymentToSupabaseMap(updatedPayment),
      );
    });
  }
}