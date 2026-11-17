import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ask_jeeves_vmi/data/services/location/realtime_location_service.dart';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';
import 'dart:async';

/// Service to validate location and internet connectivity
class LocationValidationService {
  static final LocationValidationService _instance = LocationValidationService._internal();
  
  factory LocationValidationService() {
    return _instance;
  }
  
  LocationValidationService._internal();

  final RealtimeLocationService _locationService = RealtimeLocationService();
  final SecureStorageService _storage = SecureStorageService();
  
  StreamSubscription<LocationData>? _locationSubscription;
  
  bool _isLocationValid = false;
  LocationData? _lastValidLocation;
  LocationData? _enrollmentLocation;
  
  // Callbacks
  VoidCallback? onLocationOutOfBounds;
  VoidCallback? onInternetDisconnected;
  VoidCallback? onValidationFailed;

  /// Load enrollment location from storage
  Future<bool> loadEnrollmentLocation() async {
    try {
      final latStr = await _storage.read('enrollment_latitude');
      final lonStr = await _storage.read('enrollment_longitude');
      
      if (latStr != null && lonStr != null) {
        final lat = double.parse(latStr);
        final lon = double.parse(lonStr);
        
        _enrollmentLocation = LocationData(
          latitude: lat,
          longitude: lon,
          accuracy: 0,
          altitude: 0,
          speed: 0,
          timestamp: DateTime.now(),
        );
        
        debugPrint('[LocationValidation] ✅ Enrollment location loaded: $_enrollmentLocation');
        return true;
      }
      
      debugPrint('[LocationValidation] ⚠️ No enrollment location found');
      return false;
    } catch (e) {
      debugPrint('[LocationValidation] ❌ Error loading enrollment location: $e');
      return false;
    }
  }

  /// Validate location is within geofence
  Future<bool> validateLocationInGeofence() async {
    try {
      debugPrint('[LocationValidation] 📍 Validating location...');
      
      // Load enrollment location if not already loaded
      if (_enrollmentLocation == null) {
        await loadEnrollmentLocation();
      }
      
      if (_enrollmentLocation == null) {
        debugPrint('[LocationValidation] ⚠️ No enrollment location found');
        return false;
      }
      
      // Get current location
      final currentLocation = await _locationService.getCurrentLocation();
      
      // Check if within geofence (15 meters)
      final distance = LocationData.calculateDistance(currentLocation, _enrollmentLocation!);
      _isLocationValid = distance <= 15; // 15 meter radius
      
      if (_isLocationValid) {
        _lastValidLocation = currentLocation;
        debugPrint('[LocationValidation] ✅ Location valid (${distance.toStringAsFixed(1)}m from center)');
      } else {
        debugPrint('[LocationValidation] ❌ Location out of bounds (${distance.toStringAsFixed(1)}m from center)');
      }
      
      return _isLocationValid;
    } catch (e) {
      debugPrint('[LocationValidation] ❌ Error validating location: $e');
      return false;
    }
  }

  /// Start continuous validation
  Future<void> startContinuousValidation() async {
    try {
      debugPrint('[LocationValidation] 🔄 Starting continuous validation...');
      
      // Load enrollment location
      await loadEnrollmentLocation();
      
      if (_enrollmentLocation == null) {
        debugPrint('[LocationValidation] ⚠️ Cannot start validation - no enrollment location');
        return;
      }
      
      // Start location tracking
      await _locationService.startTracking(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Check every 5 meters
        timeInterval: 10000, // Check every 10 seconds
      );
      
      // Monitor location changes
      _locationSubscription = _locationService.locationUpdates.listen((location) async {
        await _validateLocationChange(location);
      });
      
      debugPrint('[LocationValidation] ✅ Continuous validation started');
    } catch (e) {
      debugPrint('[LocationValidation] ❌ Error starting validation: $e');
    }
  }

  /// Validate location change
  Future<void> _validateLocationChange(LocationData currentLocation) async {
    try {
      if (_enrollmentLocation == null) return;
      
      // Calculate distance
      final distance = LocationData.calculateDistance(currentLocation, _enrollmentLocation!);
      final wasValid = _isLocationValid;
      _isLocationValid = distance <= 15; // 15 meter radius
      
      // If location went out of bounds - IMMEDIATE LOGOUT with simple message
      if (wasValid && !_isLocationValid) {
        debugPrint('[LocationValidation] 🚨 User left authorized area (${distance.toStringAsFixed(1)}m)');
        _isLocationValid = false;
        onLocationOutOfBounds?.call();
      }
      
      // If location came back in bounds
      if (!wasValid && _isLocationValid) {
        _lastValidLocation = currentLocation;
        debugPrint('[LocationValidation] ✅ User back in authorized area');
      }
    } catch (e) {
      debugPrint('[LocationValidation] ❌ Error validating location change: $e');
    }
  }

  /// Stop continuous validation
  Future<void> stopContinuousValidation() async {
    try {
      await _locationSubscription?.cancel();
      await _locationService.stopTracking();
      debugPrint('[LocationValidation] ✅ Continuous validation stopped');
    } catch (e) {
      debugPrint('[LocationValidation] ❌ Error stopping validation: $e');
    }
  }

  /// Validate app can be opened
  Future<bool> validateAppCanOpen() async {
    try {
      debugPrint('[LocationValidation] 🔐 Validating app access...');
      
      // Check location
      final locationValid = await validateLocationInGeofence();
      if (!locationValid) {
        debugPrint('[LocationValidation] ❌ Location verification failed');
        onLocationOutOfBounds?.call();
        return false;
      }
      
      debugPrint('[LocationValidation] ✅ Access granted');
      return true;
    } catch (e) {
      debugPrint('[LocationValidation] ❌ Error validating app access: $e');
      onValidationFailed?.call();
      return false;
    }
  }

  /// Get validation status
  Map<String, dynamic> getValidationStatus() {
    return {
      'isLocationValid': _isLocationValid,
      'lastValidLocation': _lastValidLocation,
      'enrollmentLocation': _enrollmentLocation,
      'timestamp': DateTime.now(),
    };
  }

  /// Dispose resources
  void dispose() {
    _locationSubscription?.cancel();
    _locationService.dispose();
    debugPrint('[LocationValidation] ✅ Resources disposed');
  }
}
