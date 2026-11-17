import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'dart:math';

/// Service for encryption and cryptographic operations
class EncryptionService {
  /// Generate random encryption key
  static Uint8List generateKey({int length = 32}) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (i) => random.nextInt(256)),
    );
  }

  /// Generate random IV (Initialization Vector)
  static Uint8List generateIV({int length = 16}) {
    return generateKey(length: length);
  }

  /// Hash data using SHA-256
  static String hashSHA256(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Hash data using SHA-512
  static String hashSHA512(String data) {
    final bytes = utf8.encode(data);
    final digest = sha512.convert(bytes);
    return digest.toString();
  }

  /// Encrypt data using AES-256-CBC
  static Uint8List encryptAES(
    String plainText,
    Uint8List key,
    Uint8List iv,
  ) {
    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );

    final params = PaddedBlockCipherParameters(
      ParametersWithIV(KeyParameter(key), iv),
      null,
    );

    cipher.init(true, params);

    final plainBytes = Uint8List.fromList(utf8.encode(plainText));
    return cipher.process(plainBytes);
  }

  /// Decrypt data using AES-256-CBC
  static String decryptAES(
    Uint8List cipherText,
    Uint8List key,
    Uint8List iv,
  ) {
    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );

    final params = PaddedBlockCipherParameters(
      ParametersWithIV(KeyParameter(key), iv),
      null,
    );

    cipher.init(false, params);

    final decrypted = cipher.process(cipherText);
    return utf8.decode(decrypted);
  }

  /// Generate secure random token
  static String generateSecureToken({int length = 32}) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Verify data integrity using HMAC
  static bool verifyHMAC(
    String data,
    String receivedHmac,
    String secret,
  ) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString() == receivedHmac;
  }

  /// Generate HMAC for data
  static String generateHMAC(String data, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }
}
