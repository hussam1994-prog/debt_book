import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/observability/debug_logger.dart';
import '../../core/sync/sync_status_provider.dart';
import '../../core/database/app_database.dart';
import '../../data/repositories/person_repository_impl.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../../data/mappers/person_mapper.dart';

class CloudSyncService {
  final SupabaseClient _client = Supabase.instance.client;
  final AppDatabase _db;
  final SyncStatusNotifier _statusNotifier;

  CloudSyncService(this._db, this._statusNotifier);

  String? get _userId => _client.auth.currentUser?.id;

  // ========== Persons ==========
  Future<void> pushPersonsToCloud(List<Person> persons) async {
    final userId = _userId;
    logDebug('🔑 User ID: $userId');
    if (userId == null) {
      logError('pushPersonsToCloud', 'User ID is null', null);
      return;
    }

    for (final person in persons) {
      await _client.from('persons').upsert({
        'id': person.id.value,
        'user_id': userId,
        'name': person.name,
        'phone': person.phone,
        'email': person.email,
        'created_at': person.createdAt.toIso8601String(),
        'updated_at': person.updatedAt.toIso8601String(),
        'is_deleted': person.isDeleted,
      });
    }
  }

  Future<void> softDeletePersonOnCloud(PersonId personId) async {
    final userId = _userId;
    if (userId == null) return;

    await _client.from('persons').update({
      'is_deleted': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', personId.value).eq('user_id', userId);
  }

  Future<List<Map<String, dynamic>>> fetchPersons() async {
    try {
      final userId = _userId;
      if (userId == null) return [];
      final data = await _client
          .from('persons')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false);
      return data;
    } catch (e, st) {
      logError('fetchPersons', e, st);
      return [];
    }
  }

  Future<int> syncPersonsFromCloud() async {
    try {
      final data = await fetchPersons();
      var count = 0;
      for (final row in data) {
        final personId = row['id'] as String;
        final existing = await (_db.select(_db.persons)
              ..where((t) => t.id.equals(personId)))
            .getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.persons).insert(
                PersonsCompanion.insert(
                  id: row['id'] as String,
                  name: row['name'] as String,
                  phone: Value(row['phone'] as String?),
                  email: Value(row['email'] as String?),
                  createdAt: DateTime.parse(row['created_at'] as String)
                      .millisecondsSinceEpoch,
                  updatedAt: DateTime.parse(row['updated_at'] as String)
                      .millisecondsSinceEpoch,
                  version: Value(row['version'] as int? ?? 1),
                  isDeleted: Value(row['is_deleted'] as bool? ?? false),
                ),
                mode: InsertMode.insertOrIgnore, // ✅ الصحيح
              );
          count++;
        }
      }
      return count;
    } catch (e, st) {
      logError('syncPersonsFromCloud', e, st);
      return 0;
    }
  }

  // ========== Debts ==========
  Future<void> pushDebtsToCloud(List<Debt> debts) async {
    final userId = _userId;
    if (userId == null) return;
    for (final debt in debts) {
      await _client.from('debts').upsert({
        'id': debt.id.value,
        'user_id': userId,
        'person_id': debt.personId.value,
        'description': debt.description,
        'amount': debt.amount.amount,
        'currency': debt.amount.currency,
        'due_date': debt.dueDate?.toIso8601String(),
        'status': debt.status.name,
        'created_at': debt.createdAt.toIso8601String(),
        'updated_at': debt.updatedAt.toIso8601String(),
        'version': debt.version,
        'is_deleted': debt.isDeleted,
        'attachment_path': debt.attachmentPath,
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchDebts() async {
    try {
      final userId = _userId;
      if (userId == null) return [];
      final data = await _client
          .from('debts')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false);
      return data;
    } catch (e, st) {
      logError('fetchDebts', e, st);
      return [];
    }
  }

  Future<int> syncDebtsFromCloud() async {
    try {
      final data = await fetchDebts();
      var count = 0;
      for (final row in data) {
        final debtId = row['id'] as String;
        final existing = await (_db.select(_db.debts)
              ..where((t) => t.id.equals(debtId)))
            .getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.debts).insert(
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
                  attachmentPath: Value(row['attachment_path'] as String?),
                ),
                mode: InsertMode.insertOrIgnore, // ✅
              );
          count++;
        }
      }
      return count;
    } catch (e, st) {
      logError('syncDebtsFromCloud', e, st);
      return 0;
    }
  }

  // ========== Payments ==========
  Future<void> pushPaymentsToCloud(List<Payment> payments) async {
    final userId = _userId;
    if (userId == null) return;
    for (final payment in payments) {
      await _client.from('payments').upsert({
        'id': payment.id.value,
        'user_id': userId,
        'debt_id': payment.debtId.value,
        'amount': payment.amount.amount,
        'currency': payment.amount.currency,
        'payment_date': payment.paymentDate.toIso8601String(),
        'method': payment.method.name,
        'notes': payment.notes,
        'created_at': payment.createdAt.toIso8601String(),
        'updated_at': payment.updatedAt.toIso8601String(),
        'version': payment.version,
        'is_deleted': payment.isDeleted,
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchPayments() async {
    try {
      final userId = _userId;
      if (userId == null) return [];
      final data = await _client
          .from('payments')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false);
      return data;
    } catch (e, st) {
      logError('fetchPayments', e, st);
      return [];
    }
  }

  Future<int> syncPaymentsFromCloud() async {
    try {
      final data = await fetchPayments();
      var count = 0;
      for (final row in data) {
        final paymentId = row['id'] as String;
        final existing = await (_db.select(_db.payments)
              ..where((t) => t.id.equals(paymentId)))
            .getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.payments).insert(
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
                ),
                mode: InsertMode.insertOrIgnore, // ✅
              );
          count++;
        }
      }
      return count;
    } catch (e, st) {
      logError('syncPaymentsFromCloud', e, st);
      return 0;
    }
  }

  // ========== Ledger ==========
  Future<void> pushLedgerEntriesToCloud(List<LedgerEntry> entries) async {
    final userId = _userId;
    if (userId == null) return;
    for (final entry in entries) {
      await _client.from('ledger_entries').upsert({
        'id': entry.id.value,
        'user_id': userId,
        'debt_id': entry.debtId.value,
        'entry_type': entry.entryType.name,
        'amount': entry.amount.amount,
        'currency': entry.amount.currency,
        'correlation_id': entry.correlationId?.value,
        'source_entry_id': entry.sourceEntryId?.value,
        'payment_id': entry.paymentId?.value,
        'created_at': entry.createdAt.toIso8601String(),
        'server_sequence': entry.serverSequence,
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchLedgerEntries() async {
    try {
      final userId = _userId;
      if (userId == null) return [];
      final data = await _client
          .from('ledger_entries')
          .select()
          .eq('user_id', userId);
      return data;
    } catch (e, st) {
      logError('fetchLedgerEntries', e, st);
      return [];
    }
  }

  Future<int> syncLedgerEntriesFromCloud() async {
    try {
      final data = await fetchLedgerEntries();
      var count = 0;
      for (final row in data) {
        final entryId = row['id'] as String;
        final existing = await (_db.select(_db.ledgerEntries)
              ..where((t) => t.id.equals(entryId)))
            .getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.ledgerEntries).insert(
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
                mode: InsertMode.insertOrIgnore, // ✅
              );
          count++;
        }
      }
      return count;
    } catch (e, st) {
      logError('syncLedgerEntriesFromCloud', e, st);
      return 0;
    }
  }

  // ========== Sync All ==========
  Future<Map<String, int>> syncAll() async {
    _statusNotifier.startSync();

    try {
      final personRows = await _db.select(_db.persons).get();
      final persons = personRows.map(PersonMapper.fromRow).toList();

      final debtRepo = DebtRepositoryImpl(_db);
      final paymentRepo = PaymentRepositoryImpl(_db);
      final ledgerRepo = LedgerRepositoryImpl(_db);

      final debts = await debtRepo.findAll();
      final payments = await paymentRepo.findAll();
      final ledger = await ledgerRepo.findAll();

      await pushPersonsToCloud(persons);
      await pushDebtsToCloud(debts);
      await pushPaymentsToCloud(payments);
      await pushLedgerEntriesToCloud(ledger);

      await syncPersonsFromCloud();
      await syncDebtsFromCloud();
      await syncPaymentsFromCloud();
      await syncLedgerEntriesFromCloud();

      final cloudPersons = await fetchPersons();
      final cloudDebts = await fetchDebts();
      final cloudPayments = await fetchPayments();
      final cloudLedger = await fetchLedgerEntries();

      _statusNotifier.finishSync(DateTime.now());

      return {
        'persons': cloudPersons.length,
        'debts': cloudDebts.length,
        'payments': cloudPayments.length,
        'ledger': cloudLedger.length,
      };
    } catch (e) {
      _statusNotifier.finishSync(null);
      rethrow;
    }
  }
}