import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeletons.dart';
import '../../dashboard/providers/analytics_providers.dart';
import '../../debts/providers/debts_grouped_provider.dart';
import '../widgets/debts_trend_chart.dart';
import '../widgets/top_debtors_chart.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  void _refreshLocal() {
    ref.invalidate(allDebtsProvider);
    ref.invalidate(balancesByDebtProvider);
    ref.invalidate(overdueDebtsProvider);
    ref.invalidate(monthlyTrendProvider);
    ref.invalidate(debtsGroupedByPersonProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث التقارير محليًا')),
      );
    }
  }

  // ─── تصدير CSV ───
  Future<void> _exportToCsv() async {
    try {
      final allDebts = await ref.read(allDebtsProvider.future);
      final balances = await ref.read(balancesByDebtProvider.future);
      final personRepo = ref.read(personRepositoryProvider);

      final rows = <Map<String, String>>[];
      for (final debt in allDebts) {
        final person = await personRepo.findById(debt.personId);
        final balance = balances[debt.id] ?? Money.zero;
        rows.add({
          'person': person?.name ?? 'Unknown',
          'description': debt.description ?? '',
          'originalAmount': '${debt.amount.amount}',
          'balance': '${balance.amount}',
          'status': debt.status.name,
          'dueDate': debt.dueDate?.toIso8601String() ?? '',
        });
      }

      final exportService = ref.read(exportServiceProvider);
      final file = await exportService.exportDebtsToCsv(rows: rows);

      if (mounted) {
        _showShareDialog(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  // ─── تصدير PDF ───
  Future<void> _exportToPdf() async {
    try {
      final allDebts = await ref.read(allDebtsProvider.future);
      final balances = await ref.read(balancesByDebtProvider.future);
      final personRepo = ref.read(personRepositoryProvider);

      final rows = <Map<String, String>>[];
      for (final debt in allDebts) {
        final person = await personRepo.findById(debt.personId);
        final balance = balances[debt.id] ?? Money.zero;
        rows.add({
          'person': person?.name ?? 'Unknown',
          'description': debt.description ?? '',
          'originalAmount': '${debt.amount.amount}',
          'balance': '${balance.amount}',
          'status': debt.status.name,
          'dueDate': debt.dueDate?.toIso8601String() ?? '',
        });
      }

      final l10n = context.l10n;
      final labels = <String, String>{
        'pdfReportTitle': l10n.pdfReportTitle,
        'pdfPerson': l10n.pdfPerson,
        'pdfDescription': l10n.pdfDescription,
        'pdfOriginalAmount': l10n.pdfOriginalAmount,
        'pdfBalance': l10n.pdfBalance,
        'pdfStatus': l10n.pdfStatus,
        'pdfDueDate': l10n.pdfDueDate,
      };

      final pdfService = ref.read(pdfExportServiceProvider);
      final file = await pdfService.exportDebtsToPdf(rows: rows, labels: labels);

      if (mounted) {
        _showShareDialog(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  // ─── ✅ تصدير Excel ───
  Future<void> _exportToExcel() async {
    try {
      final allDebts = await ref.read(allDebtsProvider.future);
      final balances = await ref.read(balancesByDebtProvider.future);
      final personRepo = ref.read(personRepositoryProvider);

      final rows = <Map<String, String>>[];
      for (final debt in allDebts) {
        final person = await personRepo.findById(debt.personId);
        final balance = balances[debt.id] ?? Money.zero;
        rows.add({
          'person': person?.name ?? 'Unknown',
          'description': debt.description ?? '',
          'originalAmount': '${debt.amount.amount}',
          'balance': '${balance.amount}',
          'status': debt.status.name,
          'dueDate': debt.dueDate?.toIso8601String() ?? '',
        });
      }

      final l10n = context.l10n;
      final labels = <String, String>{
        'person': l10n.pdfPerson,
        'description': l10n.pdfDescription,
        'originalAmount': l10n.pdfOriginalAmount,
        'balance': l10n.pdfBalance,
        'status': l10n.pdfStatus,
        'dueDate': l10n.pdfDueDate,
      };

      final service = ref.read(excelExportServiceProvider);
      final file =
          await service.exportDebtsToExcel(rows: rows, labels: labels);

      if (mounted) {
        _showShareDialog(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تصدير Excel: $e')),
        );
      }
    }
  }

  void _showShareDialog(String filePath) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تم التصدير'),
        content: const Text('هل تريد مشاركة الملف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('مشاركة'),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await SharePlus.instance.share(
                ShareParams(files: [XFile(filePath)]),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final allDebtsAsync = ref.watch(allDebtsProvider);
    final balancesAsync = ref.watch(balancesByDebtProvider);
    final overdueAsync = ref.watch(overdueDebtsProvider);
    final trendAsync = ref.watch(monthlyTrendProvider);
    final groupedAsync = ref.watch(debtsGroupedByPersonProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
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
          // ✅ تقرير متعدد
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'تقرير متعدد',
            onPressed: () => context.go('/multi-person-report'),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _exportToPdf,
          ),
          // ✅ Excel
          IconButton(
            icon: const Icon(Icons.table_chart, color: Colors.green),
            tooltip: 'تصدير Excel',
            onPressed: _exportToExcel,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: l10n.exportCsv,
            onPressed: _exportToCsv,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshLocal(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── الملخص العام ───
              Text(l10n.overview, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              _SummarySection(
                allDebtsAsync: allDebtsAsync,
                balancesAsync: balancesAsync,
              ),

              const SizedBox(height: AppSpacing.lg),

              // ─── رسم الاتجاه الشهري ───
              Text('تطور الديون الشهري', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: trendAsync.when(
                    data: (data) => DebtsTrendChart(
                      months: data.map((e) => e.key).toList(),
                      totals: data.map((e) => e.value).toList(),
                    ),
                    loading: () => const ChartSkeleton(),
                    error: (e, st) => SizedBox(
                      height: 220,
                      child: Center(child: Text('Error: $e')),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ─── رسم أعلى 5 مدينين ───
              Text('أعلى 5 مدينين', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: groupedAsync.when(
                    data: (summaries) =>
                        TopDebtorsChart(summaries: summaries),
                    loading: () => const ChartSkeleton(),
                    error: (e, st) => SizedBox(
                      height: 250,
                      child: Center(child: Text('Error: $e')),
                    ),
                  ),
                ),
              ),

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
                    children:
                        debts.map((debt) => _DebtTile(debt: debt)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
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
    final l10n = context.l10n;
    return Row(
      children: [
        _StatBox(
          label: l10n.totalDebts,
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
          label: l10n.balance,
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
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: textTheme.bodyMedium),
              const SizedBox(height: 4),
              valueAsync.when(
                data: (value) {
                  final display = isMoney
                      ? '${(value as Money).amount} IQD'
                      : '$value';
                  return Text(
                    display,
                    style: textTheme.titleMedium?.copyWith(fontSize: 14),
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