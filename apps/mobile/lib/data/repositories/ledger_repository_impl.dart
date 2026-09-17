import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/database/outbox_repository.dart';
import '../../core/database/tables/outbox_table.dart';
import '../mappers/ledger_entry_mapper.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final AppDatabase _db;
  final OutboxRepository _outboxRepo;

  // ✅ استقبل OutboxRepository من الخارج
  LedgerRepositoryImpl(this._db, this._outboxRepo);

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
  Future<void> append(LedgerEntry entry) async {
    await _db.transaction(() async {
      await _db.into(_db.ledgerEntries).insert(
            LedgerEntriesCompanion.insert(
              id: entry.id.value,
              debtId: entry.debtId.value,
              entryType: entry.entryType.name,
              amount: entry.amount.amount,
              currency: Value(entry.amount.currency),
              correlationId: Value(entry.correlationId?.value),
              sourceEntryId: Value(entry.sourceEntryId?.value),
              paymentId: Value(entry.paymentId?.value),
              createdAt: entry.createdAt.millisecondsSinceEpoch,
              serverSequence: Value(entry.serverSequence),
            ),
          );

      await _outboxRepo.enqueue(
        entityType: 'ledger_entry',
        entityId: entry.id.value,
        operation: OutboxOperation.insert,
        payload: _ledgerEntryToSupabaseMap(entry),
      );
    });
  }

  @override
  Future<void> hardDeleteEntry(LedgerEntryId id) async {
    await _db.transaction(() async {
      final row = await (_db.select(_db.ledgerEntries)
            ..where((t) => t.id.equals(id.value)))
          .getSingleOrNull();
      await (_db.delete(_db.ledgerEntries)
            ..where((t) => t.id.equals(id.value)))
          .go();
      if (row != null) {
        await _outboxRepo.enqueue(
          entityType: 'ledger_entry',
          entityId: id.value,
          operation: OutboxOperation.delete,
          payload: _ledgerEntryToSupabaseMap(LedgerEntryMapper.fromRow(row)),
        );
      }
    });
  }

  @override
  Future<List<LedgerEntry>> findByDebtId(DebtId debtId) async {
    final rows = await (_db.select(_db.ledgerEntries)
          ..where((t) => t.debtId.equals(debtId.value)))
        .get();
    return rows.map(LedgerEntryMapper.fromRow).toList();
  }

  @override
  Future<List<LedgerEntry>> findAll() async {
    final rows = await _db.select(_db.ledgerEntries).get();
    return rows.map(LedgerEntryMapper.fromRow).toList();
  }

  @override
  Future<List<LedgerEntry>> findByDebtIdPaginated(
    DebtId debtId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await (_db.select(_db.ledgerEntries)
          ..where((t) => t.debtId.equals(debtId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit, offset: offset))
        .get();
    return rows.map(LedgerEntryMapper.fromRow).toList();
  }
}