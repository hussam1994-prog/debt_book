import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_formatters.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/whatsapp/whatsapp_service.dart';
import '../../../core/widgets/empty_state.dart';
import '../../people/providers/people_providers.dart';
import '../providers/ledger_paginated_provider.dart';
import '../widgets/ledger_timeline.dart';

class DebtDetailPage extends ConsumerStatefulWidget {
  final DebtId debtId;
  const DebtDetailPage({super.key, required this.debtId});

  @override
  ConsumerState<DebtDetailPage> createState() => _DebtDetailPageState();
}

class _DebtDetailPageState extends ConsumerState<DebtDetailPage> {
  Debt? _debt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ledgerPaginatedProvider(widget.debtId).notifier).loadMore();
    });
  }

  void _refreshLocal() {
    ref.read(ledgerPaginatedProvider(widget.debtId).notifier).refresh();
    ref.invalidate(paymentsForDebtProvider(widget.debtId));
    ref.invalidate(balanceForDebtProvider(widget.debtId));
    ref.invalidate(installmentsForDebtProvider(widget.debtId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.detailsRefreshed)),
      );
    }
  }

  // ─── إرسال رسالة بقوالب جاهزة ───
  Future<void> _sendTemplatedMessage(Debt debt, String template) async {
    final l10n = context.l10n;
    try {
      final person =
          await ref.read(personRepositoryProvider).findById(debt.personId);
      if (person == null || person.phone == null || person.phone!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noPhoneForPerson)),
          );
        }
        return;
      }

      final balance = await ref.read(getBalanceProvider).call(debt.id);
      final dueDateStr = debt.dueDate != null
          ? _formatDate(debt.dueDate!)
          : l10n.notSpecified;

      final message = WhatsAppService.getTemplate(
        l10n: l10n,
        template: template,
        personName: person.name,
        amount: balance.amount,
        dueDate: dueDateStr,
      );

      await WhatsAppService.sendReminder(
        phone: person.phone!,
        message: message,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
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
    ref.read(ledgerPaginatedProvider(widget.debtId).notifier).refresh();
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
    ref.read(ledgerPaginatedProvider(widget.debtId).notifier).refresh();
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
                    decoration:
                        InputDecoration(labelText: l10n.adjustmentAmount),
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
                    ref
                        .read(ledgerPaginatedProvider(widget.debtId).notifier)
                        .refresh();
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
    if (balance.amount > 0) return AppColors.error;
    if (balance.amount < 0) return AppColors.success;
    return colorScheme.onSurface;
  }

  // ─── دفتر الأستاذ: Timeline ───
  Widget _buildLedgerList() {
    final l10n = context.l10n;
    final ledgerState = ref.watch(ledgerPaginatedProvider(widget.debtId));
    final notifier =
        ref.watch(ledgerPaginatedProvider(widget.debtId).notifier);

    if (ledgerState.isEmpty) {
      if (notifier.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return EmptyState(icon: Icons.list_alt, title: l10n.noLedgerEntries);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          notifier.loadMore();
        }
        return false;
      },
      child: LedgerTimeline(entries: ledgerState),
    );
  }

  // ─── الدفعات ───
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
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.payment, color: AppColors.primary),
                ),
                title: Text(
                  AppFormatters.money(context, payment.amount.amount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(_formatDate(payment.paymentDate)),
                trailing: payment.isDeleted
                    ? const Icon(Icons.block, color: AppColors.textHint)
                    : IconButton(
                        icon: const Icon(Icons.undo, color: AppColors.error),
                        tooltip: l10n.reversal,
                        onPressed: () async {
                          final reversePayment =
                              ref.read(reversePaymentProvider);
                          await reversePayment(payment.id);
                          if (!mounted) return;
                          ref
                              .read(ledgerPaginatedProvider(widget.debtId)
                                  .notifier)
                              .refresh();
                          ref.invalidate(
                              paymentsForDebtProvider(widget.debtId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.paymentReversed)),
                            );
                          }
                        },
                      ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Text(context.l10n.errorGeneric(e.toString())),
      ),
    );
  }

  // ─── الأقساط ───
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
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: installments.length,
          itemBuilder: (context, index) {
            final installment = installments[index];
            final isPaid = installment.status == InstallmentStatus.paid;
            final isOverdue = installment.status == InstallmentStatus.overdue;

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPaid
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    '${installment.number}',
                    style: TextStyle(
                      color: isPaid ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  AppFormatters.money(context, installment.amount.amount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${l10n.dueDate}: ${_formatDate(installment.dueDate)}',
                ),
                trailing: isPaid
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : IconButton(
                        icon: Icon(
                          Icons.check_circle_outline,
                          color: isOverdue
                              ? AppColors.error
                              : AppColors.textHint,
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
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Text(context.l10n.errorGeneric(e.toString())),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final debtAsync = ref.watch(debtRepositoryProvider).findById(widget.debtId);
    final paymentsAsync = ref.watch(paymentsForDebtProvider(widget.debtId));
    final installmentsAsync =
        ref.watch(installmentsForDebtProvider(widget.debtId));
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
          // زر قوالب رسائل واتساب
          PopupMenuButton<String>(
            icon: const Icon(Icons.chat, color: Colors.green),
            tooltip: l10n.sendWhatsappMessage,
            onSelected: (template) {
              if (_debt != null) _sendTemplatedMessage(_debt!, template);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reminder',
                child: Row(
                  children: [
                    const Text('📩', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(l10n.templateReminder),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reminder_urgent',
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(l10n.templateUrgent),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reminder_overdue',
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(l10n.templateOverdue),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'thank_you',
                child: Row(
                  children: [
                    const Text('🙏', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(l10n.templateThankYou),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'postpone',
                child: Row(
                  children: [
                    const Text('⏰', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(l10n.templatePostpone),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'congratulations',
                child: Row(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(l10n.templateCongratulations),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (_debt == null) return;
              switch (value) {
                case 'edit':
                  _showEditDebtDialog(_debt!);
                  break;
                case 'adjust':
                  _showAdjustmentDialog(context, ref);
                  break;
                case 'cancel':
                  _confirmCancelDebt();
                  break;
                case 'delete':
                  _confirmDeleteDebt(_debt!);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.edit),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'adjust',
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.addAdjustment),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    const Icon(Icons.cancel_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.cancelDebt),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(l10n.deleteDebt,
                        style: const TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
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
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder<Money>(
                              future: balanceAsync,
                              builder: (context, balanceSnapshot) {
                                final balance = balanceSnapshot.data;
                                return Text(
                                  '${l10n.balance}: ${balance != null ? AppFormatters.money(context, balance.amount) : "---"}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _balanceColor(context, balance),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                            if (debt.dueDate != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.event,
                                      size: 16, color: AppColors.textHint),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${l10n.dueDate}: ${_formatDate(debt.dueDate!)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (debt.attachmentPath != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
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
                              _buildLedgerList(),
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
        onPressed: () =>
            context.go('/debt/${widget.debtId.value}/add-payment'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(l10n.addPayment),
      ),
    );
  }
}