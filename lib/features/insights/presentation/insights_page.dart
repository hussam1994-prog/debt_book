import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../dashboard/providers/analytics_providers.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.smartInsights),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: insightsAsync.when(
        data: (insights) {
          if (insights.isEmpty) {
            return EmptyState(
              icon: Icons.lightbulb_outline,
              title: l10n.noInsights,
              subtitle: l10n.noInsights,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            itemCount: insights.length,
            itemBuilder: (context, index) {
              final insight = insights[index];
              return AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates, color: AppColors.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        insight.message,
                        style: AppTextStyles.bodyLarge,
                      ),
                    ),
                    if (insight.debtId != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => context.go('/debt/${insight.debtId}'),
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
    );
  }
}