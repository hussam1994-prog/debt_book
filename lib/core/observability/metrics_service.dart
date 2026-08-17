
/// مقياس واحد.
class Metric {
  final String name;
  final double value;
  final DateTime timestamp;

  const Metric({
    required this.name,
    required this.value,
    required this.timestamp,
  });
}

/// خدمة تجميع المقاييس في الذاكرة.
class MetricsService {
  final List<Metric> _metrics = [];
  final int maxSize = 1000;

  /// تسجيل مقياس.
  void record(String name, double value) {
    _metrics.add(Metric(
      name: name,
      value: value,
      timestamp: DateTime.now(),
    ));
    if (_metrics.length > maxSize) {
      _metrics.removeAt(0);
    }
  }

  /// تسجيل مدة عملية.
  Future<T> time<T>(String name, Future<T> Function() operation) async {
    final start = DateTime.now();
    try {
      return await operation();
    } finally {
      final duration = DateTime.now().difference(start).inMilliseconds;
      record(name, duration.toDouble());
    }
  }

  /// زيادة عداد.
  void incrementCounter(String name) {
    record(name, 1);
  }

  /// الحصول على جميع المقاييس.
  List<Metric> getAllMetrics() => List.unmodifiable(_metrics);

  /// مسح المقاييس.
  void clear() => _metrics.clear();
}