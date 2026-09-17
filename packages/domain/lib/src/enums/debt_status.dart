/// حالة الدين.
enum DebtStatus {
  active,
  paid,
  overdue,
  cancelled;

  /// تحويل من النص (للاستخدام مع قاعدة البيانات)
  static DebtStatus fromString(String value) {
    return DebtStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown DebtStatus: $value'),
    );
  }

  String get name => toString().split('.').last;
}