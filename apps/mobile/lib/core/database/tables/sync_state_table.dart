import 'package:drift/drift.dart';

/// جدول لتخزين آخر وقت مزامنة لكل نوع كيان.
/// يُستخدم لتنفيذ Delta Sync (جلب التغييرات فقط منذ آخر مزامنة).
@DataClassName('SyncState')
class SyncStates extends Table {
  /// نوع الكيان: 'persons' | 'debts' | 'payments' | 'ledger_entries' | 'installments'
  TextColumn get entityType => text()();

  /// آخر وقت تمت فيه مزامنة هذا الكيان بنجاح
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {entityType};
}