import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/analytics_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outstandingAsync = ref.watch(totalOutstandingProvider);
    final paidAsync = ref.watch(totalPaidProvider);
    final peopleCountAsync = ref.watch(peopleWithDebtsCountProvider);
    final overdueAsync = ref.watch(overdueDebtsProvider);
    final last7PaymentsAsync = ref.watch(last7DaysPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
            Row(
              children: [
                _StatCard(
                  label: 'Outstanding',
                  valueAsync: outstandingAsync,
                  icon: Icons.receipt_long,
                  color: AppColors.error,
                ),
                _StatCard(
                  label: 'Paid',
                  valueAsync: paidAsync,
                  icon: Icons.payments,
                  color: Colors.green,
                ),
                _StatCard(
                  label: 'People',
                  valueAsync: peopleCountAsync,
                  icon: Icons.people,
                  color: AppColors.primary,
                  isMoney: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Payments (Last 7 Days)', style: AppTextStyles.headline2),
            const SizedBox(height: AppSpacing.sm),
            _BarChart(paymentsAsync: last7PaymentsAsync),
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
                  children: debts.map((debt) => _DebtCard(debt: debt)).toList(),
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

class _StatCard extends ConsumerWidget {
  final String label;
  final AsyncValue<Object> valueAsync;
  final IconData icon;
  final Color color;
  final bool isMoney;

  const _StatCard({
    required this.label,
    required this.valueAsync,
    required this.icon,
    required this.color,
    this.isMoney = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 4),
            valueAsync.when(
              data: (value) {
                final display = isMoney ? '${(value as Money).amount} IQD' : '$value';
                return Text(
                  display,
                  style: AppTextStyles.headline2.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
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
    );
  }
}

class _BarChart extends StatelessWidget {
  final AsyncValue<List<Payment>> paymentsAsync;
  const _BarChart({required this.paymentsAsync});

  @override
  Widget build(BuildContext context) {
    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return const Text('No payments in last 7 days.');
        }
        final now = DateTime.now();
        final days = List.generate(7, (i) =>
            DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
        final totals = days.map((day) {
          final dayEnd = day.add(const Duration(days: 1));
          return payments
              .where((p) => p.paymentDate.isAfter(day) && p.paymentDate.isBefore(dayEnd))
              .fold<int>(0, (sum, p) => sum + p.amount.amount);
        }).toList();

        final maxVal = totals.fold<int>(0, (max, v) => v > max ? v : max);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (index) {
                final dayLabel = '${days[index].day}/${days[index].month}';
                final barHeight = maxVal == 0 ? 1.0 : (totals[index] / maxVal * 80);
                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${totals[index]}', style: const TextStyle(fontSize: 10)),
                      const SizedBox(height: 4),
                      Container(
                        height: barHeight + 1,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(dayLabel, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _DebtCard extends ConsumerWidget {
  final Debt debt;
  const _DebtCard({required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(debt.description ?? 'Debt'),
      subtitle: Text('${debt.amount.amount} IQD'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go('/debt/${debt.id.value}'),
    );
  }
}