import 'package:drift/drift.dart';
import 'person_table.dart';
/// جدول الديون.
@DataClassName('DebtRow')
class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get personId => text()
    .customConstraint('NOT NULL REFERENCES persons(id)')
    .references(Persons, #id)();
  TextColumn get description => text().nullable()();
  IntColumn get amount => integer()(); // المبلغ الأصلي بالدينار
  TextColumn get currency => text().withDefault(const Constant('IQD'))();
  IntColumn get dueDate => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get deletedAt => integer().nullable()();
  TextColumn get attachmentPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}