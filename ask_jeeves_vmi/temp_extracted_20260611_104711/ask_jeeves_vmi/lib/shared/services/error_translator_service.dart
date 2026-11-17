/// Enterprise VMI Error Translator Service
/// Converts technical errors into user-friendly messages
library;

import 'package:flutter/foundation.dart';

class ErrorTranslation {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? action;

  const ErrorTranslation({
    required this.title,
    required this.message,
    this.actionLabel,
    this.action,
  });
}

class ErrorTranslatorService {
  /// Translates technical errors into user-friendly messages
  static ErrorTranslation translate(dynamic error) {
    final errorString = error.toString().toLowerCase();
    final errorType = error.runtimeType.toString().toLowerCase();

    // Network & Connectivity Errors
    if (_isNetworkTimeout(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Connection Issue',
        message: 'We couldn\'t connect to the workspace. Please check your internet connection and try again.',
      );
    }

    if (_isNoInternet(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Internet Disconnected',
        message: 'Your device appears to be offline. Reconnect to the internet and try again.',
      );
    }

    if (_isServerUnavailable(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Service Temporarily Unavailable',
        message: 'The workspace service is currently unavailable. Please try again in a few minutes.',
      );
    }

    // Authentication & Session Errors
    if (_isAuthenticationFailed(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Sign-In Failed',
        message: 'We couldn\'t verify your account. Please sign in again.',
      );
    }

    if (_isSessionExpired(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Session Ended',
        message: 'Your session has expired for security reasons. Please sign in again.',
      );
    }

    if (_isTokenInvalid(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Authentication Required',
        message: 'Your credentials are no longer valid. Please sign in again.',
      );
    }

    // Workspace Connection Errors
    if (_isWorkspaceConnectionLost(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Workspace Disconnected',
        message: 'Your connection to the workspace was interrupted. Please reconnect and try again.',
      );
    }

    if (_isWorkspaceReconnectionFailed(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Unable to Reconnect',
        message: 'We couldn\'t restore your workspace connection. Please restart your session.',
      );
    }

    // WebRTC & VMI Session Errors
    if (_isVMISessionError(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Workspace Connection Issue',
        message: 'We couldn\'t connect to your workspace. Please check your internet and try again.',
      );
    }

    if (_isWebRTCError(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Display Connection Issue',
        message: 'There was a problem showing your workspace. Reconnecting now.',
      );
    }

    if (_isICEConnectionFailed(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Connection Setup Failed',
        message: 'We couldn\'t establish a secure connection. Please try again.',
      );
    }

    if (_isSDPError(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Setup Error',
        message: 'There was a problem setting up your workspace. Please try again.',
      );
    }

    // Location & Geofence Errors
    if (_isLocationValidationFailed(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Location Verification Required',
        message: 'Your location could not be verified. Please ensure location services are enabled.',
      );
    }

    if (_isGeofenceViolation(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Access Restricted',
        message: 'Workspace access is not available from your current location.',
      );
    }

    if (_isLocationPermissionDenied(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Location Permission Required',
        message: 'Please allow location access to continue using the workspace.',
      );
    }

    // Biometric & Device Security Errors
    if (_isBiometricAuthFailed(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Verification Failed',
        message: 'We couldn\'t verify your identity. Please try again.',
      );
    }

    if (_isFaceRecognitionFailed(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Identity Check Failed',
        message: 'We couldn\'t confirm your identity. Please try again in better lighting.',
      );
    }

    if (_isDeviceSecurityRisk(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Security Alert',
        message: 'This device does not meet security requirements. Access has been restricted.',
      );
    }

    if (_isRootJailbreakDetected(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Device Not Supported',
        message: 'For security reasons, this device cannot access the workspace.',
      );
    }

    if (_isDeviceAttestationFailed(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Device Verification Failed',
        message: 'We couldn\'t verify your device security. Please contact support.',
      );
    }

    // Permission Errors
    if (_isPermissionDenied(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Permission Required',
        message: 'Please allow the required permissions to continue.',
      );
    }

    if (_isCameraPermissionDenied(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Camera Permission Required',
        message: 'Please allow camera access for identity verification.',
      );
    }

    // File & Upload Errors
    if (_isFileUploadFailed(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Upload Failed',
        message: 'The file could not be uploaded. Please try again.',
      );
    }

    if (_isFileTooLarge(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'File Too Large',
        message: 'The file size exceeds the maximum allowed. Please choose a smaller file.',
      );
    }

    if (_isInvalidFileType(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Invalid File Type',
        message: 'This file type is not supported. Please choose a different file.',
      );
    }

    // Security Violations
    if (_isSecurityViolation(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Security Alert',
        message: 'A security issue was detected. Your session has been ended for protection.',
      );
    }

    if (_isTamperDetected(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Security Warning',
        message: 'Unusual activity was detected. Access has been restricted.',
      );
    }

    if (_isScreenshotBlocked(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Action Not Allowed',
        message: 'Screenshots are disabled for security reasons.',
      );
    }

    // Rate Limiting & Throttling
    if (_isRateLimited(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Too Many Attempts',
        message: 'Please wait a moment before trying again.',
      );
    }

    // Data & Storage Errors
    if (_isStorageFull(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Storage Full',
        message: 'Your device storage is full. Please free up space and try again.',
      );
    }

    if (_isDataCorrupted(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Data Issue',
        message: 'Some data appears corrupted. Please restart the app.',
      );
    }

    // Vault & Encryption Errors
    if (_isVaultInitializationFailed(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Security Setup Failed',
        message: 'We couldn\'t set up secure storage. Please try again.',
      );
    }

    if (_isEncryptionError(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Security Error',
        message: 'There was a problem securing your data. Please restart the app.',
      );
    }

    // API & HTTP Errors (by status code patterns)
    if (_isBadRequest(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Invalid Request',
        message: 'Something went wrong with your request. Please try again.',
      );
    }

    if (_isUnauthorized(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Access Denied',
        message: 'You don\'t have permission to access this. Please sign in again.',
      );
    }

    if (_isForbidden(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Access Restricted',
        message: 'You don\'t have permission to perform this action.',
      );
    }

    if (_isNotFound(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Not Found',
        message: 'The requested resource could not be found. Please try again.',
      );
    }

    if (_isConflict(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Conflict Detected',
        message: 'This action conflicts with existing data. Please refresh and try again.',
      );
    }

    if (_isServerError(errorString, errorType)) {
      return const ErrorTranslation(
        title: 'Server Issue',
        message: 'Something went wrong on our end. Please try again in a moment.',
      );
    }

    // Default fallback
    return const ErrorTranslation(
      title: 'Something Went Wrong',
      message: 'An unexpected issue occurred. Please try again.',
    );
  }

  // Network & Connectivity Checkers
  static bool _isNetworkTimeout(String error, String type) {
    return error.contains('timeout') ||
        error.contains('timed out') ||
        type.contains('timeout');
  }

  static bool _isNoInternet(String error, String type) {
    return error.contains('no internet') ||
        error.contains('network unavailable') ||
        error.contains('offline') ||
        type.contains('socketexception');
  }

  static bool _isServerUnavailable(String error, String type) {
    return error.contains('502') ||
        error.contains('503') ||
        error.contains('504') ||
        error.contains('service unavailable') ||
        error.contains('bad gateway') ||
        error.contains('gateway timeout');
  }

  // Authentication & Session Checkers
  static bool _isAuthenticationFailed(String error, String type) {
    return error.contains('authentication failed') ||
        error.contains('login failed') ||
        error.contains('invalid credentials') ||
        error.contains('wrong password');
  }

  static bool _isSessionExpired(String error, String type) {
    return error.contains('session expired') ||
        error.contains('session timeout') ||
        error.contains('session invalid');
  }

  static bool _isTokenInvalid(String error, String type) {
    return error.contains('token expired') ||
        error.contains('invalid token') ||
        error.contains('token invalid') ||
        error.contains('jwt expired');
  }

  // Workspace Connection Checkers
  static bool _isWorkspaceConnectionLost(String error, String type) {
    return error.contains('workspace disconnected') ||
        error.contains('workspace connection lost') ||
        error.contains('not connected to workspace') ||
        error.contains('websocket closed');
  }

  static bool _isWorkspaceReconnectionFailed(String error, String type) {
    return error.contains('reconnection failed') ||
        error.contains('reconnect failed') ||
        error.contains('could not reconnect');
  }

  // WebRTC & VMI Session Checkers
  static bool _isVMISessionError(String error, String type) {
    return error.contains('vmi session') ||
        error.contains('failed to load vmi') ||
        error.contains('vmi connection') ||
        error.contains('session load failed');
  }

  static bool _isWebRTCError(String error, String type) {
    return error.contains('webrtc') ||
        error.contains('rtc error') ||
        error.contains('peer connection');
  }

  static bool _isICEConnectionFailed(String error, String type) {
    return error.contains('ice') ||
        error.contains('ice failed') ||
        error.contains('ice connection failed');
  }

  static bool _isSDPError(String error, String type) {
    return error.contains('sdp') ||
        error.contains('sdp error') ||
        error.contains('session description');
  }

  // Location & Geofence Checkers
  static bool _isLocationValidationFailed(String error, String type) {
    return error.contains('location validation') ||
        error.contains('location verification') ||
        error.contains('could not verify location');
  }

  static bool _isGeofenceViolation(String error, String type) {
    return error.contains('geofence') ||
        error.contains('outside allowed area') ||
        error.contains('location not allowed');
  }

  static bool _isLocationPermissionDenied(String error, String type) {
    return error.contains('location permission') &&
        error.contains('denied');
  }

  // Biometric & Device Security Checkers
  static bool _isBiometricAuthFailed(String error, String type) {
    return error.contains('biometric') &&
        (error.contains('failed') || error.contains('error'));
  }

  static bool _isFaceRecognitionFailed(String error, String type) {
    return error.contains('face recognition') ||
        error.contains('face auth') ||
        error.contains('face verification');
  }

  static bool _isDeviceSecurityRisk(String error, String type) {
    return error.contains('device security') ||
        error.contains('security risk') ||
        error.contains('insecure device');
  }

  static bool _isRootJailbreakDetected(String error, String type) {
    return error.contains('root') ||
        error.contains('jailbreak') ||
        error.contains('rooted device') ||
        error.contains('jailbroken device');
  }

  static bool _isDeviceAttestationFailed(String error, String type) {
    return error.contains('attestation') ||
        error.contains('device verification failed');
  }

  // Permission Checkers
  static bool _isPermissionDenied(String error, String type) {
    return error.contains('permission denied') ||
        error.contains('permission required');
  }

  static bool _isCameraPermissionDenied(String error, String type) {
    return error.contains('camera permission') &&
        error.contains('denied');
  }

  // File & Upload Checkers
  static bool _isFileUploadFailed(String error, String type) {
    return error.contains('upload failed') ||
        error.contains('file upload') ||
        error.contains('could not upload');
  }

  static bool _isFileTooLarge(String error, String type) {
    return error.contains('file too large') ||
        error.contains('file size') ||
        error.contains('exceeds maximum');
  }

  static bool _isInvalidFileType(String error, String type) {
    return error.contains('invalid file type') ||
        error.contains('file type not supported') ||
        error.contains('unsupported format');
  }

  // Security Violation Checkers
  static bool _isSecurityViolation(String error, String type) {
    return error.contains('security violation') ||
        error.contains('security breach');
  }

  static bool _isTamperDetected(String error, String type) {
    return error.contains('tamper') ||
        error.contains('tampering detected') ||
        error.contains('integrity violation');
  }

  static bool _isScreenshotBlocked(String error, String type) {
    return error.contains('screenshot') ||
        error.contains('screen capture');
  }

  // Rate Limiting Checker
  static bool _isRateLimited(String error, String type) {
    return error.contains('rate limit') ||
        error.contains('too many requests') ||
        error.contains('429');
  }

  // Data & Storage Checkers
  static bool _isStorageFull(String error, String type) {
    return error.contains('storage full') ||
        error.contains('disk full') ||
        error.contains('no space');
  }

  static bool _isDataCorrupted(String error, String type) {
    return error.contains('corrupted') ||
        error.contains('corrupt data') ||
        error.contains('data integrity');
  }

  // Vault & Encryption Checkers
  static bool _isVaultInitializationFailed(String error, String type) {
    return error.contains('vault') &&
        (error.contains('initialization') || error.contains('init'));
  }

  static bool _isEncryptionError(String error, String type) {
    return error.contains('encryption') ||
        error.contains('decryption') ||
        error.contains('cipher');
  }

  // HTTP Status Code Checkers
  static bool _isBadRequest(String error, String type) {
    return error.contains('400') || error.contains('bad request');
  }

  static bool _isUnauthorized(String error, String type) {
    return error.contains('401') || error.contains('unauthorized');
  }

  static bool _isForbidden(String error, String type) {
    return error.contains('403') || error.contains('forbidden');
  }

  static bool _isNotFound(String error, String type) {
    return error.contains('404') || error.contains('not found');
  }

  static bool _isConflict(String error, String type) {
    return error.contains('409') || error.contains('conflict');
  }

  static bool _isServerError(String error, String type) {
    return error.contains('500') ||
        error.contains('internal server error') ||
        error.contains('server error');
  }
}
