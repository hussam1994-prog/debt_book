import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// حالة الاتصال
class ConnectivityState {
  final bool isOnline;
  ConnectivityState(this.isOnline);
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>(
  (ref) => ConnectivityNotifier(),
);

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityNotifier()
      : _connectivity = Connectivity(),
        super(ConnectivityState(true)) {
    _init();
  }

  Future<void> _init() async {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      state = ConnectivityState(online);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}