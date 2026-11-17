import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

/// Service to protect against screenshots and screen recording
/// 
/// Features:
/// - Android: Prevents screenshots using FLAG_SECURE (shows blank/black screen)
/// - iOS: Detects screenshots and screen recording, shows secure overlay in app switcher
/// - Detects screenshot attempts and logs them
/// - Shows secure overlay when app goes to background/recent apps
/// - Hides sensitive content in app switcher
/// - Production-ready for iOS 15+ and Android
class ScreenshotProtectionService {
  static const platform = MethodChannel('com.ask_jeeves.vmi/screenshot_protection');
  
  static bool _isScreenshotDetected = false;
  static bool _isScreenRecording = false;
  static final StreamController<bool> _screenshotStream = StreamController<bool>.broadcast();
  static final StreamController<bool> _screenRecordingStream = StreamController<bool>.broadcast();
  
  /// Stream that emits true when screenshot is detected
  static Stream<bool> get screenshotDetected => _screenshotStream.stream;
  
  /// Stream that emits true when screen recording is detected (iOS only)
  static Stream<bool> get screenRecordingDetected => _screenRecordingStream.stream;
  
  /// Initialize screenshot protection
  static Future<void> initialize() async {
    debugPrint('[ScreenshotProtection] 🔐 Initializing screenshot protection...');
    debugPrint('[ScreenshotProtection] Platform: ${Platform.operatingSystem}');
    
    try {
      // Set up method channel handler for screenshot and screen recording detection
      platform.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'onScreenshotDetected':
            _handleScreenshotDetected(call.arguments);
            break;
            
          case 'onScreenRecordingDetected':
            _handleScreenRecordingDetected(call.arguments);
            break;
            
          default:
            debugPrint('[ScreenshotProtection] Unknown method: ${call.method}');
        }
      });
      
      // Enable screenshot protection on native side
      await platform.invokeMethod('enableScreenshotProtection');
      
      if (Platform.isAndroid) {
        debugPrint('[ScreenshotProtection] ✅ Android: FLAG_SECURE enabled');
        debugPrint('[ScreenshotProtection] 🔒 Screenshots will show blank screen');
      } else if (Platform.isIOS) {
        debugPrint('[ScreenshotProtection] ✅ iOS: Screenshot & recording detection enabled');
        debugPrint('[ScreenshotProtection] 🔒 Secure overlay enabled for app switcher');
        
        // Check if already recording
        final isRecording = await isScreenRecording();
        if (isRecording) {
          debugPrint('[ScreenshotProtection] ⚠️ Screen recording already in progress!');
          _isScreenRecording = true;
          _screenRecordingStream.add(true);
        }
      }
      
    } catch (e) {
      debugPrint('[ScreenshotProtection] ❌ Error initializing: $e');
    }
  }
  
  /// Handle screenshot detection from native side
  static void _handleScreenshotDetected(dynamic arguments) {
    debugPrint('[ScreenshotProtection] 📸 Screenshot detected!');
    
    if (arguments is Map) {
      final timestamp = arguments['timestamp'];
      final platform = arguments['platform'];
      debugPrint('[ScreenshotProtection] Platform: $platform, Time: $timestamp');
    }
    
    if (Platform.isAndroid) {
      debugPrint('[ScreenshotProtection] ⚠️ Screenshot will show blank screen (FLAG_SECURE)');
    } else if (Platform.isIOS) {
      debugPrint('[ScreenshotProtection] ⚠️ Screenshot captured - consider showing warning');
    }
    
    _isScreenshotDetected = true;
    _screenshotStream.add(true);
    
    // Reset after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _isScreenshotDetected = false;
      _screenshotStream.add(false);
    });
  }
  
  /// Handle screen recording detection from native side (iOS only)
  static void _handleScreenRecordingDetected(dynamic arguments) {
    if (arguments is Map) {
      final isRecording = arguments['isRecording'] as bool? ?? false;
      final timestamp = arguments['timestamp'];
      final platform = arguments['platform'];
      
      debugPrint('[ScreenshotProtection] 🎥 Screen recording: ${isRecording ? "STARTED" : "STOPPED"}');
      debugPrint('[ScreenshotProtection] Platform: $platform, Time: $timestamp');
      
      _isScreenRecording = isRecording;
      _screenRecordingStream.add(isRecording);
      
      if (isRecording) {
        debugPrint('[ScreenshotProtection] ⚠️ WARNING: Screen is being recorded!');
      }
    }
  }
  
  /// Check if screenshot is currently detected
  static bool get isScreenshotDetected => _isScreenshotDetected;
  
  /// Check if screen recording is active (iOS only)
  static bool get isScreenRecordingActive => _isScreenRecording;
  
  /// Check if screen is being recorded (iOS only)
  static Future<bool> isScreenRecording() async {
    if (!Platform.isIOS) return false;
    
    try {
      final result = await platform.invokeMethod('isScreenRecording');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('[ScreenshotProtection] Error checking screen recording: $e');
      return false;
    }
  }
  
  /// Show secure overlay (called when app goes to background)
  static Future<void> showSecureOverlay() async {
    try {
      await platform.invokeMethod('showSecureOverlay');
      debugPrint('[ScreenshotProtection] 🔒 Secure overlay shown');
    } catch (e) {
      debugPrint('[ScreenshotProtection] Error showing secure overlay: $e');
    }
  }
  
  /// Hide secure overlay (called when app returns to foreground)
  static Future<void> hideSecureOverlay() async {
    try {
      await platform.invokeMethod('hideSecureOverlay');
      debugPrint('[ScreenshotProtection] 🔓 Secure overlay hidden');
    } catch (e) {
      debugPrint('[ScreenshotProtection] Error hiding secure overlay: $e');
    }
  }
  
  /// Disable screenshot protection (for specific screens if needed)
  static Future<void> disableProtection() async {
    try {
      await platform.invokeMethod('disableScreenshotProtection');
      debugPrint('[ScreenshotProtection] Screenshot protection disabled');
    } catch (e) {
      debugPrint('[ScreenshotProtection] Error disabling protection: $e');
    }
  }
  
  /// Enable screenshot protection
  static Future<void> enableProtection() async {
    try {
      await platform.invokeMethod('enableScreenshotProtection');
      debugPrint('[ScreenshotProtection] Screenshot protection enabled');
    } catch (e) {
      debugPrint('[ScreenshotProtection] Error enabling protection: $e');
    }
  }
  
  /// Dispose resources
  static void dispose() {
    _screenshotStream.close();
    _screenRecordingStream.close();
  }
}
