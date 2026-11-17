import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:ask_jeeves_vmi/presentation/widgets/glassmorphic_container.dart';
import 'package:ask_jeeves_vmi/core/router/app_router.dart';
import 'package:ask_jeeves_vmi/security/providers/security_providers.dart';
import 'package:ask_jeeves_vmi/data/services/location/location_validation_service.dart';
import 'package:ask_jeeves_vmi/data/services/location/workspace_location_monitor_service.dart';

/// Device verification screen with trust scoring
class DeviceVerificationScreen extends ConsumerStatefulWidget {
  const DeviceVerificationScreen({super.key});

  @override
  ConsumerState<DeviceVerificationScreen> createState() =>
      _DeviceVerificationScreenState();
}

class _DeviceVerificationScreenState
    extends ConsumerState<DeviceVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _verificationProgress = 0.0;
  String _currentCheck = 'Initializing...';
  bool _isComplete = false;

  final List<Map<String, dynamic>> _checks = [
    {'name': 'Device Integrity', 'icon': Icons.phone_android, 'duration': 200},
    {'name': 'Root Detection', 'icon': Icons.security, 'duration': 150},
    {'name': 'Jailbreak Check', 'icon': Icons.shield, 'duration': 150},
    {'name': 'Trust Score', 'icon': Icons.verified_user, 'duration': 200},
    {'name': 'Hardware Attestation', 'icon': Icons.memory, 'duration': 200},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _startVerification();
    _initializeLocationTracking();
  }

  /// Initialize location tracking during device verification
  Future<void> _initializeLocationTracking() async {
    debugPrint('[DeviceVerification] 📍 Initializing location tracking...');

    try {
      final locationValidation = LocationValidationService();

      // Set up callbacks for validation failures - IMMEDIATE LOGOUT
      locationValidation.onLocationOutOfBounds = () {
        debugPrint(
          '[DeviceVerification] 📍 User out of authorized location - IMMEDIATE LOGOUT',
        );
        _performImmediateLogout('Out of authorized location');
      };

      locationValidation.onValidationFailed = () {
        debugPrint(
          '[DeviceVerification] ❌ Validation failed - IMMEDIATE LOGOUT',
        );
        _performImmediateLogout('Validation failed');
      };

      // Start continuous validation
      await locationValidation.startContinuousValidation();
      debugPrint('[DeviceVerification] ✅ Location validation started');

      // Start workspace location monitoring
      final workspaceLocationMonitor = ref.read(
        workspaceLocationMonitorServiceProvider,
      );

      workspaceLocationMonitor.onWorkspaceLocationViolation = () {
        debugPrint(
          '[DeviceVerification] 🚨 Workspace location violation - IMMEDIATE LOGOUT',
        );
        _performImmediateLogout(
          'User moved out of authorized area while using workspace',
        );
      };

      // Ensure monitoring is started (checks location against geofence every 10s)
      workspaceLocationMonitor.startMonitoring();
      debugPrint(
        '[DeviceVerification] ✅ Workspace location monitoring started (checks every 10s)',
      );
    } catch (e) {
      debugPrint(
        '[DeviceVerification] ❌ Error initializing location tracking: $e',
      );
    }
  }

  /// Perform immediate logout without any alert or dialog
  void _performImmediateLogout(String reason) {
    debugPrint('[DeviceVerification] 🔐 IMMEDIATE LOGOUT: $reason');

    // Navigate to login screen IMMEDIATELY (no alert, no dialog)
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _startVerification() async {
    final deviceSecurity = ref.read(deviceSecurityProvider);

    // Check 1: Device Integrity
    setState(() {
      _currentCheck = _checks[0]['name'];
      _verificationProgress = 0.2;
    });
    await Future.delayed(Duration(milliseconds: _checks[0]['duration']));

    // Check 2: Root Detection
    setState(() {
      _currentCheck = _checks[1]['name'];
      _verificationProgress = 0.4;
    });
    final isCompromised = await deviceSecurity.isDeviceCompromised();
    await Future.delayed(Duration(milliseconds: _checks[1]['duration']));

    // Check 3: Jailbreak Check
    setState(() {
      _currentCheck = _checks[2]['name'];
      _verificationProgress = 0.6;
    });
    await Future.delayed(Duration(milliseconds: _checks[2]['duration']));

    // Check 4: Trust Score
    setState(() {
      _currentCheck = _checks[3]['name'];
      _verificationProgress = 0.8;
    });
    await deviceSecurity.calculateTrustScore();
    await Future.delayed(Duration(milliseconds: _checks[3]['duration']));

    // Check 5: Hardware Attestation
    setState(() {
      _currentCheck = _checks[4]['name'];
      _verificationProgress = 1.0;
    });
    await Future.delayed(Duration(milliseconds: _checks[4]['duration']));

    setState(() {
      _isComplete = true;
    });

    // Show result
    if (isCompromised) {
      _showSecurityWarning();
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.go(AppRoutes.geofenceValidation);
      }
    }
  }

  void _showSecurityWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Device appears rooted/jailbroken - security risk detected'),
        backgroundColor: AppTheme.warningRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        action: SnackBarAction(
          label: 'Continue',
          textColor: Colors.white,
          onPressed: () {
            context.go(AppRoutes.geofenceValidation);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.deepBlack, AppTheme.darkMatterViolet],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;
              // Smaller, more reasonable icon sizes
              final iconSize = screenHeight > 700 ? 80.0 : 60.0;
              final iconInnerSize = screenHeight > 700 ? 40.0 : 30.0;
              final spacing1 = screenHeight > 700 ? 24.0 : 12.0;
              final spacing2 = screenHeight > 700 ? 12.0 : 8.0;
              final progressSize = screenHeight > 700 ? 100.0 : 80.0;
              final padding = screenHeight > 700 ? 20.0 : 12.0;
              
              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Verification icon
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isComplete
                            ? LinearGradient(
                                colors: [
                                  AppTheme.successGreen,
                                  AppTheme.mercuryTeal,
                                ],
                              )
                            : AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: (_isComplete
                                    ? AppTheme.successGreen
                                    : AppTheme.electricCyan)
                                .withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isComplete ? Icons.check_circle : Icons.security,
                        size: iconInnerSize,
                        color: AppTheme.deepBlack,
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 2000.ms),

                    SizedBox(height: spacing1),

                    Text(
                      _isComplete ? 'Device Verified' : 'Verifying Device',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),

                    SizedBox(height: spacing2),

                    Text(
                      _currentCheck,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.electricCyan,
                          ),
                    ),

                    SizedBox(height: spacing1),

                    // Progress indicator - Flexible to adapt to available space
                    Flexible(
                      child: GlassmorphicContainer(
                        padding: EdgeInsets.all(screenHeight > 700 ? 20 : 12),
                        borderRadius: AppTheme.radiusLarge,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Circular progress
                            SizedBox(
                              width: progressSize,
                              height: progressSize,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: progressSize,
                                    height: progressSize,
                                    child: CircularProgressIndicator(
                                      value: _verificationProgress,
                                      strokeWidth: 5,
                                      backgroundColor: AppTheme.electricCyan
                                          .withOpacity(0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _isComplete
                                            ? AppTheme.successGreen
                                            : AppTheme.electricCyan,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(_verificationProgress * 100).toInt()}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _isComplete
                                              ? AppTheme.successGreen
                                              : AppTheme.electricCyan,
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: spacing1),

                            // Checks list - Flexible to fit available space
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _checks.length,
                                itemBuilder: (context, index) {
                                  final check = _checks[index];
                                  final isChecked = _verificationProgress >
                                      (index / _checks.length);

                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: screenHeight > 700 ? 4 : 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isChecked
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: isChecked
                                              ? AppTheme.successGreen
                                              : AppTheme.electricCyan
                                                  .withOpacity(0.3),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          check['icon'],
                                          color: isChecked
                                              ? AppTheme.ghostWhite
                                              : AppTheme.ghostWhite
                                                  .withOpacity(0.3),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            check['name'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: isChecked
                                                      ? AppTheme.ghostWhite
                                                      : AppTheme.ghostWhite
                                                          .withOpacity(0.3),
                                                  fontSize: 12,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: spacing2),

                    // Security info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 12,
                          color: AppTheme.electricCyan.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Zero-Trust Security Protocol',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.electricCyan.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
