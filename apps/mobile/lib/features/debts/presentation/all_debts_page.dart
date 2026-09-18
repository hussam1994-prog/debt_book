import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_formatters.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../people/widgets/person_card.dart';
import '../providers/debts_grouped_provider.dart';
import '../providers/debts_paginated_provider.dart';

class AllDebtsPage extends ConsumerStatefulWidget {
  const AllDebtsPage({super.key});

  @override
  ConsumerState<AllDebtsPage> createState() => _AllDebtsPageState();
}

class _AllDebtsPageState extends ConsumerState<AllDebtsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  bool _grouped = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(debtsPaginatedProvider.notifier).loadMore();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(debtsPaginatedProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshLocal() async {
    if (_grouped) {
      ref.invalidate(debtsGroupedByPersonProvider);
    } else {
      await ref.read(debtsPaginatedProvider.notifier).refresh();
    }
  }

  // ─── ✅ تصدير التقرير المجمّع (PDF / CSV / Excel) ───
  Future<void> _exportGroupedReport() async {
    final l10n = context.l10n;
    final summariesAsync = ref.read(debtsGroupedByPersonProvider);
    final summaries = await summariesAsync.value;
    if (summaries == null || summaries.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noDataToExport)),
      );
      return;
    }

    final action = await showModalBottomSheet<String>(
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
                l10n.exportReport,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.table_view, color: Colors.blue),
                title: const Text('CSV'),
                subtitle: Text(l10n.simpleTextFile),
                onTap: () => Navigator.pop(ctx, 'csv'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF'),
                subtitle: Text(l10n.officialReport),
                onTap: () => Navigator.pop(ctx, 'pdf'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.table_chart,
                  color: Colors.green,
                ),
                title: const Text('Excel'),
                subtitle: Text(l10n.professionalTable),
                onTap: () => Navigator.pop(ctx, 'excel'),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == null) return;

    try {
      final l10n = context.l10n;

      if (action == 'csv') {
        final file = await ref
            .read(exportServiceProvider)
            .exportGroupedDebtsToCsv(summaries: summaries);
        if (!mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            text: l10n.groupedDebtsReport,
            files: [XFile(file.path)],
          ),
        );
      } else if (action == 'pdf') {
        final file = await ref
            .read(pdfExportServiceProvider)
            .exportGroupedDebtsToPdf(
              summaries: summaries,
              labels: {
                'groupedDebtsReportTitle': l10n.pdfReportTitle,
                'person': l10n.pdfPerson,
                'totalOutstanding': l10n.totalOutstanding,
                'debts': l10n.debts,
                'dueDate': l10n.dueDate,
              },
            );
        if (!mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            text: l10n.groupedDebtsReport,
            files: [XFile(file.path)],
          ),
        );
      } else if (action == 'excel') {
        final rows = summaries.map((s) => <String, String>{
              'person': s.personName,
              'totalOutstanding': '${s.totalOutstanding.amount}',
              'debts': '${s.debtCount}',
              'dueDate': s.lastDueDate != null
                  ? '${s.lastDueDate!.day}/${s.lastDueDate!.month}/${s.lastDueDate!.year}'
                  : '',
            }).toList();

        final file = await ref
            .read(excelExportServiceProvider)
            .exportGroupedToExcel(
              rows: rows,
              labels: {
                'person': l10n.pdfPerson,
                'totalOutstanding': l10n.totalOutstanding,
                'debts': l10n.debts,
                'dueDate': l10n.dueDate,
              },
            );

        if (!mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            text: l10n.groupedDebtsReport,
            files: [XFile(file.path)],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.exportFailedGeneric(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allDebts),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: Icon(_grouped ? Icons.list : Icons.people),
            tooltip: _grouped ? l10n.individualView : l10n.groupedView,
            onPressed: () {
              setState(() {
                _grouped = !_grouped;
              });
            },
          ),
          if (_grouped)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: l10n.aggregateReportTooltip,
              onPressed: _exportGroupedReport,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _refreshLocal,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: _grouped ? _buildGroupedList() : _buildIndividualList(),
          ),
        ],
      ),
    );
  }

  // ─── العرض المجمّع حسب الشخص ───
  Widget _buildGroupedList() {
    final groupedAsync = ref.watch(debtsGroupedByPersonProvider);
    final l10n = context.l10n;

    return groupedAsync.when(
      data: (summaries) {
        final filtered = _query.isEmpty
            ? summaries
            : summaries
                .where((s) => s.personName.toLowerCase().contains(_query))
                .toList();

        if (filtered.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: l10n.noDebts,
            subtitle: l10n.noDebts,
          );
        }

        final totalOutstanding = filtered.fold<int>(
            0, (sum, s) => sum + s.totalOutstanding.amount);
        final totalDebts =
            filtered.fold<int>(0, (sum, s) => sum + s.debtCount);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryItem(
                        icon: Icons.people,
                        label: l10n.people,
                        value: '${filtered.length}',
                      ),
                      _summaryItem(
                        icon: Icons.receipt_long,
                        label: l10n.debts,
                        value: '$totalDebts',
                      ),
                      _summaryItem(
                        icon: Icons.account_balance_wallet,
                        label: l10n.totalOutstanding,
                        value: AppFormatters.money(context, totalOutstanding),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshLocal,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final summary = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: PersonCard(
                        summary: summary,
                        onTap: () => context
                            .go('/person/${summary.personId.value}'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Text(context.l10n.errorGeneric(e.toString())),
      ),
    );
  }

  // ─── العرض الفردي ───
  Widget _buildIndividualList() {
    final debts = ref.watch(debtsPaginatedProvider);
    final notifier = ref.watch(debtsPaginatedProvider.notifier);
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _refreshLocal,
      child: debts.isEmpty
          ? (notifier.isLoading
              ? const Center(child: CircularProgressIndicator())
              : EmptyState(
                  icon: Icons.receipt_long,
                  title: l10n.noDebts,
                  subtitle: l10n.noDebts,
                ))
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: debts.length + (notifier.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == debts.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final entry = debts[index];
                final debt = entry.$1;
                final personName = entry.$2 ?? l10n.unknownPerson;

                final desc = debt.description?.toLowerCase() ?? '';
                final matchesQuery = _query.isEmpty ||
                    desc.contains(_query) ||
                    personName.toLowerCase().contains(_query);

                if (!matchesQuery) {
                  return const SizedBox.shrink();
                }

                return AppCard(
                  onTap: () => context.go('/debt/${debt.id.value}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.description ?? l10n.description,
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        personName,
                        style: textTheme.bodyMedium,
                      ),
                      Text(
                        AppFormatters.money(context, debt.amount.amount),
                        style: textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
      ],
    );
  }
}