import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/tables/outbox_table.dart';
import '../providers.dart';

class OutboxStats {
  final int pending;
  final int failed;
  final int synced;
  final DateTime? lastSyncedAt;

  const OutboxStats({
    this.pending = 0,
    this.failed = 0,
    this.synced = 0,
    this.lastSyncedAt,
  });
}

final outboxStatsProvider = FutureProvider<OutboxStats>((ref) async {
  final db = ref.watch(appDatabaseProvider);

  final pending = await (db.select(db.outboxTable)
        ..where((t) => t.status.equalsValue(OutboxStatus.pending)))
      .get();

  final failed = await (db.select(db.outboxTable)
        ..where((t) => t.status.equalsValue(OutboxStatus.failed)))
      .get();

  final synced = await (db.select(db.outboxTable)
        ..where((t) => t.status.equalsValue(OutboxStatus.synced))
        ..orderBy([(t) => OrderingTerm.desc(t.syncedAt)])
        ..limit(1))
      .get();

  return OutboxStats(
    pending: pending.length,
    failed: failed.length,
    synced: synced.length,
    lastSyncedAt: synced.isEmpty ? null : synced.first.syncedAt,
  );
});