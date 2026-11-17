import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ask_jeeves_vmi/data/services/api/api_client.dart';

/// API Service for WebRTC streaming endpoints
class WebRTCApiService {
  final ApiClient _apiClient;
  
  // Logging configuration - set to false to reduce verbose logs
  static const bool _verboseLogging = false;

  WebRTCApiService(this._apiClient);

  /// Create a new WebRTC session
  /// POST /api/v1/webrtc/session
  Future<WebRTCSessionResponse> createWebRTCSession({
    required int sessionId,
    required String deviceUuid,
    String targetUrl = '', // Empty string means backend will use default
    String? resolution, // Resolution in format "1920x1080" (optional - backend will use default if not provided)
    String? loginEmail, // User's email for auto-login (optional)
    String? loginPassword, // User's password for auto-login (optional)
    required int timeoutMinutes,
  }) async {
    try {
      if (_verboseLogging) {
        debugPrint('[WebRTC API] Creating session...');
        debugPrint('[WebRTC API] ========== REQUEST TO BACKEND ==========');
      }
      
      final requestData = <String, dynamic>{
        'session_id': sessionId,
        'device_uuid': deviceUuid,
        'target_url': targetUrl, // Backend will use default if empty
        'timeout_minutes': timeoutMinutes,
        'login_email': loginEmail ?? '', // Send empty string if null
        'login_password': loginPassword ?? '', // Send empty string if null
      };
      
      // Add resolution if provided
      if (resolution != null && resolution.isNotEmpty) {
        requestData['resolution'] = resolution;
      }
      
      if (_verboseLogging) {
        debugPrint('[WebRTC API]   session_id: $sessionId');
        debugPrint('[WebRTC API]   device_uuid: ${deviceUuid.substring(0, 8)}...');
        if (targetUrl.isEmpty) {
          debugPrint('[WebRTC API]   target_url: (empty - backend will use default)');
        } else {
          debugPrint('[WebRTC API]   target_url: $targetUrl');
        }
        debugPrint('[WebRTC API]   timeout_minutes: $timeoutMinutes');
        if (loginEmail != null && loginEmail.isNotEmpty) {
          debugPrint('[WebRTC API]   login_email: $loginEmail');
        } else {
          debugPrint('[WebRTC API]   login_email: (not provided)');
        }
        if (loginPassword != null && loginPassword.isNotEmpty) {
          debugPrint('[WebRTC API]   login_password: ******** (provided)');
        } else {
          debugPrint('[WebRTC API]   login_password: (not provided)');
        }
        if (resolution != null && resolution.isNotEmpty) {
          debugPrint('[WebRTC API]   resolution: $resolution');
        } else {
          debugPrint('[WebRTC API]   resolution: (backend will use default 1920x1080)');
        }
        debugPrint('[WebRTC API] ==========================================');
      }
      
      final response = await _apiClient.post(
        '/webrtc/session',
        data: requestData,
      );

      final sessionResponse = WebRTCSessionResponse.fromJson(response.data);
      
      if (_verboseLogging) {
        debugPrint('[WebRTC API] ✅ Session created');
        debugPrint('[WebRTC API] Response status: ${response.statusCode}');
        debugPrint('[WebRTC API] ========== BACKEND RESPONSE ==========');
        debugPrint('[WebRTC API] Container ID: ${sessionResponse.containerId}');
        debugPrint('[WebRTC API] Container Name: ${sessionResponse.containerName}');
        debugPrint('[WebRTC API] Status: ${sessionResponse.status}');
        debugPrint('[WebRTC API] Target URL: ${sessionResponse.targetUrl}');
        debugPrint('[WebRTC API] Resolution (backend decided): ${sessionResponse.resolution}');
        debugPrint('[WebRTC API] Created: ${sessionResponse.createdAt}');
        debugPrint('[WebRTC API] Expires: ${sessionResponse.expiresAt}');
        debugPrint('[WebRTC API] Message: ${sessionResponse.message}');
        debugPrint('[WebRTC API] ==========================================');
      }
      
      return sessionResponse;
    } catch (e) {
      // Always show errors
      debugPrint('[WebRTC API] ❌ Session creation failed: $e');
      debugPrint('[WebRTC API] ❌ This is a BACKEND error');
      rethrow;
    }
  }

  /// Get WebRTC session information
  /// GET /api/v1/webrtc/session/{session_id}
  Future<WebRTCSessionInfoResponse> getWebRTCSession({
    required int sessionId,
    required String deviceUuid,
  }) async {
    try {
      final response = await _apiClient.get(
        '/webrtc/session/$sessionId',
        queryParameters: {
          'device_uuid': deviceUuid,
        },
      );

      return WebRTCSessionInfoResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('[WebRTCAPI] ❌ Error fetching session: $e');
      rethrow;
    }
  }

  /// Destroy a WebRTC session
  /// DELETE /api/v1/webrtc/session/{session_id}
  Future<WebRTCDestroyResponse> destroyWebRTCSession({
    required int sessionId,
    required String deviceUuid,
  }) async {
    try {
      debugPrint('[WebRTC API] ========================================');
      debugPrint('[WebRTC API] 🗑️ DESTROYING WEBRTC SESSION');
      debugPrint('[WebRTC API] ========================================');
      debugPrint('[WebRTC API] Request details:');
      debugPrint('[WebRTC API]   Session ID: $sessionId');
      debugPrint('[WebRTC API]   Device UUID: ${deviceUuid.substring(0, 8)}...');
      debugPrint('[WebRTC API]   Endpoint: DELETE /webrtc/session/$sessionId');
      debugPrint('[WebRTC API] ');
      debugPrint('[WebRTC API] 🔄 Sending destroy request to backend...');
      
      final response = await _apiClient.delete(
        '/webrtc/session/$sessionId',
        queryParameters: {
          'device_uuid': deviceUuid,
        },
      );

      final destroyResponse = WebRTCDestroyResponse.fromJson(response.data);
      
      debugPrint('[WebRTC API] ========================================');
      debugPrint('[WebRTC API] ✅ SESSION DESTROYED SUCCESSFULLY');
      debugPrint('[WebRTC API] ========================================');
      debugPrint('[WebRTC API] Response details:');
      debugPrint('[WebRTC API]   Container: ${destroyResponse.containerName}');
      debugPrint('[WebRTC API]   Session ID: ${destroyResponse.sessionId}');
      debugPrint('[WebRTC API]   Device UUID: ${destroyResponse.deviceUuid.substring(0, 8)}...');
      debugPrint('[WebRTC API]   Destroyed: ${destroyResponse.destroyed}');
      debugPrint('[WebRTC API]   Message: ${destroyResponse.message}');
      debugPrint('[WebRTC API] ========================================');
      
      return destroyResponse;
    } catch (e) {
      debugPrint('[WebRTC API] ========================================');
      debugPrint('[WebRTC API] ❌ DESTROY SESSION FAILED');
      debugPrint('[WebRTC API] ========================================');
      debugPrint('[WebRTC API] Error: $e');
      debugPrint('[WebRTC API] Session ID: $sessionId');
      debugPrint('[WebRTC API] ');
      
      if (e.toString().contains('404')) {
        debugPrint('[WebRTC API] 📭 Session not found (404)');
        debugPrint('[WebRTC API] This means:');
        debugPrint('[WebRTC API]   - Session was already destroyed');
        debugPrint('[WebRTC API]   - Session never existed');
        debugPrint('[WebRTC API]   - Session expired and was auto-cleaned');
      } else if (e.toString().contains('500')) {
        debugPrint('[WebRTC API] 🔴 Backend error (500)');
        debugPrint('[WebRTC API] This is a BACKEND issue');
        debugPrint('[WebRTC API] Check backend logs for details');
      } else {
        debugPrint('[WebRTC API] ⚠️ Unknown error');
        debugPrint('[WebRTC API] This might be a network issue');
      }
      
      debugPrint('[WebRTC API] ========================================');
      rethrow;
    }
  }

  /// Handle WebRTC offer and get answer
  /// POST /api/v1/webrtc/offer
  Future<WebRTCAnswerResponse> handleWebRTCOffer({
    required int sessionId,
    required String deviceUuid,
    required String sdp,
    required String type,
  }) async {
    try {
      // Validate inputs before sending
      if (sdp.isEmpty) {
        throw Exception('SDP is empty');
      }
      if (type.isEmpty) {
        throw Exception('SDP type is empty');
      }
      
      // Only log if verbose mode is enabled
      if (_verboseLogging) {
        debugPrint('[WebRTC API] Sending offer (${sdp.length} chars)');
        debugPrint('[WebRTC API] Session ID: $sessionId');
        
        // Check for required SDP components
        final hasVideo = sdp.contains('m=video');
        final hasAudio = sdp.contains('m=audio');
        final hasCandidates = sdp.contains('a=candidate:');
        final hasIceUfrag = sdp.contains('a=ice-ufrag:');
        final hasIcePwd = sdp.contains('a=ice-pwd:');
        final hasFingerprint = sdp.contains('a=fingerprint:');
        
        debugPrint('[WebRTC API] SDP Components:');
        debugPrint('[WebRTC API]   - Video: $hasVideo');
        debugPrint('[WebRTC API]   - Audio: $hasAudio');
        debugPrint('[WebRTC API]   - ICE Candidates: $hasCandidates');
        debugPrint('[WebRTC API]   - ICE ufrag: $hasIceUfrag');
        debugPrint('[WebRTC API]   - ICE pwd: $hasIcePwd');
        debugPrint('[WebRTC API]   - Fingerprint: $hasFingerprint');
        
        if (!hasVideo && !hasAudio) {
          debugPrint('[WebRTC API] ⚠️ WARNING: No media lines in SDP!');
        }
        if (!hasCandidates) {
          debugPrint('[WebRTC API] ⚠️ WARNING: No ICE candidates in SDP!');
        }
      }
      
      final requestData = {
        'session_id': sessionId,
        'device_uuid': deviceUuid,
        'sdp': sdp,
        'type': type,
      };
      
      final response = await _apiClient.post(
        '/webrtc/offer',
        data: requestData,
      );

      if (_verboseLogging) {
        debugPrint('[WebRTC API] ✅ Answer received (${response.data['sdp'].toString().length} chars)');
      }
      
      return WebRTCAnswerResponse.fromJson(response.data);
    } catch (e) {
      // Always show backend errors
      debugPrint('[WebRTC API] ❌ Offer failed: $e');
      debugPrint('[WebRTC API] ❌ BACKEND ERROR - Check backend logs');
      rethrow;
    }
  }

  /// Cleanup expired WebRTC sessions (admin/cron endpoint)
  /// POST /api/v1/webrtc/cleanup-expired
  Future<void> cleanupExpiredSessions() async {
    try {
      debugPrint('[WebRTC API] ========================================');
      debugPrint('[WebRTC API] 🧹 CLEANING UP EXPIRED SESSIONS');
      debugPrint('[WebRTC API] ========================================');
      debugPrint('[WebRTC API] Endpoint: POST /webrtc/cleanup-expired');
      debugPrint('[WebRTC API] This will remove all expired Docker containers');
      debugPrint('[WebRTC API] ');
      debugPrint('[WebRTC API] 🔄 Sending cleanup request...');
      
      await _apiClient.post('/webrtc/cleanup-expired');
      
      debugPrint('[WebRTC API] ========================================');
      debugPrint('[WebRTC API] ✅ EXPIRED SESSIONS CLEANED UP');
      debugPrint('[WebRTC API] ========================================');
      debugPrint('[WebRTC API] All expired Docker containers removed');
      debugPrint('[WebRTC API] ========================================');
    } catch (e) {
      debugPrint('[WebRTC API] ========================================');
      debugPrint('[WebRTC API] ⚠️ CLEANUP EXPIRED SESSIONS FAILED');
      debugPrint('[WebRTC API] ========================================');
      debugPrint('[WebRTC API] Error: $e');
      debugPrint('[WebRTC API] ');
      
      if (e.toString().contains('403') || e.toString().contains('401')) {
        debugPrint('[WebRTC API] 🔒 Permission denied');
        debugPrint('[WebRTC API] This endpoint requires admin permissions');
      } else if (e.toString().contains('404')) {
        debugPrint('[WebRTC API] 📭 Endpoint not found');
        debugPrint('[WebRTC API] Backend may not have this endpoint implemented');
      } else if (e.toString().contains('500')) {
        debugPrint('[WebRTC API] 🔴 Backend error');
        debugPrint('[WebRTC API] Check backend logs for details');
      }
      
      debugPrint('[WebRTC API] ========================================');
      rethrow;
    }
  }
}

/// WebRTC Session Response (from create endpoint)
class WebRTCSessionResponse {
  final String containerId;
  final String containerName;
  final int sessionId;
  final String deviceUuid;
  final String? accessToken;
  final String targetUrl;
  final String resolution;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String message;

  WebRTCSessionResponse({
    required this.containerId,
    required this.containerName,
    required this.sessionId,
    required this.deviceUuid,
    this.accessToken,
    required this.targetUrl,
    required this.resolution,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.message,
  });

  factory WebRTCSessionResponse.fromJson(Map<String, dynamic> json) {
    return WebRTCSessionResponse(
      containerId: json['container_id'] as String,
      containerName: json['container_name'] as String,
      sessionId: json['session_id'] as int,
      deviceUuid: json['device_uuid'] as String,
      accessToken: json['access_token'] as String?,
      targetUrl: json['target_url'] as String,
      resolution: json['resolution'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'container_id': containerId,
      'container_name': containerName,
      'session_id': sessionId,
      'device_uuid': deviceUuid,
      'access_token': accessToken,
      'target_url': targetUrl,
      'resolution': resolution,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'message': message,
    };
  }
}

/// WebRTC Session Info Response (from get endpoint)
class WebRTCSessionInfoResponse {
  final String containerId;
  final String containerName;
  final int sessionId;
  final String deviceUuid;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;

  WebRTCSessionInfoResponse({
    required this.containerId,
    required this.containerName,
    required this.sessionId,
    required this.deviceUuid,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  factory WebRTCSessionInfoResponse.fromJson(Map<String, dynamic> json) {
    return WebRTCSessionInfoResponse(
      containerId: json['container_id'] as String,
      containerName: json['container_name'] as String,
      sessionId: json['session_id'] as int,
      deviceUuid: json['device_uuid'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

/// WebRTC Destroy Response
class WebRTCDestroyResponse {
  final String containerName;
  final int sessionId;
  final String deviceUuid;
  final bool destroyed;
  final String message;

  WebRTCDestroyResponse({
    required this.containerName,
    required this.sessionId,
    required this.deviceUuid,
    required this.destroyed,
    required this.message,
  });

  factory WebRTCDestroyResponse.fromJson(Map<String, dynamic> json) {
    return WebRTCDestroyResponse(
      containerName: json['container_name'] as String,
      sessionId: json['session_id'] as int,
      deviceUuid: json['device_uuid'] as String,
      destroyed: json['destroyed'] as bool,
      message: json['message'] as String,
    );
  }
}

/// WebRTC Answer Response (from offer endpoint)
class WebRTCAnswerResponse {
  final String sdp;
  final String type;

  WebRTCAnswerResponse({
    required this.sdp,
    required this.type,
  });

  factory WebRTCAnswerResponse.fromJson(Map<String, dynamic> json) {
    return WebRTCAnswerResponse(
      sdp: json['sdp'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sdp': sdp,
      'type': type,
    };
  }
}

/// Provider for WebRTC API Service
final webRTCApiServiceProvider = Provider<WebRTCApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WebRTCApiService(apiClient);
});
