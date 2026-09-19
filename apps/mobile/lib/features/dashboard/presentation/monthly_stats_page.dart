import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_formatters.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/monthly_stats_provider.dart';

class MonthlyStatsPage extends ConsumerWidget {
  const MonthlyStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statsAsync = ref.watch(monthlyStatsProvider);
    final totalDebtsAsync = ref.watch(totalDebtsAmountProvider);
    final totalPaymentsAsync = ref.watch(totalPaymentsAmountProvider);
    final topDebtorsAsync = ref.watch(topDebtorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.monthlyStats),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () {
              ref.invalidate(monthlyStatsProvider);
              ref.invalidate(totalDebtsAmountProvider);
              ref.invalidate(totalPaymentsAmountProvider);
              ref.invalidate(topDebtorsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(monthlyStatsProvider);
          ref.invalidate(totalDebtsAmountProvider);
          ref.invalidate(totalPaymentsAmountProvider);
          ref.invalidate(topDebtorsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ─── البطاقات الإجمالية ───
            Row(
              children: [
                Expanded(
                  child: _TotalCard(
                    icon: Icons.receipt_long,
                    label: l10n.totalOutstandingLabel,
                    valueAsync: totalDebtsAsync,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TotalCard(
                    icon: Icons.payments,
                    label: l10n.totalPaymentsLabel,
                    valueAsync: totalPaymentsAsync,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── رسم بياني ───
            Text(
              l10n.debtsAndPayments6Months,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  height: 220,
                  child: statsAsync.when(
                    data: (stats) => _MonthlyBarChart(stats: stats),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, st) => Center(
                      child: Text(l10n.errorGeneric(e.toString())),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── أعلى 5 مدينين ───
            Text(
              l10n.top5Debtors,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: topDebtorsAsync.when(
                  data: (debtors) {
                    if (debtors.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(l10n.noData),
                        ),
                      );
                    }
                    return Column(
                      children: debtors.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final d = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  d['name'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                AppFormatters.money(
                                  context,
                                  d['amount'] as int,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, st) => Center(
                    child: Text(l10n.errorGeneric(e.toString())),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── جدول شهري ───
            Text(
              l10n.monthlyDetails,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: statsAsync.when(
                  data: (stats) {
                    return Column(
                      children: stats.map((s) {
                        final monthName = _monthName(context, s.month.month);
                        return ListTile(
                          dense: true,
                          title: Text('$monthName ${s.month.year}'),
                          subtitle: Text(
                            l10n.newDebtsAndPayments(
                              s.newDebts,
                              s.payments,
                            ),
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+${s.newDebtsAmount}',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '-${s.paymentsAmount}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, st) => Center(
                    child: Text(l10n.errorGeneric(e.toString())),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(BuildContext context, int month) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.MMMM(locale).format(DateTime(2020, month, 1));
  }
}

// ─── بطاقة إجمالي ───
class _TotalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final AsyncValue<int> valueAsync;
  final Color color;

  const _TotalCard({
    required this.icon,
    required this.label,
    required this.valueAsync,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            valueAsync.when(
              data: (v) => Text(
                AppFormatters.number(context, v),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              loading: () => const SizedBox(
                height: 20,
                width: 20,
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

// ─── رسم بياني للأعمدة ───
class _MonthlyBarChart extends StatelessWidget {
  final List<MonthlyStats> stats;

  const _MonthlyBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxY = stats.fold<int>(0, (m, s) {
      return [m, s.newDebtsAmount, s.paymentsAmount]
          .reduce((a, b) => a > b ? a : b);
    }).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? maxY * 1.2 : 100,
        barGroups: stats.asMap().entries.map((entry) {
          final idx = entry.key;
          final s = entry.value;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: s.newDebtsAmount.toDouble(),
                color: AppColors.error,
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: s.paymentsAmount.toDouble(),
                color: AppColors.success,
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= stats.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _shortMonth(context, stats[idx].month.month),
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 25,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  String _shortMonth(BuildContext context, int month) {
    final locale = Localizations.localeOf(context).toString();
    // استخدام DateFormat يعرض أسماء الأشهر حسب اللغة تلقائياً
    return DateFormat.MMM(locale).format(DateTime(2020, month, 1));
  }
}