import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ask_jeeves_vmi/security/services/biometric_service.dart';
import 'package:ask_jeeves_vmi/data/services/device/screenshot_service.dart';
import 'package:ask_jeeves_vmi/security/services/device_security_service.dart';
import 'package:ask_jeeves_vmi/features/session/services/session_service.dart';
import 'package:ask_jeeves_vmi/data/services/api/api_client.dart';

/// Comprehensive security manager that enables all security features
class SecurityManager {
  final BiometricService _biometricService;
  final ScreenshotService _screenshotService;
  final DeviceSecurityService _deviceSecurityService;
  final SessionService _sessionService;

  SecurityManager({
    required BiometricService biometricService,
    required ScreenshotService screenshotService,
    required DeviceSecurityService deviceSecurityService,
    required SessionService sessionService,
  })  : _biometricService = biometricService,
        _screenshotService = screenshotService,
        _deviceSecurityService = deviceSecurityService,
        _sessionService = sessionService;

  /// Initialize all security features
  Future<SecurityInitializationResult> initializeAllSecurityFeatures() async {
    debugPrint('[Security] Initializing all security features...');

    final results = <String, bool>{};
    final errors = <String>[];

    // 1. Enable screenshot prevention
    try {
      final screenshotEnabled = await _screenshotService.enableScreenshotPrevention();
      results['screenshot_prevention'] = screenshotEnabled;
      debugPrint('[Security] Screenshot prevention: ${screenshotEnabled ? "ENABLED" : "NOT AVAILABLE"}');
    } catch (e) {
      errors.add('Screenshot prevention error: $e');
      results['screenshot_prevention'] = false;
    }

    // 2. Check biometric availability
    try {
      final biometricAvailable = await _biometricService.isBiometricAvailable();
      results['biometric_available'] = biometricAvailable;
      
      if (biometricAvailable) {
        final biometricTypes = await _biometricService.getAvailableBiometrics();
        debugPrint('[Security] Biometric authentication: AVAILABLE');
        debugPrint('[Security] Available biometric types: $biometricTypes');
      } else {
        debugPrint('[Security] Biometric authentication: NOT AVAILABLE');
      }
    } catch (e) {
      errors.add('Biometric check error: $e');
      results['biometric_available'] = false;
    }

    // 3. Verify device security
    try {
      final deviceVerification = await _deviceSecurityService.verifyDevice();
      results['device_verified'] = deviceVerification.isPassed;
      results['device_compromised'] = deviceVerification.isCompromised;
      
      debugPrint('[Security] Device verification: ${deviceVerification.isPassed ? "PASSED" : "FAILED"}');
      debugPrint('[Security] Device compromised: ${deviceVerification.isCompromised ? "YES" : "NO"}');
      
      if (deviceVerification.isCompromised) {
        errors.add('Device is compromised (jailbroken/rooted)');
      }
    } catch (e) {
      errors.add('Device verification error: $e');
      results['device_verified'] = false;
    }

    // 4. Initialize session monitoring
    try {
      // Session will be started after login, just verify service is available
      final sessionActive = await _sessionService.isSessionActive();
      results['session_monitoring'] = true;
      debugPrint('[Security] Session monitoring: READY');
      debugPrint('[Security] Active session: ${sessionActive ? "YES" : "NO"}');
    } catch (e) {
      errors.add('Session monitoring error: $e');
      results['session_monitoring'] = false;
    }

    final allEnabled = !results.values.contains(false);
    
    debugPrint('[Security] Security initialization complete');
    debugPrint('[Security] All features enabled: ${allEnabled ? "YES" : "NO"}');
    
    if (errors.isNotEmpty) {
      debugPrint('[Security] Errors encountered:');
      for (final error in errors) {
        debugPrint('[Security]   - $error');
      }
    }

    return SecurityInitializationResult(
      allEnabled: allEnabled,
      results: results,
      errors: errors,
    );
  }

  /// Require biometric authentication
  Future<bool> requireBiometricAuth({
    String reason = 'Please authenticate to continue',
  }) async {
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      
      if (!isAvailable) {
        debugPrint('[Security] Biometric authentication not available');
        return false;
      }

      final authenticated = await _biometricService.authenticate(
        localizedReason: reason,
        useErrorDialogs: true,
        stickyAuth: true,
      );

      debugPrint('[Security] Biometric authentication: ${authenticated ? "SUCCESS" : "FAILED"}');
      return authenticated;
    } catch (e) {
      debugPrint('[Security] Biometric authentication error: $e');
      return false;
    }
  }

  /// Check if device is secure
  Future<bool> isDeviceSecure() async {
    try {
      final verification = await _deviceSecurityService.verifyDevice();
      return verification.isPassed && !verification.isCompromised;
    } catch (e) {
      debugPrint('[Security] Device security check error: $e');
      return false;
    }
  }

  /// Get comprehensive security status
  Future<SecurityStatus> getSecurityStatus() async {
    final biometricAvailable = await _biometricService.isBiometricAvailable();
    final screenshotPrevention = await _screenshotService.isScreenshotPreventionEnabled();
    final deviceVerification = await _deviceSecurityService.verifyDevice();
    final sessionActive = await _sessionService.isSessionActive();

    return SecurityStatus(
      biometricAvailable: biometricAvailable,
      screenshotPreventionEnabled: screenshotPrevention,
      deviceTrustScore: deviceVerification.trustScore,
      deviceCompromised: deviceVerification.isCompromised,
      sessionActive: sessionActive,
      overallSecurityLevel: _calculateSecurityLevel(
        biometricAvailable,
        screenshotPrevention,
        deviceVerification.trustScore,
        deviceVerification.isCompromised,
      ),
    );
  }

  /// Calculate overall security level
  SecurityLevel _calculateSecurityLevel(
    bool biometricAvailable,
    bool screenshotPrevention,
    int trustScore,
    bool deviceCompromised,
  ) {
    if (deviceCompromised) {
      return SecurityLevel.critical;
    }

    if (trustScore < 50) {
      return SecurityLevel.low;
    }

    int score = 0;
    if (biometricAvailable) score += 25;
    if (screenshotPrevention) score += 25;
    if (trustScore >= 70) score += 25;
    if (trustScore >= 90) score += 25;

    if (score >= 75) return SecurityLevel.high;
    if (score >= 50) return SecurityLevel.medium;
    return SecurityLevel.low;
  }

  /// Perform security audit
  Future<SecurityAuditReport> performSecurityAudit() async {
    debugPrint('[Security] Performing security audit...');

    final checks = <SecurityCheck>[];

    // Check 1: Biometric authentication
    final biometricAvailable = await _biometricService.isBiometricAvailable();
    checks.add(SecurityCheck(
      name: 'Biometric Authentication',
      passed: biometricAvailable,
      message: biometricAvailable
          ? 'Biometric authentication is available'
          : 'Biometric authentication is not available',
      severity: biometricAvailable ? SecuritySeverity.info : SecuritySeverity.warning,
    ));

    // Check 2: Screenshot prevention
    final screenshotPrevention = await _screenshotService.isScreenshotPreventionEnabled();
    checks.add(SecurityCheck(
      name: 'Screenshot Prevention',
      passed: screenshotPrevention,
      message: screenshotPrevention
          ? 'Screenshot prevention is enabled'
          : 'Screenshot prevention is not available on this platform',
      severity: screenshotPrevention ? SecuritySeverity.info : SecuritySeverity.warning,
    ));

    // Check 3: Device verification
    final deviceVerification = await _deviceSecurityService.verifyDevice();
    checks.add(SecurityCheck(
      name: 'Device Verification',
      passed: deviceVerification.isPassed,
      message: deviceVerification.isPassed ? 'Device verified' : 'Device verification failed',
      severity: deviceVerification.isPassed ? SecuritySeverity.info : SecuritySeverity.error,
    ));

    // Check 4: Device compromise
    checks.add(SecurityCheck(
      name: 'Device Integrity',
      passed: !deviceVerification.isCompromised,
      message: deviceVerification.isCompromised
          ? 'Device is compromised (jailbroken/rooted)'
          : 'Device integrity verified',
      severity: deviceVerification.isCompromised ? SecuritySeverity.critical : SecuritySeverity.info,
    ));

    // Check 5: Session monitoring
    final sessionActive = await _sessionService.isSessionActive();
    checks.add(SecurityCheck(
      name: 'Session Monitoring',
      passed: sessionActive,
      message: sessionActive
          ? 'Session monitoring is active'
          : 'Session monitoring is not active',
      severity: sessionActive ? SecuritySeverity.info : SecuritySeverity.warning,
    ));

    final passedChecks = checks.where((c) => c.passed).length;
    final totalChecks = checks.length;
    final overallPassed = passedChecks == totalChecks;

    debugPrint('[Security] Security audit complete: $passedChecks/$totalChecks checks passed');

    return SecurityAuditReport(
      checks: checks,
      passedChecks: passedChecks,
      totalChecks: totalChecks,
      overallPassed: overallPassed,
      timestamp: DateTime.now(),
    );
  }
}

/// Security initialization result
class SecurityInitializationResult {
  final bool allEnabled;
  final Map<String, bool> results;
  final List<String> errors;

  SecurityInitializationResult({
    required this.allEnabled,
    required this.results,
    required this.errors,
  });
}

/// Security status
class SecurityStatus {
  final bool biometricAvailable;
  final bool screenshotPreventionEnabled;
  final int deviceTrustScore;
  final bool deviceCompromised;
  final bool sessionActive;
  final SecurityLevel overallSecurityLevel;

  SecurityStatus({
    required this.biometricAvailable,
    required this.screenshotPreventionEnabled,
    required this.deviceTrustScore,
    required this.deviceCompromised,
    required this.sessionActive,
    required this.overallSecurityLevel,
  });
}

/// Security level enum
enum SecurityLevel {
  critical,
  low,
  medium,
  high,
}

/// Security check
class SecurityCheck {
  final String name;
  final bool passed;
  final String message;
  final SecuritySeverity severity;

  SecurityCheck({
    required this.name,
    required this.passed,
    required this.message,
    required this.severity,
  });
}

/// Security severity enum
enum SecuritySeverity {
  info,
  warning,
  error,
  critical,
}

/// Security audit report
class SecurityAuditReport {
  final List<SecurityCheck> checks;
  final int passedChecks;
  final int totalChecks;
  final bool overallPassed;
  final DateTime timestamp;

  SecurityAuditReport({
    required this.checks,
    required this.passedChecks,
    required this.totalChecks,
    required this.overallPassed,
    required this.timestamp,
  });
}

/// Provider for security manager
final securityManagerProvider = Provider<SecurityManager>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  
  return SecurityManager(
    biometricService: BiometricService(),
    screenshotService: ScreenshotService(),
    deviceSecurityService: DeviceSecurityService(),
    sessionService: SessionService(apiClient),
  );
});
