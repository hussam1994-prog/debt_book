import 'package:drift/drift.dart';
import 'debt_table.dart';
/// جدول التذكيرات.
@DataClassName('ReminderRow')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text()
    .customConstraint('NOT NULL REFERENCES debts(id)')
    .references(Debts, #id)();
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