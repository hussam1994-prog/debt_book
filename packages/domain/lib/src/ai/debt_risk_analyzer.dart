import '../entities/debt.dart';
import '../entities/payment.dart';
import '../value_objects/money.dart';

/// مستوى المخاطر.
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

/// نتيجة تحليل المخاطر.
class DebtRiskResult {
  final Debt debt;
  final RiskLevel riskLevel;
  final double score; // 0.0 (منخفض) - 1.0 (حرج)
  final String? reason;

  const DebtRiskResult({
    required this.debt,
    required this.riskLevel,
    required this.score,
    this.reason,
  });
}

/// محلل مخاطر الدين بناءً على التأخر وتاريخ الدفع.
class DebtRiskAnalyzer {
  const DebtRiskAnalyzer();

  /// تحليل مخاطر دين معين.
  DebtRiskResult analyze({
    required Debt debt,
    required Money currentBalance,
    required List<Payment> payments,
    DateTime? now,
  }) {
    final currentDate = now ?? DateTime.now();
    double score = 0.0;
    final reasons = <String>[];

    // 1. الرصيد المستحق
    if (currentBalance.amount > 0) {
      // كلما زاد المبلغ، زادت المخاطر (نسبيًا)
      final balanceFactor = (currentBalance.amount / 1000000).clamp(0.0, 1.0);
      score += balanceFactor * 0.3;
    }

    // 2. تجاوز تاريخ الاستحقاق
    if (debt.dueDate != null && currentBalance.amount > 0) {
      final overdueDays = currentDate.difference(debt.dueDate!).inDays;
      if (overdueDays > 0) {
        score += 0.4;
        reasons.add('متأخر $overdueDays يوم');
        if (overdueDays > 30) score += 0.2;
        if (overdueDays > 90) score += 0.2;
      }
    }

    // 3. عدم وجود دفعات منتظمة
    final activePayments = payments.where((p) => !p.isDeleted).toList();
    if (activePayments.isEmpty && currentBalance.amount > 0) {
      score += 0.2;
      reasons.add('لا توجد دفعات سابقة');
    } else if (activePayments.isNotEmpty) {
      final lastPayment = activePayments.last;
      final daysSinceLastPayment = currentDate.difference(lastPayment.paymentDate).inDays;
      if (daysSinceLastPayment > 60) {
        score += 0.2;
        reasons.add('آخر دفعة قبل $daysSinceLastPayment يوم');
      }
    }

    // 4. الدين ملغي أو مدفوع
    if (currentBalance.amount <= 0) {
      score = 0.0;
      reasons.clear();
      reasons.add('الرصيد مدفوع');
    }

    score = score.clamp(0.0, 1.0);

    final riskLevel = _toRiskLevel(score);

    return DebtRiskResult(
      debt: debt,
      riskLevel: riskLevel,
      score: score,
      reason: reasons.isEmpty ? null : reasons.join('، '),
    );
  }

  RiskLevel _toRiskLevel(double score) {
    if (score < 0.25) return RiskLevel.low;
    if (score < 0.5) return RiskLevel.medium;
    if (score < 0.75) return RiskLevel.high;
    return RiskLevel.critical;
  }
}