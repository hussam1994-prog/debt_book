import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_formatters.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/whatsapp/whatsapp_service.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/people_providers.dart';
import '../providers/person_tag_provider.dart';

class PersonDetailPage extends ConsumerStatefulWidget {
  final PersonId personId;
  const PersonDetailPage({super.key, required this.personId});

  @override
  ConsumerState<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends ConsumerState<PersonDetailPage> {
  Person? _person;

  void _refreshLocal() {
    ref.invalidate(personRepositoryProvider);
    ref.invalidate(debtsForPersonProvider(widget.personId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.dataRefreshed)),
      );
    }
  }

  // ─── اختيار اللون ───
  void _showColorPicker(Person person) {
    final l10n = context.l10n;
    final tags = ref.read(personTagProvider);
    final currentIndex = tags[person.id.value];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.choosePersonColor),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            AppColors.tagColors.length,
            (index) {
              final isSelected = currentIndex == index;
              return GestureDetector(
                onTap: () {
                  ref.read(personTagProvider.notifier).setColor(
                        person.id.value,
                        index,
                      );
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.tagColors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(personTagProvider.notifier)
                  .clearColor(person.id.value);
              Navigator.pop(ctx);
            },
            child: Text(l10n.removeColor),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  // ─── إرسال كشف (نص أو PDF) ───
  Future<void> _sendWhatsAppStatement(Person person) async {
    final l10n = context.l10n;

    if (person.phone == null || person.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noPhoneForPerson)),
      );
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.sendStatement,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: Text(l10n.textMessage),
                subtitle: Text(l10n.balanceSummaryInMessage),
                onTap: () => Navigator.pop(ctx, 'text'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(l10n.pdfStatement),
                subtitle: Text(l10n.fullPdfFile),
                onTap: () => Navigator.pop(ctx, 'pdf'),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'text') {
      await _sendTextStatement(person);
    } else {
      await _sendPdfStatement(person);
    }
  }

  Future<void> _sendTextStatement(Person person) async {
    final l10n = context.l10n;
    try {
      final debts =
          await ref.read(debtsForPersonProvider(widget.personId).future);
      final balances = await ref.read(balancesForDebtsProvider(debts).future);
      final total = await ref
          .read(totalOutstandingForPersonProvider(widget.personId).future);

      if (debts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noDebts)),
          );
        }
        return;
      }

      final lines = StringBuffer();
      lines.writeln(l10n.mrMrs(person.name));
      lines.writeln(l10n.outstandingAmounts);
      for (final debt in debts) {
        final balance = balances[debt.id] ?? Money.zero;
        if (balance.amount > 0) {
          lines.writeln(
              '- ${debt.description ?? l10n.debtFallback}: ${balance.amount}');
        }
      }
      lines.writeln(l10n.statementTotal(total.amount));

      await WhatsAppService.sendReminder(
        phone: person.phone!,
        message: lines.toString(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
        );
      }
    }
  }

  Future<void> _sendPdfStatement(Person person) async {
    final l10n = context.l10n;
    try {
      final debts =
          await ref.read(debtsForPersonProvider(widget.personId).future);
      final balances = await ref.read(balancesForDebtsProvider(debts).future);
      final total = await ref
          .read(totalOutstandingForPersonProvider(widget.personId).future);

      if (debts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noDebts)),
          );
        }
        return;
      }

      final debtRows = debts.map((debt) {
        final balance = balances[debt.id] ?? Money.zero;
        return <String, String>{
          'description': debt.description ?? '',
          'originalAmount': '${debt.amount.amount}',
          'balance': '${balance.amount}',
          'status': debt.status.name,
        };
      }).toList();

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
        await SharePlus.instance.share(
          ShareParams(
            text: l10n.statementShareText(person.name, total.amount),
            files: [XFile(file.path)],
            subject: l10n.statementTitle,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sendPdfFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _exportPersonStatementPdf(Person person) async {
    final l10n = context.l10n;
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
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)]),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
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
    final tags = ref.watch(personTagProvider);

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
            icon: const Icon(Icons.color_lens),
            tooltip: l10n.changeColorTooltip,
            onPressed: () {
              if (_person != null) _showColorPicker(_person!);
            },
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
                if (person != null) _buildHeader(person, totalAsync, tags),
                const Divider(height: 1),
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
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: 100,
                        ),
                        itemCount: debts.length,
                        itemBuilder: (context, index) {
                          final debt = debts[index];
                          final balance = balancesAsync.value?[debt.id];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            child: _DebtCard(
                              debt: debt,
                              balance: balance,
                              onTap: () =>
                                  context.go('/debt/${debt.id.value}'),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(
                      child: Text(l10n.errorGeneric(e.toString())),
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
            context.go('/person/${widget.personId.value}/add-debt'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(l10n.addDebt),
      ),
    );
  }

  Widget _buildHeader(
      Person person, AsyncValue<Money> totalAsync, Map<String, int> tags) {
    final l10n = context.l10n;
    final avatarColor = colorForPerson(person.id.value, person.name, tags);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Hero(
                tag: 'person_avatar_${person.id.value}',
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: avatarColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: avatarColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    person.name.trim().substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: avatarColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (person.phone != null && person.phone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              person.phone!,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          totalAsync.when(
            data: (total) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.totalOutstanding,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppFormatters.money(context, total.amount),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => const Text('---'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (person.phone != null && person.phone!.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendWhatsAppStatement(person),
                    icon: const Icon(Icons.chat, color: Colors.green, size: 18),
                    label: Text(
                      l10n.sendWhatsAppStatement,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              if (person.phone != null && person.phone!.isNotEmpty)
                const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _exportPersonStatementPdf(person),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: Text(
                    l10n.exportStatementPdf,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.name)),
              const SizedBox(height: 8),
              TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: l10n.phone)),
              const SizedBox(height: 8),
              TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: l10n.email)),
              const SizedBox(height: 8),
              TextField(
                  controller: notesController,
                  decoration: InputDecoration(labelText: l10n.notes)),
            ],
          ),
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

    await ref.read(personRepositoryProvider).softDelete(person.id);
    await ref.read(peoplePaginatedProvider.notifier).refresh();

    if (!mounted) return;
    context.go('/');
  }
}

// ─── بطاقة الدين ───
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
    final currentBalance = balance?.amount ?? debt.amount.amount;
    final progress = debt.amount.amount > 0
        ? (1 - (currentBalance / debt.amount.amount)).clamp(0.0, 1.0)
        : 0.0;
    final statusColor = _statusColor(debt.status);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      debt.description ?? l10n.description,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(context, debt.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      AppFormatters.money(context, currentBalance),
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: currentBalance > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ),
                  if (debt.amount.amount != currentBalance) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.fromAmount(
                          AppFormatters.money(context, debt.amount.amount),
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
              if (debt.amount.amount > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.success),
                  ),
                ),
              ],
              if (debt.dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${l10n.dueDate}: ${AppFormatters.date(context, debt.dueDate!)}',
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(DebtStatus status) {
    switch (status) {
      case DebtStatus.paid:
        return AppColors.success;
      case DebtStatus.overdue:
        return AppColors.error;
      case DebtStatus.cancelled:
        return AppColors.textHint;
      default:
        return AppColors.primary;
    }
  }

  String _statusLabel(BuildContext context, DebtStatus status) {
    final l10n = context.l10n;
    switch (status) {
      case DebtStatus.paid:
        return l10n.statusPaid;
      case DebtStatus.overdue:
        return l10n.statusOverdue;
      case DebtStatus.cancelled:
        return l10n.statusCancelled;
      default:
        return l10n.statusActive;
    }
  }
}