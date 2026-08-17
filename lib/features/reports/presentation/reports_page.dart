import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.trending_up, color: AppColors.primary),
            title: const Text('Payment Trends'),
            subtitle: const Text('View payment trends over time'),
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart, color: AppColors.primary),
            title: const Text('Debt Distribution'),
            subtitle: const Text('See debts by person or category'),
          ),
          ListTile(
            leading: const Icon(Icons.warning, color: AppColors.error),
            title: const Text('Overdue Debts'),
            subtitle: const Text('List of overdue debts'),
          ),
        ],
      ),
    );
  }
}