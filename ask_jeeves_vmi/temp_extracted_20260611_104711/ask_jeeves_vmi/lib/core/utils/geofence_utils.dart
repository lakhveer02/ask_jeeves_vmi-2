import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

/// Geofence utility class for distance calculations and geofence validation
/// Uses Haversine formula for accurate distance calculations
class GeofenceUtils {
  /// Calculate distance between two coordinates in meters
  /// Uses Geolocator's distanceBetween which implements the Haversine formula
  /// 
  /// Returns distance in meters
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Calculate distance from a position to a point
  static double calculateDistanceFromPosition({
    required Position position,
    required double targetLat,
    required double targetLon,
  }) {
    return calculateDistance(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: targetLat,
      lon2: targetLon,
    );
  }

  /// Check if a position is inside a geofence
  /// 
  /// Returns true if the position is within the radius of the geofence center
  static bool isInsideGeofence({
    required double currentLat,
    required double currentLon,
    required double geofenceLat,
    required double geofenceLon,
    required double radiusMeters,
  }) {
    final distance = calculateDistance(
      lat1: currentLat,
      lon1: currentLon,
      lat2: geofenceLat,
      lon2: geofenceLon,
    );
    
    return distance <= radiusMeters;
  }

  /// Check if a position is inside a geofence and return detailed result
  /// 
  /// Returns a GeofenceCheckResult with distance and inside status
  static GeofenceCheckResult checkGeofence({
    required double currentLat,
    required double currentLon,
    required double geofenceLat,
    required double geofenceLon,
    required double radiusMeters,
  }) {
    final distance = calculateDistance(
      lat1: currentLat,
      lon1: currentLon,
      lat2: geofenceLat,
      lon2: geofenceLon,
    );
    
    final isInside = distance <= radiusMeters;
    
    return GeofenceCheckResult(
      distance: distance,
      isInside: isInside,
      radiusMeters: radiusMeters,
    );
  }

  /// Calculate bearing (direction) from one point to another in degrees
  /// 0° = North, 90° = East, 180° = South, 270° = West
  static double calculateBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    final lonDiff = _degreesToRadians(lon2 - lon1);

    final y = math.sin(lonDiff) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(lonDiff);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = _radiansToDegrees(bearingRad);

    return (bearingDeg + 360) % 360;
  }

  /// Get cardinal direction from bearing
  /// Returns: N, NE, E, SE, S, SW, W, NW
  static String getCardinalDirection(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Calculate the area of a circular geofence in square meters
  static double calculateGeofenceArea(double radiusMeters) {
    return math.pi * radiusMeters * radiusMeters;
  }

  /// Check if position accuracy is acceptable for geofence validation
  /// 
  /// Returns true if accuracy is better than the threshold
  static bool isAccuracyAcceptable({
    required double accuracy,
    double threshold = 50.0, // Default 50 meters
  }) {
    return accuracy <= threshold;
  }

  /// Get distance status message
  static String getDistanceStatusMessage({
    required double distance,
    required double radiusMeters,
  }) {
    if (distance <= radiusMeters) {
      return 'Inside geofence';
    } else {
      final excess = distance - radiusMeters;
      return 'Outside geofence by ${excess.toStringAsFixed(1)}m';
    }
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Convert radians to degrees
  static double _radiansToDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }

  /// Validate multiple geofences and return the closest one
  static MultiGeofenceResult checkMultipleGeofences({
    required double currentLat,
    required double currentLon,
    required List<GeofencePoint> geofences,
  }) {
    if (geofences.isEmpty) {
      throw ArgumentError('Geofences list cannot be empty');
    }

    GeofenceCheckResult? closestGeofence;
    GeofencePoint? closestPoint;
    double minDistance = double.infinity;
    bool isInsideAny = false;

    for (final geofence in geofences) {
      final result = checkGeofence(
        currentLat: currentLat,
        currentLon: currentLon,
        geofenceLat: geofence.latitude,
        geofenceLon: geofence.longitude,
        radiusMeters: geofence.radiusMeters,
      );

      if (result.distance < minDistance) {
        minDistance = result.distance;
        closestGeofence = result;
        closestPoint = geofence;
      }

      if (result.isInside) {
        isInsideAny = true;
      }
    }

    return MultiGeofenceResult(
      isInsideAny: isInsideAny,
      closestGeofence: closestGeofence!,
      closestPoint: closestPoint!,
      totalGeofences: geofences.length,
    );
  }
}

/// Result of a geofence check
class GeofenceCheckResult {
  final double distance;
  final bool isInside;
  final double radiusMeters;

  GeofenceCheckResult({
    required this.distance,
    required this.isInside,
    required this.radiusMeters,
  });

  /// Distance from the edge of the geofence
  /// Negative if inside, positive if outside
  double get distanceFromEdge => distance - radiusMeters;

  /// Percentage of radius (0-100+)
  /// 0% = at center, 100% = at edge, >100% = outside
  double get radiusPercentage => (distance / radiusMeters) * 100;

  @override
  String toString() {
    return 'GeofenceCheckResult('
        'distance: ${distance.toStringAsFixed(1)}m, '
        'isInside: $isInside, '
        'radius: ${radiusMeters.toStringAsFixed(1)}m'
        ')';
  }
}

/// Represents a geofence point
class GeofencePoint {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  GeofencePoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });
}

/// Result of checking multiple geofences
class MultiGeofenceResult {
  final bool isInsideAny;
  final GeofenceCheckResult closestGeofence;
  final GeofencePoint closestPoint;
  final int totalGeofences;

  MultiGeofenceResult({
    required this.isInsideAny,
    required this.closestGeofence,
    required this.closestPoint,
    required this.totalGeofences,
  });

  @override
  String toString() {
    return 'MultiGeofenceResult('
        'isInsideAny: $isInsideAny, '
        'closestDistance: ${closestGeofence.distance.toStringAsFixed(1)}m, '
        'closestGeofence: ${closestPoint.name}'
        ')';
  }
}
