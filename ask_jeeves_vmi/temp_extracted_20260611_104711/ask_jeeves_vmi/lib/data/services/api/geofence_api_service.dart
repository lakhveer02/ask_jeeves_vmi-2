import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ask_jeeves_vmi/data/services/api/api_client.dart';

/// Geofence API Service
/// Handles all geofence-related API calls
class GeofenceApiService {
  final ApiClient _apiClient;

  GeofenceApiService(this._apiClient);

  /// Create a new geofence for a device
  Future<GeofenceResponse> createGeofence({
    required String deviceUuid,
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    bool active = true,
  }) async {
    try {
      
      final response = await _apiClient.post(
        '/geofences',
        data: {
          'device_uuid': deviceUuid,
          'name': name,
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
          'active': active,
        },
      );

      return GeofenceResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all geofences for a device
  Future<List<GeofenceResponse>> getDeviceGeofences({
    required String deviceUuid,
    bool activeOnly = true,
  }) async {
    try {
      
      final response = await _apiClient.get(
        '/geofences/device/$deviceUuid',
        queryParameters: {
          'active_only': activeOnly,
        },
      );

      final List<dynamic> data = response.data as List<dynamic>;
      final geofences = data.map((json) => GeofenceResponse.fromJson(json as Map<String, dynamic>)).toList();
      
      return geofences;
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific geofence by ID
  Future<GeofenceResponse> getGeofence(int geofenceId) async {
    try {
      
      final response = await _apiClient.get('/geofences/$geofenceId');
      
      return GeofenceResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

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
      
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (radius != null) data['radius'] = radius;
      if (active != null) data['active'] = active;

      final response = await _apiClient.put(
        '/geofences/$geofenceId',
        data: data,
      );

      return GeofenceResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a geofence
  Future<void> deleteGeofence(int geofenceId) async {
    try {
      
      await _apiClient.delete('/geofences/$geofenceId');
      
    } catch (e) {
      rethrow;
    }
  }

  /// Check if a location is within device's geofence
  Future<GeofenceCheckResponse> checkLocation({
    required String deviceUuid,
    required double latitude,
    required double longitude,
  }) async {
    try {
      
      final response = await _apiClient.post(
        '/geofences/check/$deviceUuid',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      final result = GeofenceCheckResponse.fromJson(response.data);
      
      
      return result;
    } catch (e) {
      rethrow;
    }
  }
}

/// Geofence Response Model
class GeofenceResponse {
  final int id;
  final String deviceUuid;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  GeofenceResponse({
    required this.id,
    required this.deviceUuid,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GeofenceResponse.fromJson(Map<String, dynamic> json) {
    return GeofenceResponse(
      id: json['id'] as int,
      deviceUuid: json['device_uuid'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      active: json['active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_uuid': deviceUuid,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'active': active,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// Geofence Check Response Model
class GeofenceCheckResponse {
  final bool insideGeofence;
  final double distance;
  final int? geofenceId;
  final String? geofenceName;
  final String message;

  GeofenceCheckResponse({
    required this.insideGeofence,
    required this.distance,
    this.geofenceId,
    this.geofenceName,
    required this.message,
  });

  factory GeofenceCheckResponse.fromJson(Map<String, dynamic> json) {
    // Parse distance - API returns distance in meters
    double distanceValue = (json['distance'] as num).toDouble();
    
    // Check if API explicitly provides a unit field
    final String? unit = json['distance_unit'] as String?;
    
    if (unit != null) {
      // Use explicit unit from API
      if (unit.toLowerCase() == 'km' || unit.toLowerCase() == 'kilometers') {
        distanceValue = distanceValue * 1000;
      }
      // If unit is 'm' or 'meters', no conversion needed
    }
    // If no unit field, assume API returns meters (no conversion needed)
    
    return GeofenceCheckResponse(
      insideGeofence: json['inside_geofence'] as bool,
      distance: distanceValue,
      geofenceId: json['geofence_id'] as int?,
      geofenceName: json['geofence_name'] as String?,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'inside_geofence': insideGeofence,
    'distance': distance,
    if (geofenceId != null) 'geofence_id': geofenceId,
    if (geofenceName != null) 'geofence_name': geofenceName,
    'message': message,
  };
}

/// Provider for Geofence API Service
final geofenceApiServiceProvider = Provider<GeofenceApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GeofenceApiService(apiClient);
});
