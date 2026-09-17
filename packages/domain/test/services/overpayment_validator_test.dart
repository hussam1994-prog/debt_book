import 'package:domain/domain.dart';
import 'package:test/test.dart';


void main() {
  final validator = OverpaymentValidator();

  group('OverpaymentValidator', () {
    test('isOverpayment returns true when payment > balance', () {
      expect(validator.isOverpayment(Money(amount: 1200), Money(amount: 1000)), true);
    });

    test('isOverpayment returns false when payment <= balance', () {
      expect(validator.isOverpayment(Money(amount: 800), Money(amount: 1000)), false);
      expect(validator.isOverpayment(Money(amount: 1000), Money(amount: 1000)), false);
    });

    test('reject policy throws on overpayment', () {
      expect(
        () => validator.resolvePayment(
          paymentAmount: Money(amount: 1200),
          currentBalance: Money(amount: 1000),
          policy: OverpaymentPolicy.reject,
        ),
        throwsArgumentError,
      );
    });

    test('allow policy returns full payment', () {
      final result = validator.resolvePayment(
        paymentAmount: Money(amount: 1200),
        currentBalance: Money(amount: 1000),
        policy: OverpaymentPolicy.allow,
      );
      expect(result.amount, 1200);
    });

    test('cap_at_zero policy caps payment to balance', () {
      final result = validator.resolvePayment(
        paymentAmount: Money(amount: 1200),
        currentBalance: Money(amount: 1000),
        policy: OverpaymentPolicy.cap_at_zero,
      );
      expect(result.amount, 1000);
    });

    test('no overpayment returns same payment', () {
      final result = validator.resolvePayment(
        paymentAmount: Money(amount: 800),
        currentBalance: Money(amount: 1000),
        policy: OverpaymentPolicy.reject,
      );
      expect(result.amount, 800);
    });
  });
}