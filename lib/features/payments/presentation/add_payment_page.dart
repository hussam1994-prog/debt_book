import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (IQD)'),
            ),
            const SizedBox(height: 16),
            DropdownButton<OverpaymentPolicy>(
              value: policy,
              onChanged: (newPolicy) {
                setState(() {
                  policy = newPolicy!;
                });
              },
              items: const [
                DropdownMenuItem(
                  value: OverpaymentPolicy.reject,
                  child: Text('Reject overpayment'),
                ),
                DropdownMenuItem(
                  value: OverpaymentPolicy.cap_at_zero,
                  child: Text('Cap at zero'),
                ),
                DropdownMenuItem(
                  value: OverpaymentPolicy.allow,
                  child: Text('Allow overpayment'),
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
                  ref.invalidate(ledgerEntriesForDebtProvider(widget.debtId));
                  ref.invalidate(paymentsForDebtProvider(widget.debtId));
                  if (context.mounted) context.pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Submit Payment'),
            ),
          ],
        ),
      ),
    );
  }
}