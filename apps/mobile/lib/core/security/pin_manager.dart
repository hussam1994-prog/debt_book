import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage_keys.dart';

class PinManager {
  final FlutterSecureStorage _storage;

  PinManager(this._storage);

  /// تعيين PIN جديد (يُخزن hash فقط).
  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _storage.write(key: SecureStorageKeys.pin, value: hash);
  }

  /// التحقق من صحة PIN.
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: SecureStorageKeys.pin);
    if (storedHash == null) return false;
    return storedHash == _hashPin(pin);
  }

  /// هل يوجد PIN؟
  Future<bool> hasPin() async {
    final stored = await _storage.read(key: SecureStorageKeys.pin);
    return stored != null && stored.isNotEmpty;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}