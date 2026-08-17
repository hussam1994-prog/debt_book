import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'secure_storage_keys.dart';

class DeviceIdentity {
  final FlutterSecureStorage _storage;
  final _uuid = const Uuid();

  DeviceIdentity(this._storage);

  /// الحصول على معرف الجهاز الفريد أو إنشاؤه.
  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: SecureStorageKeys.deviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final newId = _uuid.v4();
    await _storage.write(key: SecureStorageKeys.deviceId, value: newId);
    return newId;
  }
}