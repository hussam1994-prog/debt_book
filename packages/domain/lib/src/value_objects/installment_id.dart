class InstallmentId {
  final String value;

  InstallmentId(this.value) : assert(value.isNotEmpty, 'InstallmentId cannot be empty');

  @override
  bool operator ==(Object other) =>
      other is InstallmentId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}