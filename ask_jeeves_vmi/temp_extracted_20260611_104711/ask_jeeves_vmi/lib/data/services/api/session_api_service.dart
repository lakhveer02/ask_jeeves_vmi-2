import 'package:flutter/foundation.dart';
import 'package:ask_jeeves_vmi/data/services/api/api_client.dart';

/// Session API Service - Backend session management
class SessionApiService {
  final ApiClient _apiClient;

  SessionApiService(this._apiClient);

  /// Create a new session for a device
  /// POST /api/v1/sessions/device/{device_uuid}
  Future<SessionResponse> createSession({
    required String deviceUuid,
    int expiresInMinutes = 480, // Default: 8 hours
  }) async {
    try {
      debugPrint('[SessionAPI] Creating session for device: $deviceUuid');
      debugPrint('[SessionAPI] Expires in: $expiresInMinutes minutes');
      
      final response = await _apiClient.post(
        '/sessions/device/$deviceUuid',
        queryParameters: {
          'expires_in_minutes': expiresInMinutes,
        },
      );

      debugPrint('[SessionAPI] Response status: ${response.statusCode}');
      debugPrint('[SessionAPI] Response body: ${response.data}');

      if (response.statusCode == 201) {
        return SessionResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to create session: ${response.statusCode} - ${response.data}');
      }
    } on ApiException catch (e) {
      debugPrint('[SessionAPI] ApiException creating session: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[SessionAPI] Error creating session: $e');
      rethrow;
    }
  }

  /// Get all sessions for a device
  /// GET /api/v1/sessions/device/{device_uuid}
  Future<List<SessionResponse>> getDeviceSessions({
    required String deviceUuid,
    bool activeOnly = true,
  }) async {
    try {
      debugPrint('[SessionAPI] Getting sessions for device: $deviceUuid');
      
      final response = await _apiClient.get(
        '/sessions/device/$deviceUuid',
        queryParameters: {
          'active_only': activeOnly,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SessionResponse.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get sessions: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      debugPrint('[SessionAPI] ApiException getting sessions: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[SessionAPI] Error getting sessions: $e');
      rethrow;
    }
  }

  /// Get session by ID
  /// GET /api/v1/sessions/{session_id}
  Future<SessionResponse> getSession(int sessionId) async {
    try {
      final response = await _apiClient.get('/sessions/$sessionId');

      if (response.statusCode == 200) {
        return SessionResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to get session: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      debugPrint('[SessionAPI] ApiException getting session: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[SessionAPI] Error getting session: $e');
      rethrow;
    }
  }

  /// Check session location against geofence
  /// POST /api/v1/sessions/{session_id}/check-location
  Future<SessionResponse> checkSessionLocation({
    required int sessionId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      debugPrint('[SessionAPI] Checking session location:');
      debugPrint('  Session ID: $sessionId');
      debugPrint('  Location: $latitude, $longitude');
      
      final response = await _apiClient.post(
        '/sessions/$sessionId/check-location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      debugPrint('[SessionAPI] Location check response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final session = SessionResponse.fromJson(response.data);
        
        debugPrint('[SessionAPI] Geo status: ${session.geoStatus}');
        debugPrint('[SessionAPI] Active: ${session.active}');
        
        return session;
      } else {
        throw Exception('Failed to check location: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      debugPrint('[SessionAPI] ApiException checking location: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[SessionAPI] Error checking location: $e');
      rethrow;
    }
  }

  /// Terminate a session
  /// POST /api/v1/sessions/{session_id}/terminate
  Future<SessionTerminationResponse> terminateSession({
    required int sessionId,
    String reason = 'Manual termination',
  }) async {
    try {
      debugPrint('[SessionAPI] Terminating session: $sessionId');
      debugPrint('[SessionAPI] Reason: $reason');
      
      final response = await _apiClient.post(
        '/sessions/$sessionId/terminate',
        queryParameters: {
          'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        return SessionTerminationResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to terminate session: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      debugPrint('[SessionAPI] ApiException terminating session: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[SessionAPI] Error terminating session: $e');
      rethrow;
    }
  }

  /// Terminate all sessions for a device
  /// POST /api/v1/sessions/device/{device_uuid}/terminate-all
  Future<void> terminateAllDeviceSessions({
    required String deviceUuid,
    String reason = 'Device logout',
  }) async {
    try {
      debugPrint('[SessionAPI] Terminating all sessions for device: $deviceUuid');
      
      final response = await _apiClient.post(
        '/sessions/device/$deviceUuid/terminate-all',
        queryParameters: {
          'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('[SessionAPI] All sessions terminated successfully');
      } else {
        throw Exception('Failed to terminate all sessions: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      debugPrint('[SessionAPI] ApiException terminating all sessions: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[SessionAPI] Error terminating all sessions: $e');
      rethrow;
    }
  }
}

/// Session Response Model
class SessionResponse {
  final int id;
  final String deviceUuid;
  final String sessionToken;
  final String geoStatus;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime? endedAt;
  final bool active;

  SessionResponse({
    required this.id,
    required this.deviceUuid,
    required this.sessionToken,
    required this.geoStatus,
    required this.startedAt,
    required this.expiresAt,
    this.endedAt,
    required this.active,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      id: json['id'],
      deviceUuid: json['device_uuid'],
      sessionToken: json['session_token'],
      geoStatus: json['geo_status'],
      startedAt: DateTime.parse(json['started_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      active: json['active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_uuid': deviceUuid,
      'session_token': sessionToken,
      'geo_status': geoStatus,
      'started_at': startedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'active': active,
    };
  }
}

/// Session Termination Response Model
class SessionTerminationResponse {
  final int sessionId;
  final String deviceUuid;
  final String reason;
  final DateTime terminatedAt;
  final String message;

  SessionTerminationResponse({
    required this.sessionId,
    required this.deviceUuid,
    required this.reason,
    required this.terminatedAt,
    required this.message,
  });

  factory SessionTerminationResponse.fromJson(Map<String, dynamic> json) {
    return SessionTerminationResponse(
      sessionId: json['session_id'],
      deviceUuid: json['device_uuid'],
      reason: json['reason'],
      terminatedAt: DateTime.parse(json['terminated_at']),
      message: json['message'],
    );
  }
}
