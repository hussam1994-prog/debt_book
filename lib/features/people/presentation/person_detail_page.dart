import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final personAsync = ref.watch(personRepositoryProvider).findById(widget.personId);
    final debtsAsync = ref.watch(debtsForPersonProvider(widget.personId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Person Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              if (_person != null) _showEditPersonDialog(_person!);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
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
            _person = person; // نخزنه للاستخدام في الأزرار
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
                        backgroundColor: AppColors.primary.withOpacity(0.1),
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
                              Text(person.phone!, style: AppTextStyles.bodyMedium),
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
                      return const EmptyState(
                        icon: Icons.receipt_long,
                        title: 'No Debts',
                        subtitle: 'This person has no debts yet.',
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
        label: const Text('Add Debt'),
      ),
    );
  }

  void _showEditPersonDialog(Person person) {
    final nameController = TextEditingController(text: person.name);
    final phoneController = TextEditingController(text: person.phone);
    final emailController = TextEditingController(text: person.email);
    final notesController = TextEditingController(text: person.notes);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updatedPerson = Person(
                id: person.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePerson(Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Person'),
        content: const Text('Are you sure? This will hide the person and all related data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final deletePerson = ref.read(deletePersonProvider);
    await deletePerson(person.id);
    ref.invalidate(peopleProvider);
    if (context.mounted) context.go('/');
  }
}

class _DebtCard extends ConsumerWidget {
  final Debt debt;
  final VoidCallback onTap;
  const _DebtCard({required this.debt, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              color: _statusColor(debt.status),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (debt.dueDate != null)
            Text(
              'Due: ${_formatDate(debt.dueDate!)}',
              style: AppTextStyles.bodyMedium,
            ),
        ],
      ),
    );
  }

  Color _statusColor(DebtStatus status) {
    switch (status) {
      case DebtStatus.paid:
        return Colors.green;
      case DebtStatus.overdue:
        return AppColors.error;
      case DebtStatus.cancelled:
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}