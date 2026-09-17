import '../entities/installment.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/installment_id.dart';

abstract class InstallmentRepository {
  /// حفظ قسط جديد
  Future<void> save(Installment installment);

  /// جلب أقساط دين معين
  Future<List<Installment>> findByDebtId(DebtId debtId);

  /// تحديث قسط (مثل دفعه)
  Future<void> update(Installment installment);
}