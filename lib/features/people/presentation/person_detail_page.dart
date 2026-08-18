import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final personAsync = ref.watch(personRepositoryProvider).findById(widget.personId);
    final debtsAsync = ref.watch(debtsForPersonProvider(widget.personId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.personDetails),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
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
      body: FutureBuilder<Person?>(
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
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          person.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
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
                            Text(person.name, style: AppTextStyles.headline2),
                            if (person.phone != null)
                              Text(
                                person.phone!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                            if (person.email != null)
                              Text(person.email!, style: AppTextStyles.bodyMedium),
                          ],
                        ),
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
                      itemCount: debts.length,
                      itemBuilder: (context, index) {
                        final debt = debts[index];
                        return _DebtCard(
                          debt: debt,
                          onTap: () => context.go('/debt/${debt.id.value}'),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/person/${widget.personId.value}/add-debt'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(l10n.addDebt),
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

class _DebtCard extends ConsumerWidget {
  final Debt debt;
  final VoidCallback onTap;
  const _DebtCard({required this.debt, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final balanceAsync = ref.watch(balanceForDebtProvider(debt.id));

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          balanceAsync.when(
            data: (balance) {
              return Text(
                '${balance.amount} IQD',
                style: AppTextStyles.headline2,
              );
            },
            loading: () => const Text('...'),
            error: (e, st) => Text('${debt.amount.amount} IQD'),
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
              style: AppTextStyles.bodyMedium,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}