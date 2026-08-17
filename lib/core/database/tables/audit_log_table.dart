import 'package:drift/drift.dart';

/// جدول سجل التدقيق.
@DataClassName('AuditLogRow')
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get correlationId => text().nullable()();
  TextColumn get actorId => text().nullable()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get beforeData => text().nullable()();
  TextColumn get afterData => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}