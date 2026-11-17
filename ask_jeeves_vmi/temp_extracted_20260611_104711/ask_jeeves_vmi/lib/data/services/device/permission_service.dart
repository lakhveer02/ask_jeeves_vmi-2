import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle app permissions at launch
class PermissionService {
  /// Check if all required permissions are granted
  static Future<bool> checkAllPermissions() async {
    final locationStatus = await Permission.locationWhenInUse.status;
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;
    final photosStatus = await Permission.photos.status;

    debugPrint('[Permissions] 🔍 Permission check:');
    debugPrint('[Permissions]   Location: ${locationStatus.name}');
    debugPrint('[Permissions]   Camera: ${cameraStatus.name}');
    debugPrint('[Permissions]   Microphone: ${microphoneStatus.name}');
    debugPrint('[Permissions]   Photos: ${photosStatus.name}');

    return locationStatus.isGranted &&
        cameraStatus.isGranted &&
        microphoneStatus.isGranted &&
        photosStatus.isGranted;
  }

  /// Check if location permission is permanently denied
  static Future<bool> isLocationPermanentlyDenied() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isPermanentlyDenied;
  }

  /// Check current location permission status
  static Future<PermissionStatus> getLocationStatus() async {
    return await Permission.locationWhenInUse.status;
  }

  /// Request all required permissions at app launch
  static Future<bool> requestAllPermissions(BuildContext context) async {
    debugPrint('[Permissions] 🚀 Starting permission request flow...');
    
    // FIRST: Check if all permissions are already granted
    debugPrint('[Permissions] 🔍 Checking existing permissions...');
    final locationStatus = await Permission.locationWhenInUse.status;
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;
    final photosStatus = await Permission.photos.status;
    
    debugPrint('[Permissions] Current status:');
    debugPrint('[Permissions]   Location: ${locationStatus.name}');
    debugPrint('[Permissions]   Camera: ${cameraStatus.name}');
    debugPrint('[Permissions]   Microphone: ${microphoneStatus.name}');
    debugPrint('[Permissions]   Photos: ${photosStatus.name}');
    
    // If all permissions already granted, skip requesting
    if (locationStatus.isGranted && 
        cameraStatus.isGranted && 
        microphoneStatus.isGranted && 
        photosStatus.isGranted) {
      debugPrint('[Permissions] ✅ All permissions already granted - skipping request');
      return true;
    }
    
    debugPrint('[Permissions] ⚠️ Some permissions missing - requesting...');
    
    // Only request location if not already granted
    PermissionStatus whenInUseStatus = locationStatus;
    if (!locationStatus.isGranted) {
      debugPrint('[Permissions] 📍 Step 1: Requesting locationWhenInUse...');
      whenInUseStatus = await Permission.locationWhenInUse.request();
      debugPrint('[Permissions] Location When In Use: ${whenInUseStatus.name}');
    } else {
      debugPrint('[Permissions] 📍 Location already granted - skipping');
    }

    // If location is permanently denied, show settings dialog
    if (whenInUseStatus.isPermanentlyDenied) {
      debugPrint('[Permissions] ❌ Location permanently denied');
      debugPrint('[Permissions] 🔧 Showing dialog to open Settings...');
      if (context.mounted) {
        final shouldOpenSettings = await _showOpenSettingsDialog(context);
        debugPrint('[Permissions] User chose to open settings: $shouldOpenSettings');
        if (shouldOpenSettings) {
          debugPrint('[Permissions] 📱 Opening iOS Settings...');
          await openAppSettings();
        }
      }
      return false;
    }

    // If location is denied (but not permanently), show critical warning
    if (whenInUseStatus.isDenied) {
      debugPrint('[Permissions] ❌ Location permission denied');
      if (context.mounted) {
        await _showLocationCriticalDialog(context);
      }
      return false;
    }

    // If "When In Use" is granted, optionally request "Always" for background monitoring
    if (whenInUseStatus.isGranted) {
      debugPrint('[Permissions] ✅ Location When In Use granted');
      
      // Check if "Always" is already granted
      final alwaysCurrentStatus = await Permission.locationAlways.status;
      if (!alwaysCurrentStatus.isGranted) {
        debugPrint('[Permissions] 📍 Step 2: Requesting locationAlways for background monitoring...');
        
        final alwaysStatus = await Permission.locationAlways.request();
        debugPrint('[Permissions] Location Always: ${alwaysStatus.name}');
        
        if (alwaysStatus.isGranted) {
          debugPrint('[Permissions] ✅ Location Always granted');
        } else {
          debugPrint('[Permissions] ⚠️ Location Always denied (When In Use still works)');
        }
      } else {
        debugPrint('[Permissions] 📍 Location Always already granted - skipping');
      }
    }

    // Request camera permission only if not granted
    PermissionStatus finalCameraStatus = cameraStatus;
    if (!cameraStatus.isGranted) {
      debugPrint('[Permissions] 📷 Step 3: Requesting camera...');
      finalCameraStatus = await Permission.camera.request();
      debugPrint('[Permissions] Camera: ${finalCameraStatus.name}');
    } else {
      debugPrint('[Permissions] 📷 Camera already granted - skipping');
    }

    // Request microphone permission only if not granted
    PermissionStatus finalMicrophoneStatus = microphoneStatus;
    if (!microphoneStatus.isGranted) {
      debugPrint('[Permissions] 🎤 Step 4: Requesting microphone...');
      finalMicrophoneStatus = await Permission.microphone.request();
      debugPrint('[Permissions] Microphone: ${finalMicrophoneStatus.name}');
    } else {
      debugPrint('[Permissions] 🎤 Microphone already granted - skipping');
    }

    // Request photo library permission only if not granted
    PermissionStatus finalPhotosStatus = photosStatus;
    if (!photosStatus.isGranted) {
      debugPrint('[Permissions] 📸 Step 5: Requesting photos...');
      finalPhotosStatus = await Permission.photos.request();
      debugPrint('[Permissions] Photos: ${finalPhotosStatus.name}');
    } else {
      debugPrint('[Permissions] 📸 Photos already granted - skipping');
    }

    // Check if all critical permissions are granted
    if (whenInUseStatus.isGranted) {
      debugPrint('[Permissions] ✅ All critical permissions granted');
      return true;
    } else {
      debugPrint('[Permissions] ⚠️ Some permissions were denied');
      return false;
    }
  }

  /// Request "Always" location permission (call AFTER "When In Use" is granted)
  static Future<PermissionStatus> requestAlwaysLocationPermission() async {
    debugPrint('[Permissions] 📍 Requesting locationAlways for background monitoring...');
    
    // Check if "When In Use" is granted first
    final whenInUseStatus = await Permission.locationWhenInUse.status;
    if (!whenInUseStatus.isGranted) {
      debugPrint('[Permissions] ⚠️ Cannot request Always - When In Use not granted');
      return whenInUseStatus;
    }
    
    // Request "Always" permission
    final alwaysStatus = await Permission.locationAlways.request();
    debugPrint('[Permissions] Location Always: ${alwaysStatus.name}');
    
    return alwaysStatus;
  }

  /// Show snackbar to explain why permissions are needed
  static Future<bool> showPermissionRationale(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location, Camera, Microphone & Photos needed for secure vault access'),
        backgroundColor: AppTheme.electricCyan,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
    return true;
  }

  /// Show snackbar to open app settings
  static Future<bool> _showOpenSettingsDialog(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enable Location, Camera, Microphone & Photos in Settings'),
        backgroundColor: AppTheme.warningOrange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
    return true;
  }

  /// Show critical location permission snackbar
  static Future<void> _showLocationCriticalDialog(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location access is CRITICAL for security - required to validate geofence & prevent unauthorized access'),
        backgroundColor: AppTheme.warningRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
