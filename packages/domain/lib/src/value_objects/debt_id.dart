class DebtId {
  final String value;

  DebtId(this.value) : assert(value.isNotEmpty, 'DebtId cannot be empty');

  @override
  bool operator ==(Object other) => other is DebtId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}