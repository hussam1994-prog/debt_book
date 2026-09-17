/// معرّف ارتباط العمليات المترابطة (مثل دفع وعكسه).
/// يُستخدم في `audit_log` و `ledger_entries` و `sync_queue`.
class CorrelationId {
  final String value;

  CorrelationId(this.value) : assert(value.isNotEmpty, 'CorrelationId cannot be empty');

  @override
  bool operator ==(Object other) => other is CorrelationId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}