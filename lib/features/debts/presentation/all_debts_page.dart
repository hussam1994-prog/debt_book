import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../dashboard/providers/analytics_providers.dart';

class AllDebtsPage extends ConsumerStatefulWidget {
  const AllDebtsPage({super.key});

  @override
  ConsumerState<AllDebtsPage> createState() => _AllDebtsPageState();
}

class _AllDebtsPageState extends ConsumerState<AllDebtsPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final debtsAsync = ref.watch(allDebtsWithPersonNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allDebts),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
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
            child: debtsAsync.when(
              data: (debts) {
                final filtered = _query.isEmpty
                    ? debts
                    : debts.where((entry) {
                        final desc = entry.$1.description?.toLowerCase() ?? '';
                        final person = entry.$2.toLowerCase();
                        return desc.contains(_query) || person.contains(_query);
                      }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long,
                    title: l10n.noDebts,
                    subtitle: l10n.noDebts,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    final debt = entry.$1;
                    final personName = entry.$2;
                    return AppCard(
                      onTap: () => context.go('/debt/${debt.id.value}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.description ?? l10n.description,
                            style: AppTextStyles.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            personName,
                            style: AppTextStyles.bodyMedium,
                          ),
                          Text(
                            '${debt.amount.amount} IQD',
                            style: AppTextStyles.headline2.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}