import 'package:domain/domain.dart';
import 'package:go_router/go_router.dart';

import '../features/people/presentation/people_page.dart';
import '../features/people/presentation/person_detail_page.dart';
import '../features/debts/presentation/add_debt_page.dart';
import '../features/debts/presentation/debt_detail_page.dart';
import '../features/payments/presentation/add_payment_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/settings/presentation/sync_dashboard_page.dart';
import '../features/settings/presentation/notification_settings_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/dashboard/presentation/monthly_stats_page.dart';
import '../features/backup/presentation/backup_page.dart';
import '../features/insights/presentation/insights_page.dart';
import '../features/reports/presentation/reports_page.dart';
import '../features/reports/presentation/multi_person_report_page.dart';
import '../features/debts/presentation/all_debts_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart'; // ✅ جديد

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/all-debts',
      builder: (context, state) => const AllDebtsPage(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsPage(),
    ),
    // ✅ تقرير متعدد الأشخاص
    GoRoute(
      path: '/multi-person-report',
      builder: (context, state) => const MultiPersonReportPage(),
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
    // ✅ الإحصائيات الشهرية
    GoRoute(
      path: '/monthly-stats',
      builder: (context, state) => const MonthlyStatsPage(),
    ),
    // ✅ إعادة عرض الشرح
    GoRoute(
      path: '/onboarding-replay',
      builder: (context, state) => OnboardingPage(
        onComplete: () => context.go('/settings'),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/sync-dashboard',
      builder: (context, state) => const SyncDashboardPage(),
    ),
    GoRoute(
      path: '/notification-settings',
      builder: (context, state) => const NotificationSettingsPage(),
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