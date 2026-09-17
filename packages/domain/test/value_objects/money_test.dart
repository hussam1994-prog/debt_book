import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('zero is zero and IQD', () {
      expect(Money.zero.amount, 0);
      expect(Money.zero.currency, 'IQD');
    });

    test('addition works', () {
      final a = Money(amount: 1000);
      final b = Money(amount: 500);
      final result = a + b;
      expect(result.amount, 1500);
      expect(result.currency, 'IQD');
    });

    test('subtraction works', () {
      final a = Money(amount: 1000);
      final b = Money(amount: 200);
      final result = a - b;
      expect(result.amount, 800);
    });

    test('multiplication works', () {
      final a = Money(amount: 250);
      final result = a * 3;
      expect(result.amount, 750);
    });

    test('comparison operators work', () {
      expect(Money(amount: 100) > Money(amount: 50), true);
      expect(Money(amount: 100) < Money(amount: 50), false);
      expect(Money(amount: 100) >= Money(amount: 100), true);
      expect(Money(amount: 100) <= Money(amount: 100), true);
    });

    test('currency mismatch throws on addition', () {
      final a = Money(amount: 100, currency: 'IQD');
      final b = Money(amount: 50, currency: 'USD');
      expect(() => a + b, throwsArgumentError);
    });

    test('negative money', () {
      final m = Money(amount: -50);
      expect(m.isNegative, true);
      expect(m.isZero, false);
    });

    test('to string', () {
      expect(Money(amount: 123).toString(), '123 IQD');
    });
  });
}