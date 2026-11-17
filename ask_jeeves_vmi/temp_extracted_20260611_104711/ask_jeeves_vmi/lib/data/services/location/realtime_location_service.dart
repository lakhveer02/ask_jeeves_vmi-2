import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Model for location data
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.timestamp,
  });

  /// Calculate distance between two locations (in meters)
  static double calculateDistance(LocationData loc1, LocationData loc2) {
    return Geolocator.distanceBetween(
      loc1.latitude,
      loc1.longitude,
      loc2.latitude,
      loc2.longitude,
    );
  }

  @override
  String toString() {
    return 'Location($latitude, $longitude) ±${accuracy.toStringAsFixed(1)}m';
  }
}

/// Real-time location tracking service
class RealtimeLocationService {
  static final RealtimeLocationService _instance = RealtimeLocationService._internal();
  
  factory RealtimeLocationService() {
    return _instance;
  }
  
  RealtimeLocationService._internal();

  StreamSubscription<Position>? _positionStream;
  final StreamController<LocationData> _locationController = StreamController<LocationData>.broadcast();
  
  LocationData? _lastLocation;
  bool _isTracking = false;

  /// Stream of location updates
  Stream<LocationData> get locationUpdates => _locationController.stream;
  
  /// Get last known location
  LocationData? get lastLocation => _lastLocation;
  
  /// Check if tracking is active
  bool get isTracking => _isTracking;

  /// Start real-time location tracking
  Future<void> startTracking({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 10, // Update every 10 meters
    int timeInterval = 5000, // Update every 5 seconds
  }) async {
    if (_isTracking) {
      debugPrint('[RealtimeLocation] Tracking already active');
      return;
    }

    try {
      debugPrint('[RealtimeLocation] 📍 Starting real-time location tracking...');

      // Check permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Get initial location
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
      );
      
      _lastLocation = LocationData(
        latitude: initialPosition.latitude,
        longitude: initialPosition.longitude,
        accuracy: initialPosition.accuracy,
        altitude: initialPosition.altitude,
        speed: initialPosition.speed,
        timestamp: DateTime.now(),
      );
      
      _locationController.add(_lastLocation!);
      debugPrint('[RealtimeLocation] ✅ Initial location: $_lastLocation');

      // Start continuous tracking
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          timeLimit: Duration(milliseconds: timeInterval),
        ),
      ).listen(
        (Position position) {
          _lastLocation = LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            altitude: position.altitude,
            speed: position.speed,
            timestamp: DateTime.now(),
          );
          
          _locationController.add(_lastLocation!);
          debugPrint('[RealtimeLocation] 📍 Location updated: $_lastLocation');
        },
        onError: (error) {
          debugPrint('[RealtimeLocation] ❌ Location error: $error');
        },
      );

      _isTracking = true;
      debugPrint('[RealtimeLocation] ✅ Real-time tracking started');
    } catch (e) {
      debugPrint('[RealtimeLocation] ❌ Error starting tracking: $e');
      rethrow;
    }
  }

  /// Stop real-time location tracking
  Future<void> stopTracking() async {
    try {
      await _positionStream?.cancel();
      _positionStream = null;
      _isTracking = false;
      debugPrint('[RealtimeLocation] ✅ Tracking stopped');
    } catch (e) {
      debugPrint('[RealtimeLocation] ❌ Error stopping tracking: $e');
    }
  }

  /// Get current location once
  Future<LocationData> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async {
    try {
      debugPrint('[RealtimeLocation] 📍 Getting current location...');
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
      );
      
      final location = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: DateTime.now(),
      );
      
      debugPrint('[RealtimeLocation] ✅ Current location: $location');
      return location;
    } catch (e) {
      debugPrint('[RealtimeLocation] ❌ Error getting location: $e');
      rethrow;
    }
  }

  /// Check if location is within geofence
  bool isWithinGeofence(LocationData center, double radiusMeters) {
    if (_lastLocation == null) return false;
    
    final distance = LocationData.calculateDistance(_lastLocation!, center);
    return distance <= radiusMeters;
  }

  /// Get distance to a location
  double? getDistanceTo(LocationData destination) {
    if (_lastLocation == null) return null;
    return LocationData.calculateDistance(_lastLocation!, destination);
  }

  /// Dispose resources
  void dispose() {
    _positionStream?.cancel();
    _locationController.close();
    _isTracking = false;
    debugPrint('[RealtimeLocation] ✅ Resources disposed');
  }
}
