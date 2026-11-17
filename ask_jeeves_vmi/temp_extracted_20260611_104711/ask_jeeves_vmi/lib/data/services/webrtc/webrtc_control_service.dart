import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ask_jeeves_vmi/core/config/api_constants.dart';
import 'dart:convert';
import 'dart:async';

/// Service for controlling WebRTC browser session via WebSocket
/// WebSocket URL: wss://your-ngrok-url.ngrok.io/api/v1/webrtc/ws/control/{session_id}?token={access_token}
class WebRTCControlService {
  WebSocketChannel? _channel;
  StreamSubscription? _streamSubscription;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  bool _shouldAutoReconnect = false;
  int? _sessionId;
  String? _accessToken;
  
  // Callbacks
  Function(Map<String, dynamic>)? onMessage;
  VoidCallback? onConnected;
  VoidCallback? onDisconnected;
  Function(dynamic)? onError;

  WebRTCControlService();

  /// Connect to WebSocket control endpoint
  Future<void> connect({
    required int sessionId,
    required String accessToken,
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 10),
    bool autoReconnect = true,
  }) async {
    // Store credentials for auto-reconnect
    _sessionId = sessionId;
    _accessToken = accessToken;
    _shouldAutoReconnect = autoReconnect;
    
    // Cancel any existing reconnect timer
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    int attempt = 0;
    Duration delay = const Duration(seconds: 2);

    while (attempt < maxRetries) {
      try {
        attempt++;
        debugPrint('[WebRTCControl] Connecting to WebSocket (attempt $attempt/$maxRetries)...');
        debugPrint('  Session ID: $sessionId');
        debugPrint('  Access Token: ${accessToken.substring(0, 10)}...');

        // Build WebSocket URL
        final wsUrl = '${ApiConstants.wsBaseUrl}api/v1/webrtc/ws/control/$sessionId?token=$accessToken';
        debugPrint('[WebRTCControl] WebSocket URL: $wsUrl');

        // Create WebSocket channel
        _channel = WebSocketChannel.connect(
          Uri.parse(wsUrl),
          protocols: ['websocket'],
        );

        // Set up a completer to track connection success
        final connectionCompleter = Completer<bool>();
        bool isFirstMessage = true;

        // Listen for messages
        _streamSubscription = _channel!.stream.listen(
          (message) {
            // First message indicates successful connection
            if (isFirstMessage) {
              isFirstMessage = false;
              _isConnected = true;
              if (!connectionCompleter.isCompleted) {
                connectionCompleter.complete(true);
              }
              onConnected?.call();
              debugPrint('[WebRTCControl] ✅ WebSocket connected');
            }
            _handleMessage(message);
          },
          onError: (error) {
            debugPrint('[WebRTCControl] ❌ WebSocket stream error: $error');
            _isConnected = false;
            
            if (!connectionCompleter.isCompleted) {
              connectionCompleter.completeError(error);
            }
            
            // Parse error type
            String errorType = 'Unknown error';
            if (error.toString().contains('Connection closed before full header')) {
              errorType = 'Server closed connection during handshake';
            } else if (error.toString().contains('Connection refused')) {
              errorType = 'Server refused connection';
            } else if (error.toString().contains('timeout')) {
              errorType = 'Connection timeout';
            }
            
            debugPrint('[WebRTCControl] Error type: $errorType');
            onError?.call(error);
            
            // Schedule auto-reconnect
            _scheduleReconnect();
          },
          onDone: () {
            debugPrint('[WebRTCControl] WebSocket closed');
            _isConnected = false;
            
            if (!connectionCompleter.isCompleted) {
              connectionCompleter.completeError(Exception('WebSocket closed before connection established'));
            }
            
            onDisconnected?.call();
            
            // Schedule auto-reconnect
            _scheduleReconnect();
          },
          cancelOnError: true,
        );

        // Wait for connection with timeout
        await connectionCompleter.future.timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException('WebSocket connection timeout after ${timeout.inSeconds}s');
          },
        );
        
        // Success - exit retry loop
        debugPrint('[WebRTCControl] ✅ Connection established successfully');
        return;
        
      } catch (e) {
        debugPrint('[WebRTCControl] ❌ Connection attempt $attempt failed: $e');
        
        // Clean up failed connection
        try {
          await _streamSubscription?.cancel();
          _streamSubscription = null;
          
          // Close the channel sink
          await _channel?.sink.close();
          _channel = null;
        } catch (cleanupError) {
          debugPrint('[WebRTCControl] Cleanup error: $cleanupError');
        }
        
        _isConnected = false;
        
        // Check if we should retry
        if (attempt < maxRetries) {
          debugPrint('[WebRTCControl] 🔄 Retrying in ${delay.inSeconds}s...');
          debugPrint('[WebRTCControl] Possible causes:');
          debugPrint('[WebRTCControl]   - Backend WebSocket service not ready');
          debugPrint('[WebRTCControl]   - Network connectivity issue');
          debugPrint('[WebRTCControl]   - Invalid session ID or token');
          debugPrint('[WebRTCControl]   - WebSocket endpoint not available');
          
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff: 2s, 4s, 8s
          continue; // Retry
        } else {
          // Max retries reached
          debugPrint('[WebRTCControl] ❌ Max retries reached');
          throw Exception(
            'WebSocket connection failed after $maxRetries attempts. '
            'Last error: $e'
          );
        }
      }
    }
  }

  /// Schedule auto-reconnect after 5 seconds
  void _scheduleReconnect() {
    if (!_shouldAutoReconnect || _sessionId == null || _accessToken == null) {
      debugPrint('[WebRTCControl] Auto-reconnect disabled or missing credentials');
      return;
    }
    
    // Cancel any existing timer
    _reconnectTimer?.cancel();
    
    debugPrint('[WebRTCControl] 🔄 Scheduling auto-reconnect in 5 seconds...');
    
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_shouldAutoReconnect) {
        debugPrint('[WebRTCControl] Auto-reconnect cancelled');
        return;
      }
      
      debugPrint('[WebRTCControl] 🔄 Attempting auto-reconnect...');
      
      // Attempt to reconnect (single attempt, will schedule another if it fails)
      connect(
        sessionId: _sessionId!,
        accessToken: _accessToken!,
        maxRetries: 1,
        timeout: const Duration(seconds: 5),
        autoReconnect: true,
      ).catchError((error) {
        debugPrint('[WebRTCControl] ❌ Auto-reconnect failed: $error');
        // The connect method will schedule another reconnect via onError/onDone
      });
    });
  }

  /// Handle incoming WebSocket message
  void _handleMessage(dynamic message) {
    try {
      debugPrint('[WebRTCControl] 📨 Received message: $message');
      
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      onMessage?.call(data);
    } catch (e) {
      debugPrint('[WebRTCControl] Error parsing message: $e');
    }
  }

  /// Send a command to the WebSocket
  void _sendCommand(Map<String, dynamic> command) {
    if (!_isConnected || _channel == null) {
      debugPrint('[WebRTCControl] ⚠️ Cannot send command: WebSocket not connected');
      return;
    }

    try {
      final message = jsonEncode(command);
      _channel!.sink.add(message);
      debugPrint('[WebRTCControl] 📤 Sent command: ${command['type']}');
    } catch (e) {
      debugPrint('[WebRTCControl] ❌ Error sending command: $e');
    }
  }

  /// Send scroll command
  /// Scrolls the page by deltaY pixels
  void sendScroll(int deltaY) {
    _sendCommand({
      'type': 'scroll',
      'data': {
        'delta_y': deltaY,
      },
    });
  }

  /// Send click command at coordinates
  /// Clicks at the specified x, y coordinates
  void sendClick(int x, int y) {
    _sendCommand({
      'type': 'click',
      'data': {
        'x': x,
        'y': y,
      },
    });
  }

  /// Send type command
  /// Types text into the currently focused element or specified selector
  void sendType(String text, {String? selector}) {
    final data = <String, dynamic>{
      'text': text,
    };
    
    if (selector != null) {
      data['selector'] = selector;
    }

    _sendCommand({
      'type': 'type',
      'data': data,
    });
  }

  /// Send press key command
  /// Presses a specific key (e.g., 'Enter', 'Tab', 'Escape')
  void sendPressKey(String key) {
    _sendCommand({
      'type': 'press_key',
      'data': {
        'key': key,
      },
    });
  }

  /// Send navigate command
  /// Navigates to a new URL
  void sendNavigate(String url) {
    _sendCommand({
      'type': 'navigate',
      'data': {
        'url': url,
      },
    });
  }

  /// Send click selector command
  /// Clicks on an element matching the CSS selector
  void sendClickSelector(String selector) {
    _sendCommand({
      'type': 'click_selector',
      'data': {
        'selector': selector,
      },
    });
  }

  /// Send fill input command
  /// Fills an input field matching the selector with the specified value
  void sendFillInput(String selector, String value) {
    _sendCommand({
      'type': 'fill_input',
      'data': {
        'selector': selector,
        'value': value,
      },
    });
  }

  /// Get page info
  /// Requests information about the current page
  void getPageInfo() {
    _sendCommand({
      'type': 'get_info',
      'data': {},
    });
  }

  /// Send screenshot command
  /// Requests a screenshot of the current page
  void sendScreenshot() {
    _sendCommand({
      'type': 'screenshot',
      'data': {},
    });
  }

  /// Send submit text command
  /// Submits text to the backend (e.g., for AI chat or form submission)
  void sendSubmitText(String text) {
    _sendCommand({
      'type': 'submit_text',
      'data': {
        'text': text,
      },
    });
  }

  /// Send file with optional text command
  /// Submits a file with optional accompanying text
  void sendFileWithText({
    required String fileName,
    required String fileType,
    required int fileSize,
    required String base64Data,
    String? text,
  }) {
    debugPrint('[WebRTCControl] 📤 Sending file with text command');
    debugPrint('[WebRTCControl]   File: $fileName');
    debugPrint('[WebRTCControl]   Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
    debugPrint('[WebRTCControl]   Text: ${text ?? "(none)"}');
    
    _sendCommand({
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
    });
  }

  /// Send mouse move command
  /// Moves the mouse to the specified coordinates
  void sendMouseMove(int x, int y) {
    _sendCommand({
      'type': 'mouse_move',
      'data': {
        'x': x,
        'y': y,
      },
    });
  }

  /// Send double click command
  /// Double clicks at the specified coordinates
  void sendDoubleClick(int x, int y) {
    _sendCommand({
      'type': 'double_click',
      'data': {
        'x': x,
        'y': y,
      },
    });
  }

  /// Send right click command
  /// Right clicks at the specified coordinates
  void sendRightClick(int x, int y) {
    _sendCommand({
      'type': 'right_click',
      'data': {
        'x': x,
        'y': y,
      },
    });
  }

  /// Check if WebSocket is connected
  bool get isConnected => _isConnected;

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    debugPrint('[WebRTCControl] Disconnecting WebSocket...');
    
    // Disable auto-reconnect
    _shouldAutoReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    try {
      await _streamSubscription?.cancel();
      await _channel?.sink.close();
      
      _streamSubscription = null;
      _channel = null;
      _isConnected = false;
      
      debugPrint('[WebRTCControl] ✅ WebSocket disconnected');
    } catch (e) {
      debugPrint('[WebRTCControl] Error disconnecting: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _shouldAutoReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    disconnect();
  }
}

/// Provider for WebRTC Control Service
final webRTCControlServiceProvider = Provider<WebRTCControlService>((ref) {
  final service = WebRTCControlService();
  
  // Cleanup on dispose
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
