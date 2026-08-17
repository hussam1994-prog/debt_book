import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../people/providers/people_providers.dart';

class DebtDetailPage extends ConsumerWidget {
  final DebtId debtId;
  const DebtDetailPage({super.key, required this.debtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtAsync = ref.watch(debtRepositoryProvider).findById(debtId);
    final entriesAsync = ref.watch(ledgerEntriesForDebtProvider(debtId));
    final paymentsAsync = ref.watch(paymentsForDebtProvider(debtId));
    final getBalance = ref.read(getBalanceProvider);
    final balanceAsync = getBalance(debtId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Add Adjustment',
            onPressed: () => _showAdjustmentDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            tooltip: 'Cancel Debt',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Cancel Debt'),
                  content: const Text('Are you sure you want to cancel this debt?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('No'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;

              final cancelDebt = ref.read(cancelDebtProvider);
              try {
                await cancelDebt(debtId);
                ref.invalidate(ledgerEntriesForDebtProvider(debtId));
                ref.invalidate(paymentsForDebtProvider(debtId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debt cancelled')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Debt?>(
        future: debtAsync,
        builder: (context, debtSnapshot) {
          final debt = debtSnapshot.data;
          return Column(
            children: [
              if (debt != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.description ?? 'Debt',
                            style: AppTextStyles.headline2,
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<Money>(
                            future: balanceAsync,
                            builder: (context, balanceSnapshot) {
                              final balance = balanceSnapshot.data;
                              return Text(
                                'Balance: ${balance != null ? balance.amount : "---"} IQD',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _balanceColor(balance),
                                ),
                              );
                            },
                          ),
                          if (debt.dueDate != null)
                            Text(
                              'Due: ${_formatDate(debt.dueDate!)}',
                              style: AppTextStyles.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              const Divider(),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Ledger'),
                          Tab(text: 'Payments'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildLedgerList(entriesAsync),
                            _buildPaymentsList(context, paymentsAsync, ref),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/debt/${debtId.value}/add-payment'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Payment'),
      ),
    );
  }

  void _showAdjustmentDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final isIncrease = ValueNotifier<bool>(true);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Adjustment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (IQD)'),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<bool>(
                valueListenable: isIncrease,
                builder: (context, value, _) {
                  return Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: isIncrease.value,
                        onChanged: (v) => isIncrease.value = v!,
                      ),
                      const Text('Increase debt'),
                      Radio<bool>(
                        value: false,
                        groupValue: isIncrease.value,
                        onChanged: (v) => isIncrease.value = v!,
                      ),
                      const Text('Decrease debt'),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text);
                if (amount == null || amount <= 0) return;
                final isIncreaseValue = isIncrease.value;
                final adjustmentAmount = isIncreaseValue ? amount : -amount;
                final addAdjustment = ref.read(addAdjustmentProvider);
                try {
                  await addAdjustment(
                    debtId: debtId,
                    amount: Money(amount: adjustmentAmount),
                  );
                  ref.invalidate(ledgerEntriesForDebtProvider(debtId));
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Adjustment added')),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Color _balanceColor(Money? balance) {
    if (balance == null) return AppColors.textPrimary;
    if (balance.amount > 0) return AppColors.error;
    if (balance.amount < 0) return Colors.green;
    return AppColors.textPrimary;
  }

  Widget _buildLedgerList(AsyncValue<List<LedgerEntry>> entriesAsync) {
    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const EmptyState(icon: Icons.list_alt, title: 'No Ledger Entries');
        }
        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              leading: Icon(
                entry.amount.amount >= 0 ? Icons.add_circle : Icons.remove_circle,
                color: entry.amount.amount >= 0 ? AppColors.error : Colors.green,
              ),
              title: Text(entry.entryType.name),
              subtitle: Text('${entry.amount.amount} IQD'),
              trailing: Text(_formatDate(entry.createdAt)),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPaymentsList(
    BuildContext context,
    AsyncValue<List<Payment>> paymentsAsync,
    WidgetRef ref,
  ) {
    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return const EmptyState(icon: Icons.payment, title: 'No Payments');
        }
        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return ListTile(
              leading: const Icon(Icons.payment, color: AppColors.primary),
              title: Text('Payment ${payment.amount.amount} IQD'),
              subtitle: Text(payment.paymentDate.toString()),
              trailing: payment.isDeleted
                  ? const Icon(Icons.block, color: AppColors.textSecondary)
                  : IconButton(
                      icon: const Icon(Icons.undo, color: AppColors.error),
                      onPressed: () async {
                        final reversePayment = ref.read(reversePaymentProvider);
                        try {
                          await reversePayment(payment.id);
                          ref.invalidate(ledgerEntriesForDebtProvider(debtId));
                          ref.invalidate(paymentsForDebtProvider(debtId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Payment reversed')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}