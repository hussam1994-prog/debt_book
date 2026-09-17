import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_provider.dart';
import '../sync/sync_status_provider.dart';

class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final connectivity = ref.watch(connectivityProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (!connectivity.isOnline) {
      return Material(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'غير متصل',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    String text;
    IconData icon;
    Color color;

    if (syncStatus.isSyncing) {
      text = 'جار المزامنة...';
      icon = Icons.sync;
      color = colorScheme.primary;
    } else if (syncStatus.lastSyncTime != null) {
      final diff = DateTime.now().difference(syncStatus.lastSyncTime!);
      String timeAgo;
      if (diff.inSeconds < 60) {
        timeAgo = 'قبل ${diff.inSeconds} ثانية';
      } else if (diff.inMinutes < 60) {
        timeAgo = 'قبل ${diff.inMinutes} دقيقة';
      } else {
        timeAgo = 'قبل ${diff.inHours} ساعة';
      }

      // ✅ إظهار الأعداد إذا كانت متوفرة
      final counts = syncStatus.counts;
      if (counts != null && counts.isNotEmpty) {
        text = 'آخر مزامنة: $timeAgo • '
            '${counts['persons'] ?? 0} أشخاص، ${counts['debts'] ?? 0} ديون';
      } else {
        text = 'آخر مزامنة: $timeAgo';
      }
      icon = Icons.cloud_done;
      color = Colors.green;
    } else {
      text = 'جاهز للمزامنة';
      icon = Icons.cloud_outlined;
      color = colorScheme.onSurfaceVariant;
    }

    return Material(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}