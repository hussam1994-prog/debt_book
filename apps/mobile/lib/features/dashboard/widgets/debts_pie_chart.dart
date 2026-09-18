import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class DebtsPieChart extends StatelessWidget {
  final int activeCount;
  final int overdueCount;
  final int completedCount;

  const DebtsPieChart({
    super.key,
    required this.activeCount,
    required this.overdueCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = activeCount + overdueCount + completedCount;
    if (total == 0) {
      return Center(child: Text(AppLocalizations.of(context)!.noData));
    }

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 55,
          sections: [
            if (activeCount > 0)
              PieChartSectionData(
                value: activeCount.toDouble(),
                color: AppColors.success,
                title: '$activeCount',
                radius: 55,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            if (overdueCount > 0)
              PieChartSectionData(
                value: overdueCount.toDouble(),
                color: AppColors.error,
                title: '$overdueCount',
                radius: 55,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            if (completedCount > 0)
              PieChartSectionData(
                value: completedCount.toDouble(),
                color: AppColors.info,
                title: '$completedCount',
                radius: 55,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}