// ignore_for_file: deprecated_member_use

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mock Position class (since geolocator is disabled)
class Position {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  
  Position({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
  });
}

/// Service for geolocation and geofencing
/// COMMENTED OUT - Geolocation functionality disabled
class GeolocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    // return await Geolocator.isLocationServiceEnabled();
    return false; // Geolocation disabled
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    // final status = await Permission.location.request();
    // return status.isGranted;
    return false; // Geolocation disabled
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    // Geolocation disabled - return null
    return null;
  }

  /// Get current position (alias for getCurrentLocation)
  Future<Position> getCurrentPosition() async {
    // Geolocation disabled - return mock position
    return Position(
      latitude: 0.0,
      longitude: 0.0,
      accuracy: 0.0,
      speed: 0.0,
    );
  }

  /// Check if current location is within geofence
  Future<GeofenceResult> checkGeofence({
    required double centerLat,
    required double centerLon,
    required double radiusMeters,
  }) async {
    // final position = await getCurrentLocation();
    
    // if (position == null) {
    //   return GeofenceResult(
    //     isWithinGeofence: false,
    //     distance: null,
    //     currentLocation: null,
    //     error: 'Unable to get current location',
    //   );
    // }

    // // Calculate distance from center
    // final distance = Geolocator.distanceBetween(
    //   centerLat,
    //   centerLon,
    //   position.latitude,
    //   position.longitude,
    // );

    // return GeofenceResult(
    //   isWithinGeofence: distance <= radiusMeters,
    //   distance: distance,
    //   currentLocation: position,
    //   error: null,
    // );
    
    return GeofenceResult(
      isWithinGeofence: false,
      distance: null,
      currentLocation: null,
      error: 'Geolocation disabled',
    );
  }

  /// Validate location (anti-spoof check - simplified)
  Future<bool> validateLocation(Position position) async {
    // // Check accuracy
    // if (position.accuracy > 50) {
    //   return false; // Poor accuracy might indicate spoofing
    // }

    // // Check if speed is realistic (not teleporting)
    // if (position.speed > 100) { // 100 m/s = 360 km/h
    //   return false;
    // }

    // // In production, implement more sophisticated checks:
    // // - Compare with cell tower location
    // // - Check against known GPS spoofing patterns
    // // - Verify with multiple location providers

    // return true;
    return false; // Geolocation disabled
  }

  /// Get distance between two coordinates in meters
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return 0.0; // Geolocation disabled
  }

  /// Stream location updates
  Stream<Position> getLocationStream() {
    // return Geolocator.getPositionStream(
    //   locationSettings: const LocationSettings(
    //     accuracy: LocationAccuracy.high,
    //     distanceFilter: 10, // Update every 10 meters
    //   ),
    // );
    return Stream.empty(); // Geolocation disabled
  }
}

/// Result of geofence check
class GeofenceResult {
  final bool isWithinGeofence;
  final double? distance;
  final Position? currentLocation;
  final String? error;

  GeofenceResult({
    required this.isWithinGeofence,
    this.distance,
    this.currentLocation,
    this.error,
  });
}

// ==================== Riverpod Provider ====================

/// Provider for GeolocationService
final geolocationServiceProvider = Provider<GeolocationService>((ref) {
  return GeolocationService();
});
