import 'package:drift/drift.dart';
import 'debt_table.dart';
import 'payment_table.dart';
import 'ledger_entry_table.dart';
import 'audit_log_table.dart';
import 'sync_queue_table.dart';
import 'category_table.dart';
/// جدول التذكيرات.
@DataClassName('ReminderRow')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text().references(Debts, #id)();
  IntColumn get remindAt => integer()();
  BoolColumn get isSent => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}