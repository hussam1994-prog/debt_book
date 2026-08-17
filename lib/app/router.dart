import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/people/presentation/people_page.dart';
import '../features/people/presentation/person_detail_page.dart';
import '../features/debts/presentation/add_debt_page.dart';
import '../features/debts/presentation/debt_detail_page.dart';
import '../features/payments/presentation/add_payment_page.dart'; // ✅ أضف هذا السطر
import '../features/settings/presentation/settings_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/backup/presentation/backup_page.dart';
import '../features/insights/presentation/insights_page.dart';
import '../features/reports/presentation/reports_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsPage(),
    ),
    GoRoute(
      path: '/insights',
      builder: (context, state) => const InsightsPage(),
    ),
    GoRoute(
      path: '/backup',
      builder: (context, state) => const BackupPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const PeoplePage(),
      routes: [
        GoRoute(
          path: 'person/:personId',
          builder: (context, state) {
            final personIdStr = state.pathParameters['personId']!;
            return PersonDetailPage(personId: PersonId(personIdStr));
          },
          routes: [
            GoRoute(
              path: 'add-debt',
              builder: (context, state) {
                final personIdStr = state.pathParameters['personId']!;
                return AddDebtPage(personId: PersonId(personIdStr));
              },
            ),
          ],
        ),
        GoRoute(
          path: 'debt/:debtId',
          builder: (context, state) {
            final debtIdStr = state.pathParameters['debtId']!;
            return DebtDetailPage(debtId: DebtId(debtIdStr));
          },
          routes: [
            GoRoute(
              path: 'add-payment',
              builder: (context, state) {
                final debtIdStr = state.pathParameters['debtId']!;
                return AddPaymentPage(debtId: DebtId(debtIdStr));
              },
            ),
          ],
        ),
      ],
    ),
  ],
);