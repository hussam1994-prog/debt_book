import '../entities/ledger_entry.dart';
import '../entities/payment.dart';
import '../enums/ledger_entry_type.dart';
import '../enums/overpayment_policy.dart';
import '../enums/payment_method.dart';
import '../repositories/debt_repository.dart';
import '../repositories/ledger_repository.dart';
import '../repositories/payment_repository.dart';
import '../services/balance_calculator.dart';
import '../services/overpayment_validator.dart';
import '../services/uuid_generator.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/ledger_entry_id.dart';
import '../value_objects/money.dart';
import '../value_objects/payment_id.dart';

/// حالة استخدام: إضافة دفعة لدين.
class AddPayment {
  final DebtRepository _debtRepository;
  final LedgerRepository _ledgerRepository;
  final PaymentRepository _paymentRepository;
  final UuidGenerator _uuidGenerator;
  final BalanceCalculator _balanceCalculator;
  final OverpaymentValidator _overpaymentValidator;

  AddPayment({
    required DebtRepository debtRepository,
    required LedgerRepository ledgerRepository,
    required PaymentRepository paymentRepository,
    required UuidGenerator uuidGenerator,
    BalanceCalculator balanceCalculator = const BalanceCalculator(),
    OverpaymentValidator overpaymentValidator = const OverpaymentValidator(),
  })  : _debtRepository = debtRepository,
        _ledgerRepository = ledgerRepository,
        _paymentRepository = paymentRepository,
        _uuidGenerator = uuidGenerator,
        _balanceCalculator = balanceCalculator,
        _overpaymentValidator = overpaymentValidator;

  /// ينفذ عملية الدفع ويرجع الدفعة المُنشأة.
  Future<Payment> call({
    required DebtId debtId,
    required Money amount,
    PaymentMethod method = PaymentMethod.cash,
    String? notes,
    OverpaymentPolicy policy = OverpaymentPolicy.reject,
  }) async {
    // 1. التحقق من وجود الدين
    final debt = await _debtRepository.findById(debtId);
    if (debt == null) {
      throw ArgumentError('Debt not found: $debtId');
    }

    // 2. حساب الرصيد الحالي
    final entries = await _ledgerRepository.findByDebtId(debtId);
    final currentBalance = _balanceCalculator.calculateBalance(entries);

    // 3. تطبيق سياسة الدفع الزائد
    final effectiveAmount =
        _overpaymentValidator.resolvePayment(
      paymentAmount: amount,
      currentBalance: currentBalance,
      policy: policy,
    );

    if (effectiveAmount.isZero) {
      throw ArgumentError('Payment amount cannot be zero after applying policy');
    }

    // 4. إنشاء الدفعة
    final now = DateTime.now();
    final payment = Payment(
      id: PaymentId(_uuidGenerator.generateUuidV7()),
      debtId: debtId,
      amount: effectiveAmount,
      paymentDate: now,
      method: method,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    // 5. إنشاء القيد المالي (سالب لتخفيض الالتزام)
    final paymentEntry = LedgerEntry(
      id: LedgerEntryId(_uuidGenerator.generateUuidV7()),
      debtId: debtId,
      entryType: LedgerEntryType.payment,
      amount: Money(amount: -effectiveAmount.amount, currency: effectiveAmount.currency),
      paymentId: payment.id,
      createdAt: now,
    );

    // 6. حفظ الدفعة والقيد بشكل ذري
    await _paymentRepository.recordPayment(payment, paymentEntry);

    return payment;
  }
}