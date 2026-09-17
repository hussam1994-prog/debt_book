class PaymentId {
  final String value;

  PaymentId(this.value) : assert(value.isNotEmpty, 'PaymentId cannot be empty');

  @override
  bool operator ==(Object other) => other is PaymentId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}