// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:ask_jeeves_vmi/presentation/widgets/glassmorphic_container.dart';
import 'package:ask_jeeves_vmi/presentation/widgets/holographic_button.dart';
import 'package:ask_jeeves_vmi/core/router/app_router.dart';
import 'package:ask_jeeves_vmi/security/providers/security_providers.dart' as security;
import 'package:ask_jeeves_vmi/data/providers/auth_provider.dart';
import 'package:ask_jeeves_vmi/data/services/location/geolocation_service.dart';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';
import 'package:ask_jeeves_vmi/data/services/device/device_registration_service.dart';
import 'package:ask_jeeves_vmi/data/services/device/face_recognition_service.dart';
import 'package:ask_jeeves_vmi/data/services/location/geofence_service.dart';
import 'package:ask_jeeves_vmi/data/services/device/permission_service.dart';
import 'package:ask_jeeves_vmi/core/utils/distance_formatter.dart';
import 'package:ask_jeeves_vmi/core/utils/responsive_utils.dart';
import 'package:ask_jeeves_vmi/shared/handlers/client_error_handler.dart';

/// Biometric-only login screen with Face ID/Touch ID/Fingerprint
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  bool _isEnrolled = false;
  bool _biometricsAvailable = false;
  bool _faceEnrolled = false;
  List<BiometricType> _availableBiometrics = [];
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
    _requestPermissionsOnce();
  }

  /// Request permissions once when login screen loads
  Future<void> _requestPermissionsOnce() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;
    
    // iOS requires longer delay to ensure context is ready
    // iOS is stricter than Android about context availability
    debugPrint('[Login] ⏳ Waiting for context to be ready (iOS requirement)...');
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    debugPrint('[Login] 📱 Requesting permissions...');
    
    try {
      final allGranted = await PermissionService.requestAllPermissions(context);
      
      if (allGranted) {
        debugPrint('[Login] ✅ All permissions granted');
      } else {
        debugPrint('[Login] ⚠️ Some permissions denied');
      }
    } catch (e) {
      debugPrint('[Login] ❌ Permission error: $e');
    }
  }

  Future<void> _checkBiometricStatus() async {
    try {
      final biometricService = ref.read(security.biometricProvider);
      final storage = ref.read(secureStorageServiceProvider);
      final faceRecognitionService = ref.read(faceRecognitionServiceProvider);
      
      // Check if biometrics are available
      final isAvailable = await biometricService.isBiometricAvailable();
      final availableBiometrics = await biometricService.getAvailableBiometrics();
      
      // Check if user is already enrolled
      final enrolledUser = await storage.read('biometric_user_enrolled');
      
      // Check if face is enrolled
      final faceEnrolled = await faceRecognitionService.isFaceEnrolled();
      
      setState(() {
        _biometricsAvailable = isAvailable;
        _availableBiometrics = availableBiometrics;
        _isEnrolled = enrolledUser == 'true';
        _faceEnrolled = faceEnrolled;
      });

      debugPrint('[Biometric] Available: $isAvailable');
      debugPrint('[Biometric] Types: $availableBiometrics');
      debugPrint('[Biometric] Enrolled: $_isEnrolled');
      debugPrint('[Face] Enrolled: $faceEnrolled');
    } catch (e) {
      debugPrint('[Biometric] Error checking status: $e');
    }
  }

  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return Icons.remove_red_eye;
    } else {
      return Icons.security;
    }
  }

  /// Check if face authentication should be shown (iOS only)
  bool _shouldShowFaceAuth() {
    return Theme.of(context).platform == TargetPlatform.iOS;
  }

  Future<void> _handleBiometricLogin() async {
    if (!_biometricsAvailable) {
      _showErrorMessage('Biometric authentication not available on this device');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final biometricService = ref.read(security.biometricProvider);
      
      // Authenticate with biometrics
      final authenticated = await biometricService.authenticate(
        // localizedReason: 'Authenticate to access Ask-Jeeves Vault',
      );

      if (authenticated) {
        debugPrint('[Login] Biometric authentication successful');
        
        // Validate location before proceeding with login
        final storage = ref.read(secureStorageServiceProvider);
        final geofenceIdStr = await storage.read('login_geofence_id');
        
        if (geofenceIdStr != null) {
          try {
            debugPrint('[Login] Validating location...');
            final geofenceService = ref.read(geofenceServiceProvider);
            final locationCheck = await geofenceService.checkCurrentLocation();
            
            debugPrint('[Login] Location check result:');
            debugPrint('  Inside Geofence: ${locationCheck.insideGeofence}');
            debugPrint('  Distance: ${locationCheck.distance.toStringAsFixed(1)}m');
            debugPrint('  Message: ${locationCheck.message}');
            
            if (!locationCheck.insideGeofence) {
              // User is outside the 2 radius
              setState(() => _isLoading = false);
              
              // Show warning dialog
              if (mounted) {
                await _showLocationWarningDialog(locationCheck.distance);
              }
              return;
            }
            
            debugPrint('[Login] Location validated successfully');
          } catch (e) {
            debugPrint('[Login] Warning: Location validation failed: $e');
            // Continue with login even if location check fails
            // (to avoid blocking users if GPS is unavailable)
          }
        } else {
          debugPrint('[Login] No geofence configured, skipping location validation');
        }
        
        // Use unified authentication endpoint
        final registrationService = ref.read(deviceRegistrationServiceProvider);
        
        debugPrint('[Login] Authenticating device with backend...');
        final authResponse = await registrationService.authenticateDevice();
        
        debugPrint('[Login] Device authentication successful');
        debugPrint('  Device ID: ${authResponse.deviceId}');
        debugPrint('  Status: ${authResponse.status}');
        debugPrint('  Is New Device: ${authResponse.isNewDevice}');
        debugPrint('  Token Expires In: ${authResponse.expiresIn}s');
        
        // Create or resume session after location validation and device auth
        try {
          debugPrint('[Login] Creating/resuming session...');
          final sessionService = ref.read(security.sessionProvider);
          final sessionId = await sessionService.startSession(
            userId: authResponse.deviceId.toString(),
            email: '',
          );
          
          debugPrint('[Login] Session ready');
          debugPrint('  Session ID: $sessionId');
        } catch (e) {
          debugPrint('[Login] Error: Could not create session: $e');
          // Don't continue with login if session creation fails
          throw Exception('Session creation failed: $e');
        }
        
        // Get location if available (optional for geofence validation)
        double? latitude;
        double? longitude;
        
        try {
          final geolocationService = ref.read(geolocationServiceProvider);
          final position = await geolocationService.getCurrentPosition();
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (e) {
          debugPrint('[Login] Location unavailable: $e');
        }

        // Perform biometric login with auth provider
        await _performBiometricLogin(latitude, longitude);
        
        if (mounted) {
          setState(() => _isLoading = false);
          
          // Show success message
          final actionText = authResponse.isNewDevice ? 'registered and logged in' : 'logged in';
          _showSuccessMessage(
            'Device $actionText successfully!'
          );
          
          // Navigate to device verification (next step in zero-trust flow)
          context.go(AppRoutes.deviceVerification);
        }
      } else {
        setState(() => _isLoading = false);
        _showErrorMessage('Biometric authentication failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('[Login] Error: $e');
      
      // Use error translator for user-friendly message
      if (mounted) {
        ClientErrorHandler.showAutoErrorSnackbar(
          context,
          error: e,
        );
      }
    }
  }

  Future<void> _performBiometricLogin(double? latitude, double? longitude) async {
    final storage = ref.read(secureStorageServiceProvider);
    
    // Get stored user email (only if previously saved from manual login)
    String? email = await storage.read('biometric_user_email');
    
    if (email == null || email.isEmpty) {
      email = await storage.read('user_email');
    }
    
    // If no email stored, backend will handle authentication via device ID
    if (email == null || email.isEmpty) {
      debugPrint('[Login] No stored email - backend will authenticate via device ID');
      email = 'device_auth'; // Placeholder indicating device-based auth
    }
    
    // Use the auth provider with biometric authentication
    await ref.read(authProvider.notifier).login(
      email: email,
      password: 'biometric_auth', // Placeholder - not used in biometric flow
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> _handleBiometricEnrollment() async {
    if (!_biometricsAvailable) {
      _showErrorMessage('Biometric authentication not available on this device');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final biometricService = ref.read(security.biometricProvider);
      
      // Authenticate to enroll
      final authenticated = await biometricService.authenticate(
        // localizedReason: 'Authenticate to access Ask-Jeeves Vault',
      );

      if (authenticated) {
        debugPrint('[Enrollment] Biometric authentication successful');
        
        // Use unified authentication endpoint
        // Backend automatically handles both new and existing devices
        final registrationService = ref.read(deviceRegistrationServiceProvider);
        
        debugPrint('[Enrollment] Authenticating device with backend...');
        final authResponse = await registrationService.authenticateDevice();
        
        debugPrint('[Enrollment] Device authentication successful');
        debugPrint('  Device ID: ${authResponse.deviceId}');
        debugPrint('  Status: ${authResponse.status}');
        debugPrint('  Is New Device: ${authResponse.isNewDevice}');
        
        // Check if device was accepted
        if (authResponse.isActive) {
          final storage = ref.read(secureStorageServiceProvider);
          
          // Mark user as enrolled (email will be saved when user does manual login)
          await storage.write('biometric_user_enrolled', 'true');
          await storage.write('user_id', authResponse.deviceId.toString());
          
          debugPrint('[Enrollment] Device enrolled successfully');
          debugPrint('[Enrollment] Note: Email will be saved after first manual login');
          
          // Create geofence at current location (15 meter radius)
          try {
            debugPrint('[Enrollment] Creating 2 geofence at current location...');
            final geofenceService = ref.read(geofenceServiceProvider);
            final geofence = await geofenceService.createGeofenceAtCurrentLocation(
              name: 'Login Location',
              radius: 15.0, // 15 meters
            );
            
            // Save geofence ID for future validation
            await storage.write('login_geofence_id', geofence.id.toString());
            
            debugPrint('[Enrollment] Geofence created successfully');
            debugPrint('  Geofence ID: ${geofence.id}');
            debugPrint('  Location: ${geofence.latitude}, ${geofence.longitude}');
            debugPrint('  Radius: ${geofence.radius}m');
          } catch (e) {
            debugPrint('[Enrollment] Warning: Could not create geofence: $e');
            // Don't fail enrollment if geofence creation fails
          }
          
          // Create session after enrollment
          try {
            debugPrint('[Enrollment] Creating session...');
            final sessionService = ref.read(security.sessionProvider);
            final sessionId = await sessionService.startSession(
              userId: authResponse.deviceId.toString(),
              email: '',
            );
            
            debugPrint('[Enrollment] Session created successfully');
            debugPrint('  Session ID: $sessionId');
          } catch (e) {
            debugPrint('[Enrollment] Error: Could not create session: $e');
            // Don't fail enrollment if session creation fails, but log it
            debugPrint('[Enrollment] Warning: Session creation failed, continuing with enrollment');
          }
          
          setState(() {
            _isEnrolled = true;
            _isLoading = false;
          });
          
          // Show success message
          final actionText = authResponse.isNewDevice ? 'registered' : 'authenticated';
          _showSuccessMessage(
            'Device $actionText successfully!'
          );
          
          // Navigate directly to device verification after enrollment
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              debugPrint('[Enrollment] Navigating to device verification');
              context.go(AppRoutes.deviceVerification);
            }
          });
          
          // Show security recommendations if any (optional)
          if (authResponse.securityRecommendations.isNotEmpty) {
            Future.delayed(const Duration(seconds: 1), () {
              _showSecurityRecommendations(authResponse.securityRecommendations);
            });
          }
        } else {
          // Device was rejected
          setState(() => _isLoading = false);
          _showErrorMessage(
            'Device authentication rejected\n'
            'Reason: ${authResponse.message}'
          );
        }
      } else {
        setState(() => _isLoading = false);
        _showErrorMessage('Biometric authentication failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('[Enrollment] Error: $e');
      
      // Use error translator for user-friendly message
      if (mounted) {
        ClientErrorHandler.showAutoErrorSnackbar(
          context,
          error: e,
          onRetry: () => _handleBiometricEnrollment(),
        );
      }
    }
  }

  Future<void> _handleFaceEnrollment() async {
    if (!_biometricsAvailable) {
      _showErrorMessage('Biometric authentication not available on this device');
      return;
    }

    // Show info about Face authentication on Android
    if (Theme.of(context).platform == TargetPlatform.android) {
      _showFaceAuthInfo(isEnrollment: true);
    } else {
      // iOS - directly use biometric
      await _handleBiometricEnrollment();
    }
  }

  void _showFaceAuthInfo({required bool isEnrollment}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Android will show biometric options. Choose Face Unlock when prompted.'),
        backgroundColor: AppTheme.warningRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        action: SnackBarAction(
          label: 'Continue',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            if (isEnrollment) {
              _handleBiometricEnrollment();
            } else {
              _handleBiometricLogin();
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleFaceLogin() async {
    if (!_biometricsAvailable) {
      _showErrorMessage('Biometric authentication not available on this device');
      return;
    }

    // Show info about Face authentication on Android
    if (Theme.of(context).platform == TargetPlatform.android) {
      _showFaceAuthInfo(isEnrollment: false);
    } else {
      // iOS - directly use biometric
      await _handleBiometricLogin();
    }
  }

  Future<void> _showLocationWarningDialog(double distance) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location blocked: ${DistanceFormatter.format(distance)} from authorized area (max 15m)'),
        backgroundColor: AppTheme.warningRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.warningRed,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    }
  }

  void _showSecurityRecommendations(List<String> recommendations) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Security: ${recommendations.take(2).join(', ')}'),
        backgroundColor: AppTheme.warningRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveUtils.getResponsiveImageSize(context, 120);
    final innerIconSize = ResponsiveUtils.getResponsiveIconSize(context, 60);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.deepBlack,
              AppTheme.darkMatterViolet,
              AppTheme.quantumBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.getMaxContentWidth(context),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Biometric icon
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.electricCyan.withOpacity(0.5),
                            blurRadius: ResponsiveUtils.isMobile(context) ? 40 : 50,
                            spreadRadius: ResponsiveUtils.isMobile(context) ? 10 : 15,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getBiometricIcon(),
                        size: innerIconSize,
                        color: AppTheme.deepBlack,
                      ),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack)
                        .then()
                        .shimmer(duration: 2000.ms),

                    ResponsiveUtils.getResponsiveVerticalSpacing(
                      context,
                      small: 24,
                      medium: 32,
                      large: 40,
                    ),

                    Text(
                      'VMI',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 32),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),

                    ResponsiveUtils.getResponsiveVerticalSpacing(
                      context,
                      small: 8,
                      medium: 12,
                      large: 16,
                    ),

                    Text(
                      _biometricsAvailable
                          ? 'Secure ${_getBiometricTypeText()} Authentication'
                          : 'Biometric Authentication Unavailable',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _biometricsAvailable
                                ? AppTheme.electricCyan
                                : AppTheme.warningRed,
                          ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 48),

                    // Main content
                    GlassmorphicContainer(
                      padding: const EdgeInsets.all(32),
                      borderRadius: AppTheme.radiusLarge,
                      child: Column(
                        children: [
                          if (!_biometricsAvailable) ...[
                            // Biometrics not available
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 64,
                              color: AppTheme.warningRed,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Biometric Authentication Not Available',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'This device does not support biometric authentication or it is not set up. Please enable Face ID, Touch ID, or Fingerprint in your device settings.',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ] else if (!_isEnrolled) ...[
                            // First time - enrollment
                            Icon(
                              _getBiometricIcon(),
                              size: 64,
                              color: AppTheme.electricCyan,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Welcome to VMI',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            // const SizedBox(height: 16),
                            // Text(
                            //   'Choose your authentication method',
                            //   style: Theme.of(context).textTheme.bodySmall,
                            //   textAlign: TextAlign.center,
                            // ),
                            const SizedBox(height: 32),
                            
                            // Biometric enrollment button
                            HolographicButton(
                              text: 'Enroll ${_getBiometricTypeText()}',
                              onPressed: _handleBiometricEnrollment,
                              isLoading: _isLoading,
                              icon: _getBiometricIcon(),
                            ),
                            
                            // Face recognition enrollment button (iOS only)
                            if (_shouldShowFaceAuth()) ...[
                              const SizedBox(height: 16),
                              HolographicButton(
                                text: 'Enroll Face Recognition',
                                onPressed: _handleFaceEnrollment,
                                isLoading: _isLoading,
                                icon: Icons.face_retouching_natural,
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.quantumBlue,
                                    AppTheme.darkMatterViolet,
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              Text(
                                'OR',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.electricCyan.withOpacity(0.5),
                                    ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Enroll both button
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : () async {
                                  await _handleBiometricEnrollment();
                                  if (_isEnrolled && mounted) {
                                    await _handleFaceEnrollment();
                                  }
                                },
                                icon: const Icon(Icons.security),
                                label: const Text('Enroll Both Methods'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.electricCyan,
                                  side: BorderSide(color: AppTheme.electricCyan.withOpacity(0.5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                ),
                              ),
                            ],
                          ] else ...[
                            // Already enrolled - login
                            Icon(
                              _getBiometricIcon(),
                              size: 64,
                              color: AppTheme.successGreen,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Welcome',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            // const SizedBox(height: 16),
                            // Text(
                            //   'Choose your authentication method',
                            //   style: Theme.of(context).textTheme.bodySmall,
                            //   textAlign: TextAlign.center,
                            // ),
                            const SizedBox(height: 32),
                            
                            // Biometric login button
                            HolographicButton(
                              text: 'Login with ${_getBiometricTypeText()}',
                              onPressed: _handleBiometricLogin,
                              isLoading: _isLoading,
                              icon: _getBiometricIcon(),
                            ),
                            
                            // Face recognition login button (iOS only, if enrolled)
                            if (_shouldShowFaceAuth() && _faceEnrolled) ...[
                              const SizedBox(height: 16),
                              HolographicButton(
                                text: 'Login with Face Recognition',
                                onPressed: _handleFaceLogin,
                                isLoading: _isLoading,
                                icon: Icons.face_retouching_natural,
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.quantumBlue,
                                    AppTheme.darkMatterViolet,
                                  ],
                                ),
                              ),
                            ] else if (_shouldShowFaceAuth() && !_faceEnrolled) ...[
                              const SizedBox(height: 16),
                              // OutlinedButton.icon(
                              //   onPressed: _isLoading ? null : _handleFaceEnrollment,
                              //   icon: const Icon(Icons.face_retouching_natural),
                              //   label: const Text('Enroll Face Recognition'),
                              //   style: OutlinedButton.styleFrom(
                              //     foregroundColor: AppTheme.quantumBlue,
                              //     side: BorderSide(color: AppTheme.quantumBlue.withOpacity(0.5)),
                              //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              //   ),
                              // ),
                            ],
                          ],

                          const SizedBox(height: 24),

                          // Available biometrics info
                          // if (_availableBiometrics.isNotEmpty)
                            // Container(
                            //   padding: const EdgeInsets.all(16),
                            //   decoration: BoxDecoration(
                            //     color: AppTheme.electricCyan.withAlpha(26),
                            //     borderRadius: BorderRadius.circular(12),
                            //     border: Border.all(
                            //       color: AppTheme.electricCyan.withAlpha(51),
                            //     ),
                            //   ),
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: [
                            //       Row(
                            //         children: [
                            //           Icon(
                            //             Icons.info_outline,
                            //             size: 16,
                            //             color: AppTheme.electricCyan,
                            //           ),
                            //           const SizedBox(width: 8),
                            //           Text(
                            //             'Available Biometrics',
                            //             style: Theme.of(context)
                            //                 .textTheme
                            //                 .labelMedium
                            //                 ?.copyWith(
                            //                   color: AppTheme.electricCyan,
                            //                   fontWeight: FontWeight.w600,
                            //                 ),
                            //           ),
                            //         ],
                            //       ),
                            //       const SizedBox(height: 8),
                            //       ..._availableBiometrics.map((type) {
                            //         String typeName = type.toString().split('.').last;
                            //         return Padding(
                            //           padding: const EdgeInsets.only(top: 4),
                            //           child: Row(
                            //             children: [
                            //               Icon(
                            //                 Icons.check_circle,
                            //                 size: 14,
                            //                 color: AppTheme.successGreen,
                            //               ),
                            //               const SizedBox(width: 8),
                            //               Text(
                            //                 typeName.toUpperCase(),
                            //                 style: Theme.of(context)
                            //                     .textTheme
                            //                     .bodySmall,
                            //               ),
                            //             ],
                            //           ),
                            //         );
                            //       }),
                            //     ],
                            //   ),
                            // ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 24),

                    // Security badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 16,
                          color: AppTheme.successGreen,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Zero-Trust Multi-Factor Security',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.successGreen,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 800.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
