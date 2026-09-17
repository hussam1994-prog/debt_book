import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../cloud/supabase_config.dart';
import '../cloud/sync_service.dart';
import '../database/app_database.dart';

/// ✅ اسم المهمة الفريد (يجب أن يكون بصيغة عكسية للنطاق).
const String backgroundSyncTask = 'com.example.mobile.backgroundSync';

/// ✅ Dispatcher يُستدعى من WorkManager في isolate منفصل.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 Background sync started: $task');

    try {
      // 1. تهيئة Supabase
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );

      // 2. التحقق من وجود مستخدم مسجل
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('⏸️ No user, skipping background sync');
        return true;
      }

      // 3. فتح قاعدة البيانات
      final db = AppDatabase();

      // 4. تنفيذ المزامنة
      final syncService = SyncService(
        db: db,
        supabase: Supabase.instance.client,
      );

      await syncService.syncNow();
      await db.close();

      debugPrint('✅ Background sync complete');
      return true;
    } catch (e, st) {
      debugPrint('❌ Background sync failed: $e\n$st');
      return false;
    }
  });
}

class BackgroundSync {
  /// ✅ تهيئة WorkManager (تُستدعى مرة واحدة في main).
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    debugPrint('✅ WorkManager initialized');
  }

  /// ✅ تسجيل مهمة المزامنة الدورية.
  static Future<void> registerPeriodicSync() async {
    try {
      await Workmanager().registerPeriodicTask(
        backgroundSyncTask, // uniqueName
        backgroundSyncTask, // taskName
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
      debugPrint('✅ Background sync registered');
    } catch (e) {
      debugPrint('❌ Failed to register background sync: $e');
    }
  }

  /// ✅ إلغاء المهمة (عند تسجيل الخروج).
  static Future<void> cancel() async {
    try {
      await Workmanager().cancelByUniqueName(backgroundSyncTask);
      debugPrint('🛑 Background sync cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel background sync: $e');
    }
  }
}