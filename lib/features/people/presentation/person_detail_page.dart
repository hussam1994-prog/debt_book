import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/people_providers.dart';

class PersonDetailPage extends ConsumerWidget {
  final PersonId personId;
  const PersonDetailPage({super.key, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(personRepositoryProvider).findById(personId);
    final debtsAsync = ref.watch(debtsForPersonProvider(personId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Person Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: FutureBuilder<Person?>(
        future: personAsync,
        builder: (context, personSnapshot) {
          final person = personSnapshot.data;
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
        onPressed: () => context.go('/person/${personId.value}/add-debt'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Debt'),
      ),
    );
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