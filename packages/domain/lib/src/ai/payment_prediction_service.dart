import '../entities/payment.dart';
import '../entities/debt.dart';
import '../value_objects/debt_id.dart';
import '../repositories/payment_repository.dart';

/// نتيجة التنبؤ بالدفع.
class PaymentPrediction {
  final DebtId debtId;
  final DateTime? predictedNextPaymentDate;
  final int predictedAmount;
  final double confidence; // 0.0 - 1.0

  const PaymentPrediction({
    required this.debtId,
    this.predictedNextPaymentDate,
    required this.predictedAmount,
    required this.confidence,
  });
}

/// خدمة التنبؤ بالدفع بناءً على تاريخ الدفعات.
class PaymentPredictionService {
  final PaymentRepository _paymentRepository;

  const PaymentPredictionService(this._paymentRepository);

  /// التنبؤ بالدفعة القادمة لدين معين.
  Future<PaymentPrediction> predictNextPayment(DebtId debtId) async {
    final payments = await _paymentRepository.findByDebtId(debtId);

    // نستثني الدفعات الملغاة
    final activePayments = payments.where((p) => !p.isDeleted).toList()
      ..sort((a, b) => a.paymentDate.compareTo(b.paymentDate));

    if (activePayments.isEmpty) {
      return PaymentPrediction(
        debtId: debtId,
        predictedAmount: 0,
        confidence: 0.0,
      );
    }

    // حساب متوسط المبلغ
    final totalAmount = activePayments.fold<int>(
      0,
      (sum, p) => sum + p.amount.amount,
    );
    final avgAmount = totalAmount ~/ activePayments.length;

    // حساب متوسط الفترة بين الدفعات (بالأيام)
    int avgIntervalDays = 0;
    if (activePayments.length > 1) {
      final intervals = <int>[];
      for (var i = 1; i < activePayments.length; i++) {
        final diff = activePayments[i].paymentDate
            .difference(activePayments[i - 1].paymentDate)
            .inDays;
        intervals.add(diff);
      }
      avgIntervalDays = intervals.reduce((a, b) => a + b) ~/ intervals.length;
    }

    DateTime? predictedDate;
    double confidence = 0.0;

    if (avgIntervalDays > 0) {
      final lastPayment = activePayments.last;
      predictedDate = lastPayment.paymentDate.add(
        Duration(days: avgIntervalDays),
      );
      // الثقة تزداد مع عدد الدفعات وانتظامها
      confidence = (activePayments.length / (activePayments.length + 2)).clamp(0.0, 1.0);
    } else if (activePayments.length == 1) {
      // لا توجد فترات كافية، نتنبأ بمبلغ فقط
      predictedDate = null;
      confidence = 0.3;
    }

    return PaymentPrediction(
      debtId: debtId,
      predictedNextPaymentDate: predictedDate,
      predictedAmount: avgAmount,
      confidence: confidence,
    );
  }
}