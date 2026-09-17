import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design.dart';

class PersonCard extends StatelessWidget {
  final PersonDebtSummary summary;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  const PersonCard({
    super.key,
    required this.summary,
    required this.onTap,
    this.onCall,
    this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final hasOverdue = summary.lastDueDate != null &&
        summary.lastDueDate!.isBefore(DateTime.now()) &&
        summary.totalOutstanding.amount > 0;

    final isSettled = summary.totalOutstanding.amount == 0;
    final statusColor = isSettled
        ? AppColors.info
        : (hasOverdue ? AppColors.error : AppColors.success);
    final statusLabel = isSettled
        ? 'مكتمل'
        : (hasOverdue ? 'متأخر' : 'نشط');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // الأفاتار
              _buildAvatar(),

              const SizedBox(width: AppSpacing.md),

              // المعلومات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الاسم + الشارة
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            summary.personName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _statusChip(statusLabel, statusColor),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // المبلغ
                    Text(
                      '${_formatAmount(summary.totalOutstanding.amount)} IQD',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSettled
                            ? AppColors.info
                            : (hasOverdue ? AppColors.error : AppColors.primary),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // التفاصيل السفلية
                    Row(
                      children: [
                        _metaChip(Icons.receipt_long, '${summary.debtCount}'),
                        if (summary.lastDueDate != null) ...[
                          const SizedBox(width: 12),
                          _metaChip(
                            Icons.event,
                            '${summary.lastDueDate!.day}/${summary.lastDueDate!.month}',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // سهم
              Icon(Icons.chevron_left, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final color = AppColors.forName(summary.personName);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        summary.personName.trim().substring(0, 1),
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _formatAmount(int amount) {
    final str = amount.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      buffer.write(str[i]);
      if ((str.length - i - 1) % 3 == 0 && i != str.length - 1) {
        buffer.write(',');
      }
    }
    return amount < 0 ? '-$buffer' : buffer.toString();
  }
}