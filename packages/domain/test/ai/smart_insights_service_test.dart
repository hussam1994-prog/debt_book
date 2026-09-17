import 'package:domain/domain.dart';
import 'package:test/test.dart';

class FakePaymentRepository implements PaymentRepository {
  @override
  Future<List<Payment>> findByDebtId(DebtId debtId) async => [];

  @override
  Future<void> recordPayment(Payment payment, LedgerEntry paymentEntry) async {}

  @override
  Future<List<Payment>> findAll() async => [];

  @override
  Future<Payment?> findById(PaymentId id) async => null;

  @override
  Future<void> softDeletePayment(PaymentId id) async {}
}

void main() {
  final riskAnalyzer = const DebtRiskAnalyzer();
  final predictionService = PaymentPredictionService(FakePaymentRepository());
  final service = SmartInsightsService(
    riskAnalyzer: riskAnalyzer,
    predictionService: predictionService,
  );

  test('generates insight for overdue debt', () async {
    final debt = Debt(
      id: DebtId('d1'),
      personId: PersonId('p1'),
      amount: Money(amount: 1000),
      dueDate: DateTime.now().subtract(const Duration(days: 5)),
      status: DebtStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final balances = {DebtId('d1'): Money(amount: 800)};
    final paymentsByDebt = <DebtId, List<Payment>>{};

    final insights = await service.generateInsights(
      debts: [debt],
      balances: balances,
      paymentsByDebt: paymentsByDebt,
    );
    expect(insights.isNotEmpty, true);
    expect(insights.first.message.contains('مخاطر'), true);
  });
}