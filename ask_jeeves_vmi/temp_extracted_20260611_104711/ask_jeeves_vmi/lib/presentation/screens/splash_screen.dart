// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:ask_jeeves_vmi/core/config/app_constants.dart';
import 'package:ask_jeeves_vmi/core/router/app_router.dart';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';

/// Cinematic splash screen with holographic logo animation
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _controller.forward();

    // Check device registration and navigate accordingly
    _checkDeviceRegistration();
  }
  
  Future<void> _checkDeviceRegistration() async {
    // Reduced wait time for faster startup
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted || _isDisposed) return;
    
    try {
      final storage = ref.read(secureStorageServiceProvider);
      
      // Check if device_uuid exists (device is registered)
      final deviceUuid = await storage.read('device_uuid');
      final deviceRegistered = await storage.read('device_registered');
      
      debugPrint('[Splash] Device UUID: ${deviceUuid != null ? "Found" : "Not found"}');
      debugPrint('[Splash] Device Registered: $deviceRegistered');
      
      if (mounted) {
        if (deviceUuid != null && deviceRegistered == 'true') {
          // Device is registered - go to login screen
          debugPrint('[Splash] Device registered - navigating to login');
          context.go(AppRoutes.login);
        } else {
          // Device not registered - go to biometric requirement (enrollment flow)
          debugPrint('[Splash] Device not registered - navigating to enrollment');
          context.go(AppRoutes.biometricRequirement);
        }
      }
    } catch (e) {
      debugPrint('[Splash] Error checking registration: $e');
      // On error, go to biometric requirement screen
      if (mounted) {
        context.go(AppRoutes.biometricRequirement);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(
              20,
              (index) => Positioned(
                left: (index * 50.0) % MediaQuery.of(context).size.width,
                top: (index * 80.0) % MediaQuery.of(context).size.height,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.electricCyan.withOpacity(0.3),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.electricCyan.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(),
                    )
                    .fadeIn(duration: 1000.ms)
                    .then()
                    .fadeOut(duration: 1000.ms),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with holographic effect
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.electricCyan.withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.security,
                      size: 60,
                      color: AppTheme.deepBlack,
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 800.ms,
                        curve: Curves.easeOutBack,
                      )
                      .then()
                      .shimmer(
                        duration: 1500.ms,
                        color: AppTheme.electricCyan,
                      ),

                  const SizedBox(height: 40),

                  // App name
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 12),

                  // Tagline
                  Text(
                    AppConstants.appTagline,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.electricCyan,
                          letterSpacing: 1,
                        ),
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 60),

                  // Loading indicator
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      backgroundColor: AppTheme.electricCyan.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.electricCyan,
                      ),
                      minHeight: 2,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1200.ms, duration: 400.ms),
                ],
              ),
            ),

            // Version info at bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Version ${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.ghostWhite.withOpacity(0.5),
                      ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 1600.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
