import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import '../database/tables/outbox_table.dart';
import '../observability/logging_service.dart';

/// خدمة المزامنة — Outbox Pattern مع Debounce + Batch + Exponential Backoff.
///
/// - تعمل في الخلفية بشكل دوري (Timer.periodic).
/// - تستمع لتغيّر الاتصال (Connectivity) وتزامن فوراً عند العودة.
/// - تستخدم [LoggingService] لتسجيل المعلومات والأخطاء.
class SyncService {
  SyncService({
    required this.db,
    required this.supabase,
    LoggingService? logger,
    this.maxRetries = 8,
    this.baseBackoff = const Duration(seconds: 5),
    this.maxBackoff = const Duration(minutes: 30),
  }) : _logger = logger ?? LoggingService();

  final AppDatabase db;
  final SupabaseClient supabase;
  final LoggingService _logger;
  final int maxRetries;
  final Duration baseBackoff;
  final Duration maxBackoff;

  Timer? _periodicTimer;
  Timer? _debounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;
  bool _isOnline = true;
  bool _isStarted = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  Future<void> start({Duration interval = const Duration(seconds: 30)}) async {
    if (_isStarted) return;
    _isStarted = true;

    _periodicTimer?.cancel();
    _connectivitySub?.cancel();

    try {
      final initialResults = await Connectivity().checkConnectivity();
      _isOnline = initialResults.any((r) => r != ConnectivityResult.none);
      _logger.info('Initial connectivity: online=$_isOnline');
    } catch (_) {
      _isOnline = true;
    }

    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (results) async {
        final wasOnline = _isOnline;
        _isOnline = results.any((r) => r != ConnectivityResult.none);

        _logger.info('Connectivity changed: online=$_isOnline');

        if (_isOnline && !wasOnline) {
          _logger.info('Network restored, syncing now');
          await _resetFailedItemsForRetry();
          syncNow();
        }
      },
    );

    _periodicTimer = Timer.periodic(interval, (_) {
      if (_isOnline && _lifecycle == AppLifecycleState.resumed) {
        syncNow();
      }
    });

    if (_isOnline) {
      syncNow();
    }
  }

  Future<void> _resetFailedItemsForRetry() async {
    try {
      final now = DateTime.now();
      await (db.update(db.outboxTable)
            ..where((t) =>
                (t.status.equalsValue(OutboxStatus.pending) |
                    t.status.equalsValue(OutboxStatus.failed)) &
                t.nextRetryAt.isBiggerThanValue(now)))
          .write(OutboxTableCompanion(
        nextRetryAt: Value(now),
      ));
    } catch (_) {}
  }

  void scheduleSyncNow() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (_isOnline) syncNow();
    });
  }

  void updateLifecycle(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed && _isOnline) {
      syncNow();
    }
  }

  void stop() {
    _isStarted = false;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    if (!_isOnline) return;

    _isSyncing = true;
    final stopwatch = Stopwatch()..start();

    try {
      await _resetStaleInFlight();
      final pendingItems = await _fetchDueItems(maxItems: 200);

      if (pendingItems.isEmpty) return;

      _logger.info('Processing ${pendingItems.length} outbox items');

      final grouped = <String, List<OutboxItem>>{};
      for (final item in pendingItems) {
        grouped.putIfAbsent(item.entityType, () => []).add(item);
      }

      for (final entry in grouped.entries) {
        await _processBatch(entry.key, entry.value);
      }

      _logger.info('Sync complete in ${stopwatch.elapsedMilliseconds}ms');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _resetStaleInFlight() async {
    await (db.update(db.outboxTable)
          ..where((t) => t.status.equalsValue(OutboxStatus.inFlight)))
        .write(const OutboxTableCompanion(
      status: Value(OutboxStatus.pending),
    ));
  }

  Future<List<OutboxItem>> _fetchDueItems({int maxItems = 100}) {
    final now = DateTime.now();
    return (db.select(db.outboxTable)
          ..where((t) =>
              t.status.equalsValue(OutboxStatus.pending) &
              t.nextRetryAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(maxItems))
        .get();
  }

  Future<void> _processBatch(String entityType, List<OutboxItem> items) async {
    final upserts = <OutboxItem>[];
    final deletes = <OutboxItem>[];

    for (final item in items) {
      if (item.operation == OutboxOperation.delete) {
        deletes.add(item);
      } else {
        upserts.add(item);
      }
    }

    if (upserts.isNotEmpty) {
      await _batchUpsert(entityType, upserts);
    }
    if (deletes.isNotEmpty) {
      await _batchDelete(entityType, deletes);
    }
  }

  /// Batch Upsert مع Deduplication حسب `id` (FIFO).
  ///
  /// يحل مشكلة `21000: ON CONFLICT DO UPDATE command cannot affect row a second time`.
  Future<void> _batchUpsert(
      String entityType, List<OutboxItem> items) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      final table = _tableNameFor(entityType);

      final Map<String, OutboxItem> latestById = {};
      for (final item in items) {
        try {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          final id = payload['id'] as String?;
          if (id != null && id.isNotEmpty) {
            latestById[id] = item;
          }
        } catch (_) {}
      }

      if (latestById.isEmpty) {
        await db.transaction(() async {
          for (final item in items) {
            await _markSynced(item.id);
          }
        });
        return;
      }

      final payloads = latestById.values.map((item) {
        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        payload['client_id'] = item.clientId;
        payload['user_id'] = currentUserId;
        return payload;
      }).toList();

      await supabase.from(table).upsert(payloads, onConflict: 'id');

      await db.transaction(() async {
        for (final item in items) {
          await _markSynced(item.id);
        }
      });

      _logger.info(
          'Batch $entityType synced: ${items.length} items (${payloads.length} unique)');
    } on PostgrestException catch (e) {
      final isClientError = e.code != null && e.code!.startsWith('23');
      _logger.error('Batch $entityType failed [${e.code}]', error: e);
      for (final item in items) {
        if (isClientError) {
          await _markFailedPermanently(item);
        } else {
          await _scheduleRetry(item);
        }
      }
    } catch (e) {
      final isNetworkError = _isNetworkError(e);
      _logger.error('Batch $entityType failed', error: e);

      if (isNetworkError) {
        _isOnline = false;
        _logger.info('Marked as offline due to network error');
      }

      for (final item in items) {
        await _scheduleRetry(item);
      }
    }
  }

  bool _isNetworkError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('connection closed') ||
        msg.contains('timeout');
  }

  Future<void> _batchDelete(
      String entityType, List<OutboxItem> items) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      final table = _tableNameFor(entityType);

      final ids = items.map((i) => i.entityId).toSet().toList();

      await supabase
          .from(table)
          .delete()
          .inFilter('id', ids)
          .eq('user_id', currentUserId ?? '');

      await db.transaction(() async {
        for (final item in items) {
          await _markSynced(item.id);
        }
      });

      _logger.info('Batch delete $entityType: ${items.length} items');
    } catch (e) {
      _logger.error('Batch delete $entityType failed', error: e);
      if (_isNetworkError(e)) {
        _isOnline = false;
      }
      for (final item in items) {
        await _scheduleRetry(item);
      }
    }
  }

  String _tableNameFor(String entityType) {
    switch (entityType) {
      case 'person':
        return 'persons';
      case 'debt':
        return 'debts';
      case 'payment':
        return 'payments';
      case 'ledger_entry':
        return 'ledger_entries';
      case 'installment':
        return 'installments';
      default:
        throw ArgumentError('نوع كيان غير معروف: $entityType');
    }
  }

  Future<void> _markSynced(int id) => (db.update(db.outboxTable)
        ..where((t) => t.id.equals(id)))
      .write(OutboxTableCompanion(
        status: const Value(OutboxStatus.synced),
        syncedAt: Value(DateTime.now()),
      ));

  Future<void> _scheduleRetry(OutboxItem item) async {
    final newRetryCount = item.retryCount + 1;
    if (newRetryCount > maxRetries) {
      await _markFailedPermanently(item);
      return;
    }

    final backoffSeconds = !_isOnline
        ? 60
        : min(
            baseBackoff.inSeconds * pow(2, newRetryCount).toInt(),
            maxBackoff.inSeconds,
          );

    final jitter = Random().nextInt(5);
    final nextRetryAt =
        DateTime.now().add(Duration(seconds: backoffSeconds + jitter));

    await (db.update(db.outboxTable)..where((t) => t.id.equals(item.id)))
        .write(OutboxTableCompanion(
      status: const Value(OutboxStatus.pending),
      retryCount: Value(newRetryCount),
      nextRetryAt: Value(nextRetryAt),
    ));
  }

  Future<void> _markFailedPermanently(OutboxItem item) =>
      (db.update(db.outboxTable)..where((t) => t.id.equals(item.id))).write(
        const OutboxTableCompanion(status: Value(OutboxStatus.failed)),
      );
}