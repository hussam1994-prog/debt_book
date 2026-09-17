import '../entities/audit_log.dart';

/// عقد مستودع سجل التدقيق.
abstract class AuditLogRepository {
  /// حفظ سجل تدقيق جديد.
  Future<void> save(AuditLog entry);
}