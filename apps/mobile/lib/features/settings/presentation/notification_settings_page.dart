import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/theme/app_theme.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationPrefsProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefs = ref.watch(notificationPrefsProvider);
    final notifier = ref.read(notificationPrefsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationSettings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ─── المفتاح الرئيسي ───
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: Text(l10n.enableNotifications),
            subtitle: Text(l10n.enableNotificationsSubtitle),
            value: prefs.enabled,
            onChanged: (value) => notifier.setEnabled(value),
          ),
          const Divider(),

          // ─── ساعات الهدوء ───
          SwitchListTile(
            secondary: const Icon(Icons.bedtime),
            title: Text(l10n.quietHours),
            subtitle: Text(l10n.quietHoursSubtitle),
            value: prefs.quietHoursEnabled,
            onChanged: prefs.enabled
                ? (value) => notifier.setQuietHoursEnabled(value)
                : null,
          ),
          if (prefs.quietHoursEnabled) ...[
            ListTile(
              leading: const Icon(Icons.nightlight),
              title: Text(l10n.quietHoursFrom),
              trailing: Text(
                _formatMinutes(prefs.quietStart),
                style: const TextStyle(fontSize: 16),
              ),
              enabled: prefs.enabled,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: prefs.quietStart ~/ 60,
                    minute: prefs.quietStart % 60,
                  ),
                );
                if (picked != null) {
                  await notifier.setQuietHours(
                    start: picked.hour * 60 + picked.minute,
                    end: prefs.quietEnd,
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny),
              title: Text(l10n.quietHoursTo),
              trailing: Text(
                _formatMinutes(prefs.quietEnd),
                style: const TextStyle(fontSize: 16),
              ),
              enabled: prefs.enabled,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: prefs.quietEnd ~/ 60,
                    minute: prefs.quietEnd % 60,
                  ),
                );
                if (picked != null) {
                  await notifier.setQuietHours(
                    start: prefs.quietStart,
                    end: picked.hour * 60 + picked.minute,
                  );
                }
              },
            ),
          ],
          const Divider(),

          // ─── تذكيرات الاستحقاق ───
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Text(
              l10n.dueReminders,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_today),
            title: Text(l10n.remind7Days),
            value: prefs.remind7Days,
            onChanged: prefs.enabled
                ? (value) => notifier.setRemind7Days(value)
                : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_today),
            title: Text(l10n.remind3Days),
            value: prefs.remind3Days,
            onChanged: prefs.enabled
                ? (value) => notifier.setRemind3Days(value)
                : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_today),
            title: Text(l10n.remind1Day),
            value: prefs.remind1Day,
            onChanged: prefs.enabled
                ? (value) => notifier.setRemind1Day(value)
                : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.warning_amber),
            title: Text(l10n.remindOverdueDaily),
            subtitle: Text(l10n.remindOverdueSubtitle),
            value: prefs.remindOverdue,
            onChanged: prefs.enabled
                ? (value) => notifier.setRemindOverdue(value)
                : null,
          ),
          const Divider(),

          // ─── أنواع أخرى ───
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Text(
              l10n.otherNotifications,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.summarize),
            title: Text(l10n.weeklySummary),
            subtitle: Text(l10n.weeklySummarySubtitle),
            value: prefs.weeklySummary,
            onChanged: prefs.enabled
                ? (value) => notifier.setWeeklySummary(value)
                : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.payments),
            title: Text(l10n.paymentNotifications),
            subtitle: Text(l10n.paymentNotificationsSubtitle),
            value: prefs.paymentAlerts,
            onChanged: prefs.enabled
                ? (value) => notifier.setPaymentAlerts(value)
                : null,
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── ملاحظة ───
          Card(
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.notificationInfo,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}