import 'package:flutter/rendering.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

/// Service for handling biometric authentication
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to access the vault',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    BiometricType? preferredBiometric,
  }) async {
    try {
      // Add hint about preferred biometric in the message
      String enhancedReason = localizedReason;
      if (preferredBiometric != null) {
        if (preferredBiometric == BiometricType.face) {
          enhancedReason = '$localizedReason\nPreferred: Face Recognition';
        } else if (preferredBiometric == BiometricType.fingerprint) {
          enhancedReason = '$localizedReason\nPreferred: Fingerprint';
        }
      }
      
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: enhancedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: ${e.message}');
      return false;
    }
  }

  /// Stop authentication
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      debugPrint('Error stopping authentication: $e');
    }
  }
}
