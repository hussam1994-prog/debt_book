import 'package:domain/domain.dart';
import '../../core/database/app_database.dart';

class LedgerEntryMapper {
  static LedgerEntry fromRow(LedgerEntryRow row) {
    return LedgerEntry(
      id: LedgerEntryId(row.id),
      debtId: DebtId(row.debtId),
      entryType: LedgerEntryType.fromString(row.entryType),
      amount: Money(amount: row.amount, currency: row.currency),
      correlationId: row.correlationId != null
          ? CorrelationId(row.correlationId!)
          : null,
      sourceEntryId: row.sourceEntryId != null
          ? LedgerEntryId(row.sourceEntryId!)
          : null,
      paymentId: row.paymentId != null ? PaymentId(row.paymentId!) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      serverSequence: row.serverSequence,
    );
  }
}