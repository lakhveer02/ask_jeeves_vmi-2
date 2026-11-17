import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';
import 'package:ask_jeeves_vmi/data/services/api/session_api_service.dart';
import 'package:ask_jeeves_vmi/data/services/api/api_client.dart';

/// Service for managing user sessions
class SessionService {
  final SecureStorageService _storage = SecureStorageService();
  late final SessionApiService _sessionApi;
  final Uuid _uuid = const Uuid();
  
  Timer? _sessionTimer;
  Timer? _tokenRotationTimer;
  DateTime? _sessionStartTime;
  String? _currentSessionId;
  int? _backendSessionId;
  String? _sessionToken;

  // Session timeout in minutes (8 hours = 480 minutes)
  static const int sessionTimeoutMinutes = 480;
  static const int tokenRotationMinutes = 5;

  SessionService(ApiClient apiClient) {
    _sessionApi = SessionApiService(apiClient);
  }

  /// Start a new session (or resume existing one)
  /// First checks if active session exists, otherwise creates new one
  Future<String> startSession({
    required String userId,
    required String email,
  }) async {
    try {
      // Get device UUID
      final deviceUuid = await _storage.read('device_uuid');
      if (deviceUuid == null) {
        throw Exception('Device UUID not found. Please authenticate first.');
      }

      debugPrint('[Session] Starting session for device: $deviceUuid');

      // Check if active session already exists
      SessionResponse? sessionResponse;
      try {
        debugPrint('[Session] Checking for existing active sessions...');
        final existingSessions = await _sessionApi.getDeviceSessions(
          deviceUuid: deviceUuid,
          activeOnly: true,
        );

        debugPrint('[Session] Found ${existingSessions.length} active session(s)');
        
        if (existingSessions.isNotEmpty) {
          // Use existing session
          sessionResponse = existingSessions.first;
          debugPrint('[Session] ♻️ REUSING existing active session:');
          debugPrint('  Session ID: ${sessionResponse.id}');
          debugPrint('  Session Token: ${sessionResponse.sessionToken}');
          debugPrint('  Geo Status: ${sessionResponse.geoStatus}');
          debugPrint('  Started At: ${sessionResponse.startedAt}');
          debugPrint('  Expires At: ${sessionResponse.expiresAt}');
          debugPrint('[Session] ✅ Same session ID will be used for WebRTC');
        } else {
          debugPrint('[Session] No active sessions found - will create new one');
        }
      } catch (e) {
        debugPrint('[Session] Error checking existing sessions: $e');
        debugPrint('[Session] Will create new session');
      }

      // If no existing session, create new one
      if (sessionResponse == null) {
        debugPrint('[Session] 🆕 Creating NEW backend session...');
        debugPrint('[Session] This will generate a NEW session ID');
        sessionResponse = await _sessionApi.createSession(
          deviceUuid: deviceUuid,
          expiresInMinutes: sessionTimeoutMinutes,
        );

        debugPrint('[Session] ✅ Backend session created:');
        debugPrint('  Session ID: ${sessionResponse.id} (NEW)');
        debugPrint('  Session Token: ${sessionResponse.sessionToken}');
        debugPrint('  Geo Status: ${sessionResponse.geoStatus}');
        debugPrint('  Expires At: ${sessionResponse.expiresAt}');
        debugPrint('[Session] This session ID will be used for WebRTC');
      }

      // Generate local session ID
      _currentSessionId = _uuid.v4();
      _sessionStartTime = DateTime.now();
      _backendSessionId = sessionResponse.id;
      _sessionToken = sessionResponse.sessionToken;

      // Save session data
      await _storage.saveSessionToken(_currentSessionId!);
      await _storage.write('backend_session_id', sessionResponse.id.toString());
      await _storage.write('backend_session_token', sessionResponse.sessionToken);
      await _storage.saveUserId(userId);
      await _storage.saveUserEmail(email);
      await _storage.saveLastLoginTime(_sessionStartTime!);

      // Start session timeout timer
      _startSessionTimer();

      // Start token rotation timer
      _startTokenRotationTimer();

      debugPrint('[Session] Session started successfully');
      return _currentSessionId!;
    } catch (e) {
      debugPrint('[Session] Error starting session: $e');
      rethrow;
    }
  }

  /// Start session timeout timer
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(
      Duration(minutes: sessionTimeoutMinutes),
      () {
        // Session expired
        endSession(reason: 'Session timeout');
      },
    );
  }

  /// Start token rotation timer
  void _startTokenRotationTimer() {
    _tokenRotationTimer?.cancel();
    _tokenRotationTimer = Timer.periodic(
      Duration(minutes: tokenRotationMinutes),
      (timer) {
        // Rotate tokens
        _rotateTokens();
      },
    );
  }

  /// Rotate authentication tokens
  Future<void> _rotateTokens() async {
    debugPrint('Rotating authentication tokens...');
    // In production, call backend API to get new tokens
    // For now, just log the rotation
    final currentToken = await _storage.getAccessToken();
    if (currentToken != null) {
      // Generate new token (in production, get from backend)
      final newToken = _uuid.v4();
      await _storage.saveAccessToken(newToken);
      debugPrint('Token rotated successfully');
    }
  }

  /// Extend session (reset timeout)
  void extendSession() {
    _startSessionTimer();
  }

  /// End session and cleanup
  Future<void> endSession({String reason = 'User logout'}) async {
    try {
      debugPrint('[Session] Ending session: $reason');

      // Terminate backend session if exists
      if (_backendSessionId != null) {
        try {
          await _sessionApi.terminateSession(
            sessionId: _backendSessionId!,
            reason: reason,
          );
          debugPrint('[Session] Backend session terminated');
        } catch (e) {
          debugPrint('[Session] Error terminating backend session: $e');
          // Continue with local cleanup even if backend fails
        }
      }

      // Cancel timers
      _sessionTimer?.cancel();
      _tokenRotationTimer?.cancel();

      // Clear session data
      await _storage.clearAuthData();

      // Reset state
      _currentSessionId = null;
      _sessionStartTime = null;
      _backendSessionId = null;
      _sessionToken = null;
    } catch (e) {
      debugPrint('[Session] Error ending session: $e');
      rethrow;
    }
  }

  /// Get current session ID
  String? getCurrentSessionId() {
    return _currentSessionId;
  }

  /// Get backend session ID
  int? getBackendSessionId() {
    return _backendSessionId;
  }

  /// Get session token
  String? getSessionToken() {
    return _sessionToken;
  }

  /// Check session location against geofence
  Future<SessionResponse> checkSessionLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (_backendSessionId == null) {
      throw Exception('No active session');
    }

    try {
      final response = await _sessionApi.checkSessionLocation(
        sessionId: _backendSessionId!,
        latitude: latitude,
        longitude: longitude,
      );

      // If session was terminated due to geo violation, end local session
      if (!response.active) {
        debugPrint('[Session] Session terminated by backend due to geo violation');
        await endSession(reason: 'Geofence violation');
      }

      return response;
    } catch (e) {
      debugPrint('[Session] Error checking session location: $e');
      rethrow;
    }
  }

  /// Get current session info from backend
  Future<SessionResponse?> getSessionInfo() async {
    if (_backendSessionId == null) {
      return null;
    }

    try {
      return await _sessionApi.getSession(_backendSessionId!);
    } catch (e) {
      debugPrint('[Session] Error getting session info: $e');
      return null;
    }
  }

  /// Get session duration in seconds
  int getSessionDuration() {
    if (_sessionStartTime == null) return 0;
    return DateTime.now().difference(_sessionStartTime!).inSeconds;
  }

  /// Check if session is active
  Future<bool> isSessionActive() async {
    final sessionId = await _storage.getSessionToken();
    return sessionId != null && sessionId.isNotEmpty;
  }

  /// Get remaining session time in seconds
  int getRemainingSessionTime() {
    if (_sessionStartTime == null) return 0;
    final elapsed = DateTime.now().difference(_sessionStartTime!);
    final remaining = Duration(minutes: sessionTimeoutMinutes) - elapsed;
    return remaining.inSeconds.clamp(0, sessionTimeoutMinutes * 60);
  }

  /// Dispose resources
  void dispose() {
    _sessionTimer?.cancel();
    _tokenRotationTimer?.cancel();
  }
}
