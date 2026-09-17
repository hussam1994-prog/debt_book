import '../entities/installment.dart';
import '../repositories/installment_repository.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/money.dart';

class MarkInstallmentsPaid {
  final InstallmentRepository _installmentRepository;

  const MarkInstallmentsPaid(this._installmentRepository);

  /// يحدد الأقساط المدفوعة بناءً على مبلغ الدفعة.
  /// يأخذ أقرب الأقساط المستحقة بالترتيب حتى يتم تغطية المبلغ المدفوع.
  Future<int> call({
    required DebtId debtId,
    required Money paymentAmount,
  }) async {
    final allInstallments = await _installmentRepository.findByDebtId(debtId);
    final pending = allInstallments
        .where((i) => i.status == InstallmentStatus.pending)
        .toList();

    var remaining = paymentAmount.amount;
    var paidCount = 0;

    for (final installment in pending) {
      if (remaining <= 0) break;

      if (installment.amount.amount <= remaining) {
        // القسط كامل يُغطى
        final updated = installment.copyWith(
          status: InstallmentStatus.paid,
          paidAt: DateTime.now(),
          updatedAt: DateTime.now(),
          version: installment.version + 1,
        );
        await _installmentRepository.update(updated);
        remaining -= installment.amount.amount;
        paidCount++;
      } else {
        // الدفعة أقل من القسط: نغطي جزءًا فقط (لا نغيّر الحالة)
        // في هذه الحالة نوقف لأن النظام لا يدعم دفع جزئي للقسط
        break;
      }
    }

    return paidCount;
  }
}