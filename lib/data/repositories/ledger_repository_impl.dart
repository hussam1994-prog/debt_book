import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../mappers/ledger_entry_mapper.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final AppDatabase _db;

  LedgerRepositoryImpl(this._db);

  @override
  Future<void> hardDeleteEntry(LedgerEntryId id) async {
    await (_db.delete(_db.ledgerEntries)
          ..where((t) => t.id.equals(id.value)))
        .go();
  }

  @override
  Future<void> append(LedgerEntry entry) async {
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
}