import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/sync_status_provider.dart';

class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    String text;
    IconData icon;
    Color color;

    if (status.isSyncing) {
      text = 'جار المزامنة...';
      icon = Icons.sync;
      color = colorScheme.primary;
    } else if (status.lastSyncTime != null) {
      final diff = DateTime.now().difference(status.lastSyncTime!);
      if (diff.inSeconds < 60) {
        text = 'آخر مزامنة: قبل ${diff.inSeconds} ثانية';
      } else if (diff.inMinutes < 60) {
        text = 'آخر مزامنة: قبل ${diff.inMinutes} دقيقة';
      } else {
        text = 'آخر مزامنة: قبل ${diff.inHours} ساعة';
      }
      icon = Icons.cloud_done;
      color = Colors.green;
    } else {
      text = status.isOnline ? 'جاهز للمزامنة' : 'غير متصل';
      icon = status.isOnline ? Icons.cloud_outlined : Icons.cloud_off;
      color = status.isOnline ? colorScheme.onSurfaceVariant : Colors.grey;
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