import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../../core/notifications/notification_service.dart';
import '../../features/dashboard/providers/analytics_providers.dart';
import '../../features/people/providers/people_providers.dart';
import '../../features/debts/providers/debts_paginated_provider.dart';
import '../../features/debts/providers/debts_grouped_provider.dart';
import '../database/app_database.dart';

/// خدمة Realtime — تستمع لتغييرات Supabase وتزامنها محلياً.
///
/// تستخدم [notificationServiceProvider] بدلاً من إنشاء
/// نسخ جديدة من `NotificationService` (كان يسبب إعادة تهيئة متكررة).
class RealtimeService {
  final SupabaseClient _client = Supabase.instance.client;
  final Ref _ref;
  bool _isStarted = false;

  RealtimeService(this._ref);

  void start() {
    if (_isStarted) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _isStarted = true;

    _client.channel('rt:persons').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'persons',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: _handlePersonChange,
    ).subscribe();

    _client.channel('rt:debts').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'debts',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: _handleDebtChange,
    ).subscribe();

    _client.channel('rt:payments').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'payments',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: _handlePaymentChange,
    ).subscribe();

    _client.channel('rt:ledger').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'ledger_entries',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: _handleLedgerChange,
    ).subscribe();

    _client.channel('rt:installments').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'installments',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: _handleInstallmentChange,
    ).subscribe();
  }

  Future<void> _handlePersonChange(PostgresChangePayload p) async {
    final db = _ref.read(appDatabaseProvider);
    try {
      if (p.eventType == PostgresChangeEvent.delete) {
        final id = p.oldRecord['id'] as String?;
        if (id != null) {
          await (db.delete(db.persons)..where((t) => t.id.equals(id))).go();
        }
      } else {
        final row = p.newRecord;
        await db.into(db.persons).insertOnConflictUpdate(PersonsCompanion(
              id: Value(row['id'] as String),
              name: Value(row['name'] as String),
              phone: Value(row['phone'] as String?),
              email: Value(row['email'] as String?),
              notes: Value(row['notes'] as String?),
              createdAt: Value(
                  DateTime.parse(row['created_at']).millisecondsSinceEpoch),
              updatedAt: Value(
                  DateTime.parse(row['updated_at']).millisecondsSinceEpoch),
              version: Value(row['version'] as int? ?? 1),
              isDeleted: Value(row['is_deleted'] as bool? ?? false),
            ));
      }
      _ref.invalidate(peoplePaginatedProvider);
      _ref.invalidate(peopleProvider);
    } catch (e) {
      _ref.read(loggingServiceProvider).error('RT persons error', error: e);
    }
  }

  Future<void> _handleDebtChange(PostgresChangePayload p) async {
    final db = _ref.read(appDatabaseProvider);
    try {
      if (p.eventType == PostgresChangeEvent.delete) {
        final id = p.oldRecord['id'] as String?;
        if (id != null) {
          await (db.delete(db.debts)..where((t) => t.id.equals(id))).go();
        }
      } else {
        final row = p.newRecord;
        await db.into(db.debts).insertOnConflictUpdate(DebtsCompanion(
              id: Value(row['id'] as String),
              personId: Value(row['person_id'] as String),
              description: Value(row['description'] as String?),
              amount: Value(row['amount'] as int),
              currency: Value(row['currency'] as String? ?? 'IQD'),
              dueDate: row['due_date'] != null
                  ? Value(
                      DateTime.parse(row['due_date']).millisecondsSinceEpoch)
                  : const Value(null),
              status: Value(row['status'] as String? ?? 'active'),
              createdAt: Value(
                  DateTime.parse(row['created_at']).millisecondsSinceEpoch),
              updatedAt: Value(
                  DateTime.parse(row['updated_at']).millisecondsSinceEpoch),
              version: Value(row['version'] as int? ?? 1),
              isDeleted: Value(row['is_deleted'] as bool? ?? false),
              attachmentPath: Value(row['attachment_path'] as String?),
            ));
      }
      _ref.invalidate(debtsPaginatedProvider);
      _ref.invalidate(debtsGroupedByPersonProvider);
    } catch (e) {
      _ref.read(loggingServiceProvider).error('RT debts error', error: e);
    }
  }

  Future<void> _handlePaymentChange(PostgresChangePayload p) async {
    final db = _ref.read(appDatabaseProvider);
    try {
      if (p.eventType == PostgresChangeEvent.delete) {
        final id = p.oldRecord['id'] as String?;
        if (id != null) {
          await (db.delete(db.payments)..where((t) => t.id.equals(id))).go();
        }
      } else {
        final row = p.newRecord;
        await db.into(db.payments).insertOnConflictUpdate(PaymentsCompanion(
              id: Value(row['id'] as String),
              debtId: Value(row['debt_id'] as String),
              amount: Value(row['amount'] as int),
              currency: Value(row['currency'] as String? ?? 'IQD'),
              paymentDate: Value(DateTime.parse(row['payment_date'])
                  .millisecondsSinceEpoch),
              method: Value(row['method'] as String? ?? 'cash'),
              notes: Value(row['notes'] as String?),
              createdAt: Value(
                  DateTime.parse(row['created_at']).millisecondsSinceEpoch),
              updatedAt: Value(
                  DateTime.parse(row['updated_at']).millisecondsSinceEpoch),
              version: Value(row['version'] as int? ?? 1),
              isDeleted: Value(row['is_deleted'] as bool? ?? false),
            ));

        // ✅ إشعار استلام دفعة جديدة
        await _notifyPaymentReceived(row);
      }
      _ref.invalidate(allPaymentsProvider);
      _ref.invalidate(balancesByDebtProvider);
    } catch (e) {
      _ref.read(loggingServiceProvider).error('RT payments error', error: e);
    }
  }

  /// إشعار عند استلام دفعة جديدة من جهاز آخر.
  Future<void> _notifyPaymentReceived(Map<String, dynamic> row) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentAlertsEnabled =
          prefs.getBool(NotifPrefs.paymentAlerts) ?? true;
      final notificationsEnabled = prefs.getBool(NotifPrefs.enabled) ?? true;

      if (!paymentAlertsEnabled || !notificationsEnabled) return;

      final db = _ref.read(appDatabaseProvider);
      final debtId = row['debt_id'] as String?;
      final amount = row['amount'] as int? ?? 0;
      if (debtId == null) return;

      final debt = await (db.select(db.debts)
            ..where((t) => t.id.equals(debtId)))
          .getSingleOrNull();
      if (debt == null) return;

      final person = await (db.select(db.persons)
            ..where((t) => t.id.equals(debt.personId)))
          .getSingleOrNull();

      // ✅ استخدم الـ provider الموحّد بدلاً من نسخة جديدة
      final notifService = _ref.read(notificationServiceProvider);
      await notifService.showPaymentReceivedNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        personName: person?.name ?? 'شخص',
        amount: amount,
      );
    } catch (e) {
      _ref
          .read(loggingServiceProvider)
          .error('RT payment notification error', error: e);
    }
  }

  Future<void> _handleLedgerChange(PostgresChangePayload p) async {
    final db = _ref.read(appDatabaseProvider);
    try {
      if (p.eventType != PostgresChangeEvent.delete) {
        final row = p.newRecord;
        await db
            .into(db.ledgerEntries)
            .insertOnConflictUpdate(LedgerEntriesCompanion(
              id: Value(row['id'] as String),
              debtId: Value(row['debt_id'] as String),
              entryType: Value(row['entry_type'] as String),
              amount: Value(row['amount'] as int),
              currency: Value(row['currency'] as String? ?? 'IQD'),
              correlationId: Value(row['correlation_id'] as String?),
              sourceEntryId: Value(row['source_entry_id'] as String?),
              paymentId: Value(row['payment_id'] as String?),
              createdAt: Value(
                  DateTime.parse(row['created_at']).millisecondsSinceEpoch),
              serverSequence: Value(row['server_sequence'] as int?),
            ));
      }
      _ref.invalidate(balancesByDebtProvider);
    } catch (e) {
      _ref.read(loggingServiceProvider).error('RT ledger error', error: e);
    }
  }

  Future<void> _handleInstallmentChange(PostgresChangePayload p) async {
    final db = _ref.read(appDatabaseProvider);
    try {
      if (p.eventType != PostgresChangeEvent.delete) {
        final row = p.newRecord;
        await db
            .into(db.installments)
            .insertOnConflictUpdate(InstallmentsCompanion(
              id: Value(row['id'] as String),
              debtId: Value(row['debt_id'] as String),
              number: Value(row['number'] as int),
              amount: Value(row['amount'] as int),
              currency: Value(row['currency'] as String? ?? 'IQD'),
              dueDate: Value(
                  DateTime.parse(row['due_date']).millisecondsSinceEpoch),
              status: Value(row['status'] as String? ?? 'pending'),
              paidAt: row['paid_at'] != null
                  ? Value(DateTime.parse(row['paid_at'])
                      .millisecondsSinceEpoch)
                  : const Value(null),
              notes: Value(row['notes'] as String?),
              createdAt: Value(
                  DateTime.parse(row['created_at']).millisecondsSinceEpoch),
              updatedAt: Value(
                  DateTime.parse(row['updated_at']).millisecondsSinceEpoch),
              version: Value(row['version'] as int? ?? 1),
              isDeleted: Value(row['is_deleted'] as bool? ?? false),
            ));
      }
    } catch (e) {
      _ref.read(loggingServiceProvider).error('RT installments error', error: e);
    }
  }

  void stop() {
    _isStarted = false;
    _client.removeAllChannels();
  }
}