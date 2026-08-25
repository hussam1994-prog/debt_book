import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/providers.dart';
import '../../people/providers/people_providers.dart';

class AddPaymentPage extends ConsumerStatefulWidget {
  final DebtId debtId;
  const AddPaymentPage({super.key, required this.debtId});

  @override
  ConsumerState<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends ConsumerState<AddPaymentPage> {
  final amountController = TextEditingController();
  OverpaymentPolicy policy = OverpaymentPolicy.reject;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  /// ✅ تحديث محلي بعد إضافة الدفعة
  void _refreshLocal() {
    ref.invalidate(ledgerEntriesForDebtProvider(widget.debtId));
    ref.invalidate(paymentsForDebtProvider(widget.debtId));
    ref.invalidate(balanceForDebtProvider(widget.debtId));
    ref.invalidate(installmentsForDebtProvider(widget.debtId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addPayment),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/debt/${widget.debtId.value}'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.adjustmentAmount),
            ),
            const SizedBox(height: 16),
            DropdownButton<OverpaymentPolicy>(
              value: policy,
              onChanged: (newPolicy) {
                setState(() {
                  policy = newPolicy!;
                });
              },
              items: [
                DropdownMenuItem(
                  value: OverpaymentPolicy.reject,
                  child: Text(l10n.rejectOverpayment),
                ),
                DropdownMenuItem(
                  value: OverpaymentPolicy.cap_at_zero,
                  child: Text(l10n.capAtZero),
                ),
                DropdownMenuItem(
                  value: OverpaymentPolicy.allow,
                  child: Text(l10n.allowOverpayment),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text);
                if (amount == null || amount <= 0) return;

                final addPayment = ref.read(addPaymentProvider);
                try {
                  await addPayment(
                    debtId: widget.debtId,
                    amount: Money(amount: amount),
                    policy: policy,
                  );

                  // ✅ تحديث محلي
                  _refreshLocal();

                  // ✅ محاولة تحديث الأقساط المدفوعة
                  final markPaid = ref.read(markInstallmentsPaidProvider);
                  final paidCount = await markPaid.call(
                    debtId: widget.debtId,
                    paymentAmount: Money(amount: amount),
                  );

                  if (paidCount > 0 && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم تحديث $paidCount قسط'),
                      ),
                    );
                  }

                  if (context.mounted) context.pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(l10n.submitPayment),
            ),
          ],
        ),
      ),
    );
  }
}