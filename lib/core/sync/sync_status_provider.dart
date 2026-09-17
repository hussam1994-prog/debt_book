import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncStatus {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final bool isOnline;
  final Map<String, int>? counts; // ✅ جديد

  const SyncStatus({
    this.isSyncing = false,
    this.lastSyncTime,
    this.isOnline = true,
    this.counts,
  });

  SyncStatus copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    bool? isOnline,
    Map<String, int>? counts,
    bool clearCounts = false,
  }) {
    return SyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isOnline: isOnline ?? this.isOnline,
      counts: clearCounts ? null : (counts ?? this.counts),
    );
  }
}

final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>(
  (ref) => SyncStatusNotifier(),
);

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(const SyncStatus());

  void startSync() {
    state = state.copyWith(isSyncing: true);
  }

  void finishSync(DateTime? time) {
    state = state.copyWith(
      isSyncing: false,
      lastSyncTime: time ?? DateTime.now(),
    );
  }

  // ✅ دالة جديدة لتحديث الأعداد
  void finishSyncWithCounts(DateTime? time, Map<String, int> counts) {
    state = state.copyWith(
      isSyncing: false,
      lastSyncTime: time ?? DateTime.now(),
      counts: counts,
    );
  }

  void setOnline(bool online) {
    state = state.copyWith(isOnline: online);
  }
}