import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/observability/debug_logger.dart';
import '../../core/sync/sync_status_provider.dart';
import '../../core/database/app_database.dart';

/// خدمة المزامنة السحابية.
class CloudSyncService {
  // ─────────────────────────────────────────────
  // دوال الرفع الـ idempotent
  // ✅ نستخدم onConflict: 'id' بدل 'client_id'
  // لتجنب خطأ duplicate key عند التحديثات
  // ─────────────────────────────────────────────

  static Future<void> upsertPerson(
      Map<String, dynamic> payload, SupabaseClient client) async {
    await client.from('persons').upsert(payload, onConflict: 'id');
  }

  static Future<void> upsertDebt(
      Map<String, dynamic> payload, SupabaseClient client) async {
    await client.from('debts').upsert(payload, onConflict: 'id');
  }

  static Future<void> upsertPayment(
      Map<String, dynamic> payload, SupabaseClient client) async {
    await client.from('payments').upsert(payload, onConflict: 'id');
  }

  static Future<void> upsertLedgerEntry(
      Map<String, dynamic> payload, SupabaseClient client) async {
    await client.from('ledger_entries').upsert(payload, onConflict: 'id');
  }

  static Future<void> upsertInstallment(
      Map<String, dynamic> payload, SupabaseClient client) async {
    await client.from('installments').upsert(payload, onConflict: 'id');
  }

  // ─────────────────────────────────────────────
  // الخدمة التقليدية
  // ─────────────────────────────────────────────

  final SupabaseClient _client = Supabase.instance.client;
  final AppDatabase _db;
  final SyncStatusNotifier _statusNotifier;

  CloudSyncService(this._db, this._statusNotifier);

  String? get _userId => _client.auth.currentUser?.id;

  // ─────────────────────────────────────────────
  // Sync State (Delta Sync)
  // ─────────────────────────────────────────────

  Future<DateTime?> _getLastSyncTime(String entityType) async {
    final row = await (_db.select(_db.syncStates)
          ..where((t) => t.entityType.equals(entityType)))
        .getSingleOrNull();
    return row?.lastSyncedAt;
  }

  Future<void> _setLastSyncTime(String entityType, DateTime time) async {
    await _db.into(_db.syncStates).insertOnConflictUpdate(
          SyncStatesCompanion.insert(
            entityType: entityType,
            lastSyncedAt: time,
          ),
        );
  }

  // ─────────────────────────────────────────────
  // Persons
  // ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchPersons({DateTime? since}) async {
    try {
      final userId = _userId;
      if (userId == null) return [];
      var query = _client.from('persons').select().eq('user_id', userId);
      if (since != null) {
        query = query.gt('updated_at', since.toIso8601String());
      }
      return await query;
    } catch (e, st) {
      logError('fetchPersons', e, st);
      return [];
    }
  }

  Future<int> syncPersonsFromCloud({DateTime? since}) async {
    try {
      final data = await fetchPersons(since: since);
      if (data.isEmpty) return 0;

      return await _db.transaction(() async {
        var count = 0;
        for (final row in data) {
          await _db.into(_db.persons).insertOnConflictUpdate(
                PersonsCompanion.insert(
                  id: row['id'] as String,
                  name: row['name'] as String,
                  phone: Value(row['phone'] as String?),
                  email: Value(row['email'] as String?),
                  notes: Value(row['notes'] as String?),
                  createdAt: DateTime.parse(row['created_at'] as String)
                      .millisecondsSinceEpoch,
                  updatedAt: DateTime.parse(row['updated_at'] as String)
                      .millisecondsSinceEpoch,
                  version: Value(row['version'] as int? ?? 1),
                  isDeleted: Value(row['is_deleted'] as bool? ?? false),
                  deletedAt: row['deleted_at'] != null
                      ? Value(DateTime.parse(row['deleted_at'] as String)
                          .millisecondsSinceEpoch)
                      : const Value(null),
                ),
              );
          count++;
        }
        return count;
      });
    } catch (e, st) {
      logError('syncPersonsFromCloud', e, st);
      return 0;
    }
  }

  // ─────────────────────────────────────────────
  // Debts
  // ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchDebts({DateTime? since}) async {
    try {
      final userId = _userId;
      if (userId == null) return [];
      var query = _client.from('debts').select().eq('user_id', userId);
      if (since != null) {
        query = query.gt('updated_at', since.toIso8601String());
      }
      return await query;
    } catch (e, st) {
      logError('fetchDebts', e, st);
      return [];
    }
  }

  Future<int> syncDebtsFromCloud({DateTime? since}) async {
    try {
      final data = await fetchDebts(since: since);
      if (data.isEmpty) return 0;

      return await _db.transaction(() async {
        var count = 0;
        for (final row in data) {
          await _db.into(_db.debts).insertOnConflictUpdate(
                DebtsCompanion.insert(
                  id: row['id'] as String,
                  personId: row['person_id'] as String,
                  description: Value(row['description'] as String?),
                  amount: row['amount'] as int,
                  currency: Value(row['currency'] as String? ?? 'IQD'),
                  dueDate: row['due_date'] != null
                      ? Value(DateTime.parse(row['due_date'] as String)
                          .millisecondsSinceEpoch)
                      : const Value(null),
                  status: Value(row['status'] as String? ?? 'active'),
                  createdAt: DateTime.parse(row['created_at'] as String)
                      .millisecondsSinceEpoch,
                  updatedAt: DateTime.parse(row['updated_at'] as String)
                      .millisecondsSinceEpoch,
                  version: Value(row['version'] as int? ?? 1),
                  isDeleted: Value(row['is_deleted'] as bool? ?? false),
                  deletedAt: row['deleted_at'] != null
                      ? Value(DateTime.parse(row['deleted_at'] as String)
                          .millisecondsSinceEpoch)
                      : const Value(null),
                  attachmentPath: Value(row['attachment_path'] as String?),
                ),
              );
          count++;
        }
        return count;
      });
    } catch (e, st) {
      logError('syncDebtsFromCloud', e, st);
      return 0;
    }
  }

  // ─────────────────────────────────────────────
  // Payments
  // ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchPayments({DateTime? since}) async {
    try {
      final userId = _userId;
      if (userId == null) return [];
      var query = _client.from('payments').select().eq('user_id', userId);
      if (since != null) {
        query = query.gt('updated_at', since.toIso8601String());
      }
      return await query;
    } catch (e, st) {
      logError('fetchPayments', e, st);
      return [];
    }
  }

  Future<int> syncPaymentsFromCloud({DateTime? since}) async {
    try {
      final data = await fetchPayments(since: since);
      if (data.isEmpty) return 0;

      return await _db.transaction(() async {
        var count = 0;
        for (final row in data) {
          await _db.into(_db.payments).insertOnConflictUpdate(
                PaymentsCompanion.insert(
                  id: row['id'] as String,
                  debtId: row['debt_id'] as String,
                  amount: row['amount'] as int,
                  currency: Value(row['currency'] as String? ?? 'IQD'),
                  paymentDate: DateTime.parse(row['payment_date'] as String)
                      .millisecondsSinceEpoch,
                  method: Value(row['method'] as String? ?? 'cash'),
                  notes: Value(row['notes'] as String?),
                  createdAt: DateTime.parse(row['created_at'] as String)
                      .millisecondsSinceEpoch,
                  updatedAt: DateTime.parse(row['updated_at'] as String)
                      .millisecondsSinceEpoch,
                  version: Value(row['version'] as int? ?? 1),
                  isDeleted: Value(row['is_deleted'] as bool? ?? false),
                  deletedAt: row['deleted_at'] != null
                      ? Value(DateTime.parse(row['deleted_at'] as String)
                          .millisecondsSinceEpoch)
                      : const Value(null),
                ),
              );
          count++;
        }
        return count;
      });
    } catch (e, st) {
      logError('syncPaymentsFromCloud', e, st);
      return 0;
    }
  }

  // ─────────────────────────────────────────────
  // Ledger Entries
  // ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchLedgerEntries(
      {DateTime? since}) async {
    try {
      final userId = _userId;
      if (userId == null) return [];
      var query =
          _client.from('ledger_entries').select().eq('user_id', userId);
      if (since != null) {
        query = query.gt('created_at', since.toIso8601String());
      }
      return await query;
    } catch (e, st) {
      logError('fetchLedgerEntries', e, st);
      return [];
    }
  }

  Future<int> syncLedgerEntriesFromCloud({DateTime? since}) async {
    try {
      final data = await fetchLedgerEntries(since: since);
      if (data.isEmpty) return 0;

      return await _db.transaction(() async {
        var count = 0;
        for (final row in data) {
          await _db.into(_db.ledgerEntries).insertOnConflictUpdate(
                LedgerEntriesCompanion.insert(
                  id: row['id'] as String,
                  debtId: row['debt_id'] as String,
                  entryType: row['entry_type'] as String,
                  amount: row['amount'] as int,
                  currency: Value(row['currency'] as String? ?? 'IQD'),
                  correlationId: Value(row['correlation_id'] as String?),
                  sourceEntryId: Value(row['source_entry_id'] as String?),
                  paymentId: Value(row['payment_id'] as String?),
                  createdAt: DateTime.parse(row['created_at'] as String)
                      .millisecondsSinceEpoch,
                  serverSequence: Value(row['server_sequence'] as int?),
                ),
              );
          count++;
        }
        return count;
      });
    } catch (e, st) {
      logError('syncLedgerEntriesFromCloud', e, st);
      return 0;
    }
  }

  // ─────────────────────────────────────────────
  // Installments
  // ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchInstallments(
      {DateTime? since}) async {
    try {
      final userId = _userId;
      if (userId == null) return [];
      var query =
          _client.from('installments').select().eq('user_id', userId);
      if (since != null) {
        query = query.gt('updated_at', since.toIso8601String());
      }
      return await query;
    } catch (e, st) {
      logError('fetchInstallments', e, st);
      return [];
    }
  }

  Future<int> syncInstallmentsFromCloud({DateTime? since}) async {
    try {
      final data = await fetchInstallments(since: since);
      if (data.isEmpty) return 0;

      return await _db.transaction(() async {
        var count = 0;
        for (final row in data) {
          await _db.into(_db.installments).insertOnConflictUpdate(
                InstallmentsCompanion.insert(
                  id: row['id'] as String,
                  debtId: row['debt_id'] as String,
                  number: row['number'] as int,
                  amount: row['amount'] as int,
                  currency: Value(row['currency'] as String? ?? 'IQD'),
                  dueDate: DateTime.parse(row['due_date'] as String)
                      .millisecondsSinceEpoch,
                  status: Value(row['status'] as String? ?? 'pending'),
                  paidAt: row['paid_at'] != null
                      ? Value(DateTime.parse(row['paid_at'] as String)
                          .millisecondsSinceEpoch)
                      : const Value(null),
                  notes: Value(row['notes'] as String?),
                  createdAt: DateTime.parse(row['created_at'] as String)
                      .millisecondsSinceEpoch,
                  updatedAt: DateTime.parse(row['updated_at'] as String)
                      .millisecondsSinceEpoch,
                  version: Value(row['version'] as int? ?? 1),
                  isDeleted: Value(row['is_deleted'] as bool? ?? false),
                  deletedAt: row['deleted_at'] != null
                      ? Value(DateTime.parse(row['deleted_at'] as String)
                          .millisecondsSinceEpoch)
                      : const Value(null),
                ),
              );
          count++;
        }
        return count;
      });
    } catch (e, st) {
      logError('syncInstallmentsFromCloud', e, st);
      return 0;
    }
  }

  // ─────────────────────────────────────────────
  // المزامنة اليدوية الشاملة
  // ─────────────────────────────────────────────

  Future<ManualSyncResult> fullManualSync({
    required Future<void> Function() pushOutbox,
  }) async {
    _statusNotifier.startSync();
    try {
      try {
        await pushOutbox();
      } catch (e, st) {
        logError('fullManualSync.push', e, st);
      }

      final online = await _isReachable();

      if (online) {
        final personsSince = await _getLastSyncTime('persons');
        await syncPersonsFromCloud(since: personsSince);
        await _setLastSyncTime('persons', DateTime.now());

        final debtsSince = await _getLastSyncTime('debts');
        await syncDebtsFromCloud(since: debtsSince);
        await _setLastSyncTime('debts', DateTime.now());

        final paymentsSince = await _getLastSyncTime('payments');
        await syncPaymentsFromCloud(since: paymentsSince);
        await _setLastSyncTime('payments', DateTime.now());

        final ledgerSince = await _getLastSyncTime('ledger_entries');
        await syncLedgerEntriesFromCloud(since: ledgerSince);
        await _setLastSyncTime('ledger_entries', DateTime.now());

        final installmentsSince = await _getLastSyncTime('installments');
        await syncInstallmentsFromCloud(since: installmentsSince);
        await _setLastSyncTime('installments', DateTime.now());
      }

      final localCounts = await _localCounts();
      _statusNotifier.finishSync(online ? DateTime.now() : null);
      return ManualSyncResult(localCounts: localCounts, wasOnline: online);
    } catch (e) {
      _statusNotifier.finishSync(null);
      rethrow;
    }
  }

  Future<bool> _isReachable() async {
    try {
      await _client.from('persons').select('id').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, int>> _localCounts() async {
    final persons = await (_db.select(_db.persons)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    final debts = await (_db.select(_db.debts)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    final payments = await (_db.select(_db.payments)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    final ledger = await _db.select(_db.ledgerEntries).get();
    final installments = await (_db.select(_db.installments)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    return {
      'persons': persons.length,
      'debts': debts.length,
      'payments': payments.length,
      'ledger': ledger.length,
      'installments': installments.length,
    };
  }
}

class ManualSyncResult {
  final Map<String, int> localCounts;
  final bool wasOnline;

  ManualSyncResult({required this.localCounts, required this.wasOnline});
}