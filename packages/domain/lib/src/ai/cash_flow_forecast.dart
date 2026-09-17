import '../entities/payment.dart';

/// توقع التدفق النقدي لشهر.
class CashFlowForecastResult {
  final DateTime month;
  final int predictedTotalAmount;
  final double confidence;

  const CashFlowForecastResult({
    required this.month,
    required this.predictedTotalAmount,
    required this.confidence,
  });
}

/// خدمة التنبؤ بالتدفق النقدي بناءً على تاريخ الدفعات.
class CashFlowForecast {
  const CashFlowForecast();

  /// التنبؤ بالتدفق لشهر قادم.
  List<CashFlowForecastResult> forecastNextMonths(
    List<Payment> allPayments, {
    int months = 3,
  }) {
    final activePayments = allPayments.where((p) => !p.isDeleted).toList();
    if (activePayments.isEmpty) return [];

    // تجميع المبالغ حسب الشهر
    final monthlyTotals = <DateTime, int>{};
    for (final p in activePayments) {
      final monthKey = DateTime(p.paymentDate.year, p.paymentDate.month);
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + p.amount.amount;
    }

    // حساب متوسط شهري
    if (monthlyTotals.isEmpty) return [];
    final totalSum = monthlyTotals.values.reduce((a, b) => a + b);
    final avg = totalSum ~/ monthlyTotals.length;

    final now = DateTime.now();
    final results = <CashFlowForecastResult>[];
    for (var i = 1; i <= months; i++) {
      final forecastMonth = DateTime(now.year, now.month + i);
      results.add(CashFlowForecastResult(
        month: forecastMonth,
        predictedTotalAmount: avg,
        confidence: (0.7 - (i * 0.1)).clamp(0.2, 0.7),
      ));
    }
    return results;
  }
}