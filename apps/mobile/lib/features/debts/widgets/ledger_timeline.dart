import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design.dart';

class LedgerTimeline extends StatelessWidget {
  final List<LedgerEntry> entries;

  const LedgerTimeline({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isCredit = entry.amount.amount >= 0;
        final color = isCredit ? AppColors.error : AppColors.success;
        final isLast = index == entries.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // العمود الأيسر (RTL: يمين)
              SizedBox(
                width: 50,
                child: Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              ),
              // البطاقة
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCredit ? Icons.add_circle : Icons.remove_circle,
                              color: color,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _entryLabel(entry.entryType),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${isCredit ? "+" : ""}${entry.amount.amount}',
                              style: TextStyle(
                                color: color,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(entry.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _entryLabel(LedgerEntryType type) {
    switch (type) {
      case LedgerEntryType.debt_creation:
        return 'إنشاء الدين';
      case LedgerEntryType.payment:
        return 'دفعة';
      case LedgerEntryType.reversal:
        return 'عكس دفعة';
      case LedgerEntryType.adjustment:
        return 'تسوية';
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}