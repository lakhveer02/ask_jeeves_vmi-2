import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';
import 'package:ask_jeeves_vmi/data/services/api/api_client.dart';
import 'package:ask_jeeves_vmi/data/services/api/session_api_service.dart';
import 'package:ask_jeeves_vmi/data/services/webrtc/webrtc_session_service.dart';
import 'dart:async';

/// Session Security Service
/// Handles immediate session termination for security violations
class SessionSecurityService {
  final SecureStorageService _storage;
  final ApiClient _apiClient;
  final WebRTCSessionService _webrtcSessionService;
  
  bool _isTerminating = false;

  SessionSecurityService(
    this._storage,
    this._apiClient,
    this._webrtcSessionService,
  );

  /// Immediately terminate session due to security violation
  /// This is a BLOCKING operation that waits for WebRTC cleanup
  Future<void> terminateSessionImmediately(String reason) async {
    if (_isTerminating) {
      debugPrint('[Security] ⚠️ Already terminating session, skipping...');
      return;
    }

    _isTerminating = true;
    
    debugPrint('[Security] ========================================');
    debugPrint('[Security] 🚨 IMMEDIATE SESSION TERMINATION');
    debugPrint('[Security] ========================================');
    debugPrint('[Security] Reason: $reason');
    debugPrint('[Security] ');
    debugPrint('[Security] 🔄 Starting SYNCHRONOUS cleanup...');
    debugPrint('[Security] This will BLOCK until complete:');
    debugPrint('[Security]   1. Destroy ALL WebRTC sessions');
    debugPrint('[Security]   2. Terminate backend session');
    debugPrint('[Security]   3. Clear all local storage');
    debugPrint('[Security] ========================================');

    // CHANGED: Wait for completion instead of fire-and-forget
    try {
      await _performTerminationSync(reason);
      debugPrint('[Security] ✅ Synchronous termination complete');
    } catch (e) {
      debugPrint('[Security] ❌ Synchronous termination failed: $e');
    } finally {
      _isTerminating = false;
    }
  }

  /// Perform session termination SYNCHRONOUSLY (blocking)
  Future<void> _performTerminationSync(String reason) async {
    try {
      debugPrint('[Security] ========================================');
      debugPrint('[Security] 🧹 SYNCHRONOUS CLEANUP STARTED: $reason');
      debugPrint('[Security] ========================================');
      
      final sessionIdStr = await _storage.read('backend_session_id');
      final deviceUuid = await _storage.read('device_uuid');
      
      debugPrint('[Security] 📋 Checking storage:');
      debugPrint('[Security]   Backend Session ID: ${sessionIdStr ?? "NULL"}');
      debugPrint('[Security]   Device UUID: ${deviceUuid != null ? "${deviceUuid.substring(0, 8)}..." : "NULL"}');
      debugPrint('[Security] ');
      
      // STEP 1: ALWAYS destroy WebRTC sessions FIRST (most important!)
      debugPrint('[Security] 🗑️ STEP 1: Destroying ALL WebRTC sessions...');
      debugPrint('[Security] (This is CRITICAL - must happen regardless of backend session)');
      try {
        await _webrtcSessionService.destroyAllWebRTCSessions().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('[Security] ⚠️ WebRTC destruction timeout (5s)');
            debugPrint('[Security] Sessions may still be running on backend');
            throw TimeoutException('WebRTC destruction timeout');
          },
        );
        debugPrint('[Security] ✅ All WebRTC sessions destroyed successfully');
      } catch (e) {
        debugPrint('[Security] ========================================');
        debugPrint('[Security] ❌ WEBRTC DESTRUCTION FAILED');
        debugPrint('[Security] ========================================');
        debugPrint('[Security] Error: $e');
        debugPrint('[Security] ⚠️ Docker containers may still be running!');
        debugPrint('[Security] ⚠️ Backend will auto-cleanup after expiration');
        debugPrint('[Security] ========================================');
        // Continue with other cleanup even if WebRTC fails
      }
      
      debugPrint('[Security] ');
      
      // STEP 2: Terminate backend session (only if we have session info)
      if (sessionIdStr != null && deviceUuid != null) {
        final sessionId = int.parse(sessionIdStr);
        
        debugPrint('[Security] 🔐 STEP 2: Terminating backend session...');
        debugPrint('[Security]   Session ID: $sessionId');
        try {
          final sessionApiService = SessionApiService(_apiClient);
          
          await sessionApiService.terminateSession(
            sessionId: sessionId,
            reason: reason,
          ).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('[Security] ⚠️ Session termination timeout (3s)');
              throw TimeoutException('Session termination timeout');
            },
          );
          
          debugPrint('[Security] ✅ Backend session terminated successfully');
        } catch (e) {
          debugPrint('[Security] ⚠️ Session termination failed: $e');
          debugPrint('[Security] Session may already be terminated');
          // Continue with storage cleanup even if termination fails
        }
      } else {
        debugPrint('[Security] ℹ️ No backend session info found');
        debugPrint('[Security] Skipping backend session termination');
      }
      
      debugPrint('[Security] ');
      
      // STEP 3: Clear ALL storage (complete reset)
      debugPrint('[Security] 🧹 STEP 3: Clearing ALL storage...');
      try {
        await _storage.clearAll();
        debugPrint('[Security] ✅ All storage cleared successfully');
      } catch (e) {
        debugPrint('[Security] ⚠️ Storage clear failed: $e');
        // Try to at least clear auth data as fallback
        try {
          await _storage.clearAuthData();
          debugPrint('[Security] ✅ Auth data cleared (fallback)');
        } catch (e2) {
          debugPrint('[Security] ❌ Auth data clear failed: $e2');
        }
      }
      
      debugPrint('[Security] ========================================');
      debugPrint('[Security] ✅ SYNCHRONOUS CLEANUP COMPLETE');
      debugPrint('[Security] ========================================');
    } catch (e, stackTrace) {
      debugPrint('[Security] ========================================');
      debugPrint('[Security] ❌ SYNCHRONOUS CLEANUP ERROR');
      debugPrint('[Security] ========================================');
      debugPrint('[Security] Error: $e');
      debugPrint('[Security] Stack trace:');
      debugPrint('$stackTrace');
      debugPrint('[Security] ========================================');
      rethrow;
    }
  }

  /// Check if session is currently being terminated
  bool get isTerminating => _isTerminating;
}

/// Provider for Session Security Service
final sessionSecurityServiceProvider = Provider<SessionSecurityService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final apiClient = ApiClient(storage);
  final webrtcSessionService = ref.watch(webRTCSessionServiceProvider);
  
  return SessionSecurityService(storage, apiClient, webrtcSessionService);
});
