import 'dart:async';

/// مراقب أداء بسيط لقياس فترات.
class PerformanceMonitor {
  final Map<String, Stopwatch> _watches = {};

  /// بدء قياس.
  void start(String label) {
    _watches[label] = Stopwatch()..start();
  }

  /// إيقاف قياس وإرجاع المدة بالميلي ثانية.
  int stop(String label) {
    final watch = _watches.remove(label);
    if (watch == null) return 0;
    watch.stop();
    return watch.elapsedMilliseconds;
  }

  /// قياس دالة.
  Future<T> measure<T>(String label, Future<T> Function() func) async {
    start(label);
    try {
      return await func();
    } finally {
      stop(label);
    }
  }
}