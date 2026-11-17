import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ask_jeeves_vmi/data/services/api/geofence_api_service.dart';
import 'package:ask_jeeves_vmi/data/services/location/geofence_monitor_service.dart';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';
import 'package:ask_jeeves_vmi/data/services/api/api_client.dart';

/// Comprehensive Geofence Service
/// Combines API management with local monitoring
class GeofenceService {
  final GeofenceApiService _apiService;
  final GeofenceMonitorService _monitorService;
  final SecureStorageService _storage;

  GeofenceService(
    this._apiService,
    this._monitorService,
    this._storage,
  );

  /// Create a geofence for the current device
  Future<GeofenceResponse> createGeofenceForCurrentDevice({
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    bool active = true,
  }) async {
    try {
      // Get device UUID from storage (MAC address-like identifier)
      final deviceUuid = await _storage.read('device_uuid');
      if (deviceUuid == null) {
        throw Exception('Device UUID not found. Please authenticate first.');
      }


      // Create geofence via API
      final geofence = await _apiService.createGeofence(
        deviceUuid: deviceUuid,
        name: name,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        active: active,
      );

      return geofence;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all geofences for the current device
  Future<List<GeofenceResponse>> getCurrentDeviceGeofences({
    bool activeOnly = true,
  }) async {
    try {
      final deviceUuid = await _storage.read('device_uuid');
      if (deviceUuid == null) {
        throw Exception('Device UUID not found. Please authenticate first.');
      }


      final geofences = await _apiService.getDeviceGeofences(
        deviceUuid: deviceUuid,
        activeOnly: activeOnly,
      );

      return geofences;
    } catch (e) {
      rethrow;
    }
  }

  /// Check current location against device's geofences
  /// If no geofence exists (404), automatically creates one at current location
  /// Retries on 503 (service unavailable) with exponential backoff
  Future<GeofenceCheckResponse> checkCurrentLocation({int retryCount = 0}) async {
    try {
      // Get device UUID
      final deviceUuid = await _storage.read('device_uuid');
      if (deviceUuid == null) {
        throw Exception('Device UUID not found. Please authenticate first.');
      }

      // Get current position with timeout
      final position = await _monitorService.getCurrentPosition().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Failed to get location within 15 seconds');
        },
      );
      
      if (position == null) {
        throw Exception('Unable to get current location');
      }


      // Check location via API with timeout
      try {
        final result = await _apiService.checkLocation(
          deviceUuid: deviceUuid,
          latitude: position.latitude,
          longitude: position.longitude,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Geofence API request timed out');
          },
        );

        return result;
      } on ApiException catch (e) {
        // Handle 503 (service unavailable) - retry with backoff
        if (e.statusCode == 503 && retryCount < 3) {
          final delaySeconds = (retryCount + 1) * 2; // 2s, 4s, 6s
          
          await Future.delayed(Duration(seconds: delaySeconds));
          
          // Retry recursively
          return checkCurrentLocation(retryCount: retryCount + 1);
        }
        
        // Handle 404 (no geofence found)
        if (e.statusCode == 404 && retryCount == 0) {
          
          try {
            // Create geofence at current location with 15m radius
            await createGeofenceAtCurrentLocation(
              name: 'Login Location',
              radius: 15.0,
            );
            
            
            // Retry the location check
            final result = await _apiService.checkLocation(
              deviceUuid: deviceUuid,
              latitude: position.latitude,
              longitude: position.longitude,
            );
            
            return result;
          } catch (createError) {
            rethrow;
          }
        }
        
        // For other errors, rethrow
        rethrow;
      } catch (e) {
        // Handle non-ApiException errors
        final errorString = e.toString().toLowerCase();
        
        // Check if error is 503 (service unavailable) - retry with backoff
        if ((errorString.contains('503') || 
             errorString.contains('service unavailable') ||
             errorString.contains('temporarily unavailable')) &&
            retryCount < 3) {
          
          final delaySeconds = (retryCount + 1) * 2; // 2s, 4s, 6s
          
          await Future.delayed(Duration(seconds: delaySeconds));
          
          // Retry recursively
          return checkCurrentLocation(retryCount: retryCount + 1);
        }
        
        // Check if error is 404 (no geofence found)
        if ((errorString.contains('404') || 
             errorString.contains('not found') ||
             errorString.contains('no active geofences')) &&
            retryCount == 0) {
          
          // Create geofence at current location with 2 radius
          await createGeofenceAtCurrentLocation(
            name: 'Login Location',
            radius: 15.0,
          );
          
          
          // Retry the location check
          final result = await _apiService.checkLocation(
            deviceUuid: deviceUuid,
            latitude: position.latitude,
            longitude: position.longitude,
          );
          
          return result;
        } else {
          // Not a 404 or 503 error, rethrow
          rethrow;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Initialize monitoring with device's geofences from API
  Future<void> initializeMonitoringFromAPI() async {
    try {

      // Fetch geofences from API
      final geofences = await getCurrentDeviceGeofences(activeOnly: true);

      if (geofences.isEmpty) {
        return;
      }

      // Convert API geofences to monitor regions
      final regions = geofences.map((g) => GeofenceRegion(
        id: g.id.toString(),
        name: g.name,
        latitude: g.latitude,
        longitude: g.longitude,
        radiusMeters: g.radius,
      )).toList();

      // Initialize monitor service
      await _monitorService.initialize(regions);

    } catch (e) {
      rethrow;
    }
  }

  /// Start continuous monitoring
  Future<void> startMonitoring() async {
    await _monitorService.startMonitoring();
  }

  /// Stop monitoring
  Future<void> stopMonitoring() async {
    await _monitorService.stopMonitoring();
  }

  /// Get monitoring status stream
  Stream<GeofenceStatus> get statusStream => _monitorService.statusStream;

  /// Get current monitoring status
  GeofenceStatus get currentStatus => _monitorService.currentStatus;

  /// Update a geofence
  Future<GeofenceResponse> updateGeofence({
    required int geofenceId,
    String? name,
    double? latitude,
    double? longitude,
    double? radius,
    bool? active,
  }) async {
    try {

      final updated = await _apiService.updateGeofence(
        geofenceId: geofenceId,
        name: name,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        active: active,
      );


      // Reinitialize monitoring if active geofences changed
      if (active != null) {
        await initializeMonitoringFromAPI();
      }

      return updated;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a geofence
  Future<void> deleteGeofence(int geofenceId) async {
    try {

      await _apiService.deleteGeofence(geofenceId);


      // Reinitialize monitoring
      await initializeMonitoringFromAPI();
    } catch (e) {
      rethrow;
    }
  }

  /// Create geofence at current location
  Future<GeofenceResponse> createGeofenceAtCurrentLocation({
    required String name,
    required double radius,
  }) async {
    try {
      // Get current position
      final position = await _monitorService.getCurrentPosition();
      if (position == null) {
        throw Exception('Unable to get current location');
      }


      // Get address from coordinates to use as geofence name
      String geofenceName = name; // Default to provided name
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          
          // Build address string from placemark
          List<String> addressParts = [];
          
          if (place.street != null && place.street!.isNotEmpty) {
            addressParts.add(place.street!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }
          
          if (addressParts.isNotEmpty) {
            geofenceName = addressParts.join(', ');
          }
        }
      } catch (e) {
        // Continue with default name if geocoding fails
      }

      return await createGeofenceForCurrentDevice(
        name: geofenceName,
        latitude: position.latitude,
        longitude: position.longitude,
        radius: radius,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Validate current location and return detailed result
  /// If no geofence exists (404), automatically creates one at current location
  Future<GeofenceValidationResult> validateCurrentLocation() async {
    try {
      final checkResult = await checkCurrentLocation();
      final position = _monitorService.lastPosition;

      return GeofenceValidationResult(
        isValid: checkResult.insideGeofence,
        distance: checkResult.distance,
        geofenceId: checkResult.geofenceId,
        geofenceName: checkResult.geofenceName,
        message: checkResult.message,
        latitude: position?.latitude,
        longitude: position?.longitude,
        accuracy: position?.accuracy,
      );
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _monitorService.dispose();
  }
}

/// Geofence Validation Result
class GeofenceValidationResult {
  final bool isValid;
  final double distance;
  final int? geofenceId;
  final String? geofenceName;
  final String message;
  final double? latitude;
  final double? longitude;
  final double? accuracy;

  GeofenceValidationResult({
    required this.isValid,
    required this.distance,
    this.geofenceId,
    this.geofenceName,
    required this.message,
    this.latitude,
    this.longitude,
    this.accuracy,
  });

  @override
  String toString() {
    return 'GeofenceValidationResult('
        'isValid: $isValid, '
        'distance: ${distance.toStringAsFixed(1)}m, '
        'geofence: $geofenceName, '
        'message: $message'
        ')';
  }
}

/// Provider for Geofence Service
final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  final apiService = ref.watch(geofenceApiServiceProvider);
  final monitorService = ref.watch(geofenceMonitorServiceProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  
  final service = GeofenceService(apiService, monitorService, storage);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
