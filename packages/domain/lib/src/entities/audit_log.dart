import '../value_objects/correlation_id.dart';

/// كيان سجل التدقيق.
class AuditLog {
  final String id;
  final String action;        // create, update, delete, reverse, sync, ...
  final String entityType;    // persons, debts, payments, ledger_entries ...
  final String entityId;
  final CorrelationId? correlationId;
  final String? actorId;      // المستخدم أو الجهاز
  final String? deviceId;
  final String? beforeData;   // JSON
  final String? afterData;    // JSON
  final DateTime createdAt;

  const AuditLog({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.correlationId,
    this.actorId,
    this.deviceId,
    this.beforeData,
    this.afterData,
    required this.createdAt,
  });
}