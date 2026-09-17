import '../entities/ledger_entry.dart';
import '../entities/payment.dart';
import '../repositories/ledger_repository.dart';
import '../repositories/payment_repository.dart';
import '../value_objects/debt_id.dart';

/// كشف حساب مبسط يجمع القيود والدفعات.
class DebtStatement {
  final List<LedgerEntry> ledgerEntries;
  final List<Payment> payments;

  const DebtStatement({required this.ledgerEntries, required this.payments});
}

/// حالة استخدام: جلب كشف حساب دين.
class GetStatement {
  final LedgerRepository _ledgerRepository;
  final PaymentRepository _paymentRepository;

  const GetStatement({
    required LedgerRepository ledgerRepository,
    required PaymentRepository paymentRepository,
  })  : _ledgerRepository = ledgerRepository,
        _paymentRepository = paymentRepository;

  Future<DebtStatement> call(DebtId debtId) async {
    final entries = await _ledgerRepository.findByDebtId(debtId);
    final payments = await _paymentRepository.findByDebtId(debtId);
    return DebtStatement(ledgerEntries: entries, payments: payments);
  }
}