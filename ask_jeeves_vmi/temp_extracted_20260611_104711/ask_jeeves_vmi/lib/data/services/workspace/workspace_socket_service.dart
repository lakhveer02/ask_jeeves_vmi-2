// ignore_for_file: library_prefixes, unused_field

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';
import 'package:ask_jeeves_vmi/core/config/api_constants.dart';

/// WebSocket service for real-time workspace interaction
/// Handles keyboard input, focus events, file uploads, and DOM synchronization
class WorkspaceSocketService {
  final SecureStorageService _storage;
  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  
  // Connection details for reconnection
  String? _workspaceId;
  String? _accessToken;
  
  // Callbacks
  VoidCallback? onConnected;
  VoidCallback? onDisconnected;
  VoidCallback? onReconnecting;
  VoidCallback? onReconnected;
  Function(Map<String, dynamic>)? onFocusEvent;
  Function(Map<String, dynamic>)? onBlurEvent;
  Function(String)? onRemoteTextUpdate;
  Function(String)? onError;

  WorkspaceSocketService(this._storage);

  /// Connect to workspace WebSocket server
  Future<void> connect({
    required String workspaceId,
    required String accessToken,
  }) async {
    try {
      if (_isConnected) {
        debugPrint('[WorkspaceSocket] Already connected');
        return;
      }

      // Store connection details for reconnection
      _workspaceId = workspaceId;
      _accessToken = accessToken;

      debugPrint('[WorkspaceSocket] 🔌 Connecting to workspace socket...');
      debugPrint('[WorkspaceSocket] Workspace ID: $workspaceId');

      // Get base URL from API constants
      final baseUrl = ApiConstants.baseUrl;
      final socketUrl = baseUrl.replaceAll('/api', ''); // Remove /api suffix for socket

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000) // Start with 2 seconds
            .setReconnectionDelayMax(30000) // Max 30 seconds
            .setReconnectionAttempts(999999) // Infinite attempts
            .setAuth({
              'token': accessToken,
              'workspaceId': workspaceId,
            })
            .build(),
      );

      _setupSocketListeners();

      debugPrint('[WorkspaceSocket] ✅ Socket initialized with auto-reconnection');
    } catch (e, stackTrace) {
      debugPrint('[WorkspaceSocket] ❌ Error connecting: $e');
      debugPrint('[WorkspaceSocket] Stack trace: $stackTrace');
      onError?.call('Failed to connect: $e');
      
      // Attempt to reconnect after error
      _scheduleReconnect();
      
      rethrow;
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _isConnected = true;
      _isReconnecting = false;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      
      debugPrint('[WorkspaceSocket] ✅ Connected to workspace');
      
      // Call appropriate callback
      if (_reconnectAttempts > 0) {
        debugPrint('[WorkspaceSocket] 🔄 Reconnected successfully after $_reconnectAttempts attempts');
        onReconnected?.call();
      }
      
      onConnected?.call();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('[WorkspaceSocket] ❌ Disconnected from workspace');
      onDisconnected?.call();
      
      // Attempt to reconnect if we have connection details
      if (_workspaceId != null && _accessToken != null && !_isReconnecting) {
        debugPrint('[WorkspaceSocket] 🔄 Will attempt to reconnect...');
        _scheduleReconnect();
      }
    });

    _socket!.onConnectError((error) {
      debugPrint('[WorkspaceSocket] ❌ Connection error: $error');
      onError?.call('Connection error: $error');
      
      // Socket.IO will handle reconnection automatically
      if (!_isReconnecting) {
        _isReconnecting = true;
        onReconnecting?.call();
      }
    });

    _socket!.onError((error) {
      debugPrint('[WorkspaceSocket] ❌ Socket error: $error');
      onError?.call('Socket error: $error');
    });
    
    // Reconnection events
    _socket!.on('reconnect_attempt', (attempt) {
      _reconnectAttempts = attempt as int;
      debugPrint('[WorkspaceSocket] 🔄 Reconnection attempt #$_reconnectAttempts');
      if (!_isReconnecting) {
        _isReconnecting = true;
        onReconnecting?.call();
      }
    });
    
    _socket!.on('reconnect', (attempt) {
      debugPrint('[WorkspaceSocket] ✅ Reconnected after $attempt attempts');
      _isReconnecting = false;
      _reconnectAttempts = 0;
      onReconnected?.call();
    });
    
    _socket!.on('reconnect_error', (error) {
      debugPrint('[WorkspaceSocket] ❌ Reconnection error: $error');
    });
    
    _socket!.on('reconnect_failed', (_) {
      debugPrint('[WorkspaceSocket] ❌ Reconnection failed after all attempts');
      _isReconnecting = false;
      
      // Schedule manual reconnect with exponential backoff
      _scheduleReconnect();
    });

    // Focus events from remote browser
    _socket!.on('focus', (data) {
      debugPrint('[WorkspaceSocket] 📍 Focus event received: $data');
      if (data is Map<String, dynamic>) {
        onFocusEvent?.call(data);
      }
    });

    // Blur events from remote browser
    _socket!.on('blur', (data) {
      debugPrint('[WorkspaceSocket] 📍 Blur event received: $data');
      if (data is Map<String, dynamic>) {
        onBlurEvent?.call(data);
      }
    });

    // Remote text updates (for synchronization)
    _socket!.on('text_update', (data) {
      debugPrint('[WorkspaceSocket] 📝 Remote text update: $data');
      if (data is String) {
        onRemoteTextUpdate?.call(data);
      } else if (data is Map && data['text'] != null) {
        onRemoteTextUpdate?.call(data['text'].toString());
      }
    });

    // Acknowledgments
    _socket!.on('typing_ack', (data) {
      debugPrint('[WorkspaceSocket] ✅ Typing acknowledged: $data');
    });

    _socket!.on('file_upload_ack', (data) {
      debugPrint('[WorkspaceSocket] ✅ File upload acknowledged: $data');
    });
  }
  
  /// Schedule a reconnection attempt with exponential backoff
  void _scheduleReconnect() {
    if (_isReconnecting || _workspaceId == null || _accessToken == null) {
      return;
    }
    
    _isReconnecting = true;
    _reconnectAttempts++;
    
    // Exponential backoff: 2s, 4s, 8s, 16s, 30s (max)
    final delay = Duration(
      seconds: (2 * (1 << (_reconnectAttempts - 1).clamp(0, 4))).clamp(2, 30),
    );
    
    debugPrint('[WorkspaceSocket] 🔄 Scheduling reconnect attempt #$_reconnectAttempts in ${delay.inSeconds}s');
    onReconnecting?.call();
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (_workspaceId != null && _accessToken != null) {
        debugPrint('[WorkspaceSocket] 🔄 Attempting manual reconnect...');
        
        try {
          // Dispose old socket
          _socket?.dispose();
          _socket = null;
          _isConnected = false;
          
          // Reconnect
          await connect(
            workspaceId: _workspaceId!,
            accessToken: _accessToken!,
          );
        } catch (e) {
          debugPrint('[WorkspaceSocket] ❌ Manual reconnect failed: $e');
          // Will schedule another attempt via the error handler
        }
      }
    });
  }

  /// Send typing event to remote browser
  void sendTyping({
    required String text,
    String? elementId,
    String? elementType,
  }) {
    if (!_isConnected || _socket == null) {
      debugPrint('[WorkspaceSocket] ⚠️ Not connected, cannot send typing');
      return;
    }

    final payload = {
      'type': 'typing',
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'elementId': ?elementId,
      'elementType': ?elementType,
    };

    debugPrint('[WorkspaceSocket] ⌨️ Sending typing: ${text.length} chars');
    _socket!.emit('typing', payload);
  }

  /// Send key press event to remote browser
  void sendKeyPress({
    required String key,
    bool ctrlKey = false,
    bool shiftKey = false,
    bool altKey = false,
    bool metaKey = false,
  }) {
    if (!_isConnected || _socket == null) {
      debugPrint('[WorkspaceSocket] ⚠️ Not connected, cannot send key press');
      return;
    }

    final payload = {
      'type': 'keypress',
      'key': key,
      'ctrlKey': ctrlKey,
      'shiftKey': shiftKey,
      'altKey': altKey,
      'metaKey': metaKey,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    debugPrint('[WorkspaceSocket] ⌨️ Sending key press: $key');
    _socket!.emit('keypress', payload);
  }

  /// Send file upload metadata to remote browser
  Future<void> sendFileUpload({
    required String fileName,
    required String fileType,
    required int fileSize,
    required String base64Data,
    String? elementId,
    String? text, // Optional text to accompany the file
  }) async {
    if (!_isConnected || _socket == null) {
      debugPrint('[WorkspaceSocket] ⚠️ Not connected, cannot send file upload');
      throw Exception('Not connected to workspace');
    }

    final payload = {
      'type': 'submit_with_file',
      'data': {
        if (text != null && text.isNotEmpty) 'text': text,
        'files': [
          {
            'filename': fileName,
            'content_base64': base64Data,
            'mime_type': fileType,
          }
        ],
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'elementId': ?elementId,
    };

    debugPrint('[WorkspaceSocket] 📤 Sending file upload: $fileName (${(fileSize / 1024).toStringAsFixed(2)} KB)');
    if (text != null && text.isNotEmpty) {
      debugPrint('[WorkspaceSocket] 📝 With text: $text');
    }
    _socket!.emit('submit_with_file', payload);
  }

  /// Send focus request to specific element
  void requestFocus({required String elementId}) {
    if (!_isConnected || _socket == null) {
      debugPrint('[WorkspaceSocket] ⚠️ Not connected, cannot request focus');
      return;
    }

    final payload = {
      'type': 'focus_request',
      'elementId': elementId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    debugPrint('[WorkspaceSocket] 📍 Requesting focus: $elementId');
    _socket!.emit('focus_request', payload);
  }

  /// Send blur request
  void requestBlur() {
    if (!_isConnected || _socket == null) {
      debugPrint('[WorkspaceSocket] ⚠️ Not connected, cannot request blur');
      return;
    }

    final payload = {
      'type': 'blur_request',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    debugPrint('[WorkspaceSocket] 📍 Requesting blur');
    _socket!.emit('blur_request', payload);
  }

  /// Check if socket is connected
  bool get isConnected => _isConnected;

  /// Disconnect from workspace
  void disconnect() {
    if (_socket != null) {
      debugPrint('[WorkspaceSocket] 🔌 Disconnecting...');
      
      // Clear connection details to prevent auto-reconnect
      _workspaceId = null;
      _accessToken = null;
      _isReconnecting = false;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      
      debugPrint('[WorkspaceSocket] ✅ Disconnected');
    }
  }

  /// Dispose resources
  void dispose() {
    _reconnectTimer?.cancel();
    disconnect();
  }
}

/// Provider for Workspace Socket Service
final workspaceSocketServiceProvider = Provider<WorkspaceSocketService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final service = WorkspaceSocketService(storage);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
