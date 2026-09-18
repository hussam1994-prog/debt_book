import 'package:flutter/foundation.dart';

/// مقاييس المزامنة — إحصائيات تشغيلية للـ Outbox.
///
/// تُستخدم للتشخيص فقط. لا تُخزَّن — تُصفَّر عند كل تشغيل.
class SyncMetrics {
  SyncMetrics._();

  static int totalPushes = 0;
  static int totalPulls = 0;
  static int failedPushes = 0;
  static int totalBytesUploaded = 0;
  static int totalBytesDownloaded = 0;
  static Duration totalSyncTime = Duration.zero;
  static DateTime? lastSuccessfulSync;

  static void recordPush(int bytes, Duration time) {
    totalPushes++;
    totalBytesUploaded += bytes;
    totalSyncTime += time;
    lastSuccessfulSync = DateTime.now();
  }

  static void recordPull(int bytes) {
    totalPulls++;
    totalBytesDownloaded += bytes;
  }

  static void recordFailure() {
    failedPushes++;
  }

  /// يطبع ملخص المقاييس في سجل التصحيح.
  ///
  /// ⚠️ لا تُسمّيها `print` — سيؤدي إلى shadowing للدالة العامة.
  static void logSummary() {
    if (!kDebugMode) return;
    debugPrint('''
📊 Sync Metrics:
  - Pushes: $totalPushes
  - Pulls: $totalPulls
  - Failures: $failedPushes
  - Bytes UP: ${(totalBytesUploaded / 1024).toStringAsFixed(1)} KB
  - Bytes DOWN: ${(totalBytesDownloaded / 1024).toStringAsFixed(1)} KB
  - Total time: ${totalSyncTime.inMilliseconds}ms
  - Last sync: $lastSuccessfulSync
''');
  }

  /// إعادة تعيين كل المقاييس.
  static void reset() {
    totalPushes = 0;
    totalPulls = 0;
    failedPushes = 0;
    totalBytesUploaded = 0;
    totalBytesDownloaded = 0;
    totalSyncTime = Duration.zero;
    lastSuccessfulSync = null;
  }
}