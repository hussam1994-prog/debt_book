import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';

/// أخطاء Google Sign-In مع رموز واضحة
enum GoogleAuthErrorType {
  cancelled,
  network,
  noIdToken,
  configurationError,
  unknown,
}

class GoogleAuthException implements Exception {
  final GoogleAuthErrorType type;
  final String message;
  final Object? originalError;

  GoogleAuthException(this.type, this.message, [this.originalError]);

  @override
  String toString() => 'GoogleAuthException($type): $message';

  /// رسالة مترجمة مناسبة للعرض.
  ///
  /// ⚠️ يتطلب [l10n] لأن Service لا يملك `BuildContext`.
  String localizedMessage(AppLocalizations l10n) {
    switch (type) {
      case GoogleAuthErrorType.cancelled:
        return l10n.loginCancelled;
      case GoogleAuthErrorType.network:
        return l10n.networkError;
      case GoogleAuthErrorType.noIdToken:
        return l10n.accountDataFailed;
      case GoogleAuthErrorType.configurationError:
        return l10n.configError;
      case GoogleAuthErrorType.unknown:
        return l10n.unexpectedError;
    }
  }
}

class GoogleAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// ⚠️ مهم: يجب أن يكون Web Client ID (وليس Android)
  static const String _webClientId =
      '689539122210-gmd3qgi71opc1a7plbgmudi49j3jdl35.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    serverClientId: _webClientId,
  );

  // ─── تسجيل الدخول التفاعلي ───

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      debugPrint('[GoogleAuth] Signing in...');

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[GoogleAuth] User cancelled');
        throw GoogleAuthException(
          GoogleAuthErrorType.cancelled,
          'User cancelled sign-in',
        );
      }

      return await _authenticateWithSupabase(googleUser);
    } on GoogleAuthException {
      rethrow;
    } on PlatformException catch (e) {
      debugPrint('[GoogleAuth] PlatformException: ${e.code}');
      if (e.code == 'network_error') {
        throw GoogleAuthException(
          GoogleAuthErrorType.network,
          'Network error',
          e,
        );
      }
      throw GoogleAuthException(
        GoogleAuthErrorType.unknown,
        e.message ?? 'Unknown platform error',
        e,
      );
    } catch (e) {
      debugPrint('[GoogleAuth] Unknown error: $e');
      throw GoogleAuthException(
        GoogleAuthErrorType.unknown,
        e.toString(),
        e,
      );
    }
  }

  // ─── تسجيل الدخول الصامت (Silent Sign-In) ───

  /// يحاول تسجيل الدخول بدون إظهار نافذة اختيار الحساب.
  /// يعمل فقط إذا كان المستخدم قد سجّل دخوله من قبل.
  /// **لا يُظهر أي UI** إذا فشل.
  Future<AuthResponse?> signInSilently() async {
    try {
      debugPrint('[GoogleAuth] Trying silent sign-in...');

      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) {
        debugPrint('[GoogleAuth] Silent sign-in: no cached user');
        return null;
      }

      debugPrint('[GoogleAuth] Silent sign-in: got cached user');
      return await _authenticateWithSupabase(googleUser);
    } catch (e) {
      debugPrint('[GoogleAuth] Silent sign-in failed: $e');
      return null;
    }
  }

  // ─── تبديل الحساب ───

  Future<AuthResponse?> switchAccount() async {
    try {
      debugPrint('[GoogleAuth] Switching account...');

      try {
        await _googleSignIn.disconnect();
      } catch (_) {}
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      await _supabase.auth.signOut();

      return await signInWithGoogle();
    } catch (e) {
      debugPrint('[GoogleAuth] Switch account failed: $e');
      rethrow;
    }
  }

  // ─── المصادقة مع Supabase ───

  Future<AuthResponse> _authenticateWithSupabase(
      GoogleSignInAccount googleUser) async {
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw GoogleAuthException(
        GoogleAuthErrorType.noIdToken,
        'Missing ID token from Google',
      );
    }

    debugPrint('[GoogleAuth] Got tokens, signing into Supabase...');

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    debugPrint(
        '[GoogleAuth] Supabase sign-in successful: ${response.user?.email}');

    return response;
  }

  // ─── معلومات المستخدم ───

  GoogleSignInAccount? get currentGoogleUser => _googleSignIn.currentUser;

  String? get displayName => _googleSignIn.currentUser?.displayName;

  String? get email => _googleSignIn.currentUser?.email;

  String? get photoUrl => _googleSignIn.currentUser?.photoUrl;

  bool get isSignedIn => _supabase.auth.currentUser != null;

  Future<bool> isAvailable() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (_) {
      return false;
    }
  }

  // ─── تسجيل الخروج ───

  /// تسجيل خروج عادي (يبقي الحساب محفوظًا على الجهاز).
  Future<void> signOut() async {
    try {
      debugPrint('[GoogleAuth] Signing out...');
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
      debugPrint('[GoogleAuth] Signed out');
    } catch (e) {
      debugPrint('[GoogleAuth] Sign out error: $e');
    }
  }

  /// قطع الاتصال بالكامل (يلغي صلاحيات التطبيق من Google).
  Future<void> disconnect() async {
    try {
      debugPrint('[GoogleAuth] Disconnecting...');
      await _googleSignIn.disconnect();
      await _supabase.auth.signOut();
      debugPrint('[GoogleAuth] Disconnected');
    } catch (e) {
      debugPrint('[GoogleAuth] Disconnect error: $e');
    }
  }
}