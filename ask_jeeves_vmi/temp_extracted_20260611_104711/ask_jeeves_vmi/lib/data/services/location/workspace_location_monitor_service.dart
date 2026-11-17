import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ask_jeeves_vmi/data/services/location/geofence_service.dart';
import 'dart:async';

/// Service to monitor workspace location violations using geofence API
/// Checks user's current location against geofence boundaries
/// If user moves out of authorized area, shows warning then triggers logout
class WorkspaceLocationMonitorService {
  final GeofenceService _geofenceService;
  
  Timer? _monitorTimer;
  Timer? _warningTimer;
  bool _isMonitoring = false;
  bool _isInWarningPeriod = false;
  int _violationCount = 0;
  
  // Callback for when workspace location violation warning is triggered (10-20 seconds before logout)
  VoidCallback? onWorkspaceLocationWarning;
  
  // Callback for when workspace location violation is detected (final logout)
  VoidCallback? onWorkspaceLocationViolation;

  WorkspaceLocationMonitorService(this._geofenceService);

  /// Start monitoring workspace location violations
  void startMonitoring() {
    if (_isMonitoring) {
      return;
    }

    _isMonitoring = true;

    // Check every 10 seconds for location violations (optimized for performance)
    _monitorTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _checkWorkspaceLocationStatus();
    });
  }

  /// Stop monitoring
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _warningTimer?.cancel();
    _warningTimer = null;
    _isMonitoring = false;
    _isInWarningPeriod = false;
    _violationCount = 0;
  }

  /// Manually trigger a location check (for testing/debugging)
  Future<void> checkLocationNow() async {
    await _checkWorkspaceLocationStatus();
  }

  /// Get monitoring status
  bool get isMonitoring => _isMonitoring;

  /// Check workspace location status using geofence API
  Future<void> _checkWorkspaceLocationStatus() async {
    try {
      
      // Check current location against geofence using existing geofence API
      final checkResult = await _geofenceService.checkCurrentLocation();
      
      
      // If user is outside geofence
      if (!checkResult.insideGeofence) {
        _violationCount++;
        
        
        // First violation: Show warning and start countdown
        if (_violationCount == 1 && !_isInWarningPeriod) {
          _isInWarningPeriod = true;
          
          // Trigger warning callback
          onWorkspaceLocationWarning?.call();
          
          // Start countdown timer (15 seconds warning period)
          _warningTimer = Timer(const Duration(seconds: 15), () {
            
            // Stop monitoring
            stopMonitoring();
            
            // Trigger final logout callback
            onWorkspaceLocationViolation?.call();
          });
        }
        // If still outside after warning started
        else if (_isInWarningPeriod) {
        }
      } else {
        // User is back inside geofence
        if (_isInWarningPeriod) {
          _warningTimer?.cancel();
          _warningTimer = null;
          _isInWarningPeriod = false;
          _violationCount = 0;
        } else {
        }
      }
    } catch (e) {
      // Log errors but continue monitoring
      
      // Don't stop monitoring on error - geofence might not exist yet or temporary network issue
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}

/// Provider for Workspace Location Monitor Service
final workspaceLocationMonitorServiceProvider = Provider<WorkspaceLocationMonitorService>((ref) {
  final geofenceService = ref.watch(geofenceServiceProvider);
  
  final service = WorkspaceLocationMonitorService(geofenceService);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
