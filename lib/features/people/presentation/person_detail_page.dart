import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/whatsapp/whatsapp_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/people_providers.dart';

class PersonDetailPage extends ConsumerStatefulWidget {
  final PersonId personId;
  const PersonDetailPage({super.key, required this.personId});

  @override
  ConsumerState<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends ConsumerState<PersonDetailPage> {
  Person? _person;

  /// ✅ تحديث محلي فقط: إعادة قراءة بيانات الشخص والديون
  void _refreshLocal() {
    ref.invalidate(personRepositoryProvider);
    ref.invalidate(debtsForPersonProvider(widget.personId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث البيانات محليًا')),
      );
    }
  }

  /// ✅ إرسال كشف المستحقات عبر واتساب
  Future<void> _sendWhatsAppStatement(Person person) async {
    try {
      final debts =
          await ref.read(debtsForPersonProvider(widget.personId).future);
      final balances = await ref.read(balancesForDebtsProvider(debts).future);
      final total = await ref
          .read(totalOutstandingForPersonProvider(widget.personId).future);

      if (debts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.noDebts)),
        );
        return;
      }

      final lines = StringBuffer();
      lines.writeln('السيد/ة ${person.name}');
      lines.writeln('المستحقات المالية:');
      for (final debt in debts) {
        final balance = balances[debt.id] ?? Money.zero;
        if (balance.amount > 0) {
          lines.writeln(
              '- ${debt.description ?? 'دين'}: ${balance.amount} دينار');
        }
      }
      lines.writeln('الإجمالي: ${total.amount} دينار');

      await WhatsAppService.sendReminder(
        phone: person.phone!,
        message: lines.toString(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// ✅ تصدير كشف PDF والمشاركة
  Future<void> _exportPersonStatementPdf(Person person) async {
    try {
      final debts =
          await ref.read(debtsForPersonProvider(widget.personId).future);
      final balances = await ref.read(balancesForDebtsProvider(debts).future);
      final total = await ref
          .read(totalOutstandingForPersonProvider(widget.personId).future);

      final debtRows = debts.map((debt) {
        final balance = balances[debt.id] ?? Money.zero;
        return <String, String>{
          'description': debt.description ?? '',
          'originalAmount': '${debt.amount.amount}',
          'balance': '${balance.amount}',
          'status': debt.status.name,
        };
      }).toList();

      final l10n = context.l10n;
      final labels = <String, String>{
        'statementFor': l10n.statementFor,
        'totalOutstanding': l10n.totalOutstanding,
        'description': l10n.description,
        'originalAmount': l10n.originalAmount,
        'balance': l10n.balance,
        'status': l10n.status,
      };

      final pdfService = ref.read(pdfExportServiceProvider);
      final file = await pdfService.exportPersonStatementToPdf(
        personName: person.name,
        debtRows: debtRows,
        totalAmount: '${total.amount}',
        labels: labels,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تصدير الكشف: ${file.path}')),
        );
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)]),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final personAsync =
        ref.watch(personRepositoryProvider).findById(widget.personId);
    final debtsAsync = ref.watch(debtsForPersonProvider(widget.personId));
    final balancesAsync =
        ref.watch(balancesForDebtsProvider(debtsAsync.value ?? []));
    final totalAsync =
        ref.watch(totalOutstandingForPersonProvider(widget.personId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.personDetails),
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
            icon: const Icon(Icons.edit),
            tooltip: l10n.edit,
            onPressed: () {
              if (_person != null) _showEditPersonDialog(_person!);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: l10n.delete,
            onPressed: () {
              if (_person != null) _confirmDeletePerson(_person!);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshLocal(),
        child: FutureBuilder<Person?>(
          future: personAsync,
          builder: (context, personSnapshot) {
            final person = personSnapshot.data;
            if (person != null) {
              _person = person;
            }
            return Column(
              children: [
                if (person != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                person.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    person.name,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  if (person.phone != null)
                                    Text(
                                      person.phone!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // ✅ بطاقة إجمالي المستحقات
                        totalAsync.when(
                          data: (total) => Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  l10n.totalOutstanding,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${total.amount} دينار',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          loading: () => const SizedBox(
                            height: 40,
                            child:
                                Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, st) => const Text('---'),
                        ),
                        const SizedBox(height: 12),
                        // ✅ أزرار كشف الحساب
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _sendWhatsAppStatement(person),
                                icon: const Icon(Icons.chat),
                                label: Text(l10n.sendWhatsAppStatement),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _exportPersonStatementPdf(person),
                                icon: const Icon(Icons.picture_as_pdf),
                                label: Text(l10n.exportStatementPdf),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                Expanded(
                  child: debtsAsync.when(
                    data: (debts) {
                      if (debts.isEmpty) {
                        return EmptyState(
                          icon: Icons.receipt_long,
                          title: l10n.noDebts,
                          subtitle: l10n.noDebts,
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: debts.length,
                        itemBuilder: (context, index) {
                          final debt = debts[index];
                          final balance = balancesAsync.value?[debt.id];
                          return _DebtCard(
                            debt: debt,
                            balance: balance,
                            onTap: () =>
                                context.go('/debt/${debt.id.value}'),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.go('/person/${widget.personId.value}/add-debt'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(l10n.addDebt),
      ),
    );
  }

  // ✅ حوار تعديل الشخص
  void _showEditPersonDialog(Person person) {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: person.name);
    final phoneController = TextEditingController(text: person.phone);
    final emailController = TextEditingController(text: person.email);
    final notesController = TextEditingController(text: person.notes);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.name)),
            TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: l10n.phone)),
            TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: l10n.email)),
            TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: l10n.notes)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              final updatedPerson = Person(
                id: person.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
                email: emailController.text.trim().isEmpty
                    ? null
                    : emailController.text.trim(),
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
                createdAt: person.createdAt,
                updatedAt: DateTime.now(),
                version: person.version + 1,
                isDeleted: person.isDeleted,
                deletedAt: person.deletedAt,
              );
              final updatePerson = ref.read(updatePersonProvider);
              await updatePerson(updatedPerson);
              ref.invalidate(personRepositoryProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  // ✅ تأكيد حذف الشخص
  Future<void> _confirmDeletePerson(Person person) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeletePerson),
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

    final deletePerson = ref.read(deletePersonProvider);
    await deletePerson(person.id);
    if (!mounted) return;
    ref.invalidate(peopleProvider);
    context.go('/');
  }
}

// ✅ كارت الدين
class _DebtCard extends ConsumerWidget {
  final Debt debt;
  final Money? balance;
  final VoidCallback onTap;
  const _DebtCard({
    required this.debt,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${balance?.amount ?? debt.amount.amount} IQD',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            debt.status.name,
            style: TextStyle(
              color: _statusColor(context, debt.status),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (debt.dueDate != null)
            Text(
              '${l10n.dueDate}: ${_formatDate(debt.dueDate!)}',
              style: textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, DebtStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case DebtStatus.paid:
        return Colors.green;
      case DebtStatus.overdue:
        return colorScheme.error;
      case DebtStatus.cancelled:
        return colorScheme.onSurfaceVariant;
      default:
        return colorScheme.primary;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}