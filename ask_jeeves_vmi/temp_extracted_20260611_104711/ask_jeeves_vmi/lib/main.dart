import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:ask_jeeves_vmi/core/router/app_router.dart';
import 'package:ask_jeeves_vmi/features/session/services/app_lifecycle_service.dart';
import 'package:ask_jeeves_vmi/data/services/device/permission_service.dart';
import 'package:ask_jeeves_vmi/data/services/device/screenshot_protection_service.dart';
import 'package:ask_jeeves_vmi/data/services/location/location_validation_service.dart';
import 'package:ask_jeeves_vmi/features/session/services/session_security_service.dart';
import 'package:ask_jeeves_vmi/data/services/location/workspace_location_monitor_service.dart';
import 'package:ask_jeeves_vmi/security/services/security_manager.dart';
import 'package:ask_jeeves_vmi/security/providers/security_providers.dart';
import 'package:ask_jeeves_vmi/security/services/realtime_security_monitor.dart' as rtm;
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';
import 'package:ask_jeeves_vmi/data/services/api/api_client.dart';
import 'package:ask_jeeves_vmi/data/services/api/session_api_service.dart';
import 'package:ask_jeeves_vmi/shared/handlers/client_error_handler.dart';
import 'package:ask_jeeves_vmi/data/services/network/network_connectivity_service.dart';
import 'package:ask_jeeves_vmi/presentation/widgets/network_error_overlay.dart';
import 'dart:async';

/// Ask-Jeeves Vault - Enterprise-Grade VMI AI Platform
/// Zero-Trust Security | Confidential Computing | Pixel Streaming
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize screenshot protection
  debugPrint('[App] Initializing screenshot protection...');
  await ScreenshotProtectionService.initialize();

  // Set up platform channel for app termination cleanup
  _setupAppTerminationHandler();

  // Set system UI overlay style for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.deepBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock orientation to portrait for mobile (optional)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const ProviderScope(child: AskJeevesVaultApp()));
}

/// Set up platform channel to handle app termination cleanup
void _setupAppTerminationHandler() {
  const platform = MethodChannel('com.ask_jeeves.vmi/app_lifecycle');

  platform.setMethodCallHandler((call) async {
    if (call.method == 'onAppTerminating') {
      debugPrint(
        '[App] Platform channel: App is terminating - performing cleanup',
      );

      // Perform synchronous cleanup
      try {
        final storage = SecureStorageService();
        final sessionIdStr = await storage.read('backend_session_id');
        final deviceUuid = await storage.read('device_uuid');

        if (sessionIdStr != null && deviceUuid != null) {
          final sessionId = int.parse(sessionIdStr);
          debugPrint('[App] Cleanup: Terminating session $sessionId');

          // Create API client and terminate session
          final apiClient = ApiClient(storage);
          final sessionApiService = SessionApiService(apiClient);

          try {
            // Use a short timeout for cleanup
            final terminationResponse = await sessionApiService
                .terminateSession(
                  sessionId: sessionId,
                  reason: 'App force-closed',
                )
                .timeout(
                  const Duration(seconds: 5),
                  onTimeout: () {
                    debugPrint('[App] Cleanup: Session termination timed out');
                    throw TimeoutException('Session termination timeout');
                  },
                );

            debugPrint(
              '[App] Cleanup: ✅ Session terminated: ${terminationResponse.reason}',
            );
            return {'success': true, 'message': 'Session terminated'};
          } catch (e) {
            debugPrint('[App] Cleanup: ⚠️ Failed to terminate session: $e');
            return {'success': false, 'message': 'Failed to terminate session'};
          }
        }
      } catch (e) {
        debugPrint('[App] Cleanup: Error during cleanup: $e');
        return {'success': false, 'message': 'Cleanup error'};
      }
    }
    return null;
  });
}

class AskJeevesVaultApp extends ConsumerStatefulWidget {
  const AskJeevesVaultApp({super.key});

  @override
  ConsumerState<AskJeevesVaultApp> createState() => AskJeevesVaultAppState();
}

class AskJeevesVaultAppState extends ConsumerState<AskJeevesVaultApp>
    with WidgetsBindingObserver {
  AppLifecycleService? _lifecycleService;
  NetworkConnectivityService? _networkService;
  bool _permissionsRequested = false;
  bool _showNetworkError = false;
  
  // Track Settings navigation for grace period
  DateTime? _lastBackgroundTime;
  bool _likelyInSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLifecycleService();
    _initializeNetworkMonitoring();
    _initializeApp();
  }

  /// Initialize app with permission requests
  Future<void> _initializeApp() async {
    // Initialize security features in parallel (non-blocking)
    _initializeSecurityFeatures();

    // Initialize location validation in parallel (non-blocking)
    _initializeLocationValidation();
  }

  /// Request all permissions - called from biometric screen after verification
  Future<void> requestPermissionsAfterBiometric() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;

    debugPrint(
      '[App] 📱 Requesting permissions after biometric verification...',
    );

    try {
      final navigatorContext = rootNavigatorKey.currentContext;

      if (navigatorContext != null) {
        debugPrint(
          '[App] 🔓 Navigator context available, requesting permissions...',
        );
        final allGranted = await PermissionService.requestAllPermissions(
          navigatorContext,
        );

        if (allGranted) {
          debugPrint('[App] ✅ All permissions granted');
        } else {
          debugPrint('[App] ⚠️ Some permissions denied');
        }
      } else {
        debugPrint(
          '[App] ❌ Navigator context is NULL - permissions cannot be requested!',
        );
        debugPrint(
          '[App] This may happen if the app is not fully initialized.',
        );
        // Try again with a small delay
        await Future.delayed(const Duration(milliseconds: 500));
        // Get context again after delay - safe because rootNavigatorKey is always valid
        final retryContext = rootNavigatorKey.currentContext;
        if (retryContext != null && mounted) {
          debugPrint('[App] 🔄 Retrying with delayed context...');
          // ignore: use_build_context_synchronously
          final allGranted = await PermissionService.requestAllPermissions(
            // ignore: use_build_context_synchronously
            retryContext,
          );
          if (allGranted) {
            debugPrint('[App] ✅ All permissions granted (after retry)');
          } else {
            debugPrint('[App] ⚠️ Some permissions denied (after retry)');
          }
        } else {
          debugPrint(
            '[App] ❌ Navigator context still NULL after retry - skipping permissions',
          );
        }
      }
    } catch (e) {
      debugPrint('[App] ❌ Permission error: $e');
      debugPrint('[App] ❌ Stack trace: ${StackTrace.current}');
    }
  }

  void _initializeLifecycleService() {
    _lifecycleService = AppLifecycleService(
      inactivityDuration: const Duration(seconds: 60), // 60 seconds for high-security VMI
      onInactivityTimeout: _handleInactivityTimeout,
      onAppClosed: _handleAppClosed,
    );
  }

  /// Initialize network connectivity monitoring
  Future<void> _initializeNetworkMonitoring() async {
    debugPrint('[App] 🌐 Initializing network monitoring...');
    
    try {
      _networkService = NetworkConnectivityService();
      await _networkService!.initialize();
      
      // Set up callbacks for connection changes
      _networkService!.onConnectionLost = () {
        debugPrint('[App] 🔴 Network connection lost');
        if (mounted) {
          setState(() {
            _showNetworkError = true;
          });
          
          // Show user-friendly message
          final context = rootNavigatorKey.currentContext;
          if (context != null && context.mounted) {
            ClientErrorHandler.showErrorSnackbar(
              context,
              'No internet connection. Please check your network.',
              duration: const Duration(seconds: 5),
            );
          }
        }
      };
      
      _networkService!.onConnectionRestored = () {
        debugPrint('[App] 🟢 Network connection restored');
        if (mounted) {
          setState(() {
            _showNetworkError = false;
          });
          
          // Show success message
          final context = rootNavigatorKey.currentContext;
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Internet connection restored',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF00FF7F), // Neon green
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        }
      };
      
      debugPrint('[App] ✅ Network monitoring initialized');
    } catch (e) {
      debugPrint('[App] ❌ Error initializing network monitoring: $e');
    }
  }

  Future<void> _initializeSecurityFeatures() async {
    debugPrint('[App] 🔐 Initializing security features...');

    try {
      final securityManager = ref.read(securityManagerProvider);
      final result = await securityManager.initializeAllSecurityFeatures();

      setState(() {});

      if (result.allEnabled) {
        debugPrint('[App] ✅ Security features initialized');
      } else {
        debugPrint('[App] ⚠️ Some security features unavailable');
      }

      // Get security status
      final status = await securityManager.getSecurityStatus();
      debugPrint(
        '[App] 🛡️ Security Level: ${status.overallSecurityLevel.name}',
      );

      // Start real-time security monitoring
      _startRealtimeSecurityMonitoring();
    } catch (e) {
      debugPrint('[App] ❌ Security initialization error: $e');
      setState(() {});
    }
  }

  /// Start real-time security monitoring with threat detection callbacks
  void _startRealtimeSecurityMonitoring() {
    try {
      final monitor = ref.read(realtimeSecurityMonitorProvider);

      // Set up critical threat callbacks
      monitor.onJailbreakDetected = () {
        debugPrint('[Security] 🚨 JAILBREAK DETECTED - Immediate logout');
        _performImmediateLogout('Device is jailbroken - critical security violation');
      };

      monitor.onRootDetected = () {
        debugPrint('[Security] 🚨 ROOT DETECTED - Immediate logout');
        _performImmediateLogout('Device is rooted - critical security violation');
      };

      monitor.onThreatDetected = (threat) {
        debugPrint('[Security] ⚠️ Threat detected: ${threat.type.name} (${threat.severity.name})');
        
        // For critical threats, perform immediate logout
        if (threat.severity == rtm.ThreatSeverity.critical) {
          debugPrint('[Security] 🚨 CRITICAL THREAT - Immediate logout');
          _performImmediateLogout(threat.message);
        }
      };

      monitor.onStatusChanged = (status) {
        debugPrint('[Security] 🔄 Security status changed: ${status.name}');
        
        // If status becomes compromised, logout immediately
        if (status == rtm.SecurityStatus.compromised) {
          debugPrint('[Security] 🚨 DEVICE COMPROMISED - Immediate logout');
          _performImmediateLogout('Device security compromised');
        }
      };

      monitor.onTrustScoreChanged = (score) {
        debugPrint('[Security] 📊 Trust score changed: $score');
        
        // If trust score drops below critical threshold, logout
        if (score < 30) {
          debugPrint('[Security] 🚨 TRUST SCORE CRITICAL - Immediate logout');
          _performImmediateLogout('Device trust score critically low');
        }
      };

      // Start monitoring
      monitor.startMonitoring();
      debugPrint('[App] ✅ Real-time security monitoring started');
    } catch (e) {
      debugPrint('[App] ❌ Failed to start security monitoring: $e');
    }
  }

  Future<void> _initializeLocationValidation() async {
    debugPrint('[App] 📍 Initializing location validation...');

    try {
      final locationValidation = LocationValidationService();

      // Set up callbacks for validation failures - IMMEDIATE LOGOUT with brief message
      locationValidation.onInternetDisconnected = () {
        debugPrint('[App] 🌐 Internet disconnected');
        _performImmediateLogout('Internet disconnected');
      };

      locationValidation.onLocationOutOfBounds = () {
        debugPrint('[App] 📍 Out of authorized location');
        _performImmediateLogout('Out of authorized location');
      };

      locationValidation.onValidationFailed = () {
        debugPrint('[App] ❌ Validation failed');
        _performImmediateLogout('Validation failed');
      };

      // Start continuous validation
      await locationValidation.startContinuousValidation();
      debugPrint('[App] ✅ Location validation started');

      // Initialize workspace monitoring
      await _initializeWorkspaceMonitoring();
    } catch (e) {
      debugPrint('[App] ❌ Error initializing location validation: $e');
    }
  }

  /// Initialize workspace monitoring for web access detection
  Future<void> _initializeWorkspaceMonitoring() async {
    debugPrint('[App] 🖥️ Initializing workspace monitoring...');

    try {
      // Check if geofence exists before starting monitoring
      final storage = ref.read(secureStorageServiceProvider);
      final geofenceIdStr = await storage.read('login_geofence_id');

      if (geofenceIdStr == null) {
        debugPrint('[App] ⚠️ No geofence configured - will start after login');
        return;
      }

      // Monitor for location violations inside workspace using geofence API
      final workspaceLocationMonitor = ref.read(
        workspaceLocationMonitorServiceProvider,
      );

      // Set up callback for workspace location violation - IMMEDIATE LOGOUT with brief message
      workspaceLocationMonitor.onWorkspaceLocationViolation = () {
        debugPrint('[App] 🚨 Workspace location violation');
        _performImmediateLogout(
          'User moved out of authorized area while using workspace',
        );
      };

      // Start monitoring
      workspaceLocationMonitor.startMonitoring();
      debugPrint('[App] ✅ Workspace monitoring started');
    } catch (e) {
      debugPrint('[App] ❌ Error initializing workspace monitoring: $e');
    }
  }

  /// Perform immediate logout with brief user-friendly error message
  Future<void> _performImmediateLogout(String reason) async {
    debugPrint('[Security] 🔐 IMMEDIATE LOGOUT: $reason');

    // Show brief user-friendly error message
    if (mounted) {
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        String userMessage = _getUserFriendlyMessage(reason);
        ClientErrorHandler.showErrorSnackbar(
          context,
          userMessage,
          duration: const Duration(seconds: 3),
        );
      }
    }

    // Small delay to show message before navigation
    await Future.delayed(const Duration(milliseconds: 500));

    // Navigate to login screen
    if (mounted) {
      try {
        final router = ref.read(goRouterProvider);
        router.go('/login');
        debugPrint('[Security] ✅ Navigated to login screen');
      } catch (e) {
        debugPrint('[Security] Error navigating to login: $e');
      }
    }

    // Use session security service for background cleanup
    try {
      final sessionSecurityService = ref.read(sessionSecurityServiceProvider);
      await sessionSecurityService.terminateSessionImmediately(reason);
    } catch (e) {
      debugPrint('[Security] Error using session security service: $e');
      // Fallback to old cleanup method
      _performCleanupInBackground(reason);
    }
  }

  /// Convert technical reason to user-friendly message
  String _getUserFriendlyMessage(String reason) {
    final lowerReason = reason.toLowerCase();

    if (lowerReason.contains('internet') || lowerReason.contains('network')) {
      return 'Connection lost';
    } else if (lowerReason.contains('location') ||
        lowerReason.contains('area') ||
        lowerReason.contains('geofence')) {
      return 'Location access required';
    } else if (lowerReason.contains('inactivity')) {
      return 'Session expired';
    } else if (lowerReason.contains('trust') ||
        lowerReason.contains('security')) {
      return 'Security check failed';
    } else if (lowerReason.contains('validation')) {
      return 'Verification failed';
    } else {
      return 'Session ended';
    }
  }

  Future<void> _handleInactivityTimeout() async {
    debugPrint('[Security] 🔐 Inactivity timeout - logging out');

    // Navigate to login screen IMMEDIATELY (don't wait for cleanup)
    if (mounted) {
      try {
        final router = ref.read(goRouterProvider);
        router.go('/login');
      } catch (e) {
        debugPrint('[Security] Error navigating to login: $e');
      }
    }

    // Use session security service for SYNCHRONOUS cleanup
    try {
      debugPrint('[Security] 🔄 Calling terminateSessionImmediately (inactivity)...');
      final sessionSecurityService = ref.read(sessionSecurityServiceProvider);
      await sessionSecurityService.terminateSessionImmediately('Inactivity timeout');
      debugPrint('[Security] ✅ terminateSessionImmediately completed (inactivity)');
    } catch (e, stackTrace) {
      debugPrint('[Security] ❌ Error using session security service: $e');
      debugPrint('[Security] Stack trace: $stackTrace');
      // Fallback to old cleanup method
      _performCleanupInBackground('Inactivity timeout');
    }
  }

  Future<void> _handleAppClosed() async {
    debugPrint('[Security] 🔐 App closed - logging out');

    // Navigate to login screen IMMEDIATELY (don't wait for cleanup)
    if (mounted) {
      try {
        final router = ref.read(goRouterProvider);
        router.go('/login');
      } catch (e) {
        debugPrint('[Security] Error navigating to login: $e');
      }
    }

    // Use session security service for SYNCHRONOUS cleanup
    try {
      debugPrint('[Security] 🔄 Calling terminateSessionImmediately...');
      final sessionSecurityService = ref.read(sessionSecurityServiceProvider);
      await sessionSecurityService.terminateSessionImmediately('App closed');
      debugPrint('[Security] ✅ terminateSessionImmediately completed');
    } catch (e, stackTrace) {
      debugPrint('[Security] ❌ Error using session security service: $e');
      debugPrint('[Security] Stack trace: $stackTrace');
      // Fallback to old cleanup method
      _performCleanupInBackground('App closed');
    }
  }

  /// Perform cleanup in background without blocking app close
  void _performCleanupInBackground(String reason) {
    // Fire and forget - don't await this
    Future.microtask(() async {
      try {
        debugPrint('[Security] 🧹 Background cleanup started: $reason');

        final storage = SecureStorageService();
        final sessionIdStr = await storage.read('backend_session_id');
        final deviceUuid = await storage.read('device_uuid');

        if (sessionIdStr != null && deviceUuid != null) {
          final sessionId = int.parse(sessionIdStr);

          // Terminate backend session with short timeout
          try {
            final apiClient = ApiClient(storage);
            final sessionApiService = SessionApiService(apiClient);

            await sessionApiService
                .terminateSession(sessionId: sessionId, reason: reason)
                .timeout(const Duration(seconds: 3));

            debugPrint('[Security] ✅ Session terminated in background');
          } catch (e) {
            debugPrint(
              '[Security] Session termination failed (background): $e',
            );
          }
        }

        // Clear auth data
        try {
          await storage.clearAuthData();
          debugPrint('[Security] ✅ Auth data cleared');
        } catch (e) {
          debugPrint('[Security] Auth data clear failed: $e');
        }
      } catch (e) {
        debugPrint('[Security] Background cleanup error: $e');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Track when app goes to background (might be Settings)
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _lastBackgroundTime = DateTime.now();
      _likelyInSettings = true;
      debugPrint('[App] 🔄 App going to background - possibly Settings');
    }
    
    // When app resumes, check if it was a quick Settings visit
    if (state == AppLifecycleState.resumed) {
      if (_lastBackgroundTime != null && _likelyInSettings) {
        final backgroundDuration = DateTime.now().difference(_lastBackgroundTime!);
        
        // If returned within 2 minutes AND it was likely Settings
        if (backgroundDuration.inSeconds < 120) {
          debugPrint('[App] ✅ Quick return from Settings (${backgroundDuration.inSeconds}s) - maintaining session');
          _likelyInSettings = false;
          _recheckPermissionsAfterResume();
          return; // Don't trigger normal lifecycle handling
        } else {
          debugPrint('[App] ⏰ Long background time (${backgroundDuration.inSeconds}s) - checking timeout');
        }
      }
      
      _likelyInSettings = false;
    }
    
    // Normal lifecycle handling
    _lifecycleService?.startMonitoring(state);

    // When app resumes, re-check permissions in case user enabled them in Settings
    if (state == AppLifecycleState.resumed && _permissionsRequested) {
      debugPrint('[App] 🔄 App resumed - re-checking permissions...');
      _recheckPermissionsAfterResume();
    }

    // Note: Blur overlay is now handled by ScreenshotBlurOverlay widget
    // No need to manually show/hide overlays here
    debugPrint('[App] 🔄 App lifecycle state: $state');
  }

  /// Re-check permissions when app resumes (in case user enabled them in Settings)
  Future<void> _recheckPermissionsAfterResume() async {
    try {
      final locationStatus = await PermissionService.getLocationStatus();
      debugPrint('[App] Location status after resume: ${locationStatus.name}');

      // Check if location is now granted
      final isGranted = locationStatus == PermissionStatus.granted;
      final isPermanentlyDenied =
          locationStatus == PermissionStatus.permanentlyDenied;

      if (isGranted) {
        debugPrint('[App] ✅ Location permission now granted');
      } else if (isPermanentlyDenied) {
        debugPrint('[App] ⚠️ Location still permanently denied');
      }
    } catch (e) {
      debugPrint('[App] Error re-checking permissions: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleService?.dispose();
    _networkService?.dispose();
    
    // Note: Cannot use ref.read() in dispose() as providers are cleaned up automatically
    // Real-time security monitoring will be stopped by Riverpod's disposal mechanism
    debugPrint('[App] 🛑 Disposing app state');
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'VMI Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            // Main app content with double-back-to-exit wrapper
            DoubleBackToExitWrapper(child: child ?? const SizedBox()),
            
            // Network error overlay (top banner)
            NetworkErrorOverlay(isVisible: _showNetworkError),
          ],
        );
      },
    );
  }
}

/// Wrapper widget that handles double back press to exit app
/// Only intercepts back button when there's no route to pop
class DoubleBackToExitWrapper extends StatefulWidget {
  final Widget child;

  const DoubleBackToExitWrapper({super.key, required this.child});

  @override
  State<DoubleBackToExitWrapper> createState() => _DoubleBackToExitWrapperState();
}

class _DoubleBackToExitWrapperState extends State<DoubleBackToExitWrapper> {
  DateTime? _lastBackPressTime;
  static const _backPressThreshold = Duration(seconds: 2);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Try to pop the navigator first
        if (Navigator.canPop(context)) {
          debugPrint('[DoubleBack] Navigator can pop - allowing navigation');
          Navigator.pop(context);
          return;
        }

        // Can't pop - apply double-back-to-exit logic
        final now = DateTime.now();
        final isSecondPress = _lastBackPressTime != null &&
            now.difference(_lastBackPressTime!) < _backPressThreshold;

        if (isSecondPress) {
          // Second press within threshold - exit app
          debugPrint('[App] 🚪 Double back press detected - exiting app');
          SystemNavigator.pop();
        } else {
          // First press - show warning
          _lastBackPressTime = now;
          debugPrint('[App] ⚠️ First back press - showing exit warning');
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: AppTheme.warningOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Exit App?',
                            style: TextStyle(
                              color: AppTheme.ghostWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Press back again to exit',
                            style: TextStyle(
                              color: AppTheme.ghostWhite.withOpacity(0.8),
                              fontSize: 13,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.warningOrange,
                      size: 20,
                    ),
                  ],
                ),
                backgroundColor: AppTheme.deepBlack.withOpacity(0.95),
                behavior: SnackBarBehavior.floating,
                duration: _backPressThreshold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppTheme.warningOrange.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                margin: const EdgeInsets.all(16),
                elevation: 8,
              ),
            );
          }
        }
      },
      child: widget.child,
    );
  }
}
