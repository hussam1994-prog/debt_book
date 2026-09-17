import '../value_objects/ledger_entry_id.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/money.dart';
import '../value_objects/correlation_id.dart';
import '../value_objects/payment_id.dart';
import '../enums/ledger_entry_type.dart';

/// قيد دفتر الأستاذ المالي (Append-Only).
/// المبلغ قد يكون موجبًا (زيادة الالتزام) أو سالبًا (تخفيض الالتزام).
class LedgerEntry {
  final LedgerEntryId id;
  final DebtId debtId;
  final LedgerEntryType entryType;
  final Money amount;
  final CorrelationId? correlationId;
  final LedgerEntryId? sourceEntryId;  // في حالة العكس يشير إلى القيد الأصلي
  final PaymentId? paymentId;          // ربط اختياري بالدفعة
  final DateTime createdAt;
  final int? serverSequence;           // الترتيب المالي بعد المزامنة

  LedgerEntry({
    required this.id,
    required this.debtId,
    required this.entryType,
    required this.amount,
    this.correlationId,
    this.sourceEntryId,
    this.paymentId,
    required this.createdAt,
    this.serverSequence,
  });
}