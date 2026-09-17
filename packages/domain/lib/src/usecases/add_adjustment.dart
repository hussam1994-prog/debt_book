import '../entities/ledger_entry.dart';
import '../enums/ledger_entry_type.dart';
import '../repositories/ledger_repository.dart';
import '../services/uuid_generator.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/ledger_entry_id.dart';
import '../value_objects/money.dart';
import '../value_objects/correlation_id.dart';

/// حالة استخدام: إضافة قيد تسوية (زيادة أو تخفيض).
class AddAdjustment {
  final LedgerRepository _ledgerRepository;
  final UuidGenerator _uuidGenerator;

  const AddAdjustment({
    required LedgerRepository ledgerRepository,
    required UuidGenerator uuidGenerator,
  })  : _ledgerRepository = ledgerRepository,
        _uuidGenerator = uuidGenerator;

  /// [amount] قد يكون موجبًا لزيادة الالتزام أو سالبًا لتخفيضه.
  Future<LedgerEntry> call({
    required DebtId debtId,
    required Money amount,
    String? notes,
    CorrelationId? correlationId,
  }) async {
    if (amount.isZero) {
      throw ArgumentError('Adjustment amount cannot be zero');
    }

    final entry = LedgerEntry(
      id: LedgerEntryId(_uuidGenerator.generateUuidV7()),
      debtId: debtId,
      entryType: LedgerEntryType.adjustment,
      amount: amount,
      correlationId: correlationId,
      createdAt: DateTime.now(),
    );

    await _ledgerRepository.append(entry);
    return entry;
  }
}