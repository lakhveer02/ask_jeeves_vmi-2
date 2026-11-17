import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ask_jeeves_vmi/security/services/device_attestation_service.dart';
import 'package:ask_jeeves_vmi/security/services/device_identity_service.dart';
import 'package:ask_jeeves_vmi/security/services/biometric_service.dart';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';
import 'package:ask_jeeves_vmi/data/services/api/api_client.dart';

/// Service for registering devices with the backend API
class DeviceRegistrationService {
  final DeviceAttestationService _attestationService;
  final DeviceIdentityService _identityService;
  final BiometricService _biometricService;
  final SecureStorageService _storage;
  final ApiClient _apiClient;

  DeviceRegistrationService(
    this._attestationService,
    this._identityService,
    this._biometricService,
    this._storage,
    this._apiClient,
  );

  /// Unified device authentication - Register or Login
  /// Backend automatically determines if device is new or existing
  /// Returns device authentication response with tokens
  /// Includes automatic retry logic for server errors (500)
  Future<DeviceAuthResponse> authenticateDevice({int maxRetries = 3}) async {
    int attempt = 0;
    Duration delay = const Duration(seconds: 1);

    while (attempt < maxRetries) {
      try {
        attempt++;
        debugPrint('[DeviceAuth] Starting unified device authentication (attempt $attempt/$maxRetries)...');

        // Collect all device information
        final deviceData = await _collectDeviceData();

        debugPrint('[DeviceAuth] Device data collected:');
        debugPrint('  UUID: ${deviceData['device_uuid']}');
        debugPrint('  Model: ${deviceData['device_model']}');
        debugPrint('  OS: ${deviceData['os_name']} ${deviceData['os_version']}');
        debugPrint('  Rooted: ${deviceData['is_rooted']}');
        debugPrint('  Jailbroken: ${deviceData['is_jailbroken']}');
        debugPrint('  Biometric: ${deviceData['biometric_enabled']}');
        debugPrint('  Device Type: ${deviceData['device_type']}');
        debugPrint('  App Version: ${deviceData['app_version']}');

        // Send unified authentication request to API
        // Backend will automatically register new devices or login existing ones
        final response = await _apiClient.post(
          '/device-auth/authenticate',
          data: deviceData,
        );

        final responseData = response.data as Map<String, dynamic>;

        final isNewDevice = responseData['is_new_device'] as bool? ?? false;
        
        debugPrint('[DeviceAuth] ✅ Authentication successful');
        debugPrint('  Device ID: ${responseData['device_id']}');
        debugPrint('  Trust Score: ${responseData['trust_score']}');
        debugPrint('  Status: ${responseData['status']}');
        debugPrint('  Is New Device: $isNewDevice');
        debugPrint('  Message: ${responseData['message']}');

        // Store tokens if provided
        if (responseData['access_token'] != null) {
          await _storage.write('access_token', responseData['access_token']);
          debugPrint('[DeviceAuth] Access token stored');
        }

        if (responseData['refresh_token'] != null) {
          await _storage.write('refresh_token', responseData['refresh_token']);
          debugPrint('[DeviceAuth] Refresh token stored');
        }

        // Store device registration info
        await _storage.write('device_registered', 'true');
        await _storage.write('device_id', responseData['device_id'].toString());
        await _storage.write('device_uuid', responseData['device_uuid']); // Store device UUID
        await _storage.write('device_trust_score', responseData['trust_score'].toString());
        
        debugPrint('[DeviceAuth] Device UUID stored: ${responseData['device_uuid']}');

        return DeviceAuthResponse.fromJson(responseData);
      } catch (e) {
        debugPrint('[DeviceAuth] ❌ Error on attempt $attempt: $e');
        
        if (e is ApiException) {
          debugPrint('[DeviceAuth] Status Code: ${e.statusCode}');
          debugPrint('[DeviceAuth] Error Data: ${e.data}');
          
          // Retry only for server errors (500-599)
          if (e.statusCode >= 500 && e.statusCode < 600) {
            if (attempt < maxRetries) {
              debugPrint('[DeviceAuth] 🔄 Server error detected, retrying in ${delay.inSeconds}s...');
              debugPrint('[DeviceAuth] Possible causes:');
              debugPrint('[DeviceAuth]   - Backend service temporarily unavailable');
              debugPrint('[DeviceAuth]   - Database connection timeout');
              debugPrint('[DeviceAuth]   - Backend overloaded');
              
              await Future.delayed(delay);
              delay *= 2; // Exponential backoff: 1s, 2s, 4s
              continue; // Retry
            } else {
              debugPrint('[DeviceAuth] ❌ Max retries reached for server error');
              throw Exception(
                'Authentication service temporarily unavailable'
              );
            }
          } else {
            // Client errors (400-499) should not be retried
            debugPrint('[DeviceAuth] ❌ Client error - not retrying');
            if (e.statusCode == 400) {
              throw Exception('Invalid device data. Please contact support.');
            } else if (e.statusCode == 401) {
              throw Exception('Authentication failed. Please try again.');
            } else if (e.statusCode == 403) {
              throw Exception('Device access denied. Please contact support.');
            } else {
              throw Exception('Authentication failed: ${e.message}');
            }
          }
        }
        
        // For non-API exceptions, don't retry
        debugPrint('[DeviceAuth] ❌ Non-API error - not retrying');
        rethrow;
      }
    }

    // Should never reach here, but just in case
    throw Exception('Authentication failed after $maxRetries attempts');
  }

  /// Legacy method - now calls unified authenticateDevice()
  @Deprecated('Use authenticateDevice() instead - backend now handles both register and login')
  Future<DeviceRegistrationResponse> registerDevice() async {
    final authResponse = await authenticateDevice();
    return DeviceRegistrationResponse.fromAuthResponse(authResponse);
  }

  /// Collect all device data for registration
  Future<Map<String, dynamic>> _collectDeviceData() async {
    // Get device attestation
    final attestation = await _attestationService.attestDevice();

    // Get device identity
    final deviceUuid = await _identityService.getOrCreateDeviceId();
    final deviceName = await _identityService.getOrCreateDeviceName();

    // Get package info
    final packageInfo = await PackageInfo.fromPlatform();

    // Get device info
    final deviceInfoPlugin = DeviceInfoPlugin();
    String deviceModel = 'Unknown';
    String osName = 'Unknown';
    String osVersion = 'Unknown';
    String deviceType = 'mobile';
    bool isRooted = false;
    bool isJailbroken = false;

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      osName = 'Android'; // Must match API validation
      osVersion = androidInfo.version.release;
      // API only accepts: tablet, mobile, desktop, laptop, server, iot, wearable, tv, automotive, gaming, other
      deviceType = 'mobile'; // Always use 'mobile' for Android devices
      isRooted = attestation.isJailbroken; // Using attestation result
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      deviceModel = iosInfo.model;
      // Check if iPad
      if (iosInfo.model.toLowerCase().contains('ipad')) {
        osName = 'iPadOS'; // Must match API validation
        deviceType = 'tablet'; // iPad is a tablet
      } else {
        osName = 'iOS'; // Must match API validation
        deviceType = 'mobile'; // iPhone is mobile
      }
      osVersion = iosInfo.systemVersion;
      isJailbroken = attestation.isJailbroken; // Using attestation result
    }

    // Check if biometrics are enabled
    final biometricEnabled = await _biometricService.isBiometricAvailable();

    // Get available biometric types
    final availableBiometrics = await _biometricService.getAvailableBiometrics();
    final biometricTypes = availableBiometrics.map((type) {
      return type.toString().split('.').last;
    }).toList();

    return {
      'device_name': deviceName,
      'device_type': deviceType,
      'device_uuid': deviceUuid,
      'device_model': deviceModel,
      'os_name': osName,
      'os_version': osVersion,
      'app_version': packageInfo.version,
      // Remove browser fields for mobile - they're optional and empty strings might cause issues
      // 'browser': '', 
      // 'browser_version': '',
      'user_agent': _generateUserAgent(osName, osVersion, deviceModel),
      'is_rooted': isRooted,
      'is_jailbroken': isJailbroken,
      'biometric_enabled': biometricEnabled,
      'device_metadata': {
        'trust_score': attestation.trustScore,
        'fingerprint': attestation.fingerprint,
        'is_developer_mode': attestation.isDeveloperMode,
        'build_number': packageInfo.buildNumber,
        'biometric_types': biometricTypes,
        'platform': Platform.operatingSystem,
        'platform_version': Platform.operatingSystemVersion,
      },
    };
  }

  /// Generate user agent string
  String _generateUserAgent(String osName, String osVersion, String deviceModel) {
    return 'AskJeevesVault/$osName $osVersion ($deviceModel)';
  }

  /// Check if device is already registered
  Future<bool> isDeviceRegistered() async {
    final registered = await _storage.read('device_registered');
    return registered == 'true';
  }

  /// Get stored device ID
  Future<String?> getStoredDeviceId() async {
    return await _storage.read('device_id');
  }

  /// Get stored trust score
  Future<int?> getStoredTrustScore() async {
    final score = await _storage.read('device_trust_score');
    return score != null ? int.tryParse(score) : null;
  }

  /// Clear device registration
  Future<void> clearRegistration() async {
    await _storage.delete('device_registered');
    await _storage.delete('device_id');
    await _storage.delete('device_uuid');
    await _storage.delete('device_trust_score');
    await _storage.delete('access_token');
    await _storage.delete('refresh_token');
    debugPrint('[DeviceRegistration] Registration cleared');
  }

  /// Login with registered device
  Future<DeviceLoginResponse> loginDevice() async {
    try {
      debugPrint('[DeviceLogin] Starting device login...');

      // Get device UUID
      final deviceUuid = await _identityService.getOrCreateDeviceId();

      // Get current device info
      final packageInfo = await PackageInfo.fromPlatform();
      final biometricEnabled = await _biometricService.isBiometricAvailable();

      // Get available biometric types
      final availableBiometrics = await _biometricService.getAvailableBiometrics();
      final biometricTypes = availableBiometrics.map((type) {
        return type.toString().split('.').last;
      }).toList();

      // Get OS version
      final deviceInfoPlugin = DeviceInfoPlugin();
      String osVersion = 'Unknown';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        osVersion = androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        osVersion = iosInfo.systemVersion;
      }

      final loginData = {
        'device_uuid': deviceUuid,
        'app_version': packageInfo.version,
        'os_version': osVersion,
        'biometric_enabled': biometricEnabled,
        'device_metadata': {
          'build_number': packageInfo.buildNumber,
          'biometric_types': biometricTypes,
          'platform': Platform.operatingSystem,
        },
      };

      debugPrint('[DeviceLogin] Login data prepared');
      debugPrint('  UUID: $deviceUuid');
      debugPrint('  App Version: ${packageInfo.version}');
      debugPrint('  OS Version: $osVersion');
      debugPrint('  Biometric: $biometricEnabled');

      // Send login request to API
      final response = await _apiClient.post(
        '/device-auth/login',
        data: loginData,
      );

      final responseData = response.data as Map<String, dynamic>;

      debugPrint('[DeviceLogin] Login response received');
      debugPrint('  Device ID: ${responseData['device_id']}');
      debugPrint('  Trust Score: ${responseData['trust_score']}');
      debugPrint('  Status: ${responseData['status']}');

      // Store tokens
      if (responseData['access_token'] != null) {
        await _storage.write('access_token', responseData['access_token']);
        debugPrint('[DeviceLogin] Access token stored');
      }

      if (responseData['refresh_token'] != null) {
        await _storage.write('refresh_token', responseData['refresh_token']);
        debugPrint('[DeviceLogin] Refresh token stored');
      }

      // Update device info
      await _storage.write('device_id', responseData['device_id'].toString());
      await _storage.write('device_uuid', responseData['device_uuid']); // Store device UUID
      await _storage.write('device_trust_score', responseData['trust_score'].toString());
      
      debugPrint('[DeviceLogin] Device UUID stored: ${responseData['device_uuid']}');

      return DeviceLoginResponse.fromJson(responseData);
    } catch (e) {
      debugPrint('[DeviceLogin] Error: $e');
      rethrow;
    }
  }

  /// Get device info from API
  Future<DeviceInfo> getDeviceInfo(String deviceUuid) async {
    try {
      final response = await _apiClient.get('/device-auth/info/$deviceUuid');
      final responseData = response.data as Map<String, dynamic>;
      return DeviceInfo.fromJson(responseData);
    } catch (e) {
      debugPrint('[DeviceInfo] Error: $e');
      rethrow;
    }
  }

  /// Get security recommendations from API
  Future<SecurityRecommendations> getSecurityRecommendations(String deviceUuid) async {
    try {
      final response = await _apiClient.get('/device-auth/security-recommendations/$deviceUuid');
      final responseData = response.data as Map<String, dynamic>;
      return SecurityRecommendations.fromJson(responseData);
    } catch (e) {
      debugPrint('[SecurityRecommendations] Error: $e');
      rethrow;
    }
  }
}

/// Unified Device Authentication Response
/// Returned by the unified /device-auth/authenticate endpoint
class DeviceAuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final int deviceId;
  final String deviceUuid;
  final int trustScore;
  final String status;
  final bool isRegistered;
  final bool isNewDevice;
  final String message;
  final List<String> securityRecommendations;

  DeviceAuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.deviceId,
    required this.deviceUuid,
    required this.trustScore,
    required this.status,
    required this.isRegistered,
    required this.isNewDevice,
    required this.message,
    required this.securityRecommendations,
  });

  factory DeviceAuthResponse.fromJson(Map<String, dynamic> json) {
    return DeviceAuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int,
      deviceId: json['device_id'] as int,
      deviceUuid: json['device_uuid'] as String,
      trustScore: (json['trust_score'] is int) 
          ? json['trust_score'] as int 
          : (json['trust_score'] as double).toInt(),
      status: json['status'] as String,
      isRegistered: json['is_registered'] as bool,
      isNewDevice: json['is_new_device'] as bool? ?? false,
      message: json['message'] as String,
      securityRecommendations: (json['security_recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  bool get isActive => status == 'active';
  bool get isRejected => status == 'rejected';
  bool get isTrusted => trustScore >= 70;
}

/// Device Registration Response
class DeviceRegistrationResponse {
  final int deviceId;
  final String deviceUuid;
  final String deviceName;
  final int trustScore;
  final String status;
  final bool isRegistered;
  final String message;
  final List<String> securityRecommendations;
  final String? accessToken;
  final String? refreshToken;
  final bool? isNewDevice;

  DeviceRegistrationResponse({
    required this.deviceId,
    required this.deviceUuid,
    required this.deviceName,
    required this.trustScore,
    required this.status,
    required this.isRegistered,
    required this.message,
    required this.securityRecommendations,
    this.accessToken,
    this.refreshToken,
    this.isNewDevice,
  });

  factory DeviceRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationResponse(
      deviceId: json['device_id'] as int,
      deviceUuid: json['device_uuid'] as String,
      deviceName: json['device_name'] as String? ?? 'Unknown Device',
      trustScore: (json['trust_score'] is int) 
          ? json['trust_score'] as int 
          : (json['trust_score'] as double).toInt(), // Handle both int and double
      status: json['status'] as String,
      isRegistered: json['is_registered'] as bool,
      message: json['message'] as String,
      securityRecommendations: (json['security_recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      isNewDevice: json['is_new_device'] as bool?,
    );
  }

  /// Create from unified auth response
  factory DeviceRegistrationResponse.fromAuthResponse(DeviceAuthResponse authResponse) {
    return DeviceRegistrationResponse(
      deviceId: authResponse.deviceId,
      deviceUuid: authResponse.deviceUuid,
      deviceName: 'Unknown Device', // Not provided in auth response
      trustScore: authResponse.trustScore,
      status: authResponse.status,
      isRegistered: authResponse.isRegistered,
      message: authResponse.message,
      securityRecommendations: authResponse.securityRecommendations,
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      isNewDevice: authResponse.isNewDevice,
    );
  }

  bool get isActive => status == 'active';
  bool get isRejected => status == 'rejected';
  bool get isTrusted => trustScore >= 70;
}

/// Device Login Response
class DeviceLoginResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final int deviceId;
  final String deviceUuid;
  final int trustScore;
  final String status;
  final bool isRegistered;
  final String message;

  DeviceLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.deviceId,
    required this.deviceUuid,
    required this.trustScore,
    required this.status,
    required this.isRegistered,
    required this.message,
  });

  factory DeviceLoginResponse.fromJson(Map<String, dynamic> json) {
    return DeviceLoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: json['expires_in'] as int,
      deviceId: json['device_id'] as int,
      deviceUuid: json['device_uuid'] as String,
      trustScore: (json['trust_score'] is int) 
          ? json['trust_score'] as int 
          : (json['trust_score'] as double).toInt(), // Handle both int and double
      status: json['status'] as String,
      isRegistered: json['is_registered'] as bool,
      message: json['message'] as String,
    );
  }

  bool get isActive => status == 'active';
}

/// Device Info Response
class DeviceInfo {
  final int id;
  final String deviceUuid;
  final String deviceName;
  final String deviceType;
  final String deviceModel;
  final String osName;
  final String osVersion;
  final String appVersion;
  final bool isRooted;
  final bool isJailbroken;
  final bool biometricEnabled;
  final int trustScore;
  final String status;
  final bool isTrusted;
  final bool isActive;
  final bool isRegistered;
  final DateTime? lastLogin;
  final int loginCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeviceInfo({
    required this.id,
    required this.deviceUuid,
    required this.deviceName,
    required this.deviceType,
    required this.deviceModel,
    required this.osName,
    required this.osVersion,
    required this.appVersion,
    required this.isRooted,
    required this.isJailbroken,
    required this.biometricEnabled,
    required this.trustScore,
    required this.status,
    required this.isTrusted,
    required this.isActive,
    required this.isRegistered,
    this.lastLogin,
    required this.loginCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'] as int,
      deviceUuid: json['device_uuid'] as String,
      deviceName: json['device_name'] as String,
      deviceType: json['device_type'] as String,
      deviceModel: json['device_model'] as String,
      osName: json['os_name'] as String,
      osVersion: json['os_version'] as String,
      appVersion: json['app_version'] as String,
      isRooted: json['is_rooted'] as bool,
      isJailbroken: json['is_jailbroken'] as bool,
      biometricEnabled: json['biometric_enabled'] as bool,
      trustScore: (json['trust_score'] is int) 
          ? json['trust_score'] as int 
          : (json['trust_score'] as double).toInt(), // Handle both int and double
      status: json['status'] as String,
      isTrusted: json['is_trusted'] as bool,
      isActive: json['is_active'] as bool,
      isRegistered: json['is_registered'] as bool,
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      loginCount: json['login_count'] as int,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Security Recommendations Response
class SecurityRecommendations {
  final int deviceId;
  final String deviceUuid;
  final int currentTrustScore;
  final String status;
  final List<String> recommendations;
  final Map<String, bool> securityStatus;

  SecurityRecommendations({
    required this.deviceId,
    required this.deviceUuid,
    required this.currentTrustScore,
    required this.status,
    required this.recommendations,
    required this.securityStatus,
  });

  factory SecurityRecommendations.fromJson(Map<String, dynamic> json) {
    return SecurityRecommendations(
      deviceId: json['device_id'] as int,
      deviceUuid: json['device_uuid'] as String,
      currentTrustScore: (json['current_trust_score'] is int) 
          ? json['current_trust_score'] as int 
          : (json['current_trust_score'] as double).toInt(), // Handle both int and double
      status: json['status'] as String,
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      securityStatus: (json['security_status'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as bool)) ??
          {},
    );
  }
}

/// Provider for device registration service
final deviceRegistrationServiceProvider = Provider<DeviceRegistrationService>((ref) {
  final attestationService = ref.watch(deviceAttestationServiceProvider);
  final identityService = ref.watch(deviceIdentityServiceProvider);
  final biometricService = BiometricService();
  final storage = ref.watch(secureStorageServiceProvider);
  final apiClient = ref.watch(apiClientProvider);

  return DeviceRegistrationService(
    attestationService,
    identityService,
    biometricService,
    storage,
    apiClient,
  );
});
