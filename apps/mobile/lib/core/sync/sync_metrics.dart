class SyncMetrics {
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

  static void print() {
    print('''
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
}