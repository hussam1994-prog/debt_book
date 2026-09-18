import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/app_formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../providers/analytics_providers.dart';
import '../widgets/debts_pie_chart.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  /// ✅ تحديث محلي فقط: إعادة تحميل بيانات لوحة المعلومات
  void _refreshLocal(WidgetRef ref) {
    ref.invalidate(totalOutstandingProvider);
    ref.invalidate(totalPaidProvider);
    ref.invalidate(peopleWithDebtsCountProvider);
    ref.invalidate(overdueDebtsProvider);
    ref.invalidate(last7DaysPaymentsProvider);
    ref.invalidate(balancesByDebtProvider);
    ref.invalidate(debtStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final outstandingAsync = ref.watch(totalOutstandingProvider);
    final paidAsync = ref.watch(totalPaidProvider);
    final peopleCountAsync = ref.watch(peopleWithDebtsCountProvider);
    final overdueAsync = ref.watch(overdueDebtsProvider);
    final last7PaymentsAsync = ref.watch(last7DaysPaymentsProvider);
    final debtStatsAsync = ref.watch(debtStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'الإحصائيات الشهرية',
            onPressed: () => context.go('/monthly-stats'),
),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () => _refreshLocal(ref),
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshLocal(ref),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── بطاقات الإحصائيات ───
                    Row(
                      children: [
                        _StatCard(
                          label: l10n.balance,
                          valueAsync: outstandingAsync,
                          icon: Icons.receipt_long,
                          color: AppColors.error,
                        ),
                        _StatCard(
                          label: l10n.paid,
                          valueAsync: paidAsync,
                          icon: Icons.payments,
                          color: AppColors.success,
                        ),
                        _StatCard(
                          label: l10n.people,
                          valueAsync: peopleCountAsync,
                          icon: Icons.people,
                          color: AppColors.primary,
                          isMoney: false,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ─── الرسم الدائري لتوزيع الديون ───
                    Text(context.l10n.debtDistribution, style: textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: debtStatsAsync.when(
                          data: (stats) => Column(
                            children: [
                              DebtsPieChart(
                                activeCount: stats['active'] ?? 0,
                                overdueCount: stats['overdue'] ?? 0,
                                completedCount: stats['completed'] ?? 0,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _legendItem('نشط', AppColors.success),
                                  const SizedBox(width: 16),
                                  _legendItem('متأخر', AppColors.error),
                                  const SizedBox(width: 16),
                                  _legendItem('مكتمل', AppColors.info),
                                ],
                              ),
                            ],
                          ),
                          loading: () => const SizedBox(
                            height: 220,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, st) =>
                              Center(child: Text(context.l10n.errorGeneric(e.toString()))),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ─── الرسم البياني لدفعات آخر 7 أيام ───
                    Text(l10n.paymentsLast7Days, style: textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    _BarChart(paymentsAsync: last7PaymentsAsync),

                    const SizedBox(height: AppSpacing.lg),

                    // ─── الديون المتأخرة ───
                    Text(l10n.noOverdue, style: textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    overdueAsync.when(
                      data: (debts) {
                        if (debts.isEmpty) {
                          return EmptyState(
                            icon: Icons.check_circle_outline,
                            title: l10n.noOverdue,
                          );
                        }
                        return Column(
                          children: debts
                              .map((debt) => _DebtCard(debt: debt))
                              .toList(),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text(context.l10n.errorGeneric(e.toString()))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ─── بطاقة إحصائية ───
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
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            valueAsync.when(
              data: (value) {
                final display = isMoney
                    ? AppFormatters.money(context, (value as Money).amount)
                    : '$value';
                return Text(
                  display,
                  style: textTheme.titleMedium?.copyWith(fontSize: 14),
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

// ─── الرسم البياني للأعمدة ───
class _BarChart extends StatelessWidget {
  final AsyncValue<List<Payment>> paymentsAsync;
  const _BarChart({required this.paymentsAsync});

  @override
  Widget build(BuildContext context) {
    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(context.l10n.noPaymentsInWeek),
          );
        }
        final now = DateTime.now();
        final days = List.generate(
          7,
          (i) => DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: 6 - i)),
        );
        final totals = days.map((day) {
          final dayEnd = day.add(const Duration(days: 1));
          return payments
              .where((p) =>
                  p.paymentDate.isAfter(day) &&
                  p.paymentDate.isBefore(dayEnd))
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
                final barHeight =
                    maxVal == 0 ? 1.0 : (totals[index] / maxVal * 80);
                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${totals[index]}',
                        style: const TextStyle(fontSize: 10),
                      ),
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
      error: (e, st) => Center(child: Text(context.l10n.errorGeneric(e.toString()))),
    );
  }
}

// ─── بطاقة الدين ───
class _DebtCard extends ConsumerWidget {
  final Debt debt;
  const _DebtCard({required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(debt.description ?? 'Debt'),
      subtitle: Text(AppFormatters.money(context, debt.amount.amount)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go('/debt/${debt.id.value}'),
    );
  }
}