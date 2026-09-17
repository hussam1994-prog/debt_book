import 'package:flutter/foundation.dart';

/// طباعة معلومات للتشخيص في الطرفية.
void logDebug(String message) {
  debugPrint('🐞 $message');
}

/// طباعة الأخطاء مع مصدرها و stack trace.
void logError(String source, Object error, StackTrace? stackTrace) {
  debugPrint('❌ [$source] $error');
  if (stackTrace != null) {
    debugPrint('Stack: $stackTrace');
  }
}