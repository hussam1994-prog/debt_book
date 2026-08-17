import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class SecurityService {
  final FlutterSecureStorage _storage;
  final _uuid = const Uuid();

  SecurityService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ---- PIN Management ----

  /// تعيين PIN جديد (يُخزن hash فقط)
  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _storage.write(key: 'pin_hash', value: hash);
  }

  /// التحقق من صحة PIN
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: 'pin_hash');
    if (storedHash == null) return false;
    return storedHash == _hashPin(pin);
  }

  /// هل يوجد PIN؟
  Future<bool> hasPin() async {
    final stored = await _storage.read(key: 'pin_hash');
    return stored != null && stored.isNotEmpty;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ---- Device Identity ----

  /// الحصول على معرف الجهاز الفريد أو إنشاؤه
  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: 'device_id');
    if (existing != null && existing.isNotEmpty) return existing;
    final newId = _uuid.v4();
    await _storage.write(key: 'device_id', value: newId);
    return newId;
  }

  // ---- Encryption (للنسخ الاحتياطي والبيانات الحساسة) ----

  /// توليد مفتاح تشفير وحفظه
  Future<encrypt.Key> _getOrCreateEncryptionKey() async {
    final existing = await _storage.read(key: 'encryption_key');
    if (existing != null && existing.isNotEmpty) {
      return encrypt.Key.fromBase64(existing);
    }
    final key = encrypt.Key.fromSecureRandom(32);
    await _storage.write(key: 'encryption_key', value: key.base64);
    return key;
  }

  /// تشفير نص
  Future<String> encryptText(String plainText) async {
    final key = await _getOrCreateEncryptionKey();
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final iv = encrypt.IV.fromLength(16);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// فك تشفير نص
  Future<String> decryptText(String cipherText) async {
    final parts = cipherText.split(':');
    if (parts.length != 2) throw const FormatException('Invalid cipherText');
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    final key = await _getOrCreateEncryptionKey();
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}