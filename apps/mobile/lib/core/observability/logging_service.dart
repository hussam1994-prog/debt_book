import 'package:logger/logger.dart';

/// خدمة تسجيل الأحداث مع مستويات مختلفة.
class LoggingService {
  final Logger _logger;

  LoggingService()
      : _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 5,
            lineLength: 80,
            colors: true,
            printEmojis: true,
          ),
        );

  void debug(String message) => _logger.d(message);

  void info(String message) => _logger.i(message);

  void warning(String message) => _logger.w(message);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}