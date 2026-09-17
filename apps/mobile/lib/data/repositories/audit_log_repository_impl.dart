import 'package:domain/domain.dart';
import '../../core/database/app_database.dart';
import 'package:drift/drift.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  final AppDatabase _db;

  AuditLogRepositoryImpl(this._db);

  @override
  Future<void> save(AuditLog entry) async {
    await _db.into(_db.auditLogs).insert(
          AuditLogsCompanion.insert(
            id: entry.id,
            action: entry.action,
            entityType: entry.entityType,
            entityId: entry.entityId,
            correlationId: Value(entry.correlationId?.value),
            actorId: Value(entry.actorId),
            deviceId: Value(entry.deviceId),
            beforeData: Value(entry.beforeData),
            afterData: Value(entry.afterData),
            createdAt: entry.createdAt.millisecondsSinceEpoch,
          ),
        );
  }
}