import 'package:domain/domain.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class TopDebtorsChart extends StatelessWidget {
  final List<PersonDebtSummary> summaries;

  const TopDebtorsChart({super.key, required this.summaries});

  @override
  Widget build(BuildContext context) {
    final top5 = [...summaries]
      ..sort((a, b) =>
          b.totalOutstanding.amount.compareTo(a.totalOutstanding.amount));
    final top = top5.take(5).toList();

    if (top.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('لا توجد بيانات')),
      );
    }

    final maxY = top.first.totalOutstanding.amount.toDouble();

    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.only(top: 24, right: 8, left: 8),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${top[group.x].personName}\n${_formatAmount(rod.toY.toInt())} IQD',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= top.length) {
                      return const SizedBox.shrink();
                    }
                    final name = top[idx].personName;
                    final shortName = name.length > 8
                        ? '${name.substring(0, 8)}…'
                        : name;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        shortName,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(
                      _formatShort(value.toInt()),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withValues(alpha: 0.15),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(top.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: top[i].totalOutstanding.amount.toDouble(),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                    width: 22,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
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
    return buffer.toString();
  }

  String _formatShort(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return '$value';
  }
}