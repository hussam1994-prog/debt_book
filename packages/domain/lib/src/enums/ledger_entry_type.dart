/// نوع القيد المالي في دفتر الأستاذ.
enum LedgerEntryType {
  debt_creation,   // إنشاء دين (زيادة الالتزام)
  payment,         // دفعة (تخفيض الالتزام)
  adjustment,      // تسوية (زيادة أو تخفيض)
  reversal;        // عكس قيد سابق (تصحيح)

  static LedgerEntryType fromString(String value) {
    return LedgerEntryType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown LedgerEntryType: $value'),
    );
  }

  String get name => toString().split('.').last;
}