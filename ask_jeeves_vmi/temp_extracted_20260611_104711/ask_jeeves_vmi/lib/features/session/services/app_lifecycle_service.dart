import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to monitor app lifecycle and handle automatic logout
class AppLifecycleService {
  Timer? _inactivityTimer;
  DateTime? _backgroundTime;
  final Duration inactivityDuration;
  final VoidCallback onInactivityTimeout;
  final VoidCallback? onAppClosed; // Called when app is closed/minimized

  AppLifecycleService({
    this.inactivityDuration = const Duration(minutes: 2),
    required this.onInactivityTimeout,
    this.onAppClosed,
  });

  /// Start monitoring app lifecycle
  void startMonitoring(AppLifecycleState state) {
    _handleLifecycleChange(state);
  }

  /// Handle app lifecycle state changes
  void _handleLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App is paused (minimized on Android, backgrounded on iOS)
        _onAppPaused();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (transitioning between states)
        _onAppInactive();
        break;
      case AppLifecycleState.detached:
        // App is detached (about to be closed)
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        // App is hidden (iOS 13+)
        _onAppHidden();
        break;
      case AppLifecycleState.resumed:
        _onAppForeground();
        break;
    }
  }

  /// Called when app is paused (minimized/backgrounded)
  void _onAppPaused() {
    _backgroundTime = DateTime.now();
    _startInactivityTimer();
    debugPrint('[AppLifecycle] App paused at $_backgroundTime');
    
    // Schedule warning notification at 75% of timeout duration (45 seconds for 60s timeout)
    if (inactivityDuration.inSeconds > 30) {
      final warningTime = Duration(seconds: (inactivityDuration.inSeconds * 0.75).round());
      Timer(warningTime, () {
        if (_backgroundTime != null) {
          debugPrint('[AppLifecycle] ⚠️ Session timeout warning - ${inactivityDuration.inSeconds - warningTime.inSeconds}s remaining');
          // App is still in background, warning would be shown when user returns
        }
      });
    }
  }

  /// Called when app is inactive (transitioning)
  void _onAppInactive() {
    debugPrint('[AppLifecycle] App inactive');
  }

  /// Called when app is detached (about to close)
  void _onAppDetached() {
    debugPrint('[AppLifecycle] App detached - triggering immediate logout');
    _cancelInactivityTimer();
    // Immediately logout when app is closed
    onAppClosed?.call();
  }

  /// Called when app is hidden (iOS 13+)
  void _onAppHidden() {
    debugPrint('[AppLifecycle] App hidden - triggering immediate logout');
    _cancelInactivityTimer();
    // Immediately logout when app is hidden
    onAppClosed?.call();
  }

  /// Called when app comes to foreground
  void _onAppForeground() {
    debugPrint('[AppLifecycle] App came to foreground');

    if (_backgroundTime != null) {
      final backgroundDuration = DateTime.now().difference(_backgroundTime!);
      debugPrint('[AppLifecycle] Was in background for: ${backgroundDuration.inSeconds}s');

      // Check if exceeded inactivity duration
      if (backgroundDuration >= inactivityDuration) {
        debugPrint('[AppLifecycle] Inactivity timeout exceeded - triggering logout');
        _cancelInactivityTimer();
        onInactivityTimeout();
        return;
      }
    }

    _cancelInactivityTimer();
    _backgroundTime = null;
  }

  /// Start inactivity timer
  void _startInactivityTimer() {
    _cancelInactivityTimer();

    _inactivityTimer = Timer(inactivityDuration, () {
      debugPrint('[AppLifecycle] Inactivity timer expired - triggering logout');
      onInactivityTimeout();
    });

    debugPrint('[AppLifecycle] Inactivity timer started for ${inactivityDuration.inMinutes} minutes');
  }

  /// Cancel inactivity timer
  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// Dispose resources
  void dispose() {
    _cancelInactivityTimer();
    _backgroundTime = null;
  }
}

/// Provider for app lifecycle service
final appLifecycleServiceProvider = Provider<AppLifecycleService>((ref) {
  throw UnimplementedError('AppLifecycleService must be overridden in main.dart');
});
