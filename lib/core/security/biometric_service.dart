import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth;

  BiometricService(this._auth);

  /// هل تتوفر المصادقة الحيوية؟
  Future<bool> isBiometricAvailable() async {
    return await _auth.canCheckBiometrics;
  }

  /// أنواع المصادقة المتاحة.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _auth.getAvailableBiometrics();
  }

  /// طلب المصادقة الحيوية.
  Future<bool> authenticate({
    required String reason,
    bool sticky = true,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: sticky,
          biometricOnly: false, // قد يكون PIN النظام
        ),
      );
    } catch (_) {
      return false;
    }
  }
}