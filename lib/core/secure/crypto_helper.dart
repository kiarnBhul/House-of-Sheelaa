import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Simple AES encryption helper using a key stored in platform secure storage.
/// - Key is generated once and stored under 'odoo_enc_key'
/// - Uses AES/CBC/PKCS7 with random IV per-encryption
class CryptoHelper {
  static const _storageKey = 'odoo_enc_key';
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Ensure an AES key exists and return it as an `encrypt` Key.
  static Future<Key> _getOrCreateKey() async {
    String? base64Key = await _secureStorage.read(key: _storageKey);
    if (base64Key == null) {
      // Generate 32 cryptographically secure random bytes
      final rnd = Random.secure();
      final keyBytes = Uint8List.fromList(List<int>.generate(32, (_) => rnd.nextInt(256)));
      base64Key = base64Encode(keyBytes);
      await _secureStorage.write(key: _storageKey, value: base64Key);
      if (kDebugMode) print('[CryptoHelper] Generated new encryption key');
    }
    final raw = base64Decode(base64Key);
    return Key(Uint8List.fromList(raw));
  }

  /// Encrypt a plaintext string and return base64 of IV + ciphertext
  static Future<String> encryptString(String plain) async {
    final key = await _getOrCreateKey();
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: null));
    final encrypted = encrypter.encrypt(plain, iv: iv);
    // Store as base64(iv):base64(ciphertext)
    final combined = '${base64Encode(iv.bytes)}:${encrypted.base64}';
    return combined;
  }

  /// Decrypt a base64 iv + ciphertext string produced by encryptString
  static Future<String?> decryptString(String cipher) async {
    try {
      final key = await _getOrCreateKey();
      final parts = cipher.split(':');
      if (parts.length != 2) return null;
      final iv = IV(base64Decode(parts[0]));
      final encrypted = Encrypted.fromBase64(parts[1]);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: null));
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      if (kDebugMode) print('[CryptoHelper] decrypt failed: $e');
      return null;
    }
  }
}
