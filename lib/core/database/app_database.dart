import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables/person_table.dart';
import 'tables/debt_table.dart';
import 'tables/payment_table.dart';
import 'tables/ledger_entry_table.dart';
import 'tables/audit_log_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/category_table.dart';
import 'tables/reminder_table.dart';
import 'tables/attachment_table.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {},
      );

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
        return NativeDatabase.createInBackground(file);
      });
    }
    return NativeDatabase.memory();
  }
}