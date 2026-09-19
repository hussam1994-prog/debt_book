import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_provider.dart';
import '../localization/l10n_extension.dart';
import '../sync/sync_status_provider.dart';

class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
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
              const Icon(Icons.cloud_off, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                l10n.offlineLabel,
                style: const TextStyle(color: Colors.red, fontSize: 12),
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
      text = l10n.syncingNow;
      icon = Icons.sync;
      color = colorScheme.primary;
    } else if (syncStatus.lastSyncTime != null) {
      final diff = DateTime.now().difference(syncStatus.lastSyncTime!);
      String timeAgo;
      if (diff.inSeconds < 60) {
        timeAgo = l10n.secondsAgo(diff.inSeconds);
      } else if (diff.inMinutes < 60) {
        timeAgo = l10n.minutesAgo(diff.inMinutes);
      } else {
        timeAgo = l10n.hoursAgo(diff.inHours);
      }

      final counts = syncStatus.counts;
      if (counts != null && counts.isNotEmpty) {
        text = l10n.lastSyncWithCounts(
          timeAgo,
          counts['persons'] ?? 0,
          counts['debts'] ?? 0,
        );
      } else {
        text = l10n.lastSyncAt(timeAgo);
      }
      icon = Icons.cloud_done;
      color = Colors.green;
    } else {
      text = l10n.syncReady;
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
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}