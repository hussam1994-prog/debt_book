import 'package:flutter/widgets.dart';
import 'package:mobile/core/cloud/sync_service.dart';

/// نسخة وهمية من SyncService — لا تحتاج Supabase.
///
/// تُستخدم في اختبارات Widget لتجنب الحاجة إلى تهيئة Supabase.
class FakeSyncService implements SyncService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
