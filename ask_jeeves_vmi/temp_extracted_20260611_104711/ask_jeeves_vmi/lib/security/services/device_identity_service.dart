import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';

/// Service for managing device identity using hardware identifiers
/// 
/// Priority order for device identification:
/// 1. Android ID (Android) - Unique per device and app
/// 2. identifierForVendor (iOS) - Unique per vendor
/// 3. Hardware identifiers combined with device info
/// 
/// Note: MAC address is restricted on modern Android/iOS for privacy
/// We use a combination of available hardware identifiers instead
class DeviceIdentityService {
  final SecureStorageService _storage;
  static const String _deviceIdKey = 'hardware_device_id';
  static const String _deviceNameKey = 'device_name';

  DeviceIdentityService(this._storage);

  /// Get unique hardware-based device ID
  /// This creates a consistent ID based on device hardware
  Future<String> getOrCreateDeviceId() async {
    try {
      // Try to get existing device ID from storage
      String? storedDeviceId = await _storage.read(_deviceIdKey);

      if (storedDeviceId != null && storedDeviceId.isNotEmpty) {
        debugPrint('[DeviceIdentity] Using stored device ID: ${storedDeviceId.substring(0, 8)}...');
        return storedDeviceId;
      }

      // Generate hardware-based device ID
      final deviceId = await _generateHardwareDeviceId();
      
      // Store it for future use
      await _storage.write(_deviceIdKey, deviceId);
      debugPrint('[DeviceIdentity] Created hardware-based device ID: ${deviceId.substring(0, 8)}...');

      return deviceId;
    } catch (e) {
      debugPrint('[DeviceIdentity] Error getting device ID: $e');
      rethrow;
    }
  }

  /// Get the raw hardware identifier (Android ID or iOS Vendor ID)
  /// This is the actual unique identifier from the device
  Future<String> getHardwareIdentifier() async {
    final deviceInfo = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Android ID - This is unique per device and app
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // Vendor ID - This is unique per vendor (developer)
        return iosInfo.identifierForVendor ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      debugPrint('[DeviceIdentity] Error getting hardware identifier: $e');
      return 'unknown';
    }
  }

  /// Generate a unique device ID based on hardware identifiers
  Future<String> _generateHardwareDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String uniqueId = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        
        // Android ID - Unique per device and app installation
        // This is the most reliable identifier on Android
        final androidId = androidInfo.id; // This is Android ID
        
        // Combine with other identifiers for extra uniqueness
        final manufacturer = androidInfo.manufacturer;
        final model = androidInfo.model;
        final hardware = androidInfo.hardware;
        final board = androidInfo.board;
        final fingerprint = androidInfo.fingerprint;
        
        // Create a unique string from available identifiers
        uniqueId = '$androidId-$manufacturer-$model-$hardware-$board-${fingerprint.hashCode}';
        
        debugPrint('[DeviceIdentity] Android identifiers:');
        debugPrint('  Android ID: $androidId');
        debugPrint('  Manufacturer: $manufacturer');
        debugPrint('  Model: $model');
        debugPrint('  Hardware: $hardware');
        
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        
        // identifierForVendor - Unique per vendor (app developer)
        // This persists across app reinstalls unless all apps from vendor are deleted
        final identifierForVendor = iosInfo.identifierForVendor ?? '';
        
        // Combine with device info
        final model = iosInfo.model;
        final systemVersion = iosInfo.systemVersion;
        final name = iosInfo.name;
        
        uniqueId = '$identifierForVendor-$model-$systemVersion-${name.hashCode}';
        
        debugPrint('[DeviceIdentity] iOS identifiers:');
        debugPrint('  Vendor ID: $identifierForVendor');
        debugPrint('  Model: $model');
        debugPrint('  System: $systemVersion');
      }

      // Hash the unique string to create a consistent device ID
      final bytes = utf8.encode(uniqueId);
      final digest = sha256.convert(bytes);
      final deviceId = digest.toString();

      return deviceId;
    } catch (e) {
      debugPrint('[DeviceIdentity] Error generating hardware ID: $e');
      rethrow;
    }
  }

  /// Get or create user-friendly device name
  Future<String> getOrCreateDeviceName() async {
    try {
      String? deviceName = await _storage.read(_deviceNameKey);

      if (deviceName == null || deviceName.isEmpty) {
        // Generate default name
        deviceName = 'Mobile Device ${DateTime.now().millisecondsSinceEpoch % 10000}';
        await _storage.write(_deviceNameKey, deviceName);
      }

      return deviceName;
    } catch (e) {
      debugPrint('[DeviceIdentity] Error managing device name: $e');
      return 'Unknown Device';
    }
  }

  /// Update device name (user can customize)
  Future<void> updateDeviceName(String name) async {
    try {
      await _storage.write(_deviceNameKey, name);
      debugPrint('[DeviceIdentity] Updated device name: $name');
    } catch (e) {
      debugPrint('[DeviceIdentity] Error updating device name: $e');
    }
  }

  /// Clear device identity (for logout/reset)
  Future<void> clearDeviceIdentity() async {
    try {
      await _storage.delete(_deviceIdKey);
      await _storage.delete(_deviceNameKey);
      debugPrint('[DeviceIdentity] Cleared device identity');
    } catch (e) {
      debugPrint('[DeviceIdentity] Error clearing device identity: $e');
    }
  }

  /// Get device identity info for backend registration
  /// Backend should validate this via device attestation APIs
  Future<Map<String, String>> getDeviceIdentityInfo() async {
    final deviceId = await getOrCreateDeviceId();
    final deviceName = await getOrCreateDeviceName();
    final hardwareId = await getHardwareIdentifier();

    return {
      'device_id': deviceId, // Hashed hardware ID
      'hardware_id': hardwareId, // Raw Android ID or iOS Vendor ID
      'device_name': deviceName,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Provider for device identity service

final deviceIdentityServiceProvider = Provider<DeviceIdentityService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return DeviceIdentityService(storage);
});
