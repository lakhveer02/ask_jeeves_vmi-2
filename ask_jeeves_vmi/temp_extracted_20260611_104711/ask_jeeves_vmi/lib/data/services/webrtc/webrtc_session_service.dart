import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ask_jeeves_vmi/data/services/api/webrtc_api_service.dart';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';
import 'dart:async';

/// Service for managing WebRTC streaming sessions
class WebRTCSessionService {
  final WebRTCApiService _apiService;
  final SecureStorageService _storage;
  
  // Logging configuration - set to true to enable verbose logs
  static const bool _verboseLogging = false;
  
  // Callback for when session is accessed from web
  VoidCallback? onSessionAccessedFromWeb;
  
  // Cancellation flag to prevent race conditions during logout
  bool _isDisposed = false;

  WebRTCSessionService(this._apiService, this._storage);
  
  /// Helper method for verbose logging
  void _log(String message) {
    if (_verboseLogging) {
      debugPrint(message);
    }
  }

  /// Reset the service state (call this when starting a new session)
  void resetServiceState() {
    _isDisposed = false;
    _log('[WebRTC] 🔄 Service state reset - ready for new sessions');
  }

  /// Create a new WebRTC session for the current session
  /// This method checks if a valid session already exists before creating a new one
  Future<WebRTCSessionResponse> createWebRTCSession({
    String? targetUrl, // Made optional - backend will use default if not provided
    String? loginEmail, // User's email for auto-login (optional)
    String? loginPassword, // User's password for auto-login (optional)
    int? deviceWidth, // Device width in pixels (for backend to determine resolution)
    int? deviceHeight, // Device height in pixels (for backend to determine resolution)
    double? devicePixelRatio, // Device pixel ratio (for backend to determine resolution)
    int timeoutMinutes = 480,
    bool forceNew = false,
  }) async {
    try {
      // Check if service has been disposed (logout in progress)
      if (_isDisposed) {
        debugPrint('[WebRTC] ⚠️ Service disposed - cancelling session creation');
        throw Exception('WebRTC service disposed - logout in progress');
      }
      
      // Get session ID from storage
      final sessionIdStr = await _storage.read('backend_session_id');
      if (sessionIdStr == null) {
        throw Exception('No active session. Please log in first.');
      }

      final sessionId = int.parse(sessionIdStr);

      // Get device UUID from storage
      final deviceUuid = await _storage.read('device_uuid');
      if (deviceUuid == null) {
        throw Exception('Device UUID not found. Please authenticate first.');
      }

      // Check if we already have a valid session (unless forceNew is true)
      if (!forceNew) {
        debugPrint('[WebRTC] 🔍 Checking for existing WebRTC session...');
        final existingSession = await getCurrentWebRTCSession();
        
        if (existingSession != null) {
          debugPrint('[WebRTC] 📦 Found existing session in storage:');
          debugPrint('  Session ID: ${existingSession.sessionId}');
          debugPrint('  Container ID: ${existingSession.containerId}');
          debugPrint('  Status: ${existingSession.status}');
          debugPrint('  Expires At: ${existingSession.expiresAt}');
          debugPrint('  Resolution: ${existingSession.resolution}');
          
          // Check if resolution matches device dimensions (if provided)
          bool resolutionMismatch = false;
          if (deviceWidth != null && deviceHeight != null) {
            final expectedResolution = '${deviceWidth}x$deviceHeight';
            if (existingSession.resolution != expectedResolution) {
              debugPrint('[WebRTC] ⚠️ Resolution mismatch detected!');
              debugPrint('  Existing: ${existingSession.resolution}');
              debugPrint('  Expected: $expectedResolution');
              debugPrint('[WebRTC] 🔄 Will destroy old session and create new one with correct resolution');
              resolutionMismatch = true;
            }
          }
          
          // Check if session is still valid
          if (existingSession.expiresAt != null && 
              existingSession.expiresAt!.isAfter(DateTime.now()) &&
              !resolutionMismatch) {
            
            // Verify with backend that session still exists
            try {
              debugPrint('[WebRTC] ✅ Verifying session with backend...');
              final backendSession = await _apiService.getWebRTCSession(
                sessionId: existingSession.sessionId,  // Use WebRTC session ID from storage!
                deviceUuid: deviceUuid,
              );
              
              debugPrint('[WebRTC] ✅ Backend confirmed session exists!');
              debugPrint('  Container: ${backendSession.containerName}');
              debugPrint('  Status: ${backendSession.status}');
              debugPrint('  Expires: ${backendSession.expiresAt}');
              
              // Check if session is in a usable state
              if (backendSession.status == 'exited' || 
                  backendSession.status == 'stopped' || 
                  backendSession.status == 'failed') {
                debugPrint('[WebRTC] ⚠️ Session status is "${backendSession.status}" - cannot reuse');
                debugPrint('[WebRTC] Container has stopped/exited - will create new session');
                
                // Clear the dead session from storage
                await _storage.delete('webrtc_session_id');
                await _storage.delete('webrtc_container_id');
                await _storage.delete('webrtc_container_name');
                await _storage.delete('webrtc_access_token');
                await _storage.delete('webrtc_target_url');
                await _storage.delete('webrtc_resolution');
                await _storage.delete('webrtc_status');
                await _storage.delete('webrtc_expires_at');
                
                // Fall through to create new session
              } else {
                // Session is running - can reuse it
                debugPrint('[WebRTC] ✅ Session is running - can reuse!');
                
                // Update storage with latest info from backend
                await _storage.write('webrtc_status', backendSession.status);
                await _storage.write('webrtc_expires_at', backendSession.expiresAt.toIso8601String());
                
                // Return existing session as WebRTCSessionResponse
                debugPrint('[WebRTC] ♻️ Reusing existing WebRTC session (not creating new one)');
                return WebRTCSessionResponse(
                  containerId: backendSession.containerId,
                  containerName: backendSession.containerName,
                  sessionId: backendSession.sessionId,
                  deviceUuid: backendSession.deviceUuid,
                  accessToken: existingSession.accessToken,
                  targetUrl: existingSession.targetUrl,
                  resolution: existingSession.resolution,
                  status: backendSession.status,
                  createdAt: backendSession.createdAt,
                  expiresAt: backendSession.expiresAt,
                  message: 'Reusing existing session',
                );
              }
            } catch (e) {
              debugPrint('[WebRTC] ⚠️ Backend verification failed: $e');
              
              // Check if it's a 404 (session not found)
              if (e.toString().contains('404') || e.toString().contains('Not found')) {
                debugPrint('[WebRTC] 📭 Session not found on backend (404)');
                debugPrint('[WebRTC] This means session was destroyed or never created');
                debugPrint('[WebRTC] Clearing local storage and will create new session...');
                
                // Clear the invalid session from storage
                await _storage.delete('webrtc_session_id');
                await _storage.delete('webrtc_container_id');
                await _storage.delete('webrtc_container_name');
                await _storage.delete('webrtc_access_token');
                await _storage.delete('webrtc_target_url');
                await _storage.delete('webrtc_resolution');
                await _storage.delete('webrtc_status');
                await _storage.delete('webrtc_expires_at');
              } else {
                debugPrint('[WebRTC] Session may have been destroyed on backend');
              }
              
              debugPrint('[WebRTC] Will create new session...');
              // Continue to create new session
            }
          } else if (resolutionMismatch) {
            // Destroy old session with wrong resolution
            debugPrint('[WebRTC] 🗑️ Destroying old session with wrong resolution...');
            try {
              // Don't use destroyWebRTCSession() as it sets _isDisposed flag
              // Instead, manually destroy and clear storage
              final webrtcSessionIdStr = await _storage.read('webrtc_session_id');
              final deviceUuid = await _storage.read('device_uuid');
              
              if (webrtcSessionIdStr != null && deviceUuid != null) {
                final webrtcSessionId = int.parse(webrtcSessionIdStr);
                
                try {
                  await _apiService.destroyWebRTCSession(
                    sessionId: webrtcSessionId,
                    deviceUuid: deviceUuid,
                  );
                  debugPrint('[WebRTC] ✅ Old session destroyed');
                } catch (e) {
                  debugPrint('[WebRTC] ⚠️ Error destroying old session: $e');
                  // Continue anyway to create new session
                }
              }
              
              // Clear session info from storage
              await _storage.delete('webrtc_session_id');
              await _storage.delete('webrtc_container_id');
              await _storage.delete('webrtc_container_name');
              await _storage.delete('webrtc_access_token');
              await _storage.delete('webrtc_target_url');
              await _storage.delete('webrtc_resolution');
              await _storage.delete('webrtc_status');
              await _storage.delete('webrtc_expires_at');
              
              debugPrint('[WebRTC] ✅ Old session cleared, will create new one');
            } catch (e) {
              debugPrint('[WebRTC] ⚠️ Error during cleanup: $e');
              // Continue anyway to create new session
            }
          } else {
            debugPrint('[WebRTC] ⏰ Existing session has expired');
            debugPrint('[WebRTC] Will create new session...');
          }
        } else {
          debugPrint('[WebRTC] 📭 No existing session found in storage');
        }
      } else {
        debugPrint('[WebRTC] 🔄 Force new session requested');
      }

      debugPrint('[WebRTC] 🆕 Creating NEW WebRTC session');
      debugPrint('  Session ID: $sessionId');
      debugPrint('  Device UUID: ${deviceUuid.substring(0, 8)}...');
      if (targetUrl != null) {
        debugPrint('  Target URL: $targetUrl (app-specified)');
      } else {
        debugPrint('  Target URL: (backend will use default)');
      }
      if (loginEmail != null && loginEmail.isNotEmpty) {
        debugPrint('  Login Email: $loginEmail (for auto-login)');
      } else {
        debugPrint('  Login Email: (not provided)');
      }
      if (loginPassword != null && loginPassword.isNotEmpty) {
        debugPrint('  Login Password: ******** (provided for auto-login)');
      } else {
        debugPrint('  Login Password: (not provided)');
      }
      if (deviceWidth != null && deviceHeight != null) {
        debugPrint('  Device dimensions: ${deviceWidth}x$deviceHeight');
        if (devicePixelRatio != null) {
          debugPrint('  Device pixel ratio: $devicePixelRatio');
        }
        debugPrint('  Resolution: (backend will determine based on device dimensions)');
      } else {
        debugPrint('  Resolution: (backend will use default)');
      }
      debugPrint('  Timeout: ${timeoutMinutes}m');

      // Create WebRTC session via API
      final session = await _apiService.createWebRTCSession(
        sessionId: sessionId,
        deviceUuid: deviceUuid,
        targetUrl: targetUrl ?? '', // Send empty string if null - backend will use default
        loginEmail: loginEmail, // Send user's email for auto-login
        loginPassword: loginPassword, // Send user's password for auto-login
        resolution: (deviceWidth != null && deviceHeight != null) 
            ? '${deviceWidth}x$deviceHeight' 
            : null, // Backend will use default 1920x1080 if null
        timeoutMinutes: timeoutMinutes,
      );

      debugPrint('[WebRTC] ✅ WebRTC session created successfully');
      debugPrint('  Container ID: ${session.containerId}');
      debugPrint('  Container Name: ${session.containerName}');
      debugPrint('  Status: ${session.status}');
      if (session.accessToken != null) {
        debugPrint('  Access Token: ${session.accessToken!.substring(0, 10)}...');
      }
      debugPrint('  Target URL: ${session.targetUrl}');
      debugPrint('  Expires At: ${session.expiresAt}');
      
      // ⚠️ Check if backend returned a login URL when we didn't request it
      // (Only warn if we sent empty/null targetUrl and backend chose login page)
      final requestedLoginPage = targetUrl != null && targetUrl.contains('/login');
      final backendReturnedLoginPage = session.targetUrl.contains('/login') || 
                                        session.targetUrl.contains('login');
      
      if (backendReturnedLoginPage && !requestedLoginPage) {
        debugPrint('[WebRTC] ⚠️⚠️⚠️ BACKEND CONFIGURATION WARNING ⚠️⚠️⚠️');
        debugPrint('[WebRTC] Backend returned a LOGIN URL: ${session.targetUrl}');
        debugPrint('[WebRTC] But we requested: ${targetUrl ?? "(backend default)"}');
        debugPrint('[WebRTC] This means:');
        debugPrint('[WebRTC]   - Backend browser will show login page');
        debugPrint('[WebRTC]   - User CANNOT interact with login form (video only)');
        debugPrint('[WebRTC]   - Backend should auto-login and navigate to dashboard');
        debugPrint('[WebRTC] ');
        debugPrint('[WebRTC] BACKEND MUST:');
        debugPrint('[WebRTC]   1. Accept session token from Flutter app');
        debugPrint('[WebRTC]   2. Auto-login using the session token');
        debugPrint('[WebRTC]   3. Navigate to dashboard/workspace (NOT login page)');
        debugPrint('[WebRTC] ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️');
      } else if (backendReturnedLoginPage && requestedLoginPage) {
        debugPrint('[WebRTC] ℹ️ Backend returned login page as requested');
        debugPrint('[WebRTC] This is expected for unauthenticated users');
      } else {
        debugPrint('[WebRTC] ✅ Backend navigated to: ${session.targetUrl}');
      }

      // Check again if service was disposed during API call
      if (_isDisposed) {
        debugPrint('[WebRTC] ⚠️ Service disposed during session creation - NOT saving to storage');
        debugPrint('[WebRTC] 🗑️ Destroying newly created session immediately...');
        try {
          await _apiService.destroyWebRTCSession(
            sessionId: sessionId,
            deviceUuid: deviceUuid,
          );
          debugPrint('[WebRTC] ✅ Zombie session destroyed');
        } catch (e) {
          debugPrint('[WebRTC] ⚠️ Error destroying zombie session: $e');
        }
        throw Exception('WebRTC service disposed - session creation cancelled');
      }

      // Save session info to storage
      // ✅ FIX BUG #7: Save WebRTC session ID from API response, NOT backend_session_id!
      // NOTE: target_url is controlled by backend and saved here for informational purposes only
      await _storage.write('webrtc_session_id', session.sessionId.toString());
      await _storage.write('webrtc_container_id', session.containerId);
      await _storage.write('webrtc_container_name', session.containerName);
      if (session.accessToken != null) {
        await _storage.write('webrtc_access_token', session.accessToken!);
      }
      await _storage.write('webrtc_target_url', session.targetUrl); // Backend-controlled, for info only
      await _storage.write('webrtc_resolution', session.resolution);
      await _storage.write('webrtc_status', session.status);
      await _storage.write('webrtc_expires_at', session.expiresAt.toIso8601String());

      return session;
    } catch (e) {
      debugPrint('[WebRTC] ❌ Error creating WebRTC session: $e');
      rethrow;
    }
  }

  /// Get WebRTC session by session ID
  Future<WebRTCSessionInfoResponse> getWebRTCSession() async {
    try {
      // Get WebRTC session ID from storage (NOT backend_session_id!)
      final webrtcSessionIdStr = await _storage.read('webrtc_session_id');
      if (webrtcSessionIdStr == null) {
        throw Exception('No WebRTC session found in storage');
      }

      final webrtcSessionId = int.parse(webrtcSessionIdStr);

      // Get device UUID from storage
      final deviceUuid = await _storage.read('device_uuid');
      if (deviceUuid == null) {
        throw Exception('Device UUID not found. Please authenticate first.');
      }

      debugPrint('[WebRTC] Fetching WebRTC session: $webrtcSessionId');

      final session = await _apiService.getWebRTCSession(
        sessionId: webrtcSessionId,
        deviceUuid: deviceUuid,
      );

      debugPrint('[WebRTC] WebRTC session fetched successfully');
      return session;
    } catch (e) {
      debugPrint('[WebRTC] Error fetching WebRTC session: $e');
      rethrow;
    }
  }

  /// Handle WebRTC offer and get answer
  Future<WebRTCAnswerResponse> handleWebRTCOffer({
    required String sdp,
    required String type,
  }) async {
    try {
      // Get WebRTC session ID from storage (NOT backend_session_id!)
      final webrtcSessionIdStr = await _storage.read('webrtc_session_id');
      if (webrtcSessionIdStr == null) {
        throw Exception('No WebRTC session found in storage');
      }

      final webrtcSessionId = int.parse(webrtcSessionIdStr);

      // Get device UUID from storage
      final deviceUuid = await _storage.read('device_uuid');
      if (deviceUuid == null) {
        throw Exception('Device UUID not found. Please authenticate first.');
      }

      debugPrint('[WebRTC] Handling WebRTC offer');
      debugPrint('  WebRTC Session ID: $webrtcSessionId');
      debugPrint('  SDP Type: $type');

      final answer = await _apiService.handleWebRTCOffer(
        sessionId: webrtcSessionId,
        deviceUuid: deviceUuid,
        sdp: sdp,
        type: type,
      );

      debugPrint('[WebRTC] WebRTC answer received');
      debugPrint('  Answer Type: ${answer.type}');

      return answer;
    } catch (e) {
      debugPrint('[WebRTC] Error handling WebRTC offer: $e');
      rethrow;
    }
  }

  /// Destroy a WebRTC session
  Future<WebRTCDestroyResponse> destroyWebRTCSession() async {
    try {
      // Set disposal flag to prevent race conditions
      _isDisposed = true;
      
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] �️ TERMINATING WEBRTC SESSION');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] �🚫 Service marked as disposed - blocking new session creation');
      
      // Get WebRTC session ID from storage (NOT backend_session_id!)
      final webrtcSessionIdStr = await _storage.read('webrtc_session_id');
      if (webrtcSessionIdStr == null) {
        debugPrint('[WebRTC] ⚠️ No WebRTC session ID in storage - nothing to destroy');
        debugPrint('[WebRTC] ========================================');
        throw Exception('No WebRTC session found in storage');
      }

      final webrtcSessionId = int.parse(webrtcSessionIdStr);
      
      // Get session details before destroying
      final containerId = await _storage.read('webrtc_container_id');
      final containerName = await _storage.read('webrtc_container_name');
      final resolution = await _storage.read('webrtc_resolution');
      final status = await _storage.read('webrtc_status');
      final expiresAtStr = await _storage.read('webrtc_expires_at');

      // Get device UUID from storage
      final deviceUuid = await _storage.read('device_uuid');
      if (deviceUuid == null) {
        throw Exception('Device UUID not found. Please authenticate first.');
      }

      debugPrint('[WebRTC] 📋 SESSION DETAILS BEFORE TERMINATION:');
      debugPrint('[WebRTC]   WebRTC Session ID: $webrtcSessionId');
      debugPrint('[WebRTC]   Container ID: ${containerId ?? "unknown"}');
      debugPrint('[WebRTC]   Container Name: ${containerName ?? "unknown"}');
      debugPrint('[WebRTC]   Resolution: ${resolution ?? "unknown"}');
      debugPrint('[WebRTC]   Status: ${status ?? "unknown"}');
      debugPrint('[WebRTC]   Expires At: ${expiresAtStr ?? "unknown"}');
      debugPrint('[WebRTC]   Device UUID: ${deviceUuid.substring(0, 8)}...');
      debugPrint('[WebRTC] ');
      debugPrint('[WebRTC] 🔄 Sending destroy request to backend...');

      final response = await _apiService.destroyWebRTCSession(
        sessionId: webrtcSessionId,
        deviceUuid: deviceUuid,
      );

      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] ✅ WEBRTC SESSION TERMINATED SUCCESSFULLY');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] 📋 TERMINATION DETAILS:');
      debugPrint('[WebRTC]   Container: ${response.containerName}');
      debugPrint('[WebRTC]   Session ID: ${response.sessionId}');
      debugPrint('[WebRTC]   Device UUID: ${response.deviceUuid.substring(0, 8)}...');
      debugPrint('[WebRTC]   Destroyed: ${response.destroyed}');
      debugPrint('[WebRTC]   Message: ${response.message}');
      debugPrint('[WebRTC] ');
      debugPrint('[WebRTC] 🧹 Clearing local storage...');

      // Clear session info from storage
      await _storage.delete('webrtc_session_id');
      await _storage.delete('webrtc_container_id');
      await _storage.delete('webrtc_container_name');
      await _storage.delete('webrtc_access_token');
      await _storage.delete('webrtc_target_url');
      await _storage.delete('webrtc_resolution');
      await _storage.delete('webrtc_status');
      await _storage.delete('webrtc_expires_at');

      debugPrint('[WebRTC] ✅ Local storage cleared');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] 🎉 SESSION TERMINATION COMPLETE');
      debugPrint('[WebRTC] ========================================');

      return response;
    } catch (e) {
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] ❌ ERROR DURING SESSION TERMINATION');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] Error: $e');
      
      // If session not found (404), clear storage anyway since it doesn't exist on backend
      if (e.toString().contains('404') || e.toString().contains('Not found')) {
        debugPrint('[WebRTC] ');
        debugPrint('[WebRTC] 📭 Session not found on backend (404)');
        debugPrint('[WebRTC] This means session was already destroyed or never existed');
        debugPrint('[WebRTC] 🧹 Clearing local storage anyway...');
        
        await _storage.delete('webrtc_session_id');
        await _storage.delete('webrtc_container_id');
        await _storage.delete('webrtc_container_name');
        await _storage.delete('webrtc_access_token');
        await _storage.delete('webrtc_target_url');
        await _storage.delete('webrtc_resolution');
        await _storage.delete('webrtc_status');
        await _storage.delete('webrtc_expires_at');
        
        debugPrint('[WebRTC] ✅ Local storage cleared');
        debugPrint('[WebRTC] ========================================');
      } else {
        debugPrint('[WebRTC] ⚠️ Session may still exist on backend');
        debugPrint('[WebRTC] ⚠️ Manual cleanup may be required');
        debugPrint('[WebRTC] ========================================');
      }
      
      rethrow;
    }
  }

  /// Get current WebRTC session info from storage
  Future<WebRTCSessionInfo?> getCurrentWebRTCSession() async {
    try {
      final sessionIdStr = await _storage.read('webrtc_session_id');
      if (sessionIdStr == null) {
        return null;
      }

      final containerId = await _storage.read('webrtc_container_id');
      final containerName = await _storage.read('webrtc_container_name');
      final accessToken = await _storage.read('webrtc_access_token');
      final targetUrl = await _storage.read('webrtc_target_url');
      final resolution = await _storage.read('webrtc_resolution');
      final status = await _storage.read('webrtc_status');
      final expiresAtStr = await _storage.read('webrtc_expires_at');

      if (containerId == null || containerName == null) {
        return null;
      }

      return WebRTCSessionInfo(
        sessionId: int.parse(sessionIdStr),
        containerId: containerId,
        containerName: containerName,
        accessToken: accessToken,
        targetUrl: targetUrl ?? '',
        resolution: resolution ?? '',
        status: status ?? 'unknown',
        expiresAt: expiresAtStr != null ? DateTime.parse(expiresAtStr) : null,
      );
    } catch (e) {
      debugPrint('[WebRTC] Error getting current WebRTC session: $e');
      return null;
    }
  }

  /// Check if WebRTC session is still valid
  /// This method checks both local storage and backend status
  /// Includes retry logic with exponential backoff for transient errors
  Future<bool> isWebRTCSessionValid() async {
    try {
      final session = await getCurrentWebRTCSession();
      if (session == null) {
        debugPrint('[WebRTC] ❌ No session in storage');
        return false;
      }

      // Check if session has expired locally
      if (session.expiresAt != null && session.expiresAt!.isBefore(DateTime.now())) {
        debugPrint('[WebRTC] ⏰ WebRTC session has expired locally');
        return false;
      }

      // Verify with backend
      final webrtcSessionIdStr = await _storage.read('webrtc_session_id');
      final deviceUuid = await _storage.read('device_uuid');
      
      if (webrtcSessionIdStr == null || deviceUuid == null) {
        debugPrint('[WebRTC] ❌ Missing WebRTC session ID or device UUID');
        return false;
      }

      // Retry with exponential backoff
      return await _retryWithBackoff(
        operation: () async {
          final backendSession = await _apiService.getWebRTCSession(
            sessionId: int.parse(webrtcSessionIdStr),
            deviceUuid: deviceUuid,
          );

          debugPrint('[WebRTC] ✅ Backend confirms session is valid');
          debugPrint('  Status: ${backendSession.status}');
          debugPrint('  Expires: ${backendSession.expiresAt}');
          
          return true;
        },
        onError: (e, attempt, maxAttempts) async {
          debugPrint('[WebRTC] ⚠️ Backend validation failed (attempt $attempt/$maxAttempts): $e');
          
          // Only return false for 404 (session not found) - don't retry
          if (e.toString().contains('404') || e.toString().contains('Not found')) {
            debugPrint('[WebRTC] ❌ Session not found (404) - session is invalid');
            debugPrint('[WebRTC] 🧹 Clearing stale session from storage');
            
            // Clear stale session info from storage
            await _storage.delete('webrtc_session_id');
            await _storage.delete('webrtc_container_id');
            await _storage.delete('webrtc_container_name');
            await _storage.delete('webrtc_access_token');
            await _storage.delete('webrtc_target_url');
            await _storage.delete('webrtc_resolution');
            await _storage.delete('webrtc_status');
            await _storage.delete('webrtc_expires_at');
            
            return RetryDecision.failImmediately(false);
          } else if (e.toString().contains('500') || e.toString().contains('Something went wrong')) {
            if (attempt < maxAttempts) {
              debugPrint('[WebRTC] 🔄 Temporary backend error (500) - will retry');
              return RetryDecision.retry();
            } else {
              debugPrint('[WebRTC] ⚠️ Backend error persists after $maxAttempts attempts');
              debugPrint('[WebRTC] ✅ Assuming session is still valid to prevent unnecessary logout');
              return RetryDecision.failImmediately(true);
            }
          } else {
            if (attempt < maxAttempts) {
              debugPrint('[WebRTC] 🔄 Network or other error - will retry');
              return RetryDecision.retry();
            } else {
              debugPrint('[WebRTC] ⚠️ Error persists after $maxAttempts attempts');
              debugPrint('[WebRTC] ✅ Assuming session is still valid to prevent unnecessary logout');
              return RetryDecision.failImmediately(true);
            }
          }
        },
      );
    } catch (e) {
      debugPrint('[WebRTC] ❌ Unexpected error checking WebRTC session validity: $e');
      debugPrint('[WebRTC] ⚠️ Assuming session is still valid to prevent unnecessary logout');
      return true; // Changed: assume valid on unexpected errors to prevent false positives
    }
  }

  /// Retry an operation with exponential backoff
  /// 
  /// Parameters:
  /// - operation: The async operation to retry
  /// - onError: Callback to handle errors and decide whether to retry
  /// - maxAttempts: Maximum number of retry attempts (default: 3)
  /// - initialDelayMs: Initial delay in milliseconds (default: 500ms)
  /// - maxDelayMs: Maximum delay in milliseconds (default: 5000ms)
  /// - backoffMultiplier: Multiplier for exponential backoff (default: 2.0)
  Future<T> _retryWithBackoff<T>({
    required Future<T> Function() operation,
    required Future<RetryDecision<T>> Function(dynamic error, int attempt, int maxAttempts) onError,
    int maxAttempts = 3,
    int initialDelayMs = 500,
    int maxDelayMs = 5000,
    double backoffMultiplier = 2.0,
  }) async {
    int attempt = 0;
    int currentDelayMs = initialDelayMs;

    while (true) {
      attempt++;
      
      try {
        return await operation();
      } catch (e) {
        final decision = await onError(e, attempt, maxAttempts);
        
        if (decision.shouldRetry && attempt < maxAttempts) {
          // Calculate delay with exponential backoff
          final delayMs = currentDelayMs.clamp(initialDelayMs, maxDelayMs);
          debugPrint('[WebRTC] ⏳ Waiting ${delayMs}ms before retry $attempt/$maxAttempts...');
          
          await Future.delayed(Duration(milliseconds: delayMs));
          
          // Increase delay for next attempt
          currentDelayMs = (currentDelayMs * backoffMultiplier).round();
        } else {
          // Either we've exhausted retries or decision says to fail immediately
          return decision.fallbackValue;
        }
      }
    }
  }

  /// Get or create WebRTC session (always creates NEW session on login)
  Future<WebRTCSessionResponse> getOrCreateWebRTCSession({
    String? targetUrl, // Optional - backend will use default if not provided
    String? loginEmail, // User's email for auto-login (optional)
    String? loginPassword, // User's password for auto-login (optional)
    int? deviceWidth, // Device width in pixels (for backend to determine resolution)
    int? deviceHeight, // Device height in pixels (for backend to determine resolution)
    double? devicePixelRatio, // Device pixel ratio (for backend to determine resolution)
    int timeoutMinutes = 480,
  }) async {
    debugPrint('[WebRTC] 🔄 Get or create WebRTC session...');
    debugPrint('[WebRTC] 🆕 ALWAYS creating NEW session (forceNew=true)');
    debugPrint('[WebRTC] This ensures clean state after logout/login');
    
    // ALWAYS force new session - don't reuse old sessions from previous logins
    return await createWebRTCSession(
      targetUrl: targetUrl,
      loginEmail: loginEmail,
      loginPassword: loginPassword,
      deviceWidth: deviceWidth,
      deviceHeight: deviceHeight,
      devicePixelRatio: devicePixelRatio,
      timeoutMinutes: timeoutMinutes,
      forceNew: true,  // ✅ ALWAYS create new session
    );
  }

  /// Destroy all WebRTC sessions (cleanup expired + current session)
  /// This is useful for cleaning up all Docker containers
  Future<void> destroyAllWebRTCSessions() async {
    try {
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] 🗑️ DESTROYING ALL WEBRTC SESSIONS');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] This will:');
      debugPrint('[WebRTC]   1. Destroy current session (if exists)');
      debugPrint('[WebRTC]   2. Cleanup all expired sessions');
      debugPrint('[WebRTC] ');
      
      // First, try to destroy the current session if it exists
      try {
        final currentSession = await getCurrentWebRTCSession();
        if (currentSession != null) {
          debugPrint('[WebRTC] 📋 CURRENT SESSION FOUND:');
          debugPrint('[WebRTC]   Session ID: ${currentSession.sessionId}');
          debugPrint('[WebRTC]   Container: ${currentSession.containerName}');
          debugPrint('[WebRTC]   Status: ${currentSession.status}');
          debugPrint('[WebRTC]   Resolution: ${currentSession.resolution}');
          debugPrint('[WebRTC] ');
          debugPrint('[WebRTC] 🗑️ Destroying current session...');
          
          await destroyWebRTCSession();
          
          debugPrint('[WebRTC] ✅ Current session destroyed successfully');
        } else {
          debugPrint('[WebRTC] ℹ️ No current session found in storage');
          debugPrint('[WebRTC] ℹ️ Nothing to destroy');
        }
      } catch (e) {
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] ⚠️ ERROR DESTROYING CURRENT SESSION');
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] Error: $e');
        debugPrint('[WebRTC] ⚠️ Continuing with expired sessions cleanup...');
        debugPrint('[WebRTC] ========================================');
        // Continue anyway to cleanup expired sessions
      }
      
      debugPrint('[WebRTC] ');
      debugPrint('[WebRTC] 🧹 CLEANING UP EXPIRED SESSIONS...');
      debugPrint('[WebRTC] (This removes old Docker containers)');
      
      // Then, cleanup all expired sessions (admin endpoint)
      try {
        await _apiService.cleanupExpiredSessions();
        
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] ✅ ALL EXPIRED SESSIONS CLEANED UP');
        debugPrint('[WebRTC] ========================================');
      } catch (e) {
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] ⚠️ EXPIRED SESSIONS CLEANUP FAILED');
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] Error: $e');
        debugPrint('[WebRTC] ');
        debugPrint('[WebRTC] This might fail if:');
        debugPrint('[WebRTC]   - User doesn\'t have admin permissions');
        debugPrint('[WebRTC]   - Backend endpoint not implemented');
        debugPrint('[WebRTC]   - No expired sessions to cleanup');
        debugPrint('[WebRTC] ');
        debugPrint('[WebRTC] ℹ️ This is non-critical - current session was already destroyed');
        debugPrint('[WebRTC] ========================================');
      }
      
      debugPrint('[WebRTC] ');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] 🎉 ALL SESSIONS DESTRUCTION COMPLETE');
      debugPrint('[WebRTC] ========================================');
    } catch (e) {
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] ❌ CRITICAL ERROR DESTROYING ALL SESSIONS');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] Error: $e');
      debugPrint('[WebRTC] ========================================');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    // Cleanup if needed
  }
}

/// WebRTC Session Info (from storage)
class WebRTCSessionInfo {
  final int sessionId;
  final String containerId;
  final String containerName;
  final String? accessToken;
  final String targetUrl;
  final String resolution;
  final String status;
  final DateTime? expiresAt;

  WebRTCSessionInfo({
    required this.sessionId,
    required this.containerId,
    required this.containerName,
    this.accessToken,
    required this.targetUrl,
    required this.resolution,
    required this.status,
    this.expiresAt,
  });

  @override
  String toString() {
    return 'WebRTCSessionInfo('
        'sessionId: $sessionId, '
        'containerId: $containerId, '
        'containerName: $containerName, '
        'status: $status, '
        'targetUrl: $targetUrl, '
        'expiresAt: $expiresAt'
        ')';
  }
}

/// Helper class for retry decision logic
class RetryDecision<T> {
  final bool shouldRetry;
  final T fallbackValue;

  RetryDecision._({
    required this.shouldRetry,
    required this.fallbackValue,
  });

  /// Continue retrying
  factory RetryDecision.retry() {
    return RetryDecision._(
      shouldRetry: true,
      fallbackValue: null as T, // Will not be used if shouldRetry is true
    );
  }

  /// Stop retrying and return the fallback value
  factory RetryDecision.failImmediately(T value) {
    return RetryDecision._(
      shouldRetry: false,
      fallbackValue: value,
    );
  }
}

/// Provider for WebRTC Session Service
final webRTCSessionServiceProvider = Provider<WebRTCSessionService>((ref) {
  final apiService = ref.watch(webRTCApiServiceProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return WebRTCSessionService(apiService, storage);
});
