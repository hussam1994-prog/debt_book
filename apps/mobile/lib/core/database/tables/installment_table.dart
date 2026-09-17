import 'package:drift/drift.dart';
import 'debt_table.dart';

@DataClassName('InstallmentRow')
class Installments extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text()
    .customConstraint('NOT NULL REFERENCES debts(id)')
    .references(Debts, #id)();
  IntColumn get number => integer()();
  IntColumn get amount => integer()();
  TextColumn get currency => text().withDefault(const Constant('IQD'))();
  IntColumn get dueDate => integer()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get paidAt => integer().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}