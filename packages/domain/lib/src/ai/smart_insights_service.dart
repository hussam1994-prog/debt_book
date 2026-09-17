import '../entities/debt.dart';
import '../entities/payment.dart';
import '../value_objects/money.dart';
import 'debt_risk_analyzer.dart';
import 'payment_prediction_service.dart';
import '../value_objects/debt_id.dart';

/// نصيحة ذكية.
class Insight {
  final String message;
  final String? debtId;
  final DateTime createdAt;

  const Insight({
    required this.message,
    this.debtId,
    required this.createdAt,
  });
}

/// خدمة توليد الرؤى الذكية.
class SmartInsightsService {
  final DebtRiskAnalyzer _riskAnalyzer;
  final PaymentPredictionService _predictionService;

  const SmartInsightsService({
    DebtRiskAnalyzer riskAnalyzer = const DebtRiskAnalyzer(),
    required PaymentPredictionService predictionService,
  })  : _riskAnalyzer = riskAnalyzer,
        _predictionService = predictionService;

  /// توليد رؤى من جميع الديون والدفعات.
  Future<List<Insight>> generateInsights({
    required List<Debt> debts,
    required Map<DebtId, Money> balances,
    required Map<DebtId, List<Payment>> paymentsByDebt,
  }) async {
    final insights = <Insight>[];
    final now = DateTime.now();

    for (final debt in debts) {
      final balance = balances[debt.id] ?? Money.zero;
      final payments = paymentsByDebt[debt.id] ?? [];

      // تجاوز الديون المدفوعة والملغاة
      if (balance.amount <= 0 || debt.status.name == 'cancelled') continue;

      // تحليل المخاطر
      final risk = _riskAnalyzer.analyze(
        debt: debt,
        currentBalance: balance,
        payments: payments,
        now: now,
      );

      if (risk.riskLevel == RiskLevel.critical || risk.riskLevel == RiskLevel.high) {
        insights.add(Insight(
          message: 'دين ${debt.description ?? debt.id.value} ذو مخاطر ${risk.riskLevel.name}: ${risk.reason ?? ""}',
          debtId: debt.id.value,
          createdAt: now,
        ));
      }

      // التنبؤ بالدفع
      final prediction = await _predictionService.predictNextPayment(debt.id);
      if (prediction.predictedNextPaymentDate != null &&
          prediction.predictedNextPaymentDate!.isBefore(now.add(const Duration(days: 7)))) {
        insights.add(Insight(
          message: 'من المتوقع دفعة بقيمة ${prediction.predictedAmount} IQD خلال أسبوع.',
          debtId: debt.id.value,
          createdAt: now,
        ));
      }
    }

    // ترتيب حسب الأهمية (المخاطر أولاً)
    insights.sort((a, b) {
      if (a.message.contains('حرج') || a.message.contains('عالية')) return -1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return insights.take(10).toList();
  }
}