import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Device Attestation Service
/// Performs comprehensive device security checks and generates trust scores
class DeviceAttestationService {
  final FlutterSecureStorage _secureStorage;
  final DeviceInfoPlugin _deviceInfo;
  
  static const String _deviceIdKey = 'device_id';
  
  DeviceAttestationService({
    FlutterSecureStorage? secureStorage,
    DeviceInfoPlugin? deviceInfo,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// Generate or retrieve persistent device ID
  Future<String> getDeviceId() async {
    String? deviceId = await _secureStorage.read(key: _deviceIdKey);
    
    if (deviceId == null) {
      deviceId = _generateDeviceId();
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    }
    
    return deviceId;
  }

  /// Perform comprehensive device attestation
  Future<DeviceAttestationResult> attestDevice() async {
    try {
      // Check for jailbreak/root (simplified - in production use dedicated package)
      final isJailbroken = await _checkJailbreak();
      final isDeveloperMode = await _checkDeveloperMode();
      
      // Get device information
      final deviceInfo = await _getDeviceInfo();
      
      // Get app information
      final packageInfo = await PackageInfo.fromPlatform();
      
      // Generate device fingerprint
      final fingerprint = await _generateDeviceFingerprint(deviceInfo);
      
      // Calculate trust score
      final trustScore = _calculateTrustScore(
        isJailbroken: isJailbroken,
        isDeveloperMode: isDeveloperMode,
        deviceInfo: deviceInfo,
      );
      
      return DeviceAttestationResult(
        deviceId: await getDeviceId(),
        fingerprint: fingerprint,
        isJailbroken: isJailbroken,
        isDeveloperMode: isDeveloperMode,
        osVersion: deviceInfo['osVersion'] as String,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        trustScore: trustScore,
        attestationTime: DateTime.now(),
        deviceInfo: deviceInfo,
      );
    } catch (e) {
      throw DeviceAttestationException('Failed to attest device: $e');
    }
  }

  /// Generate unique device ID (app-scoped)
  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = List.generate(16, (_) => DateTime.now().microsecondsSinceEpoch % 256);
    final combined = '$timestamp-${random.join()}';
    return sha256.convert(utf8.encode(combined)).toString();
  }

  /// Get platform-specific device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return {
        'platform': 'android',
        'osVersion': androidInfo.version.release,
        'sdkInt': androidInfo.version.sdkInt,
        'manufacturer': androidInfo.manufacturer,
        'model': androidInfo.model,
        'brand': androidInfo.brand,
        'isPhysicalDevice': androidInfo.isPhysicalDevice,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return {
        'platform': 'ios',
        'osVersion': iosInfo.systemVersion,
        'model': iosInfo.model,
        'name': iosInfo.name,
        'isPhysicalDevice': iosInfo.isPhysicalDevice,
      };
    }
    throw UnsupportedError('Platform not supported');
  }

  /// Generate device fingerprint (non-invasive)
  Future<String> _generateDeviceFingerprint(Map<String, dynamic> deviceInfo) async {
    final components = [
      deviceInfo['platform'],
      deviceInfo['osVersion'],
      deviceInfo['model'],
      deviceInfo['manufacturer'] ?? deviceInfo['name'],
    ];
    
    final fingerprintData = components.join('|');
    return sha256.convert(utf8.encode(fingerprintData)).toString();
  }

  /// Check for jailbreak/root (simplified)
  Future<bool> _checkJailbreak() async {
    if (Platform.isIOS) {
      // Check for common jailbreak indicators
      final jailbreakPaths = [
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/private/var/lib/apt/',
      ];
      
      for (final path in jailbreakPaths) {
        if (await File(path).exists()) {
          return true;
        }
      }
    } else if (Platform.isAndroid) {
      // Check for common root indicators
      final rootPaths = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
      ];
      
      for (final path in rootPaths) {
        if (await File(path).exists()) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Check for developer mode
  Future<bool> _checkDeveloperMode() async {
    // Simplified check - in production, use platform-specific APIs
    return kDebugMode;
  }

  /// Calculate device trust score (0-100)
  int _calculateTrustScore({
    required bool isJailbroken,
    required bool isDeveloperMode,
    required Map<String, dynamic> deviceInfo,
  }) {
    int score = 100;
    
    // Critical violations
    if (isJailbroken) score -= 100; // Instant fail
    
    // Major violations
    if (isDeveloperMode) score -= 30;
    if (!(deviceInfo['isPhysicalDevice'] as bool)) score -= 50; // Emulator
    
    // Minor violations
    final osVersion = deviceInfo['osVersion'] as String;
    if (_isOsVersionOutdated(osVersion, deviceInfo['platform'] as String)) {
      score -= 20;
    }
    
    return score.clamp(0, 100);
  }

  bool _isOsVersionOutdated(String version, String platform) {
    // Simplified version check
    if (platform == 'android') {
      final sdkInt = int.tryParse(version) ?? 0;
      return sdkInt < 26; // Android 8.0+
    } else if (platform == 'ios') {
      final majorVersion = int.tryParse(version.split('.').first) ?? 0;
      return majorVersion < 14; // iOS 14+
    }
    return false;
  }
}

/// Device Attestation Result
class DeviceAttestationResult {
  final String deviceId;
  final String fingerprint;
  final bool isJailbroken;
  final bool isDeveloperMode;
  final String osVersion;
  final String appVersion;
  final String buildNumber;
  final int trustScore;
  final DateTime attestationTime;
  final Map<String, dynamic> deviceInfo;

  DeviceAttestationResult({
    required this.deviceId,
    required this.fingerprint,
    required this.isJailbroken,
    required this.isDeveloperMode,
    required this.osVersion,
    required this.appVersion,
    required this.buildNumber,
    required this.trustScore,
    required this.attestationTime,
    required this.deviceInfo,
  });

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'fingerprint': fingerprint,
    'is_jailbroken': isJailbroken,
    'is_developer_mode': isDeveloperMode,
    'os_version': osVersion,
    'app_version': appVersion,
    'build_number': buildNumber,
    'trust_score': trustScore,
    'attestation_time': attestationTime.toIso8601String(),
    'device_info': deviceInfo,
  };

  bool get isPassed => trustScore >= 70 && !isJailbroken;
}

class DeviceAttestationException implements Exception {
  final String message;
  DeviceAttestationException(this.message);
  
  @override
  String toString() => 'DeviceAttestationException: $message';
}

// Provider
final deviceAttestationServiceProvider = Provider<DeviceAttestationService>((ref) {
  return DeviceAttestationService();
});
