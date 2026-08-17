import 'package:drift/drift.dart';
import 'debt_table.dart';
import 'payment_table.dart';
/// جدول قيود دفتر الأستاذ (Append-Only).
@DataClassName('LedgerEntryRow')
class LedgerEntries extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text().references(Debts, #id)();
  TextColumn get entryType => text()();
  IntColumn get amount => integer()(); // موجب = زيادة، سالب = تخفيض
  TextColumn get currency => text().withDefault(const Constant('IQD'))();
  TextColumn get correlationId => text().nullable()();
  TextColumn get sourceEntryId => text().nullable().references(LedgerEntries, #id)();
  TextColumn get paymentId => text().nullable().references(Payments, #id)();
  IntColumn get createdAt => integer()();
  IntColumn get serverSequence => integer().nullable().unique()();

  @override
  Set<Column> get primaryKey => {id};
}