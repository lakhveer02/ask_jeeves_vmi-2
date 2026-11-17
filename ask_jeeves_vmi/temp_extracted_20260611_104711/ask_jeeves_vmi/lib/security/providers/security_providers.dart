import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/storage/secure_storage_service.dart';
import 'package:ask_jeeves_vmi/security/services/encryption_service.dart';
import '../../data/services/location/geolocation_service.dart';
import 'package:ask_jeeves_vmi/security/services/device_security_service.dart';
import '../../data/services/device/screenshot_service.dart';
import 'package:ask_jeeves_vmi/security/services/biometric_service.dart';
import '../../features/session/services/session_service.dart';
import '../../data/services/device/permission_service.dart';
import '../../data/services/api/api_client.dart';
import 'package:ask_jeeves_vmi/security/services/device_attestation_service.dart';
import 'package:ask_jeeves_vmi/security/services/realtime_security_monitor.dart';

/// Provider for secure storage service
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider for encryption service
final encryptionProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

/// Provider for geolocation service
final geolocationProvider = Provider<GeolocationService>((ref) {
  return GeolocationService();
});

/// Provider for device security service
final deviceSecurityProvider = Provider<DeviceSecurityService>((ref) {
  return DeviceSecurityService();
});

/// Provider for screenshot service
final screenshotProvider = Provider<ScreenshotService>((ref) {
  return ScreenshotService();
});

/// Provider for biometric service
final biometricProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Provider for session service
final sessionProvider = Provider<SessionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SessionService(apiClient);
});

/// Provider for permission service
final permissionProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

/// Provider for checking if biometrics are available
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final biometricService = ref.watch(biometricProvider);
  return await biometricService.isBiometricAvailable();
});

/// Provider for device trust score
final deviceTrustScoreProvider = FutureProvider<int>((ref) async {
  final deviceSecurity = ref.watch(deviceSecurityProvider);
  return await deviceSecurity.calculateTrustScore();
});

/// Provider for current location
final currentLocationProvider = FutureProvider((ref) async {
  final geoService = ref.watch(geolocationProvider);
  return await geoService.getCurrentLocation();
});

/// Provider for session status
final sessionStatusProvider = FutureProvider<bool>((ref) async {
  final sessionService = ref.watch(sessionProvider);
  return await sessionService.isSessionActive();
});

/// Provider for device attestation service
final deviceAttestationProvider = Provider<DeviceAttestationService>((ref) {
  return DeviceAttestationService();
});

/// Provider for real-time security monitor
final realtimeSecurityMonitorProvider = Provider<RealtimeSecurityMonitor>((ref) {
  final attestationService = ref.watch(deviceAttestationProvider);
  final securityService = ref.watch(deviceSecurityProvider);
  
  final monitor = RealtimeSecurityMonitor(
    attestationService,
    securityService,
    checkInterval: const Duration(seconds: 10), // Check every 10 seconds
  );
  
  ref.onDispose(() {
    monitor.dispose();
  });
  
  return monitor;
});
