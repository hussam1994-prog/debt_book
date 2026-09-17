/// طريقة الدفع.
enum PaymentMethod {
  cash,
  bank,
  mobile_wallet,
  other;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown PaymentMethod: $value'),
    );
  }

  String get name => toString().split('.').last;
}