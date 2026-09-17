import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage_keys.dart';

class AutoLockManager {
  final FlutterSecureStorage _storage;
  AutoLockManager(this._storage);

  /// تعيين مهلة القفل بالدقائق.
  Future<void> setTimeout(Duration timeout) async {
    await _storage.write(
      key: SecureStorageKeys.autoLockTimeout,
      value: timeout.inMinutes.toString(),
    );
  }

  /// الحصول على مهلة القفل (0 = فوري).
  Future<Duration> getTimeout() async {
    final str = await _storage.read(key: SecureStorageKeys.autoLockTimeout);
    if (str == null) return Duration.zero;
    return Duration(minutes: int.tryParse(str) ?? 0);
  }
}