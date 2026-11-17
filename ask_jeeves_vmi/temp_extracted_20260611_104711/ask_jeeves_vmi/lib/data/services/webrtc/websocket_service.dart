// ignore_for_file: library_prefixes

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';

class WebSocketService {
  IO.Socket? _socket;
  final SecureStorageService _storage;
  
  // Connection state tracking
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  Timer? _reconnectTimer;
  
  // Callback for connection state changes (for UI notifications)
  Function(bool connected, String? message)? onConnectionStateChanged;
  
  // Stream controllers for different events
  final _vaultConnectedController = StreamController<Map<String, dynamic>>.broadcast();
  final _aiStreamStartController = StreamController<Map<String, dynamic>>.broadcast();
  final _aiStreamTokenController = StreamController<Map<String, dynamic>>.broadcast();
  final _aiStreamEndController = StreamController<Map<String, dynamic>>.broadcast();
  final _webrtcOfferController = StreamController<Map<String, dynamic>>.broadcast();
  final _webrtcAnswerController = StreamController<Map<String, dynamic>>.broadcast();
  final _iceCandidateController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Public streams
  Stream<Map<String, dynamic>> get vaultConnected => _vaultConnectedController.stream;
  Stream<Map<String, dynamic>> get aiStreamStart => _aiStreamStartController.stream;
  Stream<Map<String, dynamic>> get aiStreamToken => _aiStreamTokenController.stream;
  Stream<Map<String, dynamic>> get aiStreamEnd => _aiStreamEndController.stream;
  Stream<Map<String, dynamic>> get webrtcOffer => _webrtcOfferController.stream;
  Stream<Map<String, dynamic>> get webrtcAnswer => _webrtcAnswerController.stream;
  Stream<Map<String, dynamic>> get iceCandidate => _iceCandidateController.stream;
  
  WebSocketService(this._storage);
  
  Future<void> connect() async {
    final token = await _storage.read('access_token');
    
    _socket = IO.io(
      'http://localhost:3000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );
    
    _setupEventHandlers();
    
    debugPrint('🔌 WebSocket connecting...');
  }
  
  void _setupEventHandlers() {
    _socket?.onConnect((_) {
      debugPrint('✅ WebSocket connected');
      _isConnected = true;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      
      // Notify UI of successful connection
      onConnectionStateChanged?.call(true, 'Connected to workspace');
    });
    
    _socket?.onDisconnect((_) {
      debugPrint('❌ WebSocket disconnected');
      _isConnected = false;
      
      // Notify UI of disconnection
      onConnectionStateChanged?.call(false, 'Connection lost. Reconnecting...');
      
      // Attempt to reconnect
      _attemptReconnect();
    });
    
    _socket?.onError((error) {
      debugPrint('❌ WebSocket error: $error');
      
      // Notify UI of error
      onConnectionStateChanged?.call(false, 'Connection problem detected');
    });
    
    _socket?.onConnectError((error) {
      debugPrint('❌ WebSocket connection error: $error');
      _isConnected = false;
      
      // Notify UI of connection failure
      if (_reconnectAttempts < _maxReconnectAttempts) {
        onConnectionStateChanged?.call(false, 'Connecting... (${_reconnectAttempts + 1}/$_maxReconnectAttempts)');
      } else {
        onConnectionStateChanged?.call(false, 'Unable to connect. Please check your internet connection.');
      }
    });
    
    // Vault events
    _socket?.on('vault:connected', (data) {
      debugPrint('🏦 Vault connected: $data');
      _vaultConnectedController.add(data);
    });
    
    _socket?.on('vault:error', (data) {
      debugPrint('❌ Vault error: $data');
    });
    
    // AI streaming events
    _socket?.on('ai:stream:start', (data) {
      debugPrint('🤖 AI stream started');
      _aiStreamStartController.add(data);
    });
    
    _socket?.on('ai:stream:token', (data) {
      _aiStreamTokenController.add(data);
    });
    
    _socket?.on('ai:stream:end', (data) {
      debugPrint('🤖 AI stream ended');
      _aiStreamEndController.add(data);
    });
    
    _socket?.on('ai:error', (data) {
      debugPrint('❌ AI error: $data');
    });
    
    // WebRTC signaling events
    _socket?.on('webrtc:offer', (data) {
      debugPrint('📡 WebRTC offer received');
      _webrtcOfferController.add(data);
    });
    
    _socket?.on('webrtc:answer', (data) {
      debugPrint('📡 WebRTC answer received');
      _webrtcAnswerController.add(data);
    });
    
    _socket?.on('webrtc:ice-candidate', (data) {
      debugPrint('📡 ICE candidate received');
      _iceCandidateController.add(data);
    });
    
    _socket?.on('webrtc:error', (data) {
      debugPrint('❌ WebRTC error: $data');
    });
    
    // Heartbeat
    _socket?.on('heartbeat:ack', (data) {
      // Silent heartbeat acknowledgment
    });
  }
  
  // ============================================================================
  // CONNECTION MANAGEMENT
  // ============================================================================
  
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Max reconnection attempts reached');
      onConnectionStateChanged?.call(false, 'Connection failed. Please restart the app.');
      return;
    }
    
    _reconnectAttempts++;
    debugPrint('🔄 Attempting reconnection $_reconnectAttempts/$_maxReconnectAttempts...');
    
    // Wait before reconnecting (exponential backoff)
    final delay = Duration(seconds: 2 * _reconnectAttempts);
    _reconnectTimer = Timer(delay, () {
      if (_socket != null && !_isConnected) {
        _socket?.connect();
      }
    });
  }
  
  // ============================================================================
  // VAULT METHODS
  // ============================================================================
  
  void connectToVault(String vaultId) {
    debugPrint('🏦 Connecting to vault: $vaultId');
    _socket?.emit('vault:connect', {'vaultId': vaultId});
  }
  
  // ============================================================================
  // AI METHODS
  // ============================================================================
  
  void sendAIMessage(String message, String vaultId) {
    debugPrint('🤖 Sending AI message: $message');
    _socket?.emit('ai:message', {
      'message': message,
      'vaultId': vaultId,
    });
  }
  
  // ============================================================================
  // WEBRTC SIGNALING METHODS
  // ============================================================================
  
  void sendWebRTCOffer(dynamic offer, String vaultId) {
    debugPrint('📡 Sending WebRTC offer');
    _socket?.emit('webrtc:offer', {
      'offer': offer,
      'vaultId': vaultId,
    });
  }
  
  void sendWebRTCAnswer(dynamic answer, String to) {
    debugPrint('📡 Sending WebRTC answer');
    _socket?.emit('webrtc:answer', {
      'answer': answer,
      'to': to,
    });
  }
  
  void sendICECandidate(dynamic candidate, {String? to}) {
    _socket?.emit('webrtc:ice-candidate', {
      'candidate': candidate,
      'to': to,
    });
  }
  
  // ============================================================================
  // HEARTBEAT
  // ============================================================================
  
  Timer? _heartbeatTimer;
  
  void startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _socket?.emit('heartbeat', {});
    });
  }
  
  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
  }
  
  // ============================================================================
  // CLEANUP
  // ============================================================================
  
  void disconnect() {
    stopHeartbeat();
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    
    _vaultConnectedController.close();
    _aiStreamStartController.close();
    _aiStreamTokenController.close();
    _aiStreamEndController.close();
    _webrtcOfferController.close();
    _webrtcAnswerController.close();
    _iceCandidateController.close();
    
    _isConnected = false;
    _reconnectAttempts = 0;
    
    debugPrint('🔌 WebSocket disconnected and cleaned up');
  }
  
  bool get isConnected => _isConnected && (_socket?.connected ?? false);
}

// Provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final service = WebSocketService(storage);
  
  ref.onDispose(() {
    service.disconnect();
  });
  
  return service;
});
