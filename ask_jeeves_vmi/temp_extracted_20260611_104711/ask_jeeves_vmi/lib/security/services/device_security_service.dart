import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' if (dart.library.html) 'dart:html';

/// Service for device security checks
class DeviceSecurityService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Check if device is jailbroken/rooted using file system checks
  Future<bool> isDeviceCompromised() async {
    try {
      // Web platform doesn't support these checks
      if (kIsWeb) {
        return false;
      }
      
      if (Platform.isAndroid) {
        return await _checkAndroidRoot();
      } else if (Platform.isIOS) {
        return await _checkIOSJailbreak();
      }
      return false;
    } catch (e) {
      debugPrint('Error checking device compromise: $e');
      return false;
    }
  }

  /// Check for Android root indicators
  Future<bool> _checkAndroidRoot() async {
    if (kIsWeb) return false;
    
    try {
      // Check for common root files
      final rootFiles = [
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

      for (final path in rootFiles) {
        if (await File(path).exists()) {
          return true;
        }
      }

      // Check for common root apps
      final rootApps = [
        '/system/app/SuperSU',
        '/system/app/Kinguser',
        '/system/app/Magisk',
      ];

      for (final path in rootApps) {
        if (await Directory(path).exists()) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking Android root: $e');
      return false;
    }
  }

  /// Check for iOS jailbreak indicators
  Future<bool> _checkIOSJailbreak() async {
    if (kIsWeb) return false;
    
    try {
      // Check for common jailbreak files
      final jailbreakFiles = [
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/private/var/lib/apt/',
        '/private/var/lib/cydia',
        '/private/var/mobile/Library/SBSettings/Themes',
        '/private/var/tmp/cydia.log',
        '/private/var/stash',
      ];

      for (final path in jailbreakFiles) {
        if (await File(path).exists() || await Directory(path).exists()) {
          return true;
        }
      }

      // Try to write to a restricted location (jailbroken devices allow this)
      try {
        final testFile = File('/private/jailbreak_test.txt');
        await testFile.writeAsString('test');
        await testFile.delete();
        return true; // If we can write here, device is jailbroken
      } catch (e) {
        // Expected to fail on non-jailbroken devices
      }

      return false;
    } catch (e) {
      debugPrint('Error checking iOS jailbreak: $e');
      return false;
    }
  }

  /// Get device information (NO hardware identifiers)
  /// 
  /// IMPORTANT: This method does NOT return:
  /// - MAC addresses
  /// - Serial numbers
  /// - IMEI/MEID
  /// - androidId (unreliable, can change)
  /// - identifierForVendor (can change on iOS)
  /// 
  /// Use DeviceIdentityService for app-issued device IDs instead
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return {
          'platform': 'Web',
          'browserName': webInfo.browserName.name,
          'userAgent': webInfo.userAgent ?? 'Unknown',
          'vendor': webInfo.vendor ?? 'Unknown',
          'isPhysicalDevice': true, // Web is always considered "physical"
        };
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          // NOTE: androidId removed - use app-issued device ID instead
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemVersion': iosInfo.systemVersion,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
          // NOTE: identifierForVendor removed - use app-issued device ID instead
        };
      }
      return {'platform': 'Unknown'};
    } catch (e) {
      debugPrint('Error getting device info: $e');
      return {'error': e.toString()};
    }
  }

  /// Calculate device trust score (0-100)
  Future<int> calculateTrustScore() async {
    int score = 100;

    // Check if device is compromised
    final isCompromised = await isDeviceCompromised();
    if (isCompromised) {
      score -= 50; // Major penalty for jailbreak/root
    }

    // Check if physical device
    final deviceInfo = await getDeviceInfo();
    final isPhysical = deviceInfo['isPhysicalDevice'] as bool? ?? true;
    if (!isPhysical) {
      score -= 20; // Penalty for emulator/simulator
    }

    // Check OS version (simplified - in production, check against known vulnerable versions)
    if (!kIsWeb && Platform.isAndroid) {
      final sdkInt = deviceInfo['sdkInt'] as int? ?? 0;
      if (sdkInt < 26) {
        score -= 15; // Penalty for old Android version
      }
    }

    return score.clamp(0, 100);
  }

  /// Perform comprehensive device verification
  Future<DeviceVerificationResult> verifyDevice() async {
    final isCompromised = await isDeviceCompromised();
    final deviceInfo = await getDeviceInfo();
    final trustScore = await calculateTrustScore();

    return DeviceVerificationResult(
      isCompromised: isCompromised,
      deviceInfo: deviceInfo,
      trustScore: trustScore,
      isPassed: trustScore >= 70 && !isCompromised,
    );
  }
}

/// Result of device verification
class DeviceVerificationResult {
  final bool isCompromised;
  final Map<String, dynamic> deviceInfo;
  final int trustScore;
  final bool isPassed;

  DeviceVerificationResult({
    required this.isCompromised,
    required this.deviceInfo,
    required this.trustScore,
    required this.isPassed,
  });
}
