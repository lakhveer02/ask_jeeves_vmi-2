import 'dart:io' if (dart.library.html) 'dart:html';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/cupertino.dart';

/// Service for screenshot detection and prevention
/// 
/// Android: FLAG_SECURE is set in MainActivity.kt to prevent screenshots
/// iOS: Screenshots cannot be prevented, but can be detected
/// Web: Screenshot prevention not available
class ScreenshotService {

  /// Check if screenshot prevention is enabled
  /// 
  /// Returns true on Android (FLAG_SECURE is always enabled in MainActivity)
  /// Returns false on iOS (screenshots cannot be prevented on iOS)
  /// Returns false on Web (screenshots cannot be prevented on Web)
  Future<bool> isScreenshotPreventionEnabled() async {
    if (kIsWeb) {
      debugPrint('Screenshot prevention not available on Web');
      return false;
    }
    
    if (Platform.isAndroid) {
      // FLAG_SECURE is set in MainActivity.kt
      debugPrint('Screenshot prevention is enabled (FLAG_SECURE)');
      return true;
    } else if (Platform.isIOS) {
      debugPrint('Screenshot prevention not available on iOS');
      return false;
    }
    return false;
  }

  /// Enable screenshot prevention (Android only)
  /// 
  /// Note: FLAG_SECURE is already set in MainActivity.kt
  /// This method is kept for API compatibility
  Future<bool> enableScreenshotPrevention() async {
    if (kIsWeb || !Platform.isAndroid) {
      debugPrint('Screenshot prevention only available on Android');
      return false;
    }

    try {
      // FLAG_SECURE is set in MainActivity.kt onCreate()
      // window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
      debugPrint('Screenshot prevention is enabled via FLAG_SECURE in MainActivity');
      return true;
    } catch (e) {
      debugPrint('Error enabling screenshot prevention: $e');
      return false;
    }
  }

  /// Disable screenshot prevention
  /// 
  /// Note: FLAG_SECURE cannot be disabled at runtime in current implementation
  /// It's set in MainActivity.kt and remains active for the app lifecycle
  Future<bool> disableScreenshotPrevention() async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }

    try {
      debugPrint('Screenshot prevention cannot be disabled (FLAG_SECURE is permanent)');
      return false;
    } catch (e) {
      debugPrint('Error disabling screenshot prevention: $e');
      return false;
    }
  }

  /// Detect screenshot (iOS only - requires native implementation)
  /// 
  /// On iOS, screenshots cannot be prevented but can be detected
  /// using UIApplicationUserDidTakeScreenshotNotification
  Stream<bool> onScreenshotDetected() async* {
    // In production, implement native iOS code to detect screenshots
    // using UIApplicationUserDidTakeScreenshotNotification
    // For now, return empty stream
    yield false;
  }

  /// Log screenshot attempt
  /// 
  /// On Android: This won't be called because FLAG_SECURE prevents screenshots
  /// On iOS: This can be called when screenshot is detected
  Future<void> logScreenshotAttempt() async {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('Screenshot attempt detected at $timestamp');
    // In production, send to backend for audit logging
  }
}
