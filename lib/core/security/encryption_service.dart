import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage_keys.dart';

class EncryptionService {
  final FlutterSecureStorage _storage;
  EncryptionService(this._storage);

  /// توليد مفتاح تشفير جديد وحفظه.
  Future<encrypt.Key> _generateKey() async {
    final key = encrypt.Key.fromSecureRandom(32);
    await _storage.write(key: SecureStorageKeys.encryptionKey, value: key.base64);
    return key;
  }

  /// الحصول على مفتاح التشفير أو إنشاؤه.
  Future<encrypt.Key> getKey() async {
    final existing = await _storage.read(key: SecureStorageKeys.encryptionKey);
    if (existing != null) {
      return encrypt.Key.fromBase64(existing);
    }
    return _generateKey();
  }

  /// تشفير نص.
  Future<String> encryptText(String plainText) async {
    final key = await getKey();
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final iv = encrypt.IV.fromLength(16);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// فك تشفير نص.
  Future<String> decryptText(String cipherText) async {
    final parts = cipherText.split(':');
    if (parts.length != 2) throw FormatException('Invalid cipherText');
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    final key = await getKey();
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}