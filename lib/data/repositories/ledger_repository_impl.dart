import 'package:domain/domain.dart';
import '../../core/database/app_database.dart';
import 'package:drift/drift.dart';
import '../mappers/ledger_entry_mapper.dart';

// ⚠️ ملاحظة: كود sync_queue محذوف مؤقتاً — نفس سبب بقية المستودعات
// (يعتمد على packages/contracts غير المبنية بعد).

class LedgerRepositoryImpl implements LedgerRepository {
  final AppDatabase _db;
  final UuidGenerator _uuidGenerator;

  LedgerRepositoryImpl(this._db, this._uuidGenerator);

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

      // TODO(Phase 6-7): إضافة قيد sync_queue لعمليات adjustment هنا
      // بعد بناء packages/contracts
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
}