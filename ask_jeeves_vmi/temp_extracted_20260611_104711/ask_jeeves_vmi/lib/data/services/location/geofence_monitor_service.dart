import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ask_jeeves_vmi/core/utils/geofence_utils.dart';

/// Geofence Monitor Service
/// Provides continuous location monitoring and geofence validation
class GeofenceMonitorService {
  StreamSubscription<Position>? _positionSubscription;
  StreamController<GeofenceStatus>? _statusController;
  
  List<GeofenceRegion> _allowedRegions = [];
  GeofenceStatus _currentStatus = GeofenceStatus.unknown;
  Position? _lastPosition;
  
  static const Duration heartbeatInterval = Duration(seconds: 5);
  static const double accuracyThreshold = 50.0; // meters
  
  Stream<GeofenceStatus> get statusStream {
    _statusController ??= StreamController<GeofenceStatus>.broadcast();
    return _statusController!.stream;
  }

  GeofenceStatus get currentStatus => _currentStatus;
  Position? get lastPosition => _lastPosition;

  /// Initialize geofence monitoring
  Future<void> initialize(List<GeofenceRegion> allowedRegions) async {
    _allowedRegions = allowedRegions;
    
    // Request permissions
    final permissionGranted = await _requestLocationPermissions();
    if (!permissionGranted) {
      throw GeofenceException('Location permissions not granted');
    }
    
    // Verify location services
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw GeofenceException('Location services are disabled');
    }
    
  }

  /// Start continuous geofence monitoring
  Future<void> startMonitoring() async {
    if (_positionSubscription != null) {
      return; // Already monitoring
    }
    
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
      timeLimit: heartbeatInterval,
    );
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _handlePositionUpdate,
      onError: _handleLocationError,
      cancelOnError: false,
    );
    
  }

  /// Stop geofence monitoring
  Future<void> stopMonitoring() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    
  }

  /// Handle position updates
  void _handlePositionUpdate(Position position) {
    _lastPosition = position;
    
    // Validate accuracy
    if (position.accuracy > accuracyThreshold) {
      _updateStatus(GeofenceStatus.lowAccuracy);
      return;
    }
    
    // Check if position is within allowed regions
    final isInAllowedRegion = _isPositionInAllowedRegions(position);
    
    if (isInAllowedRegion) {
      _updateStatus(GeofenceStatus.inside);
    } else {
      _updateStatus(GeofenceStatus.outside);
    }
  }

  /// Check if position is within any allowed region
  bool _isPositionInAllowedRegions(Position position) {
    for (final region in _allowedRegions) {
      // Use GeofenceUtils for accurate distance calculation
      final isInside = GeofenceUtils.isInsideGeofence(
        currentLat: position.latitude,
        currentLon: position.longitude,
        geofenceLat: region.latitude,
        geofenceLon: region.longitude,
        radiusMeters: region.radiusMeters,
      );
      
      if (isInside) {
        return true;
      }
    }
    return false;
  }

  /// Handle location errors
  void _handleLocationError(dynamic error) {
    _updateStatus(GeofenceStatus.error);
  }

  /// Update geofence status
  void _updateStatus(GeofenceStatus newStatus) {
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController?.add(newStatus);
    }
  }

  /// Request location permissions
  Future<bool> _requestLocationPermissions() async {
    // Request when-in-use permission first
    var status = await Permission.location.request();
    
    if (status.isGranted) {
      // Request always permission for background monitoring
      status = await Permission.locationAlways.request();
      return status.isGranted;
    }
    
    return false;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      
      // Add timeout to prevent hanging
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
        },
      );
      
      
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Check if currently inside geofence
  Future<bool> isInsideGeofence() async {
    final position = await getCurrentPosition();
    if (position == null) return false;
    
    return _isPositionInAllowedRegions(position);
  }

  /// Get distance to nearest geofence in meters
  Future<double?> getDistanceToNearestGeofence() async {
    final position = await getCurrentPosition();
    if (position == null || _allowedRegions.isEmpty) return null;

    double minDistance = double.infinity;

    for (final region in _allowedRegions) {
      final distance = GeofenceUtils.calculateDistance(
        lat1: position.latitude,
        lon1: position.longitude,
        lat2: region.latitude,
        lon2: region.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance == double.infinity ? null : minDistance;
  }

  /// Get detailed geofence check result for current position
  Future<GeofenceCheckResult?> getCurrentGeofenceStatus() async {
    final position = await getCurrentPosition();
    if (position == null || _allowedRegions.isEmpty) return null;

    // Find the closest geofence
    GeofenceCheckResult? closestResult;
    double minDistance = double.infinity;

    for (final region in _allowedRegions) {
      final result = GeofenceUtils.checkGeofence(
        currentLat: position.latitude,
        currentLon: position.longitude,
        geofenceLat: region.latitude,
        geofenceLon: region.longitude,
        radiusMeters: region.radiusMeters,
      );

      if (result.distance < minDistance) {
        minDistance = result.distance;
        closestResult = result;
      }
    }

    return closestResult;
  }

  void dispose() {
    _positionSubscription?.cancel();
    _statusController?.close();
  }
}

/// Geofence Region
class GeofenceRegion {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  GeofenceRegion({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  factory GeofenceRegion.fromJson(Map<String, dynamic> json) {
    return GeofenceRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radius_meters': radiusMeters,
  };
}

enum GeofenceStatus {
  unknown,
  inside,
  outside,
  lowAccuracy,
  error,
}

class GeofenceException implements Exception {
  final String message;
  GeofenceException(this.message);
  
  @override
  String toString() => 'GeofenceException: $message';
}

// Provider
final geofenceMonitorServiceProvider = Provider<GeofenceMonitorService>((ref) {
  final service = GeofenceMonitorService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
