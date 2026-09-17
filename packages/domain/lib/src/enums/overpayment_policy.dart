/// سياسة التعامل مع الدفع الزائد (عندما يتجاوز الدفع المبلغ المستحق).
enum OverpaymentPolicy {
  reject,      // رفض الدفع الزائد
  allow,       // السماح به (قد يؤدي لرصيد سالب/دائن)
  cap_at_zero; // قبول الدفع ولكن تغطية المبلغ المستحق فقط وتجاهل الزائد

  static OverpaymentPolicy fromString(String value) {
    return OverpaymentPolicy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown OverpaymentPolicy: $value'),
    );
  }

  String get name => toString().split('.').last;
}