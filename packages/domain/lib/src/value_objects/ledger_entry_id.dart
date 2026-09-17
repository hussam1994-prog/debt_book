class LedgerEntryId {
  final String value;

  LedgerEntryId(this.value) : assert(value.isNotEmpty, 'LedgerEntryId cannot be empty');

  @override
  bool operator ==(Object other) => other is LedgerEntryId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}