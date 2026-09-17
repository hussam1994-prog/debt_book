/// قيمة مالية غير قابلة للتغيير.
/// العملة الأساسية: IQD (الدينار العراقي).
/// الكمية تمثل عددًا صحيحًا بالدينار.
class Money implements Comparable<Money> {
  final int amount;
  final String currency;

  Money({
    required this.amount,
    this.currency = 'IQD',
  }) : assert(currency.length == 3, 'Currency must be ISO 4217 code');

  /// عملة افتراضية ثابتة: الدينار العراقي
  static String iqd = 'IQD';

  /// صفر بالدينار العراقي
  static Money zero = Money(amount: 0);

  /// تحقق من أن المبلغ غير سالب
  bool get isNegative => amount < 0;

  /// تحقق من أن المبلغ صفر
  bool get isZero => amount == 0;

  /// تحقق من أن العملة هي الدينار العراقي
  bool get isIQD => currency == iqd;

  /// جمع مبلغين مع التحقق من تطابق العملة
  Money operator +(Money other) {
    _ensureSameCurrency(other);
    return Money(amount: amount + other.amount, currency: currency);
  }

  /// طرح مبلغين مع التحقق من تطابق العملة
  Money operator -(Money other) {
    _ensureSameCurrency(other);
    return Money(amount: amount - other.amount, currency: currency);
  }

  /// ضرب المبلغ في عدد صحيح (مثلاً لاحتساب فائدة أو عدد أشهر)
  Money operator *(int factor) {
    return Money(amount: amount * factor, currency: currency);
  }

  /// مقارنة المبالغ
  @override
  int compareTo(Money other) {
    _ensureSameCurrency(other);
    return amount.compareTo(other.amount);
  }

  bool operator >(Money other) => compareTo(other) > 0;
  bool operator <(Money other) => compareTo(other) < 0;
  bool operator >=(Money other) => compareTo(other) >= 0;
  bool operator <=(Money other) => compareTo(other) <= 0;

  /// تحقق من العملة
  void _ensureSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Currency mismatch: cannot operate on ${currency} and ${other.currency}',
      );
    }
  }

  /// صياغة نصية: "1000 IQD"
  @override
  String toString() => '$amount $currency';

  @override
  bool operator ==(Object other) =>
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);
}