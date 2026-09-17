import '../value_objects/money.dart';
import '../enums/debt_status.dart';

/// حاسبة حالة الدين.
class DebtStatusCalculator {
  
  const DebtStatusCalculator();

  /// يحسب الحالة بناءً على الرصيد الحالي وتاريخ الاستحقاق.
  ///
  /// - إذا كان [isCancelled] = true فتكون الحالة [DebtStatus.cancelled].
  /// - إذا كان الرصيد <= 0 فتكون [DebtStatus.paid].
  /// - إذا تجاوز تاريخ الاستحقاق وكان الرصيد > 0 فتكون [DebtStatus.overdue].
  /// - غير ذلك تكون [DebtStatus.active].
  DebtStatus calculate({
    required Money currentBalance,
    DateTime? dueDate,
    DateTime? now,
    bool isCancelled = false,
  }) {
    if (isCancelled) {
      return DebtStatus.cancelled;
    }

    if (currentBalance <= Money.zero) {
      return DebtStatus.paid;
    }

    final currentDate = now ?? DateTime.now();
    if (dueDate != null && currentDate.isAfter(dueDate)) {
      return DebtStatus.overdue;
    }

    return DebtStatus.active;
  }
}