import '../entities/payment.dart';
import '../entities/ledger_entry.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/payment_id.dart';
/// عقد مستودع الدفعات.
abstract class PaymentRepository {
  /// تسجيل دفعة مع قيدها المالي (عملية ذرية).
  Future<void> recordPayment(Payment payment, LedgerEntry paymentEntry);

  /// جلب دفعات دين معين.
  Future<List<Payment>> findByDebtId(DebtId debtId);
  Future<Payment?> findById(PaymentId id); 
  Future<List<Payment>> findAll();
  Future<void> softDeletePayment(PaymentId id);
}