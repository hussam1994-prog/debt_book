import 'dart:convert';
import 'package:contracts/contracts.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;

import '../../core/database/app_database.dart';
import '../../core/observability/logging_service.dart';
import '../../core/observability/metrics_service.dart';
import '../mappers/person_mapper.dart';
import '../mappers/debt_mapper.dart';
import '../mappers/payment_mapper.dart';
import '../mappers/ledger_entry_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
/// محرك المزامنة المستقل.
/// يقرأ العمليات المعلقة من sync_queue، يرسلها إلى الخادم،
/// ثم يسحب التحديثات ويطبقها محليًا.
class SyncEngine {
  final AppDatabase _db;
  final String serverUrl;
  final LoggingService _logger;
  final MetricsService _metrics;
  final LedgerIntegrityChecker _integrityChecker;

  SyncEngine({
    required AppDatabase db,
    required this.serverUrl,
    required LoggingService logger,
    required MetricsService metrics,
    required LedgerIntegrityChecker integrityChecker,
  })  : _db = db,
        _logger = logger,
        _metrics = metrics,
        _integrityChecker = integrityChecker;

  /// تنفيذ دورة مزامنة كاملة.
  /// يعيد عدد العمليات التي تمت مزامنتها بنجاح.
  Future<int> sync() async {
    final correlationId = _logger.newCorrelationId();
    _logger.info('Sync started', metadata: {'correlationId': correlationId});

    return _metrics.time('sync_duration', () async {
      try {
        // 1. Push
        final pendingOps = await _getPendingOperations();
        _logger.info('Pending operations: ${pendingOps.length}');
        _metrics.record('pending_operations', pendingOps.length.toDouble());

        if (pendingOps.isNotEmpty) {
          final pushRequest = PushRequest(operations: pendingOps);
          final pushResponse = await _sendPush(pushRequest, correlationId);
          if (!pushResponse.success) {
            if (pushResponse.error == 'conflict') {
              _logger.warning('Conflict during push', metadata: {'error': pushResponse.error});
              _metrics.incrementCounter('sync_conflicts');
              // For now, we throw to let the UI know. Later, we might handle this differently.
              throw Exception('Conflict detected during sync. Please resolve conflicts.');
            } else {
              _logger.error('Push failed: ${pushResponse.error}');
              throw Exception('Push failed: ${pushResponse.error}');
            }
          } else {
            _logger.info('Push successful');
            for (final op in pendingOps) {
              await _markOperationSynced(op.idempotencyKey);
            }
          }
        }

        // 2. Pull
        final lastCursor = await _getLastCursor();
        final pullRequest = PullRequest(cursor: lastCursor);
        final pullResponse = await _sendPull(pullRequest, correlationId);
        await _applyPull(pullResponse);

        if (pullResponse.nextCursor > (lastCursor ?? 0)) {
          await _saveLastCursor(pullResponse.nextCursor);
        }

        _logger.info('Sync completed successfully');
        _metrics.incrementCounter('sync_success');
        return pendingOps.length;
      } catch (e, st) {
        _logger.error('Sync failed', error: e, stackTrace: st);
        _metrics.incrementCounter('sync_failure');
        rethrow;
      }
    });
  }

  /// Runs a data integrity check on the local database.
  Future<void> runIntegrityCheck() async {
    final violations = await _integrityChecker.check();
    _metrics.record('integrity_violations', violations.length.toDouble());
    _logger.info('Integrity check completed', metadata: {'violations': violations.length});
  }

  // --- Push ---

  Future<List<PushOperation>> _getPendingOperations() async {
    final rows = await (_db.select(_db.syncQueue)
          ..where((t) => t.status.equals('pending')))
        .get();
    return rows.map((row) {
      return PushOperation(
        type: SyncOperationType.values.firstWhere((e) => e.name == row.operation),
        idempotencyKey: row.idempotencyKey,
        payload: jsonDecode(row.payload) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<SyncResponse> _sendPush(PushRequest request, String correlationId) async {
    final response = await http.post(
      Uri.parse('$serverUrl/api/sync/push'),
      headers: {
        'Content-Type': 'application/json',
        'X-Correlation-ID': correlationId,
      },
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode == 409) {
      // Conflict detected
      return const SyncResponse(success: false, error: 'conflict');
    }
    if (response.statusCode != 200) {
      throw Exception('Push HTTP ${response.statusCode}: ${response.body}');
    }
    return SyncResponse.fromJson(jsonDecode(response.body));
  }

  Future<void> _markOperationSynced(String idempotencyKey) async {
    await (_db.update(_db.syncQueue)
          ..where((t) => t.idempotencyKey.equals(idempotencyKey)))
        .write(SyncQueueCompanion(
      status: Value('synced'),
      syncedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  // --- Pull ---

  Future<int?> _getLastCursor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('sync_last_cursor');
  }

  Future<void> _saveLastCursor(int cursor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sync_last_cursor', cursor);
  }

  Future<PullResponse> _sendPull(PullRequest request, String correlationId) async {
    final response = await http.post(
      Uri.parse('$serverUrl/api/sync/pull'),
      headers: {
        'Content-Type': 'application/json',
        'X-Correlation-ID': correlationId,
      },
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Pull HTTP ${response.statusCode}: ${response.body}');
    }
    return PullResponse.fromJson(jsonDecode(response.body));
  }

  Future<void> _applyPull(PullResponse response) async {
    await _db.transaction(() async {
      _logger.info('Applying pull response', metadata: {
        'persons': response.persons.length,
        'debts': response.debts.length,
        'payments': response.payments.length,
        'ledgerEntries': response.ledgerEntries.length,
        'nextCursor': response.nextCursor,
      });

      // تطبيق الأشخاص
      for (final personDto in response.persons) {
        final exists = await (_db.select(_db.persons)
              ..where((t) => t.id.equals(personDto.id)))
            .getSingleOrNull();
        if (exists == null) {
          await _db.into(_db.persons).insert(
                PersonsCompanion.insert(
                  id: personDto.id,
                  name: personDto.name,
                  phone: Value(personDto.phone),
                  email: Value(personDto.email),
                  notes: Value(personDto.notes),
                  createdAt: personDto.createdAt,
                  updatedAt: personDto.updatedAt,
                  version: personDto.version,
                  isDeleted: personDto.isDeleted,
                  deletedAt: Value(personDto.deletedAt),
                ),
              );
        } else {
          // تحديث فقط إذا كانت النسخة المحلية أقل
          if (personDto.version > exists.version) {
            await (_db.update(_db.persons)
                  ..where((t) => t.id.equals(personDto.id)))
                .write(PersonsCompanion(
                  name: Value(personDto.name),
                  phone: Value(personDto.phone),
                  email: Value(personDto.email),
                  notes: Value(personDto.notes),
                  updatedAt: Value(personDto.updatedAt),
                  version: Value(personDto.version),
                  isDeleted: Value(personDto.isDeleted),
                  deletedAt: Value(personDto.deletedAt),
                ));
          }
        }
      }

      // تطبيق الديون
      for (final debtDto in response.debts) {
        final exists = await (_db.select(_db.debts)
              ..where((t) => t.id.equals(debtDto.id)))
            .getSingleOrNull();
        if (exists == null) {
          await _db.into(_db.debts).insert(
                DebtsCompanion.insert(
                  id: debtDto.id,
                  personId: debtDto.personId,
                  description: Value(debtDto.description),
                  amount: debtDto.amount,
                  currency: debtDto.currency,
                  dueDate: Value(debtDto.dueDate),
                  status: debtDto.status,
                  createdAt: debtDto.createdAt,
                  updatedAt: debtDto.updatedAt,
                  version: debtDto.version,
                  isDeleted: debtDto.isDeleted,
                  deletedAt: Value(debtDto.deletedAt),
                ),
              );
        } else {
          if (debtDto.version > exists.version) {
            await (_db.update(_db.debts)
                  ..where((t) => t.id.equals(debtDto.id)))
                .write(DebtsCompanion(
                  personId: Value(debtDto.personId),
                  description: Value(debtDto.description),
                  amount: Value(debtDto.amount),
                  currency: Value(debtDto.currency),
                  dueDate: Value(debtDto.dueDate),
                  status: Value(debtDto.status),
                  updatedAt: Value(debtDto.updatedAt),
                  version: Value(debtDto.version),
                  isDeleted: Value(debtDto.isDeleted),
                  deletedAt: Value(debtDto.deletedAt),
                ));
          }
        }
      }

      // تطبيق الدفعات
      for (final paymentDto in response.payments) {
        final exists = await (_db.select(_db.payments)
              ..where((t) => t.id.equals(paymentDto.id)))
            .getSingleOrNull();
        if (exists == null) {
          await _db.into(_db.payments).insert(
                PaymentsCompanion.insert(
                  id: paymentDto.id,
                  debtId: paymentDto.debtId,
                  amount: paymentDto.amount,
                  currency: paymentDto.currency,
                  paymentDate: paymentDto.paymentDate,
                  method: paymentDto.method,
                  notes: Value(paymentDto.notes),
                  createdAt: paymentDto.createdAt,
                  updatedAt: paymentDto.updatedAt,
                  version: paymentDto.version,
                  isDeleted: paymentDto.isDeleted,
                  deletedAt: Value(paymentDto.deletedAt),
                ),
              );
        } else {
          if (paymentDto.version > exists.version) {
            await (_db.update(_db.payments)
                  ..where((t) => t.id.equals(paymentDto.id)))
                .write(PaymentsCompanion(
                  amount: Value(paymentDto.amount),
                  currency: Value(paymentDto.currency),
                  paymentDate: Value(paymentDto.paymentDate),
                  method: Value(paymentDto.method),
                  notes: Value(paymentDto.notes),
                  updatedAt: Value(paymentDto.updatedAt),
                  version: Value(paymentDto.version),
                  isDeleted: Value(paymentDto.isDeleted),
                  deletedAt: Value(paymentDto.deletedAt),
                ));
          }
        }
      }

      // تطبيق قيود الدفتر (Append-Only)
      for (final ledgerDto in response.ledgerEntries) {
        final exists = await (_db.select(_db.ledgerEntries)
              ..where((t) => t.id.equals(ledgerDto.id)))
            .getSingleOrNull();
        if (exists == null) {
          await _db.into(_db.ledgerEntries).insert(
                LedgerEntriesCompanion.insert(
                  id: ledgerDto.id,
                  debtId: ledgerDto.debtId,
                  entryType: ledgerDto.entryType,
                  amount: ledgerDto.amount,
                  currency: ledgerDto.currency,
                  correlationId: Value(ledgerDto.correlationId),
                  sourceEntryId: Value(ledgerDto.sourceEntryId),
                  paymentId: Value(ledgerDto.paymentId),
                  createdAt: ledgerDto.createdAt,
                  serverSequence: Value(ledgerDto.serverSequence),
                ),
              );
        }
        // لا يوجد تحديث أو حذف
      }
    });
  }
}