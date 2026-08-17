import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../dashboard/providers/analytics_providers.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDebtsAsync = ref.watch(allDebtsProvider);
    final balancesAsync = ref.watch(balancesByDebtProvider);
    final overdueAsync = ref.watch(overdueDebtsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: AppTextStyles.headline2),
            const SizedBox(height: AppSpacing.sm),
            _SummarySection(
              allDebtsAsync: allDebtsAsync,
              balancesAsync: balancesAsync,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Overdue Debts', style: AppTextStyles.headline2),
            const SizedBox(height: AppSpacing.sm),
            overdueAsync.when(
              data: (debts) {
                if (debts.isEmpty) {
                  return const EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No overdue debts',
                  );
                }
                return Column(
                  children: debts.map((debt) => _DebtTile(debt: debt)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends ConsumerWidget {
  final AsyncValue<List<Debt>> allDebtsAsync;
  final AsyncValue<Map<DebtId, Money>> balancesAsync;

  const _SummarySection({
    required this.allDebtsAsync,
    required this.balancesAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _StatBox(
          label: 'Total Debts',
          valueAsync: allDebtsAsync.when(
            data: (debts) => AsyncData(debts.length),
            loading: () => const AsyncLoading(),
            error: (e, st) => AsyncError(e, st),
          ),
          icon: Icons.receipt_long,
          color: AppColors.primary,
          isMoney: false,
        ),
        _StatBox(
          label: 'Outstanding',
          valueAsync: balancesAsync.when(
            data: (balances) {
              var total = 0;
              for (final balance in balances.values) {
                if (balance.amount > 0) total += balance.amount;
              }
              return AsyncData(Money(amount: total));
            },
            loading: () => const AsyncLoading(),
            error: (e, st) => AsyncError(e, st),
          ),
          icon: Icons.money_off,
          color: AppColors.error,
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final AsyncValue<Object> valueAsync;
  final IconData icon;
  final Color color;
  final bool isMoney;

  const _StatBox({
    required this.label,
    required this.valueAsync,
    required this.icon,
    required this.color,
    this.isMoney = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 4),
              valueAsync.when(
                data: (value) {
                  final display = isMoney
                      ? '${(value as Money).amount} IQD'
                      : '$value';
                  return Text(
                    display,
                    style: AppTextStyles.headline2.copyWith(fontSize: 14),
                  );
                },
                loading: () => const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, st) => const Text('---'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtTile extends ConsumerWidget {
  final Debt debt;
  const _DebtTile({required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.error, color: AppColors.error),
      title: Text(debt.description ?? 'Debt'),
      subtitle: Text('${debt.amount.amount} IQD'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go('/debt/${debt.id.value}'),
    );
  }
}