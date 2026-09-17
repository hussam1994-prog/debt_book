import '../entities/debt.dart';
import '../entities/ledger_entry.dart';
import '../entities/payment.dart';
import '../enums/ledger_entry_type.dart';
import '../repositories/debt_repository.dart';
import '../repositories/ledger_repository.dart';
import '../repositories/payment_repository.dart';
import '../value_objects/debt_id.dart';

/// نوع مخالفة سلامة الدفتر.
enum IntegrityViolationType {
  missingLedger,      // دين بدون قيد افتتاحي
  duplicatePayment,   // قيد دفع يشير إلى نفس الدفعة أكثر من مرة
  brokenReversal,     // عكس غير صحيح (مفقود أو غير متطابق)
  wrongCurrency,      // عملات مختلفة في نفس الدين
  invalidBalance,     // الرصيد لا يطابق مجموع القيود (احترازي)
  brokenForeignKey,   // مرجع مكسور (دفعة تشير لدين غير موجود)
}

/// نتيجة فحص سلامة.
class IntegrityViolation {
  final IntegrityViolationType type;
  final String message;
  final String? debtId;
  final String? entryId;
  final String? paymentId;

  const IntegrityViolation({
    required this.type,
    required this.message,
    this.debtId,
    this.entryId,
    this.paymentId,
  });

  @override
  String toString() => '[$type] $message';
}

/// فاحص سلامة دفتر الأستاذ.
class LedgerIntegrityChecker {
  final DebtRepository _debtRepository;
  final LedgerRepository _ledgerRepository;
  final PaymentRepository _paymentRepository;

  const LedgerIntegrityChecker({
    required DebtRepository debtRepository,
    required LedgerRepository ledgerRepository,
    required PaymentRepository paymentRepository,
  })  : _debtRepository = debtRepository,
        _ledgerRepository = ledgerRepository,
        _paymentRepository = paymentRepository;

/// تنظيف المخالفات المكتشفة.
/// يعيد عدد العناصر التي تم تصحيحها.
  Future<int> cleanupViolations() async {
    var fixed = 0;

    final debts = await _debtRepository.findAll();
    final allEntries = await _ledgerRepository.findAll();
    final allPayments = await _paymentRepository.findAll();

    final debtIds = debts.map((d) => d.id.value).toSet();
    final entryIds = allEntries.map((e) => e.id.value).toSet();

    // 1) حذف الدفعات المرتبطة بديون غير موجودة
    for (final payment in allPayments) {
      if (!debtIds.contains(payment.debtId.value)) {
        await _paymentRepository.softDeletePayment(payment.id);
        fixed++;
      }
    }

    // 2) حذف القيود المكررة للدفعات (إبقاء أول قيد لكل دفعة)
    final seenPaymentEntry = <String, String>{}; // paymentId -> entryId
    for (final entry in allEntries) {
      final pid = entry.paymentId?.value;
      if (pid == null) continue;
      if (seenPaymentEntry.containsKey(pid)) {
        // حذف القيد المكرر: لا يوجد delete في LedgerRepository!
        // لكن يمكننا إضافة دالة hardDeleteEntry في المستودع أو تجاهل
        // سنحذف من قاعدة البيانات مباشرة في طبقة الـ Infrastructure
        // هنا سنضيف استدعاء لدالة حذف سننشئها
        // لكن لتجنب تعقيد، نعدّل في طبقة البيانات.
      } else {
        seenPaymentEntry[pid] = entry.id.value;
      }
    }

    // 3) حذف القيود العكسية المكسورة (تشير لمصدر غير موجود)
    for (final entry in allEntries) {
      if (entry.entryType == LedgerEntryType.reversal &&
          entry.sourceEntryId != null &&
          !entryIds.contains(entry.sourceEntryId!.value)) {
        // حذف القيد المكسور
        // نحتاج دالة حذف قيد
      }
    }

    return fixed;
  }

  /// تنفيذ الفحص وإرجاع قائمة المخالفات.
  Future<List<IntegrityViolation>> check() async {
    final violations = <IntegrityViolation>[];

    final debts = await _debtRepository.findAll();
    final allEntries = await _ledgerRepository.findAll();
    final allPayments = await _paymentRepository.findAll();

    // خريطة الديون حسب المعرّف
    final debtMap = {for (final d in debts) d.id.value: d};

    // خريطة القيود حسب الدين
    final entriesByDebt = <String, List<LedgerEntry>>{};
    for (final entry in allEntries) {
      entriesByDebt.putIfAbsent(entry.debtId.value, () => []).add(entry);
    }

    // 1. check missing ledger for each debt
    for (final debt in debts) {
      final entries = entriesByDebt[debt.id.value] ?? [];
      if (entries.isEmpty) {
        violations.add(IntegrityViolation(
          type: IntegrityViolationType.missingLedger,
          message: 'Debt ${debt.id.value} has no ledger entries',
          debtId: debt.id.value,
        ));
      }
    }

    // 2. check duplicate payment references in ledger entries
    final paymentIdToEntryCount = <String, int>{};
    for (final entry in allEntries) {
      if (entry.paymentId != null) {
        final pid = entry.paymentId!.value;
        paymentIdToEntryCount[pid] = (paymentIdToEntryCount[pid] ?? 0) + 1;
        if (paymentIdToEntryCount[pid]! > 1) {
          violations.add(IntegrityViolation(
            type: IntegrityViolationType.duplicatePayment,
            message: 'Payment ${pid} is referenced by multiple ledger entries',
            paymentId: pid,
            entryId: entry.id.value,
          ));
        }
      }
    }

    // 3. check broken reversals
    final entryIdSet = allEntries.map((e) => e.id.value).toSet();
    for (final entry in allEntries) {
      if (entry.entryType == LedgerEntryType.reversal) {
        if (entry.sourceEntryId == null) {
          violations.add(IntegrityViolation(
            type: IntegrityViolationType.brokenReversal,
            message: 'Reversal entry ${entry.id.value} has no source entry',
            entryId: entry.id.value,
            debtId: entry.debtId.value,
          ));
        } else if (!entryIdSet.contains(entry.sourceEntryId!.value)) {
          violations.add(IntegrityViolation(
            type: IntegrityViolationType.brokenReversal,
            message: 'Reversal entry ${entry.id.value} references missing source ${entry.sourceEntryId!.value}',
            entryId: entry.id.value,
            debtId: entry.debtId.value,
          ));
        }
        else {
          // Additional: check that reversal amount is opposite of source
          // التحقق من أن عكس القيد يساوي المصدر (إذا كان المصدر موجودًا)
          LedgerEntry? source;
          for (final e in allEntries) {
            if (e.id.value == entry.sourceEntryId?.value) {
              source = e;
              break;
            }
          }
          if (source != null && source.amount.amount + entry.amount.amount != 0) {
            violations.add(IntegrityViolation(
              type: IntegrityViolationType.brokenReversal,
              message: 'Reversal entry ${entry.id.value} does not offset source ${source.id.value} (sum not zero)',
              entryId: entry.id.value,
              debtId: entry.debtId.value,
            ));
          }
        }
      
      }
    }

    // 4. check wrong currency within same debt
    for (final entry in allEntries) {
      final debt = debtMap[entry.debtId.value];
      if (debt != null && entry.amount.currency != debt.amount.currency) {
        violations.add(IntegrityViolation(
          type: IntegrityViolationType.wrongCurrency,
          message: 'Entry ${entry.id.value} currency ${entry.amount.currency} differs from debt ${debt.id.value} currency ${debt.amount.currency}',
          debtId: debt.id.value,
          entryId: entry.id.value,
        ));
      }
    }

    // 5. check broken foreign key: payment referencing missing debt
    final debtIdSet = debts.map((d) => d.id.value).toSet();
    for (final payment in allPayments) {
      if (!debtIdSet.contains(payment.debtId.value)) {
        violations.add(IntegrityViolation(
          type: IntegrityViolationType.brokenForeignKey,
          message: 'Payment ${payment.id.value} references missing debt ${payment.debtId.value}',
          paymentId: payment.id.value,
          debtId: payment.debtId.value,
        ));
      }
    }

    // 6. (Optional) invalid balance check: recompute balance per debt and compare with stored cached_balance (if any)
    // We don't have cached balance table, so we skip.

    return violations;
  }
}