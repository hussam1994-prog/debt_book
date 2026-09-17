import '../value_objects/money.dart';
import '../enums/overpayment_policy.dart';

/// مدقق الدفع الزائد.
class OverpaymentValidator {
  const OverpaymentValidator();

  /// هل المبلغ المدفوع أكبر من الرصيد الحالي؟
  bool isOverpayment(Money paymentAmount, Money currentBalance) {
    return paymentAmount > currentBalance;
  }

  /// يرجع المبلغ الفعلي الذي سيُطبق بناءً على السياسة.
  ///
  /// - [OverpaymentPolicy.allow] يسمح بالدفع الزائد ويؤدي إلى رصيد سالب.
  /// - [OverpaymentPolicy.cap_at_zero] يخفض المبلغ إلى الرصيد الحالي.
  /// - [OverpaymentPolicy.reject] يرمي [ArgumentError] إذا كان الدفع زائدًا.
  Money resolvePayment({
    required Money paymentAmount,
    required Money currentBalance,
    required OverpaymentPolicy policy,
  }) {
    if (!isOverpayment(paymentAmount, currentBalance)) {
      return paymentAmount;
    }

    switch (policy) {
      case OverpaymentPolicy.allow:
        return paymentAmount;
      case OverpaymentPolicy.cap_at_zero:
        return currentBalance;
      case OverpaymentPolicy.reject:
        throw ArgumentError(
          'Payment amount ${paymentAmount.toString()} exceeds current balance ${currentBalance.toString()}',
        );
    }
  }
}