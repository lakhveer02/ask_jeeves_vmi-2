import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:ask_jeeves_vmi/presentation/widgets/glassmorphic_container.dart';
import 'package:ask_jeeves_vmi/security/providers/security_providers.dart' as security;
import 'package:ask_jeeves_vmi/core/router/app_router.dart';
import 'package:ask_jeeves_vmi/main.dart';

/// Screen that checks if biometric authentication is enabled on the device
/// If not enabled, shows message and closes the app
class BiometricRequirementScreen extends ConsumerStatefulWidget {
  const BiometricRequirementScreen({super.key});

  @override
  ConsumerState<BiometricRequirementScreen> createState() =>
      _BiometricRequirementScreenState();
}

class _BiometricRequirementScreenState
    extends ConsumerState<BiometricRequirementScreen> {
  bool _isChecking = true;
  bool _biometricsAvailable = false;
  bool _biometricsEnrolled = false;
  List<BiometricType> _availableBiometrics = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final biometricService = ref.read(security.biometricProvider);

      // Check if device supports biometrics
      final isAvailable = await biometricService.isBiometricAvailable();

      // Get available biometric types
      final availableBiometrics =
          await biometricService.getAvailableBiometrics();

      // Check if biometrics are enrolled (user has set up Face ID/Fingerprint)
      final isEnrolled = availableBiometrics.isNotEmpty;

      setState(() {
        _biometricsAvailable = isAvailable;
        _biometricsEnrolled = isEnrolled;
        _availableBiometrics = availableBiometrics;
        _isChecking = false;
      });

      debugPrint('[BiometricRequirement] Available: $isAvailable');
      debugPrint('[BiometricRequirement] Enrolled: $isEnrolled');
      debugPrint('[BiometricRequirement] Types: $availableBiometrics');

      // If biometrics are available and enrolled, proceed to request permissions then login
      if (isAvailable && isEnrolled) {
        // iOS requires delay to ensure context is ready
        debugPrint('[BiometricRequirement] ⏳ Waiting before requesting permissions...');
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          // Request permissions before navigating to login
          debugPrint('[BiometricRequirement] ✅ Biometrics verified, requesting permissions...');
          
          // Get the app state to request permissions
          final appState = context.findAncestorStateOfType<AskJeevesVaultAppState>();
          if (appState != null) {
            debugPrint('[BiometricRequirement] 📱 App state found, calling requestPermissionsAfterBiometric()...');
            await appState.requestPermissionsAfterBiometric();
          } else {
            debugPrint('[BiometricRequirement] ❌ App state NOT found - permissions cannot be requested!');
            debugPrint('[BiometricRequirement] ❌ Make sure AskJeevesVaultAppState is available in the widget tree.');
          }
          
          // Check mounted again after async operation
          if (mounted) {
            // Navigate to login
            context.go(AppRoutes.login);
          }
        }
      } else {
        // Show error message
        if (!isAvailable) {
          setState(() {
            _errorMessage =
                'This device does not support biometric authentication.';
          });
        } else if (!isEnrolled) {
          setState(() {
            _errorMessage =
                'Fingerprint or Face Lock authentication is required to use this app.\n\n'
                'Please enable biometric authentication in your device settings.';
          });
        }
      }
    } catch (e) {
      debugPrint('[BiometricRequirement] Error: $e');
      setState(() {
        _isChecking = false;
        _errorMessage = 'Biometric check failed';
      });
    }
  }

  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face Lock';
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

  void _closeApp() {
    // Close the app
    SystemNavigator.pop();
  }

  void _openSettings() {
    // Show snackbar with instructions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enable biometric: Settings → Security → Face/Fingerprint'),
        backgroundColor: AppTheme.warningRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        action: SnackBarAction(
          label: 'Recheck',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _isChecking = true;
            });
            _checkBiometricAvailability();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    // App logo/icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _biometricsAvailable && _biometricsEnrolled
                            ? AppTheme.primaryGradient
                            : LinearGradient(
                                colors: [
                                  AppTheme.warningRed,
                                  AppTheme.warningRed.withOpacity(0.7),
                                ],
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: (_biometricsAvailable && _biometricsEnrolled
                                    ? AppTheme.electricCyan
                                    : AppTheme.warningRed)
                                .withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: _isChecking
                          ? Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.deepBlack,
                              ),
                            )
                          : Icon(
                              _biometricsAvailable && _biometricsEnrolled
                                  ? _getBiometricIcon()
                                  : Icons.lock_outline,
                              size: 60,
                              color: AppTheme.deepBlack,
                            ),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack)
                        .then()
                        .shimmer(duration: 2000.ms),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      _isChecking
                          ? 'Checking Security...'
                          : _biometricsAvailable && _biometricsEnrolled
                              ? 'Security Verified'
                              : 'Security Required',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),

                    // Status message
                    if (_isChecking)
                      Text(
                        'Verifying biometric authentication...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.electricCyan,
                            ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .slideY(begin: 0.2, end: 0)
                    else if (_biometricsAvailable && _biometricsEnrolled)
                      Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 48,
                            color: AppTheme.successGreen,
                          )
                              .animate()
                              .scale(
                                  delay: 200.ms,
                                  duration: 400.ms,
                                  curve: Curves.easeOutBack),
                          const SizedBox(height: 16),
                          Text(
                            '${_getBiometricTypeText()} Enabled',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppTheme.successGreen,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Opening app...',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.electricCyan,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    else
                      GlassmorphicContainer(
                        padding: const EdgeInsets.all(32),
                        borderRadius: AppTheme.radiusLarge,
                        child: Column(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 64,
                              color: AppTheme.warningRed,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _errorMessage,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _openSettings,
                                    icon: const Icon(Icons.settings),
                                    label: const Text('How to Enable'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.electricCyan,
                                      side: BorderSide(
                                        color:
                                            AppTheme.electricCyan.withOpacity(0.5),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _closeApp,
                                    icon: const Icon(Icons.close),
                                    label: const Text('Close App'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.warningRed,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 32),

                    // Security info
                    if (!_isChecking)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.electricCyan.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.electricCyan.withAlpha(51),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppTheme.electricCyan,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This app requires biometric authentication for maximum security.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 600.ms),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
    );
  }
}
