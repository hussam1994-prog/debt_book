import 'package:flutter_riverpod/flutter_riverpod.dart';

/// حالة المزامنة الحالية
class SyncStatus {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final bool isOnline;

  const SyncStatus({
    this.isSyncing = false,
    this.lastSyncTime,
    this.isOnline = true,
  });

  SyncStatus copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    bool? isOnline,
  }) {
    return SyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// مزود حالة المزامنة
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

  void setOnline(bool online) {
    state = state.copyWith(isOnline: online);
  }
}