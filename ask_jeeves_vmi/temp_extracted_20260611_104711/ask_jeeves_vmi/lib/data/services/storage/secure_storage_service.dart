import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Service for securely storing sensitive data like tokens and API keys
/// Uses platform-specific secure storage (Keychain on iOS, KeyStore on Android)
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  final _logger = Logger();

  // Storage Keys
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyApiKey = 'api_key';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyDeviceId = 'device_id';
  static const String _keyEncryptionKey = 'encryption_key';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyLastLoginTime = 'last_login_time';
  static const String _keySessionToken = 'session_token';

  // ==================== Token Management ====================

  /// Store access token
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _keyAccessToken, value: token);
      _logger.i('Access token saved successfully');
    } catch (e) {
      _logger.e('Error saving access token: $e');
      rethrow;
    }
  }

  /// Retrieve access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (e) {
      _logger.e('Error reading access token: $e');
      return null;
    }
  }

  /// Store refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _keyRefreshToken, value: token);
      _logger.i('Refresh token saved successfully');
    } catch (e) {
      _logger.e('Error saving refresh token: $e');
      rethrow;
    }
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e) {
      _logger.e('Error reading refresh token: $e');
      return null;
    }
  }

  /// Store session token
  Future<void> saveSessionToken(String token) async {
    try {
      await _storage.write(key: _keySessionToken, value: token);
      _logger.i('Session token saved successfully');
    } catch (e) {
      _logger.e('Error saving session token: $e');
      rethrow;
    }
  }

  /// Retrieve session token
  Future<String?> getSessionToken() async {
    try {
      return await _storage.read(key: _keySessionToken);
    } catch (e) {
      _logger.e('Error reading session token: $e');
      return null;
    }
  }

  // ==================== API Key Management ====================

  /// Store API key
  Future<void> saveApiKey(String apiKey) async {
    try {
      await _storage.write(key: _keyApiKey, value: apiKey);
      _logger.i('API key saved successfully');
    } catch (e) {
      _logger.e('Error saving API key: $e');
      rethrow;
    }
  }

  /// Retrieve API key
  Future<String?> getApiKey() async {
    try {
      return await _storage.read(key: _keyApiKey);
    } catch (e) {
      _logger.e('Error reading API key: $e');
      return null;
    }
  }

  // ==================== User Data Management ====================

  /// Store user ID
  Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _keyUserId, value: userId);
      _logger.i('User ID saved successfully');
    } catch (e) {
      _logger.e('Error saving user ID: $e');
      rethrow;
    }
  }

  /// Retrieve user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _keyUserId);
    } catch (e) {
      _logger.e('Error reading user ID: $e');
      return null;
    }
  }

  /// Store user email
  Future<void> saveUserEmail(String email) async {
    try {
      await _storage.write(key: _keyUserEmail, value: email);
      _logger.i('User email saved successfully');
    } catch (e) {
      _logger.e('Error saving user email: $e');
      rethrow;
    }
  }

  /// Retrieve user email
  Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: _keyUserEmail);
    } catch (e) {
      _logger.e('Error reading user email: $e');
      return null;
    }
  }

  // ==================== Device & Security Management ====================

  /// Store device ID
  Future<void> saveDeviceId(String deviceId) async {
    try {
      await _storage.write(key: _keyDeviceId, value: deviceId);
      _logger.i('Device ID saved successfully');
    } catch (e) {
      _logger.e('Error saving device ID: $e');
      rethrow;
    }
  }

  /// Retrieve device ID
  Future<String?> getDeviceId() async {
    try {
      return await _storage.read(key: _keyDeviceId);
    } catch (e) {
      _logger.e('Error reading device ID: $e');
      return null;
    }
  }

  /// Store encryption key
  Future<void> saveEncryptionKey(String key) async {
    try {
      await _storage.write(key: _keyEncryptionKey, value: key);
      _logger.i('Encryption key saved successfully');
    } catch (e) {
      _logger.e('Error saving encryption key: $e');
      rethrow;
    }
  }

  /// Retrieve encryption key
  Future<String?> getEncryptionKey() async {
    try {
      return await _storage.read(key: _keyEncryptionKey);
    } catch (e) {
      _logger.e('Error reading encryption key: $e');
      return null;
    }
  }

  /// Store biometric enabled status
  Future<void> saveBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
      _logger.i('Biometric status saved successfully');
    } catch (e) {
      _logger.e('Error saving biometric status: $e');
      rethrow;
    }
  }

  /// Retrieve biometric enabled status
  Future<bool> getBiometricEnabled() async {
    try {
      final value = await _storage.read(key: _keyBiometricEnabled);
      return value == 'true';
    } catch (e) {
      _logger.e('Error reading biometric status: $e');
      return false;
    }
  }

  /// Store last login time
  Future<void> saveLastLoginTime(DateTime time) async {
    try {
      await _storage.write(key: _keyLastLoginTime, value: time.toIso8601String());
      _logger.i('Last login time saved successfully');
    } catch (e) {
      _logger.e('Error saving last login time: $e');
      rethrow;
    }
  }

  /// Retrieve last login time
  Future<DateTime?> getLastLoginTime() async {
    try {
      final value = await _storage.read(key: _keyLastLoginTime);
      return value != null ? DateTime.parse(value) : null;
    } catch (e) {
      _logger.e('Error reading last login time: $e');
      return null;
    }
  }

  // ==================== Custom Key-Value Storage ====================

  /// Store any custom key-value pair
  Future<void> saveCustomValue(String key, String value) async {
    try {
      // Try to delete first to avoid duplicate key errors
      await _storage.delete(key: key);
      await _storage.write(key: key, value: value);
      _logger.i('Custom value saved for key: $key');
    } catch (e) {
      _logger.e('Error saving custom value for key $key: $e');
      // Don't rethrow if it's just a duplicate key error
      if (!e.toString().contains('already exists')) {
        rethrow;
      }
    }
  }

  /// Retrieve custom value by key
  Future<String?> getCustomValue(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      _logger.e('Error reading custom value for key $key: $e');
      return null;
    }
  }

  /// Delete custom value by key
  Future<void> deleteCustomValue(String key) async {
    try {
      await _storage.delete(key: key);
      _logger.i('Custom value deleted for key: $key');
    } catch (e) {
      _logger.e('Error deleting custom value for key $key: $e');
      rethrow;
    }
  }

  // ==================== Batch Operations ====================

  /// Save all authentication data at once
  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String userId,
    String? email,
    String? deviceId,
  }) async {
    try {
      await Future.wait([
        saveAccessToken(accessToken),
        saveRefreshToken(refreshToken),
        saveUserId(userId),
        if (email != null) saveUserEmail(email),
        if (deviceId != null) saveDeviceId(deviceId),
        saveLastLoginTime(DateTime.now()),
      ]);
      _logger.i('All auth data saved successfully');
    } catch (e) {
      _logger.e('Error saving auth data: $e');
      rethrow;
    }
  }

  /// Retrieve all authentication data
  Future<Map<String, String?>> getAuthData() async {
    try {
      final results = await Future.wait([
        getAccessToken(),
        getRefreshToken(),
        getUserId(),
        getUserEmail(),
        getDeviceId(),
      ]);

      return {
        'accessToken': results[0],
        'refreshToken': results[1],
        'userId': results[2],
        'email': results[3],
        'deviceId': results[4],
      };
    } catch (e) {
      _logger.e('Error reading auth data: $e');
      return {};
    }
  }

  // ==================== Utility Methods ====================

  /// Check if user is authenticated (has valid tokens)
  Future<bool> isAuthenticated() async {
    try {
      final accessToken = await getAccessToken();
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking authentication status: $e');
      return false;
    }
  }

  /// Clear all authentication data (logout)
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyAccessToken),
        _storage.delete(key: _keyRefreshToken),
        _storage.delete(key: _keySessionToken),
        _storage.delete(key: _keyUserId),
        _storage.delete(key: _keyUserEmail),
        _storage.delete(key: _keyLastLoginTime),
      ]);
      _logger.i('All auth data cleared successfully');
    } catch (e) {
      _logger.e('Error clearing auth data: $e');
      rethrow;
    }
  }

  /// Clear all stored data (complete reset)
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      _logger.i('All secure storage cleared successfully');
    } catch (e) {
      _logger.e('Error clearing all secure storage: $e');
      rethrow;
    }
  }

  /// Get all stored keys (for debugging)
  Future<Map<String, String>> getAllValues() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      _logger.e('Error reading all values: $e');
      return {};
    }
  }

  /// Check if a specific key exists
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      _logger.e('Error checking key existence: $e');
      return false;
    }
  }

  // ==================== Generic Read/Write/Delete Methods ====================

  /// Generic read method (wrapper for getCustomValue)
  Future<String?> read(String key) async {
    return await getCustomValue(key);
  }

  /// Generic write method (wrapper for saveCustomValue)
  Future<void> write(String key, String value) async {
    await saveCustomValue(key, value);
  }

  /// Generic delete method (wrapper for deleteCustomValue)
  Future<void> delete(String key) async {
    await deleteCustomValue(key);
  }

  /// Delete all data (wrapper for clearAll)
  Future<void> deleteAll(String s) async {
    await clearAll();
  }
}

// ==================== Riverpod Provider ====================


/// Provider for SecureStorageService
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
