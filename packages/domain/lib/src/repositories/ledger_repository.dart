// packages/domain/lib/src/repositories/ledger_repository.dart
import '../entities/ledger_entry.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/ledger_entry_id.dart';

abstract class LedgerRepository {
  Future<void> append(LedgerEntry entry);
  Future<void> hardDeleteEntry(LedgerEntryId id);
  Future<List<LedgerEntry>> findByDebtId(DebtId debtId);
  Future<List<LedgerEntry>> findAll();
  Future<List<LedgerEntry>> findByDebtIdPaginated(
    DebtId debtId, {
    int limit = 50,
    int offset = 0,
  });
}