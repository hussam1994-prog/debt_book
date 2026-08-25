import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/whatsapp/whatsapp_service.dart';
import '../../../core/widgets/empty_state.dart';
import '../../people/providers/people_providers.dart';

class DebtDetailPage extends ConsumerStatefulWidget {
  final DebtId debtId;
  const DebtDetailPage({super.key, required this.debtId});

  @override
  ConsumerState<DebtDetailPage> createState() => _DebtDetailPageState();
}

class _DebtDetailPageState extends ConsumerState<DebtDetailPage> {
  Debt? _debt;

  void _refreshLocal() {
    ref.invalidate(debtRepositoryProvider);
    ref.invalidate(ledgerEntriesForDebtProvider(widget.debtId));
    ref.invalidate(paymentsForDebtProvider(widget.debtId));
    ref.invalidate(balanceForDebtProvider(widget.debtId));
    ref.invalidate(installmentsForDebtProvider(widget.debtId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث التفاصيل محليًا')),
      );
    }
  }

  String _entryTypeLabel(LedgerEntryType type) {
    final l10n = context.l10n;
    switch (type) {
      case LedgerEntryType.debt_creation:
        return l10n.debtCreation;
      case LedgerEntryType.payment:
        return l10n.payment;
      case LedgerEntryType.reversal:
        return l10n.reversal;
      case LedgerEntryType.adjustment:
        return l10n.adjustment;
    }
  }

  Future<void> _sendWhatsAppReminder(Debt debt) async {
    try {
      final person =
          await ref.read(personRepositoryProvider).findById(debt.personId);
      if (person == null || person.phone == null || person.phone!.isEmpty) {
        throw Exception('No phone number for this person');
      }

      final balance = await ref.read(getBalanceProvider).call(debt.id);
      final message =
          'مرحباً، المطلوب منك تسديد مبلغ ${balance.amount} دينار عراقي. شكراً';
      await WhatsAppService.sendReminder(phone: person.phone!, message: message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showEditDebtDialog(Debt debt) {
    final l10n = context.l10n;
    final descriptionController = TextEditingController(text: debt.description);
    final dueDateController = TextEditingController(
      text: debt.dueDate != null ? debt.dueDate.toString() : '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: l10n.description),
            ),
            TextField(
              controller: dueDateController,
              decoration: InputDecoration(labelText: l10n.dueDateHint),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              final now = DateTime.now();
              DateTime? dueDate;
              if (dueDateController.text.trim().isNotEmpty) {
                dueDate = DateTime.tryParse(dueDateController.text.trim());
              }
              final updatedDebt = debt.copyWith(
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                dueDate: dueDate,
                updatedAt: now,
                version: debt.version + 1,
              );
              final repo = ref.read(debtRepositoryProvider);
              await repo.updateDebt(updatedDebt);
              ref.invalidate(debtRepositoryProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteDebt(Debt debt) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteDebt),
        content: Text(l10n.confirmDeleteDebt),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final deleteDebt = ref.read(deleteDebtProvider);
    await deleteDebt(debt.id);
    if (!mounted) return;
    ref.invalidate(ledgerEntriesForDebtProvider(widget.debtId));
    ref.invalidate(paymentsForDebtProvider(widget.debtId));
    if (context.mounted) context.go('/');
  }

  Future<void> _confirmCancelDebt() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cancelDebt),
        content: Text(l10n.confirmCancelDebt),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final cancelDebt = ref.read(cancelDebtProvider);
    await cancelDebt(widget.debtId);
    if (!mounted) return;
    ref.invalidate(ledgerEntriesForDebtProvider(widget.debtId));
    ref.invalidate(paymentsForDebtProvider(widget.debtId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.debtCancelled)),
      );
    }
  }

  void _showAdjustmentDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final amountController = TextEditingController();
    bool isIncrease = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n.addAdjustment),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.adjustmentAmount),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.increase),
                        selected: isIncrease,
                        onSelected: (_) =>
                            setDialogState(() => isIncrease = true),
                      ),
                      ChoiceChip(
                        label: Text(l10n.decrease),
                        selected: !isIncrease,
                        onSelected: (_) =>
                            setDialogState(() => isIncrease = false),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(l10n.cancel)),
                ElevatedButton(
                  onPressed: () async {
                    final amount = int.tryParse(amountController.text);
                    if (amount == null || amount <= 0) return;
                    final adjustmentAmount = isIncrease ? amount : -amount;
                    final addAdjustment = ref.read(addAdjustmentProvider);
                    await addAdjustment(
                      debtId: widget.debtId,
                      amount: Money(amount: adjustmentAmount),
                    );
                    ref.invalidate(ledgerEntriesForDebtProvider(widget.debtId));
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.adjustmentAdded)),
                      );
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _balanceColor(BuildContext context, Money? balance) {
    final colorScheme = Theme.of(context).colorScheme;
    if (balance == null) return colorScheme.onSurface;
    if (balance.amount > 0) return colorScheme.error;
    if (balance.amount < 0) return Colors.green;
    return colorScheme.onSurface;
  }

  Widget _buildLedgerList(AsyncValue<List<LedgerEntry>> entriesAsync) {
    final l10n = context.l10n;
    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyState(
              icon: Icons.list_alt, title: l10n.noLedgerEntries);
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              leading: Icon(
                entry.amount.amount >= 0
                    ? Icons.add_circle
                    : Icons.remove_circle,
                color: entry.amount.amount >= 0
                    ? Theme.of(context).colorScheme.error
                    : Colors.green,
              ),
              title: Text(_entryTypeLabel(entry.entryType)),
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
    final l10n = context.l10n;
    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return EmptyState(icon: Icons.payment, title: l10n.noPayments);
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return ListTile(
              leading: const Icon(Icons.payment, color: AppColors.primary),
              title: Text('${l10n.payments} ${payment.amount.amount} IQD'),
              subtitle: Text(payment.paymentDate.toString()),
              trailing: payment.isDeleted
                  ? Icon(
                      Icons.block,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )
                  : IconButton(
                      icon: const Icon(Icons.undo, color: AppColors.error),
                      onPressed: () async {
                        final reversePayment = ref.read(reversePaymentProvider);
                        await reversePayment(payment.id);
                        if (!mounted) return;
                        ref.invalidate(
                            ledgerEntriesForDebtProvider(widget.debtId));
                        ref.invalidate(
                            paymentsForDebtProvider(widget.debtId));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.paymentReversed)),
                          );
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

  Widget _buildInstallmentsList(
    BuildContext context,
    AsyncValue<List<Installment>> installmentsAsync,
    WidgetRef ref,
  ) {
    final l10n = context.l10n;
    return installmentsAsync.when(
      data: (installments) {
        if (installments.isEmpty) {
          return EmptyState(
            icon: Icons.calendar_month,
            title: l10n.noInstallments,
            subtitle: l10n.noInstallments,
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: installments.length,
          itemBuilder: (context, index) {
            final installment = installments[index];
            final isPaid = installment.status == InstallmentStatus.paid;
            final isOverdue = installment.status == InstallmentStatus.overdue;

            return ListTile(
              leading: CircleAvatar(
                child: Text('${installment.number}'),
              ),
              title: Text('${installment.amount.amount} IQD'),
              subtitle: Text(
                '${l10n.dueDate}: ${_formatDate(installment.dueDate)}',
              ),
              trailing: isPaid
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : IconButton(
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: isOverdue
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () async {
                        final updated = installment.copyWith(
                          status: InstallmentStatus.paid,
                          paidAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                          version: installment.version + 1,
                        );
                        final repo = ref.read(installmentRepositoryProvider);
                        await repo.update(updated);
                        ref.invalidate(
                            installmentsForDebtProvider(widget.debtId));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.installmentPaid)),
                          );
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

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final debtAsync = ref.watch(debtRepositoryProvider).findById(widget.debtId);
    final entriesAsync = ref.watch(ledgerEntriesForDebtProvider(widget.debtId));
    final paymentsAsync = ref.watch(paymentsForDebtProvider(widget.debtId));
    final installmentsAsync = ref.watch(installmentsForDebtProvider(widget.debtId));
    final getBalance = ref.read(getBalanceProvider);
    final balanceAsync = getBalance(widget.debtId);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debtDetails),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _refreshLocal,
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: l10n.whatsappTooltip,
            onPressed: () {
              if (_debt != null) _sendWhatsAppReminder(_debt!);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n.edit,
            onPressed: () {
              if (_debt != null) _showEditDebtDialog(_debt!);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: l10n.deleteDebt,
            onPressed: () {
              if (_debt != null) _confirmDeleteDebt(_debt!);
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.addAdjustment,
            onPressed: () => _showAdjustmentDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            tooltip: l10n.cancelDebt,
            onPressed: () => _confirmCancelDebt(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshLocal(),
        child: FutureBuilder<Debt?>(
          future: debtAsync,
          builder: (context, debtSnapshot) {
            final debt = debtSnapshot.data;
            if (debt != null) {
              _debt = debt;
            }
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
                              debt.description ?? l10n.description,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<Money>(
                              future: balanceAsync,
                              builder: (context, balanceSnapshot) {
                                final balance = balanceSnapshot.data;
                                return Text(
                                  '${l10n.balance}: ${balance != null ? balance.amount : "---"} IQD',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _balanceColor(context, balance),
                                  ),
                                );
                              },
                            ),
                            if (debt.dueDate != null)
                              Text(
                                '${l10n.dueDate}: ${_formatDate(debt.dueDate!)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            if (debt.attachmentPath != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(debt.attachmentPath!),
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const Divider(),
                Expanded(
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(text: l10n.ledger),
                            Tab(text: l10n.payments),
                            Tab(text: l10n.installments),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildLedgerList(entriesAsync),
                              _buildPaymentsList(context, paymentsAsync, ref),
                              _buildInstallmentsList(
                                  context, installmentsAsync, ref),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/debt/${widget.debtId.value}/add-payment'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(l10n.addPayment),
      ),
    );
  }
}