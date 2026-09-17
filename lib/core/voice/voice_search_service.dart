import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceSearchService {
  static final VoiceSearchService _instance = VoiceSearchService._internal();
  factory VoiceSearchService() => _instance;
  VoiceSearchService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;
  List<LocaleName> _locales = [];

  bool get isAvailable => _available;
  bool get isListening => _listening;
  List<LocaleName> get availableLocales => _locales;

  /// قائمة أولويات اللغة العربية
  static const _arabicPriority = [
    'ar_iq', // العراق
    'ar_sa', // السعودية
    'ar_eg', // مصر
    'ar_ae', // الإمارات
    'ar_jo', // الأردن
  ];

  /// قائمة أولويات اللغة الإنجليزية
  static const _englishPriority = [
    'en_us', // أمريكا
    'en_gb', // بريطانيا
    'en_au', // أستراليا
  ];

  Future<bool> initialize() async {
    if (_available) return true;

    try {
      _available = await _speech.initialize(
        onError: (e) {
          debugPrint('❌ Voice error: ${e.errorMsg} (permanent: ${e.permanent})');
        },
        onStatus: (s) {
          _listening = s == 'listening';
          debugPrint('🎤 Voice status: $s');
        },
      );

      if (_available) {
        _locales = await _speech.locales();
        debugPrint('✅ Voice search available');
        debugPrint('📋 Available locales (${_locales.length}):');
        for (final l in _locales) {
          debugPrint('   - ${l.localeId} (${l.name})');
        }
      }
      return _available;
    } catch (e) {
      debugPrint('❌ Voice init failed: $e');
      return false;
    }
  }

  /// ✅ اختيار أفضل لغة من الأولويات.
  String _pickLocale(String preferredLanguageCode) {
    if (_locales.isEmpty) {
      // fallback
      return preferredLanguageCode == 'ar' ? 'ar_IQ' : 'en_US';
    }

    // اختيار قائمة الأولويات حسب اللغة المطلوبة
    final priorityList = preferredLanguageCode == 'ar'
        ? _arabicPriority
        : _englishPriority;

    // 1. جرّب كل لغة في قائمة الأولويات
    for (final target in priorityList) {
      for (final l in _locales) {
        if (l.localeId.toLowerCase() == target) {
          debugPrint('🎤 Using preferred locale: ${l.localeId}');
          return l.localeId;
        }
      }
    }

    // 2. جرّب أي لغة تبدأ بالكود
    for (final l in _locales) {
      if (l.localeId.toLowerCase().startsWith(preferredLanguageCode)) {
        debugPrint('🎤 Using first ${preferredLanguageCode} locale: ${l.localeId}');
        return l.localeId;
      }
    }

    // 3. Arabic fallback للإنجليزية، والعكس
    final fallback = preferredLanguageCode == 'ar' ? 'en' : 'ar';
    for (final l in _locales) {
      if (l.localeId.toLowerCase().startsWith(fallback)) {
        debugPrint('🎤 Fallback to: ${l.localeId}');
        return l.localeId;
      }
    }

    // 4. أول لغة متاحة
    debugPrint('🎤 Using first available: ${_locales.first.localeId}');
    return _locales.first.localeId;
  }

  /// ابدأ الاستماع.
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult, // ✅ جديد: نتيجة جزئية
    Function(String error)? onError, // ✅ جديد: معالجة الأخطاء
    String preferredLanguageCode = 'ar',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_available) {
      await initialize();
    }
    if (!_available) return;

    final localeId = _pickLocale(preferredLanguageCode);

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          } else if (onPartialResult != null &&
              result.recognizedWords.isNotEmpty) {
            onPartialResult(result.recognizedWords);
          }
        },
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        listenOptions: SpeechListenOptions(
          cancelOnError: false, // ✅ لا نُلغي عند الخطأ
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('❌ Listen failed: $e');
      if (onError != null) onError(e.toString());
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _listening = false;
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {}
    _listening = false;
  }
}