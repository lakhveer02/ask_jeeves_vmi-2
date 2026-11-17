import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:ask_jeeves_vmi/data/services/webrtc/webrtc_session_service.dart';
import 'package:ask_jeeves_vmi/data/services/webrtc/webrtc_control_service.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:ask_jeeves_vmi/core/router/app_router.dart';

/// Production-ready WebRTC streaming widget with full-screen support
/// 
/// Features:
/// - Full-screen video with RTCVideoViewObjectFitCover (fills entire screen)
/// - Device resolution matching using PlatformDispatcher
/// - Immersive mode with hidden system bars
/// - Adaptive UI layout based on orientation
/// - Notch-safe control buttons
class WebRTCStreamWidget extends StatefulWidget {
  final WebRTCSessionService sessionService;
  final WebRTCControlService controlService;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final Function(String)? onError;

  const WebRTCStreamWidget({
    super.key,
    required this.sessionService,
    required this.controlService,
    this.onConnected,
    this.onDisconnected,
    this.onError,
  });

  @override
  State<WebRTCStreamWidget> createState() => _WebRTCStreamWidgetState();
}

class _WebRTCStreamWidgetState extends State<WebRTCStreamWidget> {
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isConnecting = true;
  bool _isWebSocketConnected = false;
  String? _errorMessage;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  Timer? _sessionValidationTimer;
  Timer? _videoFrameMonitorTimer;
  bool _isReconnecting = false;
  bool _sessionValid = true;
  
  // Logging configuration - set to true to enable verbose logs
  static const bool _verboseLogging = false;

  // Device resolution for perfect full-screen matching
  late int _deviceWidth;
  late int _deviceHeight;

  // Motion detection state
  DateTime? _pointerDownTime;
  
  // Video frame monitoring
  int _lastVideoWidth = 0;
  int _lastVideoHeight = 0;

  @override
  void initState() {
    super.initState();
    _captureDeviceResolution();
    _enableImmersiveMode();
    _initializeWebRTC();
    _startSessionValidation();
    _startVideoFrameMonitoring();
  }

  @override
  void dispose() {
    _restoreSystemUI();
    _reconnectTimer?.cancel();
    _sessionValidationTimer?.cancel();
    _videoFrameMonitorTimer?.cancel();
    
    // Clear WebSocket callbacks to prevent setState after dispose
    widget.controlService.onConnected = null;
    widget.controlService.onDisconnected = null;
    widget.controlService.onMessage = null;
    widget.controlService.onError = null;
    
    _cleanup();
    super.dispose();
  }

  // CONFIGURATION: Resolution Strategy
  // true = Physical resolution (high quality, more bandwidth) - 1170x2532
  // false = Logical resolution (optimal bandwidth, good quality) - 390x844
  static const bool _usePhysicalResolution = false;  // Use logical for better performance
  
  /// Capture device's resolution using PlatformDispatcher
  /// 
  /// Resolution Strategy:
  /// - PHYSICAL (1170x2532): High quality, sharp video, more bandwidth (~5-10 Mbps)
  /// - LOGICAL (390x844): Optimal bandwidth, good quality (~1-3 Mbps)
  /// 
  /// Recommendation: Use LOGICAL for mobile devices to save bandwidth and battery
  void _captureDeviceResolution() {
    final view = ui.PlatformDispatcher.instance.views.first;
    final physicalSize = view.physicalSize;
    final devicePixelRatio = view.devicePixelRatio;
    
    final int physicalWidth = physicalSize.width.toInt();
    final int physicalHeight = physicalSize.height.toInt();
    
    // Set resolution based on strategy
    if (_usePhysicalResolution) {
      _deviceWidth = physicalWidth;
      _deviceHeight = physicalHeight;
      
      final int logicalWidth = (physicalSize.width / devicePixelRatio).toInt();
      final int logicalHeight = (physicalSize.height / devicePixelRatio).toInt();
      
      debugPrint('[WebRTC] 📱 Resolution Strategy: PHYSICAL (High Quality)');
      debugPrint('[WebRTC]    Selected: ${_deviceWidth}x$_deviceHeight px');
      debugPrint('[WebRTC]    Physical: ${physicalWidth}x$physicalHeight px');
      debugPrint('[WebRTC]    Logical: ${logicalWidth}x$logicalHeight px');
      debugPrint('[WebRTC]    Pixel Ratio: $devicePixelRatio');
      debugPrint('[WebRTC]    Aspect Ratio: ${(_deviceWidth / _deviceHeight).toStringAsFixed(2)}');
    } else {
      final int logicalWidth = (physicalSize.width / devicePixelRatio).toInt();
      final int logicalHeight = (physicalSize.height / devicePixelRatio).toInt();
      
      _deviceWidth = logicalWidth;
      _deviceHeight = logicalHeight;
      
      debugPrint('[WebRTC] 📱 Resolution Strategy: LOGICAL (Low Bandwidth)');
      debugPrint('[WebRTC]    Selected: ${_deviceWidth}x$_deviceHeight px');
      debugPrint('[WebRTC]    Physical: ${physicalWidth}x$physicalHeight px');
      debugPrint('[WebRTC]    Logical: ${logicalWidth}x$logicalHeight px');
      debugPrint('[WebRTC]    Pixel Ratio: $devicePixelRatio');
      debugPrint('[WebRTC]    Aspect Ratio: ${(_deviceWidth / _deviceHeight).toStringAsFixed(2)}');
    }
  }

  /// Enable immersive full-screen mode (hide system bars)
  void _enableImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    debugPrint('[WebRTC] 🎬 Immersive mode enabled (system bars hidden)');
  }

  /// Restore normal system UI when disposing
  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    debugPrint('[WebRTC] 🔄 System UI restored');
  }

  /// Start periodic session validation
  void _startSessionValidation() {
    debugPrint('[WebRTC] 🔍 Starting periodic session validation...');

    // Check session validity every 30 seconds
    _sessionValidationTimer = Timer.periodic(const Duration(seconds: 30), (
      _,
    ) async {
      await _validateSession();
    });
  }

  /// Start periodic video frame monitoring
  void _startVideoFrameMonitoring() {
    debugPrint('[WebRTC] 📹 Starting video frame monitoring...');

    // Monitor video frames every 2 seconds
    _videoFrameMonitorTimer = Timer.periodic(const Duration(seconds: 2), (
      _,
    ) {
      _logVideoFrameInfo();
    });
  }

  /// Log video frame information
  void _logVideoFrameInfo() {
    if (_remoteRenderer.srcObject == null) {
      // Only log once when no source
      if (_lastVideoWidth != 0 || _lastVideoHeight != 0) {
        debugPrint('[WebRTC] 📹 ❌ No video source');
        _lastVideoWidth = 0;
        _lastVideoHeight = 0;
      }
      return;
    }

    final videoWidth = _remoteRenderer.videoWidth;
    final videoHeight = _remoteRenderer.videoHeight;
    final textureId = _remoteRenderer.textureId;

    // Only log when dimensions change or every 10 seconds
    final shouldLog = (videoWidth != _lastVideoWidth || 
                       videoHeight != _lastVideoHeight ||
                       DateTime.now().second % 10 == 0);

    if (shouldLog) {
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] 📹 VIDEO FRAME INFO');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] Video Dimensions: ${videoWidth}x$videoHeight');
      debugPrint('[WebRTC] Texture ID: $textureId');
      debugPrint('[WebRTC] Has Source: ${_remoteRenderer.srcObject != null}');
      
      if (_remoteRenderer.srcObject != null) {
        final stream = _remoteRenderer.srcObject!;
        debugPrint('[WebRTC] Stream ID: ${stream.id}');
        debugPrint('[WebRTC] Video Tracks: ${stream.getVideoTracks().length}');
        debugPrint('[WebRTC] Audio Tracks: ${stream.getAudioTracks().length}');
        
        // Check video track status
        final videoTracks = stream.getVideoTracks();
        if (videoTracks.isNotEmpty) {
          final track = videoTracks[0];
          debugPrint('[WebRTC] Track ID: ${track.id}');
          debugPrint('[WebRTC] Track Enabled: ${track.enabled}');
          debugPrint('[WebRTC] Track Muted: ${track.muted}');
          debugPrint('[WebRTC] Track Kind: ${track.kind}');
        }
      }
      
      // Check if video is actually rendering
      if (videoWidth == 0 || videoHeight == 0) {
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] ⚠️ WARNING: VIDEO DIMENSIONS ARE 0x0');
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] This means:');
        debugPrint('[WebRTC] 1. Backend browser is not rendering content');
        debugPrint('[WebRTC] 2. Backend sent answer before browser was ready');
        debugPrint('[WebRTC] 3. No actual video frames are being received');
        debugPrint('[WebRTC] ');
        debugPrint('[WebRTC] BACKEND MUST:');
        debugPrint('[WebRTC] - Wait for browser to fully load and render');
        debugPrint('[WebRTC] - Verify browser dimensions before sending answer');
        debugPrint('[WebRTC] - Start video capture before WebRTC handshake');
        debugPrint('[WebRTC] ========================================');
      } else {
        debugPrint('[WebRTC] ✅ Video is rendering (${videoWidth}x$videoHeight)');
        
        // Calculate aspect ratio
        final aspectRatio = videoWidth / videoHeight;
        final deviceAspectRatio = _deviceWidth / _deviceHeight;
        debugPrint('[WebRTC] Video Aspect Ratio: ${aspectRatio.toStringAsFixed(2)}');
        debugPrint('[WebRTC] Device Aspect Ratio: ${deviceAspectRatio.toStringAsFixed(2)}');
        
        // Check for resolution mismatch
        if (videoWidth != _deviceWidth || videoHeight != _deviceHeight) {
          debugPrint('[WebRTC] ========================================');
          debugPrint('[WebRTC] ⚠️ RESOLUTION MISMATCH DETECTED');
          debugPrint('[WebRTC] ========================================');
          debugPrint('[WebRTC] Expected: ${_deviceWidth}x$_deviceHeight');
          debugPrint('[WebRTC] Received: ${videoWidth}x$videoHeight');
          debugPrint('[WebRTC] ');
          debugPrint('[WebRTC] This means:');
          debugPrint('[WebRTC] 1. Backend is not using requested resolution');
          debugPrint('[WebRTC] 2. WebRTC negotiated different resolution');
          debugPrint('[WebRTC] 3. Video will be scaled (uses more bandwidth)');
          debugPrint('[WebRTC] ');
          debugPrint('[WebRTC] BACKEND SHOULD:');
          debugPrint('[WebRTC] - Create browser window at ${_deviceWidth}x$_deviceHeight');
          debugPrint('[WebRTC] - Respect resolution parameter from request');
          debugPrint('[WebRTC] - Send video at exact device resolution');
          debugPrint('[WebRTC] ========================================');
        }
        
        if ((aspectRatio - deviceAspectRatio).abs() > 0.1) {
          debugPrint('[WebRTC] ⚠️ Aspect ratio mismatch detected');
          debugPrint('[WebRTC] Video may appear stretched or cropped');
        }
      }
      
      debugPrint('[WebRTC] ========================================');
      
      _lastVideoWidth = videoWidth;
      _lastVideoHeight = videoHeight;
    }
  }

  /// Validate if session is still valid
  Future<void> _validateSession() async {
    try {
      debugPrint('[WebRTC] 🔍 Validating session...');

      final isValid = await widget.sessionService.isWebRTCSessionValid();

      if (!mounted) return;

      if (isValid && !_sessionValid) {
        debugPrint('[WebRTC] ✅ Session became valid again');
        setState(() {
          _sessionValid = true;
        });
      } else if (!isValid && _sessionValid) {
        debugPrint('[WebRTC] ❌ Session is no longer valid');
        debugPrint('[WebRTC] 🔄 Automatically navigating to login screen...');
        setState(() {
          _sessionValid = false;
          _errorMessage = 'Session expired or destroyed';
        });
        widget.onDisconnected?.call();

        // Automatically navigate to login after brief delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            debugPrint('[WebRTC] 🔐 Navigating to login screen...');
            context.go(AppRoutes.login);
          }
        });
      } else if (isValid) {
        debugPrint('[WebRTC] ✅ Session is valid');

        // If session is valid but WebRTC is disconnected/failed, try to reconnect
        if (_peerConnection != null) {
          final iceState = await _peerConnection!.getIceConnectionState();
          final peerState = await _peerConnection!.getConnectionState();

          debugPrint(
            '[WebRTC] Current states - ICE: $iceState, Peer: $peerState',
          );

          // Check if either ICE or Peer connection has failed/disconnected
          final iceNeedsReconnect = (iceState ==
                  RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
              iceState == RTCIceConnectionState.RTCIceConnectionStateFailed);

          final peerNeedsReconnect = (peerState ==
                  RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
              peerState == RTCPeerConnectionState.RTCPeerConnectionStateFailed);

          if ((iceNeedsReconnect || peerNeedsReconnect) && !_isReconnecting) {
            debugPrint(
              '[WebRTC] 🔄 Session valid but WebRTC connection failed - auto-reconnecting...',
            );
            debugPrint('[WebRTC]    ICE needs reconnect: $iceNeedsReconnect');
            debugPrint('[WebRTC]    Peer needs reconnect: $peerNeedsReconnect');
            _scheduleReconnect();
          }
        }
      }
    } catch (e) {
      debugPrint('[WebRTC] ⚠️ Session validation error: $e');
      // Don't trigger logout on validation errors - could be temporary network issue
      // Only trigger logout if session is explicitly invalid (not just unreachable)
    }
  }

  /// Initialize WebRTC connection
  Future<void> _initializeWebRTC() async {
    try {
      debugPrint('[WebRTC] Initializing...');

      // Initialize remote renderer
      await _remoteRenderer.initialize();

      // Create peer connection
      await _createPeerConnection();

      // Create and send offer
      await _createOffer();

      // Connect WebSocket for control
      await _connectWebSocket();

      setState(() {
        _isConnecting = false;
      });

      widget.onConnected?.call();
      debugPrint('[WebRTC] ✅ Ready');
    } catch (e) {
      debugPrint('[WebRTC] ❌ Failed: $e');

      setState(() {
        _isConnecting = false;
        _errorMessage = e.toString();
      });

      widget.onError?.call(e.toString());
    }
  }

  /// Connect WebSocket for control
  Future<void> _connectWebSocket() async {
    try {
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] 🔌 CONNECTING WEBSOCKET CONTROLS');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] Note: WebSocket is OPTIONAL');
      debugPrint('[WebRTC] Video streaming works without it');

      // Get session info
      final sessionInfo = await widget.sessionService.getCurrentWebRTCSession();
      if (sessionInfo == null || sessionInfo.accessToken == null) {
        debugPrint('[WebRTC] ⚠️ No session info - skipping WebSocket');
        return;
      }

      // Set up WebSocket callbacks
      widget.controlService.onConnected = () {
        if (mounted) {
          setState(() {
            _isWebSocketConnected = true;
          });
          debugPrint('[WebRTC] ✅ WebSocket controls enabled');
        }
      };

      widget.controlService.onDisconnected = () {
        if (mounted) {
          setState(() {
            _isWebSocketConnected = false;
          });
          debugPrint('[WebRTC] ⚠️ WebSocket controls disabled');
        }
      };

      widget.controlService.onMessage = (message) {
        // Handle page info response
        if (message['type'] == 'page_info') {
          debugPrint('[WebRTC] Page: ${message['data']}');
        }
      };

      widget.controlService.onError = (error) {
        debugPrint('[WebRTC] ⚠️ WebSocket error (non-critical): $error');
        // Error is non-critical - video streaming continues
      };

      // Connect to WebSocket with timeout (run in background, don't block)
      // WebSocket is OPTIONAL - video streaming works without it
      widget.controlService
          .connect(
            sessionId: sessionInfo.sessionId,
            accessToken: sessionInfo.accessToken!,
            maxRetries: 2,
            timeout: const Duration(seconds: 10),
            autoReconnect: true,
          )
          .timeout(
            const Duration(seconds: 30), // Longer timeout to prevent premature failure
            onTimeout: () {
              debugPrint('[WebRTC] ⚠️ WebSocket connection timeout (30s)');
              debugPrint('[WebRTC] Continuing without WebSocket controls');
              return; // Return void to match Future<void>
            },
          )
          .catchError((error) {
            debugPrint('[WebRTC] ⚠️ WebSocket connection error: $error');
            debugPrint('[WebRTC] This is non-critical - video streaming continues');
            // Don't rethrow - WebSocket is optional
          });

      debugPrint('[WebRTC] ✅ WebSocket controls ready');
    } catch (e, stackTrace) {
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] ⚠️ WEBSOCKET CONNECTION FAILED');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] Error: $e');
      debugPrint('[WebRTC] This is NOT critical - video streaming continues');
      debugPrint('[WebRTC] Touch controls will not work without WebSocket');
      debugPrint('[WebRTC] ========================================');

      // Log stack trace only in debug mode
      if (kDebugMode) {
        debugPrint('[WebRTC] Stack trace: $stackTrace');
      }

      // Don't throw - WebSocket is optional for video streaming
      // Video will still work, just without interactive controls
    }
  }

  /// Create RTCPeerConnection
  Future<void> _createPeerConnection() async {
    try {
      // Configuration for peer connection with TURN servers for NAT traversal
      final configuration = {
        'iceServers': [
          // Google STUN servers (most reliable)
          {
            'urls': [
              'stun:stun.l.google.com:19302',
              'stun:stun1.l.google.com:19302',
              'stun:stun2.l.google.com:19302',
              'stun:stun3.l.google.com:19302',
              'stun:stun4.l.google.com:19302',
            ],
          },
          // Primary TURN server with TCP fallback
          {
            'urls': [
              'turn:openrelay.metered.ca:443?transport=tcp',
              'turn:openrelay.metered.ca:443',
              'turn:openrelay.metered.ca:80',
            ],
            'username': 'openrelayproject',
            'credential': 'openrelayproject',
          },
          // Backup TURN server
          {
            'urls': [
              'turn:numb.viagenie.ca:3478?transport=tcp',
              'turn:numb.viagenie.ca:3478',
            ],
            'username': 'webrtc@live.com',
            'credential': 'muazkh',
          },
        ],
        'sdpSemantics': 'unified-plan',
        'iceCandidatePoolSize': 10,
        'iceTransportPolicy': 'all', // Try all connection types
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
      };

      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] 📱 DEVICE RESOLUTION CONFIGURATION');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] Device Width: $_deviceWidth px');
      debugPrint('[WebRTC] Device Height: $_deviceHeight px');
      debugPrint('[WebRTC] Aspect Ratio: ${(_deviceWidth / _deviceHeight).toStringAsFixed(2)}');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] ICE Servers configured:');
      debugPrint('[WebRTC]   - STUN: stun.l.google.com:19302');
      debugPrint('[WebRTC]   - TURN: openrelay.metered.ca (primary)');
      debugPrint('[WebRTC]   - TURN: numb.viagenie.ca (backup)');

      // Create peer connection
      _peerConnection = await createPeerConnection(configuration);

      // Set up event handlers
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null) {
          // Parse candidate type
          final candidateStr = candidate.candidate!;
          String candidateType = 'unknown';
          if (candidateStr.contains('typ host')) {
            candidateType = 'host (local)';
          } else if (candidateStr.contains('typ srflx')) {
            candidateType = 'srflx (STUN)';
          } else if (candidateStr.contains('typ relay')) {
            candidateType = 'relay (TURN)';
          }
          
          debugPrint('[WebRTC] 🧊 ICE candidate [$candidateType]: ${candidateStr.substring(0, candidateStr.length > 80 ? 80 : candidateStr.length)}...');
        }
        // ICE candidates are trickled automatically in unified-plan
      };

      _peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
        debugPrint('[WebRTC] ICE Gathering State: $state');
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        debugPrint('[WebRTC] ICE State: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
          debugPrint('[WebRTC] ✅ ICE connected');
          _reconnectAttempts = 0; // Reset reconnect counter on success
          if (mounted) {
            setState(() {
              _sessionValid = true;
            });
          }
          // Check if video is rendering
          Future.delayed(const Duration(seconds: 2), () {
            if (_remoteRenderer.srcObject == null) {
              debugPrint(
                '[WebRTC] ⚠️ No video source after 2s - video track may not be received',
              );
            } else {
              debugPrint(
                '[WebRTC] ✅ Video source is set: ${_remoteRenderer.srcObject?.id}',
              );
            }
          });
        } else if (state ==
            RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
          debugPrint('[WebRTC] ⚠️ ICE disconnected (temporary)');
          if (mounted) {
            setState(() {});
          }
          widget.onDisconnected?.call();
          // Don't reconnect immediately - wait longer to see if it recovers
          debugPrint('[WebRTC] Waiting 10s to see if connection recovers...');
          Future.delayed(const Duration(seconds: 10), () async {
            if (!mounted) return;

            // Check if still disconnected after 10 seconds
            final currentState = await _peerConnection?.getIceConnectionState();
            if (currentState ==
                    RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
                currentState ==
                    RTCIceConnectionState.RTCIceConnectionStateFailed) {
              debugPrint(
                '[WebRTC] Connection did not recover after 10s - checking session validity...',
              );

              // Check if session is still valid before reconnecting
              final isValid = await widget.sessionService
                  .isWebRTCSessionValid();
              if (isValid) {
                debugPrint('[WebRTC] ✅ Session valid - scheduling reconnect');
                _scheduleReconnect();
              } else {
                debugPrint('[WebRTC] ❌ Session invalid - navigating to login');
                if (mounted) {
                  setState(() {
                    _sessionValid = false;
                    _errorMessage = 'Session expired';
                  });
                  // Auto-navigate to login
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      context.go(AppRoutes.login);
                    }
                  });
                }
              }
            } else {
              debugPrint('[WebRTC] Connection recovered - no reconnect needed');
            }
          });
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          debugPrint('[WebRTC] ❌ ICE failed');
          debugPrint('[WebRTC] ========================================');
          debugPrint('[WebRTC] ICE CONNECTION FAILURE DIAGNOSIS');
          debugPrint('[WebRTC] ========================================');
          debugPrint('[WebRTC] Possible causes:');
          debugPrint('[WebRTC] 1. Backend browser not rendering (0x0 dimensions)');
          debugPrint('[WebRTC] 2. Backend WebRTC server not publicly accessible');
          debugPrint('[WebRTC] 3. NAT/Firewall blocking WebRTC traffic');
          debugPrint('[WebRTC] 4. TURN servers not working or blocked');
          debugPrint('[WebRTC] 5. Backend not sending valid ICE candidates');
          debugPrint('[WebRTC] 6. Network connectivity issues');
          debugPrint('[WebRTC] ');
          debugPrint('[WebRTC] REQUIRED BACKEND FIXES:');
          debugPrint('[WebRTC] - Backend MUST wait for browser to render before sending answer');
          debugPrint('[WebRTC] - Backend MUST ensure browser window has correct size');
          debugPrint('[WebRTC] - Backend MUST start video capture before WebRTC handshake');
          debugPrint('[WebRTC] - Backend must be publicly accessible (not localhost)');
          debugPrint('[WebRTC] - Backend must have working TURN server');
          debugPrint('[WebRTC] - Backend firewall must allow UDP ports 10000-20000');
          debugPrint('[WebRTC] - Backend must send ICE candidates in SDP answer');
          debugPrint('[WebRTC] ========================================');
          
          if (mounted) {
            setState(() {});
          }
          widget.onDisconnected?.call();
          
          // Wait a bit before checking session validity (give backend time to stabilize)
          Future.delayed(const Duration(seconds: 3), () async {
            if (!mounted) return;
            
            // Check session validity before attempting reconnection
            final isValid = await widget.sessionService.isWebRTCSessionValid();
            if (isValid) {
              debugPrint('[WebRTC] ✅ Session valid - attempting reconnection');
              _scheduleReconnect();
            } else {
              debugPrint('[WebRTC] ❌ Session invalid - navigating to login');
              if (mounted) {
                setState(() {
                  _sessionValid = false;
                  _errorMessage = 'Session expired or destroyed';
                });
                // Auto-navigate to login
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    context.go(AppRoutes.login);
                  }
                });
              }
            }
          });
        }
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] 📡 TRACK RECEIVED EVENT');
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC]   Track kind: ${event.track.kind}');
        debugPrint('[WebRTC]   Track ID: ${event.track.id}');
        debugPrint('[WebRTC]   Track enabled: ${event.track.enabled}');
        debugPrint('[WebRTC]   Track muted: ${event.track.muted}');
        debugPrint('[WebRTC]   Streams count: ${event.streams.length}');

        if (event.track.kind == 'video') {
          debugPrint('[WebRTC] 📹 VIDEO TRACK RECEIVED');

          if (event.streams.isNotEmpty) {
            final stream = event.streams[0];
            debugPrint('[WebRTC] ========================================');
            debugPrint('[WebRTC] 🎬 STREAM DETAILS');
            debugPrint('[WebRTC] ========================================');
            debugPrint('[WebRTC] Stream ID: ${stream.id}');
            debugPrint(
              '[WebRTC] Stream video tracks: ${stream.getVideoTracks().length}',
            );
            debugPrint(
              '[WebRTC] Stream audio tracks: ${stream.getAudioTracks().length}',
            );

            // Get video track for diagnostics
            final videoTracks = stream.getVideoTracks();
            if (videoTracks.isNotEmpty) {
              final videoTrack = videoTracks[0];
              debugPrint('[WebRTC] ========================================');
              debugPrint('[WebRTC] 📹 VIDEO TRACK DIAGNOSTICS');
              debugPrint('[WebRTC] ========================================');
              debugPrint('[WebRTC]   - ID: ${videoTrack.id}');
              debugPrint('[WebRTC]   - Kind: ${videoTrack.kind}');
              debugPrint('[WebRTC]   - Enabled: ${videoTrack.enabled}');
              debugPrint('[WebRTC]   - Muted: ${videoTrack.muted}');

              // Ensure track is enabled
              try {
                if (videoTrack.enabled == false) {
                  debugPrint('[WebRTC] 🔧 Enabling video track...');
                  videoTrack.enabled = true;
                }

                if (videoTrack.muted == true) {
                  debugPrint('[WebRTC] ⚠️ WARNING: Video track is MUTED!');
                  debugPrint(
                    '[WebRTC] This may cause blank video',
                  );
                }
              } catch (e) {
                debugPrint('[WebRTC] ⚠️ Could not check track state: $e');
              }
            } else {
              debugPrint('[WebRTC] ❌ ERROR: Stream has NO video tracks!');
            }

            if (mounted) {
              setState(() {
                _remoteRenderer.srcObject = stream;
              });
              debugPrint('[WebRTC] ========================================');
              debugPrint('[WebRTC] ✅ VIDEO RENDERER UPDATED');
              debugPrint('[WebRTC] ========================================');

              // Log renderer state immediately
              debugPrint('[WebRTC] Renderer state (immediate):');
              debugPrint(
                '[WebRTC]   - srcObject: ${_remoteRenderer.srcObject?.id}',
              );
              debugPrint(
                '[WebRTC]   - videoWidth: ${_remoteRenderer.videoWidth}',
              );
              debugPrint(
                '[WebRTC]   - videoHeight: ${_remoteRenderer.videoHeight}',
              );
              debugPrint(
                '[WebRTC]   - textureId: ${_remoteRenderer.textureId}',
              );
              
              // Check video dimensions after a short delay (frames may not be ready immediately)
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  debugPrint('[WebRTC] ========================================');
                  debugPrint('[WebRTC] 📹 VIDEO FRAME CHECK (500ms after track)');
                  debugPrint('[WebRTC] ========================================');
                  debugPrint('[WebRTC] Video Dimensions: ${_remoteRenderer.videoWidth}x${_remoteRenderer.videoHeight}');
                  
                  if (_remoteRenderer.videoWidth == 0 || _remoteRenderer.videoHeight == 0) {
                    debugPrint('[WebRTC] ⚠️ WARNING: Still 0x0 after 500ms');
                    debugPrint('[WebRTC] Backend browser may not be rendering yet');
                  } else {
                    debugPrint('[WebRTC] ✅ Video frames are being received!');
                    debugPrint('[WebRTC] Resolution: ${_remoteRenderer.videoWidth}x${_remoteRenderer.videoHeight}');
                  }
                  debugPrint('[WebRTC] ========================================');
                }
              });
              
              // Check again after 2 seconds
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  debugPrint('[WebRTC] ========================================');
                  debugPrint('[WebRTC] 📹 VIDEO FRAME CHECK (2s after track)');
                  debugPrint('[WebRTC] ========================================');
                  debugPrint('[WebRTC] Video Dimensions: ${_remoteRenderer.videoWidth}x${_remoteRenderer.videoHeight}');
                  
                  if (_remoteRenderer.videoWidth == 0 || _remoteRenderer.videoHeight == 0) {
                    debugPrint('[WebRTC] ❌ CRITICAL: Still 0x0 after 2 seconds!');
                    debugPrint('[WebRTC] ');
                    debugPrint('[WebRTC] This is a BACKEND ISSUE:');
                    debugPrint('[WebRTC] 1. Backend browser is not rendering content');
                    debugPrint('[WebRTC] 2. Backend sent WebRTC answer too early');
                    debugPrint('[WebRTC] 3. Backend video capture not working');
                    debugPrint('[WebRTC] ');
                    debugPrint('[WebRTC] BACKEND MUST FIX:');
                    debugPrint('[WebRTC] - Wait for browser to fully load before WebRTC');
                    debugPrint('[WebRTC] - Verify browser dimensions are correct');
                    debugPrint('[WebRTC] - Start video capture before sending answer');
                  } else {
                    debugPrint('[WebRTC] ✅ Video is rendering correctly!');
                    debugPrint('[WebRTC] Resolution: ${_remoteRenderer.videoWidth}x${_remoteRenderer.videoHeight}');
                    
                    // Log frame info immediately
                    _logVideoFrameInfo();
                  }
                  debugPrint('[WebRTC] ========================================');
                }
              });
            }
          } else {
            debugPrint('[WebRTC] ⚠️ No streams in track event');
          }
        } else if (event.track.kind == 'audio') {
          debugPrint('[WebRTC] 🔊 Audio track received');
          // Audio tracks are handled automatically by WebRTC
        } else {
          debugPrint('[WebRTC] ❓ Unknown track type: ${event.track.kind}');
        }
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('[WebRTC] Peer Connection State: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          debugPrint('[WebRTC] ✅ Peer connection fully established');

          // Check transceivers and manually get streams if onTrack didn't fire
          _peerConnection!.getTransceivers().then((transceivers) async {
            debugPrint('[WebRTC] Active transceivers: ${transceivers.length}');

            for (var transceiver in transceivers) {
              debugPrint('[WebRTC]   - ${transceiver.mid}');
              if (transceiver.receiver.track != null) {
                final track = transceiver.receiver.track!;
                debugPrint(
                  '[WebRTC]     Receiver track: ${track.kind} (enabled: ${track.enabled})',
                );

                // If video track exists but renderer has no source, manually create stream
                if (track.kind == 'video' &&
                    _remoteRenderer.srcObject == null) {
                  debugPrint(
                    '[WebRTC] 🔧 Manually creating video stream from track',
                  );

                  // Get remote streams from peer connection
                  final remoteStreams = _peerConnection!.getRemoteStreams();
                  debugPrint(
                    '[WebRTC] Remote streams available: ${remoteStreams.length}',
                  );

                  if (remoteStreams.isNotEmpty) {
                    final videoStream = remoteStreams.first;
                    debugPrint(
                      '[WebRTC] Using remote stream: ${videoStream?.id}',
                    );

                    if (mounted) {
                      setState(() {
                        _remoteRenderer.srcObject = videoStream;
                      });
                      debugPrint('[WebRTC] ✅ Video renderer manually updated');
                    }
                  } else {
                    debugPrint('[WebRTC] ⚠️ No remote streams available');
                  }
                }
              }
            }
          });
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          debugPrint('[WebRTC] ❌ Peer connection failed');
          if (mounted) {
            setState(() {
              _errorMessage = 'Peer connection failed';
            });
          }
        }
      };
    } catch (e) {
      debugPrint('[WebRTC] ❌ Peer connection failed: $e');
      rethrow;
    }
  }

  /// Create offer and send to server
  Future<void> _createOffer() async {
    try {
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] STEP 1: Creating WebRTC Offer');
      debugPrint('[WebRTC] ========================================');

      // Add video transceiver BEFORE creating offer
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      debugPrint('[WebRTC] ✅ Video transceiver added (RecvOnly)');

      // Add audio transceiver as well (some backends require it)
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      debugPrint('[WebRTC] ✅ Audio transceiver added (RecvOnly)');

      // Create offer with device resolution constraints
      debugPrint('[WebRTC] Creating SDP offer with device resolution...');
      final Map<String, dynamic> offerOptions = {
        'offerToReceiveVideo': 1,
        'offerToReceiveAudio': 1,
        'mandatory': {
          'OfferToReceiveVideo': true,
          'OfferToReceiveAudio': true,
          'maxWidth': _deviceWidth.toString(),
          'maxHeight': _deviceHeight.toString(),
          'minWidth': _deviceWidth.toString(),
          'minHeight': _deviceHeight.toString(),
        },
        'optional': [
          {'DtlsSrtpKeyAgreement': true},
        ],
      };

      // Log the exact resolution being requested
      debugPrint('[WebRTC] 📐 Requesting video with resolution:');
      debugPrint('[WebRTC]    Width: $_deviceWidth px');
      debugPrint('[WebRTC]    Height: $_deviceHeight px');
      debugPrint('[WebRTC]    Constraints: ${_deviceWidth}x$_deviceHeight (min and max)');

      RTCSessionDescription offer = await _peerConnection!.createOffer(
        offerOptions,
      );
      debugPrint('[WebRTC] ✅ SDP offer created');

      debugPrint('[WebRTC] STEP 2: Setting local description...');
      await _peerConnection!.setLocalDescription(offer);
      debugPrint('[WebRTC] ✅ Local description set');

      // Wait for ICE gathering to complete before sending offer
      debugPrint('[WebRTC] STEP 3: Gathering ICE candidates...');
      await _waitForIceGatheringComplete();

      // Get the updated local description with ICE candidates
      final localDescription = await _peerConnection!.getLocalDescription();
      if (localDescription == null) {
        throw Exception('Local description is null after ICE gathering');
      }

      final offerLength = localDescription.sdp?.length ?? 0;
      debugPrint(
        '[WebRTC] ✅ Offer ready with ICE candidates ($offerLength chars)',
      );

      // Count ICE candidates
      final candidateCount =
          localDescription.sdp?.split('a=candidate:').length ?? 1;
      debugPrint('[WebRTC] ICE candidates in offer: ${candidateCount - 1}');

      // Analyze ICE candidate types
      if (localDescription.sdp != null) {
        final sdp = localDescription.sdp!;
        final hasHostCandidates = sdp.contains('typ host');
        final hasSrflxCandidates = sdp.contains('typ srflx');
        final hasRelayCandidates = sdp.contains('typ relay');
        
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] ICE CANDIDATE ANALYSIS');
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] Host candidates (local): $hasHostCandidates');
        debugPrint('[WebRTC] Srflx candidates (STUN): $hasSrflxCandidates');
        debugPrint('[WebRTC] Relay candidates (TURN): $hasRelayCandidates');
        
        if (!hasSrflxCandidates && !hasRelayCandidates) {
          debugPrint('[WebRTC] ========================================');
          debugPrint('[WebRTC] ⚠️ WARNING: NO PUBLIC IP CANDIDATES!');
          debugPrint('[WebRTC] ========================================');
          debugPrint('[WebRTC] Only localhost candidates found.');
          debugPrint('[WebRTC] This means STUN/TURN servers are not working.');
          debugPrint('[WebRTC] ');
          debugPrint('[WebRTC] Possible causes:');
          debugPrint('[WebRTC] 1. Network/firewall blocking STUN/TURN servers');
          debugPrint('[WebRTC] 2. STUN/TURN servers are down');
          debugPrint('[WebRTC] 3. VPN interfering with WebRTC');
          debugPrint('[WebRTC] 4. Corporate firewall blocking UDP');
          debugPrint('[WebRTC] ');
          debugPrint('[WebRTC] Connection will likely FAIL because:');
          debugPrint('[WebRTC] - Backend cannot reach 127.0.0.1 (localhost)');
          debugPrint('[WebRTC] - No public IP for backend to connect to');
          debugPrint('[WebRTC] - No TURN relay available');
          debugPrint('[WebRTC] ');
          debugPrint('[WebRTC] Try:');
          debugPrint('[WebRTC] 1. Switch to different network (WiFi/mobile data)');
          debugPrint('[WebRTC] 2. Disable VPN if active');
          debugPrint('[WebRTC] 3. Check if firewall is blocking UDP ports');
          debugPrint('[WebRTC] 4. Backend must provide its own TURN server');
          debugPrint('[WebRTC] ========================================');
        } else {
          debugPrint('[WebRTC] ✅ Public IP candidates found - connection should work');
        }
      }

      // Print full SDP offer for debugging
      if (localDescription.sdp != null) {
        debugPrint('[WebRTC] ========== SDP OFFER START ==========');
        final offerLines = localDescription.sdp!.split('\n');
        debugPrint('[WebRTC] Total lines: ${offerLines.length}');
        for (int i = 0; i < offerLines.length; i++) {
          debugPrint('[OFFER Line ${i + 1}] ${offerLines[i]}');
        }
        debugPrint('[WebRTC] ========== SDP OFFER END ==========');
      }

      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] STEP 4: Sending offer to backend');
      debugPrint('[WebRTC] ========================================');

      // Send offer to server and get answer
      final answer = await widget.sessionService.handleWebRTCOffer(
        sdp: localDescription.sdp!,
        type: localDescription.type!,
      );

      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] STEP 5: Received answer from backend');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] Answer size: ${answer.sdp.length} chars');

      // Count ICE candidates in answer
      final answerCandidateCount = answer.sdp.split('a=candidate:').length - 1;
      debugPrint('[WebRTC] ICE candidates in answer: $answerCandidateCount');

      // Print full SDP answer for debugging
      debugPrint('[WebRTC] ========== SDP ANSWER START ==========');
      final sdpLines = answer.sdp.split('\n');
      debugPrint('[WebRTC] Total lines: ${sdpLines.length}');
      for (int i = 0; i < sdpLines.length; i++) {
        debugPrint('[SDP Line ${i + 1}] ${sdpLines[i]}');
      }
      debugPrint('[WebRTC] ========== SDP ANSWER END ==========');

      // Check if answer contains video
      final hasVideo = answer.sdp.contains('m=video');
      final hasAudio = answer.sdp.contains('m=audio');
      final hasApplication = answer.sdp.contains('m=application');

      debugPrint('[WebRTC] ========== SDP ANALYSIS ==========');
      debugPrint('[WebRTC] Has video: $hasVideo');
      debugPrint('[WebRTC] Has audio: $hasAudio');
      debugPrint('[WebRTC] Has application: $hasApplication');

      if (!hasVideo) {
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] ❌ CRITICAL ERROR: NO VIDEO IN SDP');
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] Backend is NOT sending video track!');
        debugPrint('[WebRTC] This is why the screen is blank/green!');
        debugPrint('[WebRTC] ');
        debugPrint('[WebRTC] BACKEND MUST:');
        debugPrint('[WebRTC]   1. Start browser with correct resolution');
        debugPrint('[WebRTC]   2. Capture video from browser');
        debugPrint('[WebRTC]   3. Add video track to WebRTC peer connection');
        debugPrint('[WebRTC]   4. Include video in SDP answer');
        debugPrint('[WebRTC] ========================================');
        throw Exception(
          'Backend SDP answer has no video track - cannot display video',
        );
      }

      if (hasVideo) {
        // Extract video codec info
        final videoCodecs = <String>[];
        final videoSettings = <String>[];
        bool inVideoSection = false;
        for (final line in sdpLines) {
          if (line.startsWith('m=video')) {
            inVideoSection = true;
            debugPrint('[WebRTC] Video media line: $line');

            // Check if video is rejected
            if (line.contains(' 0 ')) {
              debugPrint('[WebRTC] ========================================');
              debugPrint('[WebRTC] ❌ VIDEO PORT IS 0 - VIDEO REJECTED!');
              debugPrint('[WebRTC] ========================================');
              debugPrint('[WebRTC] Backend rejected video track!');
              throw Exception('Backend rejected video track (port 0)');
            }
          } else if (line.startsWith('m=')) {
            inVideoSection = false;
          }
          if (inVideoSection) {
            if (line.startsWith('a=rtpmap:')) {
              videoCodecs.add(line);
            } else if (line.startsWith('a=fmtp:')) {
              videoSettings.add(line);
            } else if (line.startsWith('a=sendonly') ||
                line.startsWith('a=recvonly') ||
                line.startsWith('a=sendrecv') ||
                line.startsWith('a=inactive')) {
              debugPrint('[WebRTC] Video direction: $line');
              if (line.startsWith('a=inactive')) {
                debugPrint('[WebRTC] ========================================');
                debugPrint('[WebRTC] ❌ VIDEO TRACK IS INACTIVE!');
                debugPrint('[WebRTC] ========================================');
                throw Exception('Backend video track is inactive');
              }
            }
          }
        }
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] 📹 VIDEO CODECS AVAILABLE: ${videoCodecs.length}');
        debugPrint('[WebRTC] ========================================');
        for (final codec in videoCodecs) {
          debugPrint('[WebRTC]   $codec');
        }
        if (videoSettings.isNotEmpty) {
          debugPrint('[WebRTC] ========================================');
          debugPrint('[WebRTC] 📹 VIDEO SETTINGS:');
          debugPrint('[WebRTC] ========================================');
          for (final setting in videoSettings) {
            debugPrint('[WebRTC]   $setting');
          }
        }
        if (videoCodecs.isEmpty) {
          debugPrint('[WebRTC] ========================================');
          debugPrint('[WebRTC] ⚠️ WARNING: No video codecs found!');
          debugPrint('[WebRTC] ========================================');
          debugPrint('[WebRTC] Video track exists but no codecs specified');
          debugPrint('[WebRTC] This may cause playback issues');
        }
      }
      debugPrint('[WebRTC] ========== ANALYSIS END ==========');

      // Validate and potentially fix SDP answer
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] STEP 6: Validating SDP answer');
      debugPrint('[WebRTC] ========================================');

      String fixedSdp = _validateAndFixSdp(answer.sdp);
      if (fixedSdp != answer.sdp) {
        debugPrint('[WebRTC] ⚠️ SDP auto-fixed (BUNDLE issue)');
      } else {
        debugPrint('[WebRTC] ✅ SDP validation passed');
      }

      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] STEP 7: Setting remote description');
      debugPrint('[WebRTC] ========================================');

      // Check peer connection state before setting remote description
      final signalingState = await _peerConnection!.getSignalingState();
      debugPrint('[WebRTC] Current signaling state: $signalingState');
      
      if (signalingState == RTCSignalingState.RTCSignalingStateStable) {
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] ⚠️ WARNING: Peer connection in STABLE state');
        debugPrint('[WebRTC] ========================================');
        debugPrint('[WebRTC] This means:');
        debugPrint('[WebRTC] 1. No offer/answer exchange in progress');
        debugPrint('[WebRTC] 2. Local description may not be set');
        debugPrint('[WebRTC] 3. This could be a reconnection issue');
        debugPrint('[WebRTC] ');
        
        // Check if local description exists
        final localDesc = await _peerConnection!.getLocalDescription();
        if (localDesc == null) {
          debugPrint('[WebRTC] ❌ No local description set!');
          debugPrint('[WebRTC] Cannot set remote description without local description');
          throw Exception('Cannot set remote description: no local description set');
        } else {
          debugPrint('[WebRTC] ✅ Local description exists');
          debugPrint('[WebRTC] This might be a duplicate call - aborting');
          throw Exception('Cannot set remote description: peer connection already in stable state');
        }
      } else if (signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        debugPrint('[WebRTC] ✅ Correct state: have-local-offer');
        debugPrint('[WebRTC] Ready to set remote answer');
      } else {
        debugPrint('[WebRTC] ⚠️ Unexpected state: $signalingState');
      }

      // Set remote description
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(fixedSdp, answer.type),
      );

      debugPrint('[WebRTC] ✅ Remote description set successfully');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] STEP 8: Waiting for ICE connection');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] ICE will now attempt to establish connection...');
      debugPrint('[WebRTC] Watch for ICE state changes above');
      debugPrint('[WebRTC] Expected flow:');
      debugPrint('[WebRTC]   1. ICE State: Checking');
      debugPrint('[WebRTC]   2. ICE State: Connected');
      debugPrint('[WebRTC]   3. Peer Connection: Connected');
      debugPrint('[WebRTC]   4. Video track received');
      debugPrint('[WebRTC] ========================================');

      debugPrint('[WebRTC] ✅ WebRTC offer/answer exchange complete');
    } catch (e) {
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] ❌ WEBRTC SETUP FAILED');
      debugPrint('[WebRTC] ========================================');
      debugPrint('[WebRTC] ❌ Error: $e');
      debugPrint(
        '[WebRTC] ❌ Failed at: ${e.toString().contains('setRemoteDescription') ? 'Setting remote description' : 'Unknown step'}',
      );
      rethrow;
    }
  }

  /// Cleanup resources
  Future<void> _cleanup() async {
    try {
      await widget.controlService.disconnect();
      await _peerConnection?.close();
      await _remoteRenderer.dispose();
      _peerConnection = null;
    } catch (e) {
      debugPrint('[WebRTC] Cleanup error: $e');
    }
  }

  /// Wait for ICE gathering to complete
  Future<void> _waitForIceGatheringComplete() async {
    // Check current state
    final currentState = await _peerConnection!.getIceGatheringState();
    debugPrint('[WebRTC] Current ICE gathering state: $currentState');

    if (currentState == RTCIceGatheringState.RTCIceGatheringStateComplete) {
      debugPrint('[WebRTC] ✅ ICE already complete');
      return;
    }

    // Wait a bit for gathering to complete
    debugPrint('[WebRTC] Waiting for ICE candidates...');
    await Future.delayed(const Duration(seconds: 2));

    final finalState = await _peerConnection!.getIceGatheringState();
    debugPrint('[WebRTC] Final ICE gathering state: $finalState');

    if (finalState == RTCIceGatheringState.RTCIceGatheringStateComplete) {
      debugPrint('[WebRTC] ✅ ICE gathering complete');
    } else {
      debugPrint('[WebRTC] ⚠️ ICE gathering not complete - proceeding anyway');
    }
  }

  /// Validate and fix SDP answer (workaround for backend SDP issues)
  String _validateAndFixSdp(String sdp) {
    // Check for empty BUNDLE group
    if (sdp.contains('a=group:BUNDLE \n') ||
        sdp.contains('a=group:BUNDLE\r\n')) {
      // Extract MID from m= section
      final midMatch = RegExp(r'a=mid:(\S+)').firstMatch(sdp);
      if (midMatch != null) {
        final mid = midMatch.group(1);

        // Fix empty BUNDLE by adding the MID
        sdp = sdp.replaceAll(
          RegExp(r'a=group:BUNDLE\s*\n'),
          'a=group:BUNDLE $mid\n',
        );
        sdp = sdp.replaceAll(
          RegExp(r'a=group:BUNDLE\s*\r\n'),
          'a=group:BUNDLE $mid\r\n',
        );
      }
    }

    // Check if BUNDLE group exists but has no MIDs
    final bundleMatch = RegExp(r'a=group:BUNDLE\s+(.*)').firstMatch(sdp);
    if (bundleMatch != null) {
      final bundleMids = bundleMatch.group(1)?.trim() ?? '';
      if (bundleMids.isEmpty) {
        // Try to extract MID and fix
        final midMatch = RegExp(r'a=mid:(\S+)').firstMatch(sdp);
        if (midMatch != null) {
          final mid = midMatch.group(1);
          sdp = sdp.replaceFirst(
            RegExp(r'a=group:BUNDLE\s*'),
            'a=group:BUNDLE $mid ',
          );
        }
      }
    }

    return sdp;
  }

  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    // Prevent multiple reconnection attempts
    if (_isReconnecting) {
      if (_verboseLogging) {
        debugPrint('[WebRTC] ⚠️ Reconnection already in progress - skipping');
      }
      return;
    }

    // Check if we've exceeded max attempts first
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint(
        '[WebRTC] ❌ Max reconnect attempts reached ($_maxReconnectAttempts)',
      );
      if (mounted) {
        setState(() {
          _errorMessage =
              'Connection failed after $_maxReconnectAttempts attempts. Session is still valid - tap retry to reconnect.';
        });
      }
      return;
    }

    _reconnectAttempts++;
    
    // Calculate delay IMMEDIATELY after incrementing
    final delaySeconds = _reconnectAttempts * 2; // 2s, 4s, 6s, 8s, 10s
    
    if (_verboseLogging) {
      debugPrint(
        '[WebRTC] 🔄 Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts in ${delaySeconds}s',
      );
    }

    // Set reconnecting flag immediately to prevent duplicate schedules
    _isReconnecting = true;

    // Check if session is still valid before scheduling reconnect
    widget.sessionService.isWebRTCSessionValid().then((isValid) {
      if (!mounted) {
        if (_verboseLogging) {
          debugPrint('[WebRTC] ⚠️ Widget disposed during session validation');
        }
        _isReconnecting = false;
        return;
      }

      if (!isValid) {
        debugPrint('[WebRTC] ❌ Session invalid - cancelling reconnect');
        _isReconnecting = false;
        if (mounted) {
          setState(() {
            _sessionValid = false;
            _errorMessage = 'Session expired or destroyed';
          });
        }
        return;
      }

      if (_verboseLogging) {
        debugPrint('[WebRTC] ✅ Session valid - will reconnect in ${delaySeconds}s');
      }
      
      // Cancel any existing reconnect timer
      _reconnectTimer?.cancel();

      _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
        if (_verboseLogging) {
          debugPrint(
            '[WebRTC] ⏰ Reconnect timer fired - mounted: $mounted, reconnecting: $_isReconnecting',
          );
        }
        
        if (!mounted) {
          if (_verboseLogging) {
            debugPrint('[WebRTC] ⚠️ Widget disposed when timer fired');
          }
          _isReconnecting = false;
          return;
        }
        
        if (_isReconnecting) {
          _retryConnection();
        } else {
          if (_verboseLogging) {
            debugPrint(
              '[WebRTC] ⚠️ Reconnecting flag was cleared before timer fired',
            );
          }
        }
      });
    }).catchError((error) {
      debugPrint('[WebRTC] ❌ Error validating session for reconnect: $error');
      _isReconnecting = false; // Reset flag on error
    });
  }

  /// Retry connection
  Future<void> _retryConnection() async {
    if (_verboseLogging) {
      debugPrint(
        '[WebRTC] 🔍 _retryConnection called - mounted: $mounted, reconnecting: $_isReconnecting',
      );
    }

    if (!mounted) {
      if (_verboseLogging) {
        debugPrint('[WebRTC] ⚠️ Retry cancelled - widget disposed');
      }
      _isReconnecting = false;
      return;
    }

    if (!_isReconnecting) {
      if (_verboseLogging) {
        debugPrint('[WebRTC] ⚠️ Retry cancelled - not in reconnecting state');
      }
      return;
    }

    // Check if a connection is already in progress or established
    if (_peerConnection != null) {
      final iceState = await _peerConnection!.getIceConnectionState();
      final signalingState = await _peerConnection!.getSignalingState();
      
      // Don't retry if connection is already working or in progress
      if (iceState == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateCompleted ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateChecking ||
          signalingState != RTCSignalingState.RTCSignalingStateStable) {
        if (_verboseLogging) {
          debugPrint('[WebRTC] ⚠️ Connection already in progress or established');
          debugPrint('[WebRTC]    ICE State: $iceState');
          debugPrint('[WebRTC]    Signaling State: $signalingState');
          debugPrint('[WebRTC] Cancelling retry to avoid duplicate connection');
        }
        _isReconnecting = false;
        return;
      }
    }

    // Validate session before retrying
    if (_verboseLogging) {
      debugPrint('[WebRTC] 🔍 Validating session before retry...');
    }
    final isValid = await widget.sessionService.isWebRTCSessionValid();

    if (!isValid) {
      debugPrint(
        '[WebRTC] ❌ Session invalid - aborting retry and navigating to login',
      );
      if (mounted) {
        setState(() {
          _sessionValid = false;
          _errorMessage = 'Session expired or destroyed';
          _isReconnecting = false;
          _isConnecting = false;
        });
        // Auto-navigate to login
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go(AppRoutes.login);
          }
        });
      }
      return;
    }

    if (_verboseLogging) {
      debugPrint('[WebRTC] ✅ Session valid - proceeding with retry');
      debugPrint('[WebRTC] 🔄 Retrying connection...');
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      await _cleanup();
      _remoteRenderer = RTCVideoRenderer();
      await _initializeWebRTC();

      // Success - reset reconnecting flag
      _isReconnecting = false;
      _reconnectAttempts = 0; // Reset attempts on success
      if (_verboseLogging) {
        debugPrint('[WebRTC] ✅ Reconnection successful!');
      }
    } catch (e) {
      debugPrint('[WebRTC] ❌ Retry failed: $e');
      _isReconnecting = false;

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _errorMessage = 'Reconnection failed: $e';
        });
      }

      // Schedule another retry if session is still valid
      final stillValid = await widget.sessionService.isWebRTCSessionValid();
      if (stillValid && _reconnectAttempts < _maxReconnectAttempts) {
        if (_verboseLogging) {
          debugPrint('[WebRTC] Session still valid - will retry again');
        }
        _scheduleReconnect();
      } else if (!stillValid) {
        debugPrint('[WebRTC] ❌ Session no longer valid - stopping retries');
      } else {
        debugPrint('[WebRTC] ❌ Max attempts reached - stopping retries');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isConnecting) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.electricCyan),
              const SizedBox(height: 16),
              Text(
                _reconnectAttempts > 0
                    ? 'Reconnecting...'
                    : 'Connecting to workspace...',
                style: TextStyle(color: AppTheme.ghostWhite, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _sessionValid
                      ? Icons.wifi_off_rounded
                      : Icons.error_outline_rounded,
                  size: 64,
                  color: _sessionValid ? AppTheme.warningOrange : AppTheme.warningRed,
                ),
                const SizedBox(height: 16),
                Text(
                  _sessionValid ? 'Connection Lost' : 'Session Expired',
                  style: TextStyle(
                    color: AppTheme.ghostWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_sessionValid)
                  Text(
                    'Session is still valid',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    'Returning to login...',
                    style: TextStyle(
                      color: AppTheme.warningRed.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.ghostWhite.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                if (_sessionValid)
                  ElevatedButton.icon(
                    onPressed: () {
                      debugPrint('[WebRTC] 🔄 Manual retry button pressed');
                      setState(() {
                        _reconnectAttempts = 0;
                        _isReconnecting = true;
                        _errorMessage = null;
                      });
                      _retryConnection();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry Connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricCyan,
                      foregroundColor: Colors.black,
                    ),
                  )
                else
                  CircularProgressIndicator(
                    color: AppTheme.warningRed,
                    strokeWidth: 2,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // ========================================
    // PRODUCTION-READY FULL-SCREEN VIDEO UI
    // ========================================
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
              // ========================================
              // TRUE FULL-SCREEN VIDEO LAYER
              // Positioned edge-to-edge, no SafeArea
              // ========================================
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    if (_isWebSocketConnected &&
                        _remoteRenderer.srcObject != null) {
                      _pointerDownTime = DateTime.now();
                    }
                  },
                  onPointerMove: (event) {
                    if (_isWebSocketConnected &&
                        _remoteRenderer.srcObject != null) {
                      final deltaY = event.delta.dy.toInt();
                      if (deltaY.abs() > 2) {
                        widget.controlService.sendScroll(-deltaY);
                      }
                    }
                  },
                  onPointerUp: (event) {
                    if (_isWebSocketConnected &&
                        _remoteRenderer.srcObject != null) {
                      final renderBox = context.findRenderObject() as RenderBox;
                      final localPosition =
                          renderBox.globalToLocal(event.position);

                      final screenWidth = renderBox.size.width;
                      final screenHeight = renderBox.size.height;

                      // Convert touch coordinates using device resolution
                      final x =
                          ((localPosition.dx / screenWidth) * _deviceWidth).toInt();
                      final y =
                          ((localPosition.dy / screenHeight) * _deviceHeight).toInt();

                      if (_pointerDownTime != null) {
                        final duration =
                            DateTime.now().difference(_pointerDownTime!);

                        if (duration.inMilliseconds < 200) {
                          widget.controlService.sendClick(x, y);
                        } else if (duration.inMilliseconds > 500) {
                          widget.controlService.sendRightClick(x, y);
                        } else {
                          widget.controlService.sendClick(x, y);
                        }
                      }

                      _pointerDownTime = null;
                    }
                  },
                  // FULL-SCREEN VIDEO WITH COVER FIT (fills entire screen, may crop edges)
                  child: RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    mirror: false,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
