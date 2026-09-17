import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final calc = DebtStatusCalculator();
  final now = DateTime(2026, 8, 14);

  group('DebtStatusCalculator', () {
    test('cancelled if isCancelled true', () {
      final status = calc.calculate(
        currentBalance: Money(amount: 500),
        dueDate: null,
        now: now,
        isCancelled: true,
      );
      expect(status, DebtStatus.cancelled);
    });

    test('paid if balance <= 0', () {
      final status = calc.calculate(
        currentBalance: Money(amount: 0),
        dueDate: null,
        now: now,
      );
      expect(status, DebtStatus.paid);
    });

    test('overdue if due date passed and balance > 0', () {
      final status = calc.calculate(
        currentBalance: Money(amount: 500),
        dueDate: now.subtract(Duration(days: 1)),
        now: now,
      );
      expect(status, DebtStatus.overdue);
    });

    test('active if due date future and balance > 0', () {
      final status = calc.calculate(
        currentBalance: Money(amount: 500),
        dueDate: now.add(Duration(days: 1)),
        now: now,
      );
      expect(status, DebtStatus.active);
    });
  });
}