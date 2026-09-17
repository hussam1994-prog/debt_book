import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/person_table.dart';
import 'tables/debt_table.dart';
import 'tables/payment_table.dart';
import 'tables/ledger_entry_table.dart';
import 'tables/audit_log_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/category_table.dart';
import 'tables/reminder_table.dart';
import 'tables/attachment_table.dart';
import 'tables/installment_table.dart';
import 'tables/outbox_table.dart';
import 'tables/sync_state_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Persons,
    Debts,
    Payments,
    LedgerEntries,
    AuditLogs,
    SyncQueue,
    Categories,
    Reminders,
    Attachments,
    Installments,
    OutboxTable,
    SyncStates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// ✅ وضع الذاكرة (للاختبارات) — مع تفعيل FK على الاتصال
  AppDatabase.memory()
      : super(NativeDatabase.memory(
          setup: (db) {
            // يُنفّذ فوراً بعد فتح الاتصال — PRAGMA دائم
            db.execute('PRAGMA foreign_keys = ON');
          },
        ));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 4) {
            await m.createTable(installments);
          }
          if (from < 5) {
            await m.createTable(outboxTable);
          }
          if (from < 6) {
            await m.createTable(syncStates);
          }
        },
        // ✅ احتياط إضافي في كل فتح
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// مسح جميع البيانات المحلية
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(ledgerEntries).go();
      await delete(payments).go();
      await delete(installments).go();
      await delete(debts).go();
      await delete(persons).go();
      await delete(auditLogs).go();
      await delete(syncQueue).go();
      await delete(outboxTable).go();
      await delete(syncStates).go();
    });
  }

  Future<void> _createIndexes() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_debts_person_id ON debts(person_id);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_payments_debt_id ON payments(debt_id);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_ledger_debt_id ON ledger_entries(debt_id);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_outbox_status_retry ON outbox(status, next_retry_at);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_persons_deleted ON persons(is_deleted);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_debts_deleted ON debts(is_deleted);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_payments_deleted ON payments(is_deleted);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_installments_debt ON installments(debt_id);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_installments_deleted ON installments(is_deleted);');
  }

  static QueryExecutor _openConnection() {
    if (!kIsWeb &&
        (Platform.isWindows ||
            Platform.isLinux ||
            Platform.isMacOS ||
            Platform.isAndroid ||
            Platform.isIOS)) {
      return LazyDatabase(() async {
        final dir = await getApplicationDocumentsDirectory();
        final file = File(p.join(dir.path, 'debt_book.sqlite'));
        return NativeDatabase.createInBackground(
          file,
          setup: (db) {
            // ✅ تفعيل FK على قاعدة البيانات الحقيقية
            db.execute('PRAGMA foreign_keys = ON');
          },
        );
      });
    }
    // احتياط للويب/غير المدعوم
    return NativeDatabase.memory(
      setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }
}