import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import 'tables/outbox_table.dart';

/// مستودع Outbox: يسجل كل عملية كتابة محلية قبل رفعها للسحابة.
///
/// يدعم callback `onEnqueue` لتبليغ SyncService بأي إضافة جديدة
/// (يُستخدم لتنفيذ Debounce Scheduling).
///
/// ✅ مهم: نستخدم `Zone.root.scheduleMicrotask` لتفادي مشكلة Zone Leak
/// عندما يُستدعى enqueue داخل `db.transaction(...)`. بدون هذا الحل،
/// Timer الـ Debounce سيحمل Zone المعاملة المغلقة، ويؤدي إلى:
/// "Transaction used after it was closed"
class OutboxRepository {
  OutboxRepository(this.db, {this.onEnqueue});

  final AppDatabase db;

  /// callback يُستدعى بعد كل إضافة ناجحة إلى Outbox.
  /// SyncService يستخدمه لجدولة مزامنة سريعة (Debounce).
  final void Function()? onEnqueue;

  final _uuid = const Uuid();

  /// يضيف عنصر outbox جديد. يجب استدعاؤها داخل db.transaction(...)
  Future<OutboxItem> enqueue({
    required String entityType,
    required String entityId,
    required OutboxOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    final item = OutboxTableCompanion.insert(
      clientId: _uuid.v4(),
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payloadJson: jsonEncode(payload),
      status: Value(OutboxStatus.pending),
      retryCount: Value(0),
      nextRetryAt: Value(DateTime.now()),
      createdAt: Value(DateTime.now()),
    );

    final id = await db.into(db.outboxTable).insert(item);
    final inserted =
        await (db.select(db.outboxTable)..where((t) => t.id.equals(id)))
            .getSingle();

    // ✅ شغّل callback في الـ root zone لتفادي Zone Leak.
    // إذا استدعينا onEnqueue مباشرة، فإن Timer الـ Debounce سيرث
    // الـ zone الخاص بالمعاملة (transaction zone)، وعند انتهاء
    // المعاملة، يصبح هذا الـ zone مغلقاً → أي استعلام Drift لاحق
    // من الـ Timer يفشل بـ "Transaction used after it was closed".
    if (onEnqueue != null) {
      Zone.root.scheduleMicrotask(() => onEnqueue!());
    }

    return inserted;
  }

  /// جلب العناصر الجاهزة للرفع الآن.
  Future<List<OutboxItem>> getDueItems({int maxItems = 200}) async {
    final now = DateTime.now();
    final query = db.select(db.outboxTable)
      ..where((t) =>
          (t.status.equalsValue(OutboxStatus.pending) |
              t.status.equalsValue(OutboxStatus.failed)) &
          t.nextRetryAt.isSmallerOrEqualValue(now))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(maxItems);
    return query.get();
  }

  Future<void> markInFlight(int id) async {
    await (db.update(db.outboxTable)..where((t) => t.id.equals(id)))
        .write(const OutboxTableCompanion(
      status: Value(OutboxStatus.inFlight),
    ));
  }

  Future<void> markSynced(int id) async {
    await (db.update(db.outboxTable)..where((t) => t.id.equals(id)))
        .write(OutboxTableCompanion(
      status: const Value(OutboxStatus.synced),
      syncedAt: Value(DateTime.now()),
    ));
  }

  Future<void> markFailed(int id, {String? errorMessage}) async {
    final item =
        await (db.select(db.outboxTable)..where((t) => t.id.equals(id)))
            .getSingle();
    final newRetryCount = item.retryCount + 1;
    final delaySeconds = 1 << newRetryCount.clamp(0, 8);
    final nextRetryAt = DateTime.now().add(Duration(seconds: delaySeconds));

    await (db.update(db.outboxTable)..where((t) => t.id.equals(id)))
        .write(OutboxTableCompanion(
      status: Value(OutboxStatus.failed),
      retryCount: Value(newRetryCount),
      nextRetryAt: Value(nextRetryAt),
      lastError: Value(errorMessage ?? 'Unknown error'),
    ));
  }

  Future<void> resetForRetry(int id) async {
    await (db.update(db.outboxTable)..where((t) => t.id.equals(id)))
        .write(OutboxTableCompanion(
      status: Value(OutboxStatus.pending),
      retryCount: Value(0),
      nextRetryAt: Value(DateTime.now()),
      lastError: Value(null),
    ));
  }

  Future<void> clearSynced() async {
    await (db.delete(db.outboxTable)
          ..where((t) => t.status.equalsValue(OutboxStatus.synced)))
        .go();
  }
}