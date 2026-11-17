import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ask_jeeves_vmi/data/services/webrtc/webrtc_session_service.dart';
import 'package:ask_jeeves_vmi/data/services/webrtc/webrtc_control_service.dart';
import 'package:ask_jeeves_vmi/shared/handlers/client_error_handler.dart';
import 'package:ask_jeeves_vmi/data/services/location/location_validation_service.dart';
import 'package:ask_jeeves_vmi/data/services/location/workspace_location_monitor_service.dart';
import 'package:ask_jeeves_vmi/data/services/workspace/workspace_socket_service.dart';
import 'package:ask_jeeves_vmi/data/services/workspace/native_input_overlay_service.dart';
import 'package:ask_jeeves_vmi/data/services/workspace/workspace_file_upload_service.dart';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';
import 'package:ask_jeeves_vmi/core/router/app_router.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:ask_jeeves_vmi/presentation/widgets/input_tap_indicator.dart';
import 'package:ask_jeeves_vmi/presentation/widgets/webrtc_stream_widget.dart';
import 'package:ask_jeeves_vmi/presentation/widgets/input_modal_overlay.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  Timer? _sessionMonitorTimer;
  bool _sessionTerminatedDialogShown = false;
  String? _errorMessage;
  bool _isLoading = true;
  bool _webrtcSessionCreated = false;
  
  // Socket connection status
  String? _socketWarning;
  
  // Hybrid interaction services
  WorkspaceSocketService? _socketService;
  NativeInputOverlayService? _inputOverlayService;
  WorkspaceFileUploadService? _fileUploadService;
  final bool _showTapIndicator = false;
  Offset? _tapPosition;
// Track if user is actively typing
  
// Always show input modal by default

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHybridInteraction();
      _initializeWebRTCSession();
      _initializeLocationTracking();
      _startSessionMonitoring();
    });
  }

  @override
  void dispose() {
    _sessionMonitorTimer?.cancel();
    _cleanupHybridInteraction();
    _cleanupWorkspace();
    super.dispose();
  }

  /// Initialize hybrid interaction services
  void _initializeHybridInteraction() {
    debugPrint('[AIChatScreen] 🎯 Initializing hybrid interaction layer...');
    
    // Get services from providers
    _socketService = ref.read(workspaceSocketServiceProvider);
    _inputOverlayService = ref.read(nativeInputOverlayServiceProvider);
    _fileUploadService = ref.read(workspaceFileUploadServiceProvider);
    
    // Setup input overlay callbacks with mounted checks
    _inputOverlayService?.onKeyboardOpen = () {
      if (!mounted) return;
      debugPrint('[AIChatScreen] ⌨️ Native keyboard opened');
    };
    
    _inputOverlayService?.onKeyboardClose = () {
      if (!mounted) return;
      debugPrint('[AIChatScreen] ⌨️ Native keyboard closed');
    };
    
    _inputOverlayService?.onTextChanged = (text) {
      debugPrint('[AIChatScreen] 📝 Text changed: ${text.length} chars');
      // Rebuild to update send button state
      if (mounted) {
        setState(() {
// Track typing state
        });
      }
      // Note: Real-time typing sync disabled - text will be sent on submit
      // Uncomment below to enable real-time typing sync via WebRTC:
      // final controlService = ref.read(webRTCControlServiceProvider);
      // if (text.isNotEmpty) {
      //   controlService.sendType(text);
      //   debugPrint('[AIChatScreen] 📤 Text synced to streaming input via WebRTC');
      // }
    };
    
    // Setup socket callbacks
    _socketService?.onConnected = () {
      debugPrint('[AIChatScreen] ✅ Socket connected');
    };
    
    _socketService?.onDisconnected = () {
      debugPrint('[AIChatScreen] ❌ Socket disconnected');
    };
    
    _socketService?.onRemoteTextUpdate = (text) {
      debugPrint('[AIChatScreen] 📥 Remote text update: ${text.length} chars');
      _inputOverlayService?.updateTextFromRemote(text);
    };
    
    debugPrint('[AIChatScreen] ✅ Hybrid interaction layer initialized');
  }

  /// Hide input modal overlay with animation
  void _hideInputModalOverlay() {
    if (!mounted) return;
    
    debugPrint('[AIChatScreen] 🎬 Hiding input modal overlay');
    
    setState(() {
    });
    
    // Deactivate native input overlay
    _inputOverlayService?.deactivateInput();
  }

  /// Cleanup hybrid interaction services
  void _cleanupHybridInteraction() {
    debugPrint('[AIChatScreen] 🧹 Cleaning up hybrid interaction...');
    
    // Clear all callbacks before cleanup to prevent setState after dispose
    if (_inputOverlayService != null) {
      _inputOverlayService!.onKeyboardOpen = null;
      _inputOverlayService!.onKeyboardClose = null;
      _inputOverlayService!.onTextChanged = null;
    }
    
    if (_socketService != null) {
      _socketService!.onConnected = null;
      _socketService!.onDisconnected = null;
      _socketService!.onRemoteTextUpdate = null;
    }
    
    // Now safe to disconnect and deactivate (silent mode to prevent callbacks)
    _socketService?.disconnect();
    _inputOverlayService?.deactivateInput(silent: true);
  }

  /// Cleanup workspace when screen is disposed
  Future<void> _cleanupWorkspace() async {
    try {
      debugPrint('[AIChatScreen] 🧹 Cleaning up WebRTC session on dispose...');
      
      // Don't use ref after dispose - just skip cleanup
      // The backend will auto-cleanup expired sessions
      debugPrint('[AIChatScreen] ⚠️ Skipping WebRTC cleanup (widget disposed)');
      debugPrint('[AIChatScreen] Backend will auto-cleanup expired sessions');
    } catch (e) {
      debugPrint('[AIChatScreen] ❌ Error during WebRTC session cleanup: $e');
    }
  }

  /// Initialize location tracking while using workspace
  Future<void> _initializeLocationTracking() async {
    debugPrint('[AIChatScreen] 📍 Initializing location tracking...');
    
    try {
      final locationValidation = LocationValidationService();
      
      // Set up callbacks for validation failures - IMMEDIATE LOGOUT
      locationValidation.onLocationOutOfBounds = () {
        debugPrint('[AIChatScreen] 📍 User out of authorized location - IMMEDIATE LOGOUT');
        _performImmediateLogout('Out of authorized location');
      };
      
      locationValidation.onValidationFailed = () {
        debugPrint('[AIChatScreen] ❌ Validation failed - IMMEDIATE LOGOUT');
        _performImmediateLogout('Validation failed');
      };
      
      // Start continuous validation
      await locationValidation.startContinuousValidation();
      debugPrint('[AIChatScreen] ✅ Location validation started');
      
      // Start workspace location monitoring (checks location against geofence)
      debugPrint('[AIChatScreen] 🌍 Starting workspace location monitoring...');
      final workspaceLocationMonitor = ref.read(workspaceLocationMonitorServiceProvider);
      
      // Set up warning callback (shows popup 15 seconds before logout)
      workspaceLocationMonitor.onWorkspaceLocationWarning = () {
        debugPrint('[AIChatScreen] ⚠️ WORKSPACE LOCATION WARNING TRIGGERED!');
        debugPrint('[AIChatScreen] ⚠️ User moved out of authorized area - showing warning');
        _showGeofenceWarningDialog();
      };
      
      // Set up final violation callback (performs logout)
      workspaceLocationMonitor.onWorkspaceLocationViolation = () {
        debugPrint('[AIChatScreen] 🚨 WORKSPACE LOCATION VIOLATION CALLBACK TRIGGERED!');
        debugPrint('[AIChatScreen] 🚨 User moved out of authorized area - IMMEDIATE LOGOUT');
        _performImmediateLogout('User moved out of authorized area while using workspace');
      };
      
      // Ensure monitoring is started (in case it wasn't started in main.dart)
      workspaceLocationMonitor.startMonitoring();
      debugPrint('[AIChatScreen] ✅ Workspace location monitoring started successfully');
      debugPrint('[AIChatScreen] 📊 Monitoring will check location every 10 seconds');
      debugPrint('[AIChatScreen] 🎯 Warning callback is set: ${workspaceLocationMonitor.onWorkspaceLocationWarning != null}');
      debugPrint('[AIChatScreen] 🎯 Violation callback is set: ${workspaceLocationMonitor.onWorkspaceLocationViolation != null}');
    } catch (e, stackTrace) {
      debugPrint('[AIChatScreen] ❌ Error initializing location tracking: $e');
      debugPrint('[AIChatScreen] Stack trace: $stackTrace');
    }
  }

  /// Start monitoring session status
  void _startSessionMonitoring() {
    debugPrint('[AIChatScreen] 🔍 Starting session monitoring...');
    
    // Check session status every 10 seconds
    _sessionMonitorTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _checkSessionStatus();
    });
  }

  /// Check if workspace session is still valid
  Future<void> _checkSessionStatus() async {
    try {
      final webrtcSessionService = ref.read(webRTCSessionServiceProvider);
      
      // Check if WebRTC session is still valid
      final isValid = await webrtcSessionService.isWebRTCSessionValid();
      
      if (!isValid && !_sessionTerminatedDialogShown) {
        debugPrint('[AIChatScreen] 🚨 WebRTC session terminated or expired!');
        _sessionTerminatedDialogShown = true;
        _sessionMonitorTimer?.cancel();
        
        if (mounted) {
          _showSessionTerminatedDialog();
        }
      }
    } catch (e) {
      debugPrint('[AIChatScreen] ⚠️ Error checking session status: $e');
      
      // Only terminate on 404 (session not found)
      // 500 errors are temporary backend issues - don't terminate session
      if (!_sessionTerminatedDialogShown && e.toString().contains('404')) {
        debugPrint('[AIChatScreen] 🚨 Session not found (404) - session was destroyed!');
        _sessionTerminatedDialogShown = true;
        _sessionMonitorTimer?.cancel();
        
        if (mounted) {
          _showSessionTerminatedDialog();
        }
      } else if (e.toString().contains('500')) {
        debugPrint('[AIChatScreen] ⚠️ Backend error (500) - temporary issue, not terminating session');
        debugPrint('[AIChatScreen] Session validation will retry in 10 seconds');
      } else {
        debugPrint('[AIChatScreen] ⚠️ Unknown error - not terminating session');
      }
    }
  }

  /// Show session terminated dialog
  void _showSessionTerminatedDialog() {
    if (!mounted) return;

    // Show brief snackbar instead of dialog
    ClientErrorHandler.showErrorSnackbar(
      context,
      'Session ended',
      duration: const Duration(seconds: 3),
    );
    
    // Navigate to login after brief delay
    Future.delayed(const Duration(milliseconds: 500), () async {
      await _destroyWorkspaceAndLogout();
    });
  }

  /// Destroy workspace and logout
  Future<void> _destroyWorkspaceAndLogout() async {
    try {
      debugPrint('[AIChatScreen] ========================================');
      debugPrint('[AIChatScreen] 🔐 LOGOUT INITIATED');
      debugPrint('[AIChatScreen] ========================================');
      debugPrint('[AIChatScreen] Reason: Session terminated or expired');
      debugPrint('[AIChatScreen] ');
      debugPrint('[AIChatScreen] 🗑️ Step 1: Destroying ALL WebRTC sessions...');
      
      // Check if widget is still mounted before using ref
      if (!mounted) {
        debugPrint('[AIChatScreen] ⚠️ Widget disposed, skipping WebRTC cleanup');
        debugPrint('[AIChatScreen] ========================================');
        return;
      }
      
      final webrtcSessionService = ref.read(webRTCSessionServiceProvider);
      
      // Attempt to destroy ALL WebRTC sessions (current + expired)
      try {
        await webrtcSessionService.destroyAllWebRTCSessions();
        debugPrint('[AIChatScreen] ✅ All WebRTC sessions destroyed successfully');
      } catch (e) {
        debugPrint('[AIChatScreen] ========================================');
        debugPrint('[AIChatScreen] ⚠️ ERROR DESTROYING WEBRTC SESSIONS');
        debugPrint('[AIChatScreen] ========================================');
        debugPrint('[AIChatScreen] Error: $e');
        debugPrint('[AIChatScreen] ⚠️ Continuing with logout anyway...');
        debugPrint('[AIChatScreen] ========================================');
        // Continue with logout even if destroy fails
      }
      
      debugPrint('[AIChatScreen] ');
      debugPrint('[AIChatScreen] ⏳ Step 2: Waiting for cleanup to complete...');
      // Small delay to allow session destruction to complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('[AIChatScreen] ');
      debugPrint('[AIChatScreen] 🔄 Step 3: Navigating to login screen...');
      // Navigate to login
      if (mounted) {
        context.go(AppRoutes.login);
        debugPrint('[AIChatScreen] ========================================');
        debugPrint('[AIChatScreen] ✅ LOGOUT COMPLETE');
        debugPrint('[AIChatScreen] ========================================');
      } else {
        debugPrint('[AIChatScreen] ⚠️ Widget disposed during logout');
        debugPrint('[AIChatScreen] ========================================');
      }
    } catch (e) {
      debugPrint('[AIChatScreen] ========================================');
      debugPrint('[AIChatScreen] ❌ CRITICAL ERROR DURING LOGOUT');
      debugPrint('[AIChatScreen] ========================================');
      debugPrint('[AIChatScreen] Error: $e');
      debugPrint('[AIChatScreen] ');
      debugPrint('[AIChatScreen] 🔄 Forcing navigation to login anyway...');
      
      // Navigate to login anyway
      if (mounted) {
        context.go(AppRoutes.login);
        debugPrint('[AIChatScreen] ✅ Forced logout complete');
      }
      debugPrint('[AIChatScreen] ========================================');
    }
  }

  /// Show warning dialog when user moves out of geofence
  void _showGeofenceWarningDialog() {
    if (!mounted) return;

    // Show brief warning snackbar
    ClientErrorHandler.showWarningSnackbar(
      context,
      'Return to authorized area',
      duration: const Duration(seconds: 15),
    );
  }

  /// Perform immediate logout without any alert or dialog
  void _performImmediateLogout(String reason) async {
    debugPrint('[AIChatScreen] ========================================');
    debugPrint('[AIChatScreen] 🚨 IMMEDIATE LOGOUT TRIGGERED');
    debugPrint('[AIChatScreen] ========================================');
    debugPrint('[AIChatScreen] Reason: $reason');
    debugPrint('[AIChatScreen] ');
    debugPrint('[AIChatScreen] 🔄 Step 1: Closing any open dialogs...');

    // Close any open dialogs first
    if (mounted) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      debugPrint('[AIChatScreen] ✅ Dialogs closed');
    }

    debugPrint('[AIChatScreen] ');
    debugPrint('[AIChatScreen] 🗑️ Step 2: Destroying ALL WebRTC sessions...');
    // Destroy ALL WebRTC sessions before logout
    try {
      final webrtcSessionService = ref.read(webRTCSessionServiceProvider);
      await webrtcSessionService.destroyAllWebRTCSessions();
      debugPrint('[AIChatScreen] ✅ All WebRTC sessions destroyed successfully');
    } catch (e) {
      debugPrint('[AIChatScreen] ========================================');
      debugPrint('[AIChatScreen] ⚠️ ERROR DESTROYING WEBRTC SESSIONS');
      debugPrint('[AIChatScreen] ========================================');
      debugPrint('[AIChatScreen] Error: $e');
      debugPrint('[AIChatScreen] ⚠️ Continuing with logout anyway...');
      debugPrint('[AIChatScreen] ========================================');
      // Continue with logout even if destroy fails
    }

    debugPrint('[AIChatScreen] ');
    debugPrint('[AIChatScreen] ⏳ Step 3: Waiting for cleanup to complete...');
    // Small delay to allow session destruction to complete
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('[AIChatScreen] ');
    debugPrint('[AIChatScreen] 🔄 Step 4: Navigating to login screen...');
    // Navigate to login screen IMMEDIATELY
    if (mounted) {
      context.go(AppRoutes.login);
      debugPrint('[AIChatScreen] ========================================');
      debugPrint('[AIChatScreen] ✅ IMMEDIATE LOGOUT COMPLETE');
      debugPrint('[AIChatScreen] ========================================');
      debugPrint('[AIChatScreen] User will need to login again');
      debugPrint('[AIChatScreen] ========================================');
    } else {
      debugPrint('[AIChatScreen] ⚠️ Widget disposed during logout');
      debugPrint('[AIChatScreen] ========================================');
    }
  }

  /// Initialize WebRTC session with automatic retry logic
  Future<void> _initializeWebRTCSession({int retryCount = 0}) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 3);
    
    try {
      debugPrint('[AIChatScreen] 🎥 Initializing WebRTC session... (Attempt ${retryCount + 1}/$maxRetries)');
      
      
      // Get device orientation
      final orientation = MediaQuery.of(context).orientation;
      final mediaQuery = MediaQuery.of(context);
      final screenWidth = mediaQuery.size.width;
      final screenHeight = mediaQuery.size.height;
      final dpr = mediaQuery.devicePixelRatio;
      
      // Get safe area insets (status bar, notch, home indicator)
      final topInset = mediaQuery.padding.top;
      final bottomInset = mediaQuery.padding.bottom;
      
      // Calculate usable height (excluding status bar and home indicator)
      final usableHeight = screenHeight - topInset - bottomInset;
      
      debugPrint('[AIChatScreen] ========== DEVICE INFO ==========');
      debugPrint('[AIChatScreen] Screen size: ${screenWidth.toInt()}x${screenHeight.toInt()} (logical)');
      debugPrint('[AIChatScreen] Safe area insets:');
      debugPrint('[AIChatScreen]   Top (status bar/notch): ${topInset.toInt()}');
      debugPrint('[AIChatScreen]   Bottom (home indicator): ${bottomInset.toInt()}');
      debugPrint('[AIChatScreen] Usable height: ${usableHeight.toInt()} (excludes safe areas)');
      debugPrint('[AIChatScreen] Device pixel ratio: $dpr');
      debugPrint('[AIChatScreen] Orientation: $orientation');
      
      // Calculate physical resolution
      final physicalWidth = (screenWidth * dpr).toInt();
      final physicalHeight = (screenHeight * dpr).toInt();
      
      debugPrint('[AIChatScreen] Physical resolution: ${physicalWidth}x$physicalHeight');
      debugPrint('[AIChatScreen] ========================================');
      
      final webrtcSessionService = ref.read(webRTCSessionServiceProvider);
      
      // Reset service state to allow new session creation
      webrtcSessionService.resetServiceState();
      
      // Check if user is authorized (has valid session token)
      final storage = ref.read(secureStorageServiceProvider);
      final backendSessionToken = await storage.read('backend_session_token');
      final isAuthorized = backendSessionToken != null && backendSessionToken.isNotEmpty;
      
      // Get user's email for auto-login (backend will handle authentication)
      String? userEmail;
      String? userPassword;
      try {
        userEmail = await storage.read('user_email');
        if (userEmail == null || userEmail.isEmpty) {
          // Try alternative storage keys
          userEmail = await storage.read('biometric_user_email');
        }
        
        // Get user's password (if stored for auto-login)
        userPassword = await storage.read('user_password');
        if (userPassword == null || userPassword.isEmpty) {
          userPassword = await storage.read('biometric_user_password');
        }
        
        // No fallback - let backend handle missing credentials
        if (userEmail == null || userEmail.isEmpty) {
          debugPrint('[AIChatScreen] ℹ️ No user email found - backend will handle authentication');
          userEmail = null;
        }
        if (userPassword == null || userPassword.isEmpty) {
          debugPrint('[AIChatScreen] ℹ️ No user password found - backend will handle authentication');
          userPassword = null;
        }
      } catch (e) {
        debugPrint('[AIChatScreen] ⚠️ Could not retrieve user credentials: $e');
        debugPrint('[AIChatScreen] Backend will handle authentication without credentials');
        userEmail = null;
        userPassword = null;
      }
      
      // Backend will determine the target URL based on session authorization
      debugPrint('[AIChatScreen] ✅ Authorization status: ${isAuthorized ? "AUTHORIZED" : "NOT AUTHORIZED"}');
      if (isAuthorized) {
        debugPrint('[AIChatScreen] Session token: ${backendSessionToken.substring(0, 10)}...');
        if (userEmail != null) {
          debugPrint('[AIChatScreen] User email: $userEmail (for backend auto-login)');
        } else {
          debugPrint('[AIChatScreen] No user email - backend will handle authentication');
        }
        if (userPassword != null) {
          debugPrint('[AIChatScreen] User password: ******** (provided for backend auto-login)');
        } else {
          debugPrint('[AIChatScreen] No user password - backend will handle authentication');
        }
      }
      
      // Use smart method that checks for existing session first
      // IMPORTANT: Use LOGICAL dimensions for better performance and lower bandwidth
      debugPrint('[AIChatScreen] 🔍 Checking for existing valid session...');
      debugPrint('[AIChatScreen] ========== REQUEST TO BACKEND ==========');
      debugPrint('[AIChatScreen] 📍 Target URL: (backend will decide based on auth status)');
      debugPrint('[AIChatScreen] 📧 Login Email: ${userEmail ?? "(not provided - backend decides)"}');
      debugPrint('[AIChatScreen] 🔐 Login Password: ${userPassword != null ? "******** (provided)" : "(not provided - backend decides)"}');
      debugPrint('[AIChatScreen] 🔐 Session Token: ${isAuthorized ? "PROVIDED" : "NOT PROVIDED"}');
      debugPrint('[AIChatScreen] 📐 Resolution: Using LOGICAL resolution for optimal performance');
      debugPrint('[AIChatScreen] 📱 Device dimensions (LOGICAL):');
      debugPrint('[AIChatScreen]   Width: ${screenWidth.toInt()}');
      debugPrint('[AIChatScreen]   Height: ${usableHeight.toInt()} (usable, excludes safe areas)');
      debugPrint('[AIChatScreen]   Full height: ${screenHeight.toInt()} (includes safe areas)');
      debugPrint('[AIChatScreen]   Pixel ratio: $dpr');
      debugPrint('[AIChatScreen]   Physical equivalent: ${physicalWidth}x$physicalHeight');
      debugPrint('[AIChatScreen] ');
      debugPrint('[AIChatScreen] BACKEND WILL DECIDE:');
      if (isAuthorized) {
        debugPrint('[AIChatScreen]   ✅ User is authorized with valid session token');
        debugPrint('[AIChatScreen]   ✅ Backend should auto-login using provided credentials');
        debugPrint('[AIChatScreen]   ✅ Backend should navigate to appropriate target URL');
      } else {
        debugPrint('[AIChatScreen]   ⚠️ User is NOT authorized (no session token)');
        debugPrint('[AIChatScreen]   ⚠️ Backend should handle authentication as configured');
      }
      debugPrint('[AIChatScreen] ==========================================');
      
      final session = await webrtcSessionService.getOrCreateWebRTCSession(
        // Backend will determine target URL based on authorization
        // Pass user's email and password for auto-login
        loginEmail: userEmail,
        loginPassword: userPassword,
        // Pass LOGICAL dimensions for optimal performance and bandwidth
        // Use usable height (excludes status bar/notch and home indicator)
        // This ensures all content is visible without being hidden
        deviceWidth: screenWidth.toInt(),
        deviceHeight: usableHeight.toInt(),  // Use usable height instead of full height
        devicePixelRatio: dpr,
        timeoutMinutes: 480,
      );

      debugPrint('[AIChatScreen] ✅ WebRTC session ready');
      debugPrint('[AIChatScreen] ========== SESSION DETAILS ==========');
      debugPrint('[AIChatScreen] Container ID: ${session.containerId}');
      debugPrint('[AIChatScreen] Container Name: ${session.containerName}');
      debugPrint('[AIChatScreen] Session ID: ${session.sessionId}');
      debugPrint('[AIChatScreen] Status: ${session.status}');
      debugPrint('[AIChatScreen] ==========================================');
      debugPrint('[AIChatScreen] 🌐 STREAMING URL: ${session.targetUrl}');
      debugPrint('[AIChatScreen] ==========================================');
      debugPrint('[AIChatScreen] Resolution: ${session.resolution}');
      debugPrint('[AIChatScreen] Message: ${session.message}');
      debugPrint('[AIChatScreen] ==========================================');
      
      // WorkspaceSocket DISABLED - connection causes 403 errors
      // Connect workspace socket for file uploads and interactive features
      debugPrint('[AIChatScreen] ⚠️ WorkspaceSocket disabled - text sync not available');
      debugPrint('[AIChatScreen]   Session Access Token: ${session.accessToken != null ? "✅ Present" : "❌ Missing"}');
      debugPrint('[AIChatScreen]   Socket Service: ${_socketService != null ? "✅ Available (disabled)" : "❌ Null"}');
      
      // Commented out to prevent 403 errors
      // if (session.accessToken != null && _socketService != null) {
      //   try {
      //     debugPrint('[AIChatScreen] 🔌 Connecting workspace socket...');
      //     debugPrint('[AIChatScreen]   Workspace ID: ${session.sessionId}');
      //     debugPrint('[AIChatScreen]   Access Token: ${session.accessToken!.substring(0, 10)}...');
      //     
      //     await _socketService!.connect(
      //       workspaceId: session.sessionId.toString(), // Convert int to String
      //       accessToken: session.accessToken!,
      //     );
      //     debugPrint('[AIChatScreen] ✅ Workspace socket connected successfully');
      //     
      //     if (mounted) {
      //       setState(() {
      //       });
      //     }
      //   } catch (e, stackTrace) {
      //     debugPrint('[AIChatScreen] ❌ Workspace socket connection failed: $e');
      //     debugPrint('[AIChatScreen] Stack trace: $stackTrace');
      //     debugPrint('[AIChatScreen] File upload and some interactive features may not work');
      //     
      //     if (mounted) {
      //       setState(() {
      //         _socketWarning = 'File upload unavailable';
      //       });
      //     }
      //     // Don't block WebRTC session if socket connection fails
      //   }
      // } else {
      //   debugPrint('[AIChatScreen] ⚠️ Cannot connect workspace socket:');
      //   if (session.accessToken == null) {
      //     debugPrint('[AIChatScreen]   - Access token is missing from session');
      //   }
      //   if (_socketService == null) {
      //     debugPrint('[AIChatScreen]   - Socket service is not initialized');
      //   }
      //   
      //   if (mounted) {
      //     setState(() {
      //       _socketWarning = 'File upload unavailable';
      //     });
      //   }
      // }
      
      // Check if backend returned login URL when user is authorized
      if (isAuthorized && session.targetUrl.contains('/login')) {
        debugPrint('[AIChatScreen] ⚠️⚠️⚠️ BACKEND URL CONFIGURATION WARNING ⚠️⚠️⚠️');
        debugPrint('[AIChatScreen] User is AUTHORIZED but backend returned LOGIN URL!');
        debugPrint('[AIChatScreen] ');
        debugPrint('[AIChatScreen] Current state:');
        debugPrint('[AIChatScreen]   - User authorized: YES');
        debugPrint('[AIChatScreen]   - Session token: ${backendSessionToken.substring(0, 10)}...');
        if (userEmail != null) {
          debugPrint('[AIChatScreen]   - User email: $userEmail');
        }
        debugPrint('[AIChatScreen]   - Backend URL: ${session.targetUrl}');
        debugPrint('[AIChatScreen] ');
        debugPrint('[AIChatScreen] BACKEND SHOULD:');
        debugPrint('[AIChatScreen]   1. Check if session token is valid');
        if (userEmail != null) {
          debugPrint('[AIChatScreen]   2. Use provided user email: $userEmail');
        }
        debugPrint('[AIChatScreen]   3. Auto-login using session token or credentials');
        debugPrint('[AIChatScreen]   4. Navigate to dashboard/workspace (NOT login page)');
        debugPrint('[AIChatScreen] ');
        debugPrint('[AIChatScreen] Expected: Backend-configured dashboard URL');
        debugPrint('[AIChatScreen] Actual URL: ${session.targetUrl} (login page)');
        debugPrint('[AIChatScreen] ');
        debugPrint('[AIChatScreen] This means user will see login page but cannot interact!');
        debugPrint('[AIChatScreen] ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️');
      }
      
      // Check if backend is using desktop resolution for mobile device
      if (session.resolution == '1920x1080' || session.resolution == '1080x1920') {
        debugPrint('[AIChatScreen] ⚠️⚠️⚠️ BACKEND RESOLUTION WARNING ⚠️⚠️⚠️');
        debugPrint('[AIChatScreen] Backend is using: ${session.resolution}');
        debugPrint('[AIChatScreen] This is DESKTOP resolution for MOBILE device!');
        debugPrint('[AIChatScreen] Device info:');
        debugPrint('[AIChatScreen]   Logical: ${screenWidth.toInt()}x${screenHeight.toInt()}');
        debugPrint('[AIChatScreen]   Physical: ${physicalWidth}x$physicalHeight');
        debugPrint('[AIChatScreen] ');
        debugPrint('[AIChatScreen] BACKEND SHOULD:');
        debugPrint('[AIChatScreen]   1. Detect device type (mobile vs desktop)');
        debugPrint('[AIChatScreen]   2. Use appropriate resolution for device');
        debugPrint('[AIChatScreen]   3. For this device, use: ${physicalWidth}x$physicalHeight');
        debugPrint('[AIChatScreen] ');
        debugPrint('[AIChatScreen] Current issues:');
        debugPrint('[AIChatScreen]   - Wrong aspect ratio (16:9 vs device ratio)');
        debugPrint('[AIChatScreen]   - Content may be cut off or stretched');
        debugPrint('[AIChatScreen]   - Poor user experience');
        debugPrint('[AIChatScreen] ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _webrtcSessionCreated = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[AIChatScreen] ❌ Error creating WebRTC session (Attempt ${retryCount + 1}/$maxRetries): $e');
      
      // Retry logic for network errors
      final isNetworkError = e.toString().contains('SocketException') ||
          e.toString().contains('timeout') ||
          e.toString().contains('Connection') ||
          e.toString().contains('NetworkException');
      
      if (isNetworkError && retryCount < maxRetries - 1) {
        debugPrint('[AIChatScreen] 🔄 Network error detected, retrying in ${retryDelay.inSeconds} seconds...');
        
        if (mounted) {
          setState(() {
            _errorMessage = 'Connection issue detected. Retrying... (${retryCount + 1}/$maxRetries)';
          });
        }
        
        // Wait before retrying
        await Future.delayed(retryDelay);
        
        // Retry
        return _initializeWebRTCSession(retryCount: retryCount + 1);
      }
      
      // All retries failed or non-network error - show error
      debugPrint('[AIChatScreen] ❌ All retry attempts failed or non-recoverable error');
      debugPrint('[AIChatScreen] Stack trace: $stackTrace');
      
      // Check error type and provide helpful message
      String errorMessage = 'Failed to create WebRTC session';
      String errorDetails = '';
      
      if (e.toString().contains('500')) {
        errorMessage = 'Backend Internal Error (500)';
        errorDetails = 'The WebRTC endpoint exists but is failing internally.\n\n'
            'Common causes:\n'
            '• Docker not running on backend\n'
            '• Docker image not built\n'
            '• Missing dependencies (aiortc, playwright)\n'
            '• Port conflicts or resource limits\n\n'
            'Ask backend developer to check logs.\n\n'
            'See WEBRTC_500_ERROR_TROUBLESHOOTING.md';
      } else if (e.toString().contains('404')) {
        errorMessage = 'WebRTC Endpoint Not Found (404)';
        errorDetails = 'The backend does not have /api/v1/webrtc/session endpoint.\n\n'
            'Backend needs to implement WebRTC endpoints.';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        errorMessage = 'Authentication Error';
        errorDetails = 'Not authorized to create WebRTC session.\n\n'
            'Check device authentication.';
      } else if (isNetworkError) {
        errorMessage = 'Connection Failed';
        errorDetails = 'Could not connect to workspace after $maxRetries attempts.\n\n'
            'Please check your internet connection and try again.';
      } else {
        errorMessage = 'WebRTC Session Error';
        errorDetails = e.toString();
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = '$errorMessage\n\n$errorDetails';
          _isLoading = false;
        });
        
        // Show brief error snackbar (only after all retries failed)
        ClientErrorHandler.showErrorSnackbar(
          context,
          errorMessage,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show warning dialog before allowing back navigation
        return await _showLogoutWarning();
      },
      child: _buildContent(),
    );
  }

  /// Show logout warning dialog
  Future<bool> _showLogoutWarning() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkMatterViolet,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(
            color: AppTheme.warningOrange.withOpacity(0.5),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppTheme.warningOrange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Exit Workspace?',
                style: TextStyle(color: AppTheme.warningOrange),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Going back will end your workspace session.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppTheme.electricCyan),
                      ),
                    ),
                    child: Text(
                      'Stay',
                      style: TextStyle(color: AppTheme.electricCyan),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningOrange,
                      foregroundColor: AppTheme.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Exit Logout'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: const [],
      ),
    );
    
    return result ?? false; // Don't allow back if dialog is dismissed
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Scaffold(
        resizeToAvoidBottomInset: true,  // Allow layout to resize
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.electricCyan,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage != null && _errorMessage!.contains('Retrying')
                    ? _errorMessage!
                    : 'Initializing VMI session...',
                style: TextStyle(
                  color: AppTheme.ghostWhite,
                  fontFamily: 'SpaceGrotesk',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few moments',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.ghostWhite.withOpacity(0.6),
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        resizeToAvoidBottomInset: true,  // Allow layout to resize
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.warningRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to Load WebRTC Session',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.ghostWhite,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.ghostWhite.withOpacity(0.7),
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _initializeWebRTCSession();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: AppTheme.deepBlack,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    context.go(AppRoutes.login);
                  },
                  child: Text(
                    'Go Back',
                    style: TextStyle(
                      color: AppTheme.ghostWhite.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_webrtcSessionCreated) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.electricCyan,
          ),
        ),
      );
    }

    final sessionService = ref.watch(webRTCSessionServiceProvider);
    final controlService = ref.watch(webRTCControlServiceProvider);
    
    return Scaffold(
      resizeToAvoidBottomInset: false,  // CRITICAL: Prevent screen resize when keyboard opens
      body: Builder(
        builder: (builderContext) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // WebRTC content with keyboard insets removed (stays fixed)
              MediaQuery(
                // Remove keyboard insets from layout calculations for WebRTC
                data: MediaQuery.of(builderContext).copyWith(
                  viewInsets: EdgeInsets.zero,
                ),
                child: Stack(
                  fit: StackFit.expand,  // Ensure Stack fills entire screen
                  children: [
            // WebRTC Stream (ALWAYS full screen, behind everything)
            // This ensures video never gets minimized or toggled when user types
            // The video stream remains in full screen mode at all times
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: false,  // Keep video interactions enabled (user can still interact with stream)
                child: Stack(
                  children: [
                    // WebRTC video stream with gesture controls
                    // IMPORTANT: This stays full screen even when keyboard is open
                    WebRTCStreamWidget(
                      sessionService: sessionService,
                      controlService: controlService,
                      onConnected: () {
                        debugPrint('[AIChatScreen] ✅ WebRTC connected');
                      },
                      onDisconnected: () {
                        debugPrint('[AIChatScreen] ❌ WebRTC disconnected');
                        if (mounted) {
                          ClientErrorHandler.showWarningSnackbar(
                            context,
                            'WebRTC connection lost',
                          );
                        }
                      },
                      onError: (error) {
                        debugPrint('[AIChatScreen] ⚠️ WebRTC error: $error');
                        if (mounted) {
                          ClientErrorHandler.showErrorSnackbar(
                            context,
                            'WebRTC error: $error',
                          );
                        }
                      },
                    ),
                    
                    // Tap indicator (shows briefly when input is tapped)
                    InputTapIndicator(
                      isVisible: _showTapIndicator,
                      position: _tapPosition,
                    ),
                    
                    // Show streaming active indicator when user is typing (top-left)
                    
                    
                    // Show socket connection status (top-right)
                    if (_socketWarning != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.deepBlack.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.warningOrange.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: AppTheme.warningOrange,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _socketWarning!,
                                style: TextStyle(
                                  color: AppTheme.warningOrange,
                                  fontSize: 11,
                                  fontFamily: 'SpaceGrotesk',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    
                    
                    // Show keyboard indicator when keyboard is visible (top-right)
                   
                  ],
                ),
              ),
            ),
                  ],
                ),
              ),
              
              // Modal input overlay (outside MediaQuery override, can see keyboard)
              InputModalOverlay(
                inputOverlayService: _inputOverlayService,
                fileUploadService: _fileUploadService,
                controlService: controlService,
                onClose: _hideInputModalOverlay,
                onTypingChanged: (isTyping) {
                  if (mounted) {
                    setState(() {
                    });
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
