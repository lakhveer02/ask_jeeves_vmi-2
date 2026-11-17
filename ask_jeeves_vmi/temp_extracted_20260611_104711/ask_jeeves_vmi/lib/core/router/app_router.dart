import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ask_jeeves_vmi/presentation/screens/splash_screen.dart';
import 'package:ask_jeeves_vmi/presentation/screens/biometric_requirement_screen.dart';
import 'package:ask_jeeves_vmi/presentation/screens/onboarding_screen.dart';
import 'package:ask_jeeves_vmi/presentation/screens/login_screen.dart';
import 'package:ask_jeeves_vmi/presentation/screens/device_verification_screen.dart';
import 'package:ask_jeeves_vmi/presentation/screens/geofence_validation_screen.dart';
import 'package:ask_jeeves_vmi/presentation/screens/vault_initialization_screen.dart';
import 'package:ask_jeeves_vmi/features/workspace/screens/ai_chat_screen.dart';
import 'package:ask_jeeves_vmi/features/session/screens/session_termination_screen.dart';

/// Global navigator key for accessing context outside of widget tree
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Route names for navigation
class AppRoutes {
  static const String splash = '/';
  static const String biometricRequirement = '/biometric-requirement';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String deviceVerification = '/device-verification';
  static const String geofenceValidation = '/geofence-validation';
  static const String vaultInitialization = '/vault-initialization';
  static const String aiChat = '/ai-chat';
  static const String sessionTermination = '/session-termination';
}

/// GoRouter configuration provider
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      
      // Biometric Requirement Check
      GoRoute(
        path: AppRoutes.biometricRequirement,
        name: 'biometricRequirement',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BiometricRequirementScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      
      // Authentication Flow
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      
      GoRoute(
        path: AppRoutes.deviceVerification,
        name: 'deviceVerification',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DeviceVerificationScreen(),
          transitionsBuilder: _scaleTransition,
        ),
      ),
      
      GoRoute(
        path: AppRoutes.geofenceValidation,
        name: 'geofenceValidation',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const GeofenceValidationScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      
      // Vault Initialization
      GoRoute(
        path: AppRoutes.vaultInitialization,
        name: 'vaultInitialization',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const VaultInitializationScreen(),
          transitionsBuilder: _vaultTransition,
        ),
      ),
      
      // AI Chat
      GoRoute(
        path: AppRoutes.aiChat,
        name: 'aiChat',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AIChatScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      
      // Session Termination
      GoRoute(
        path: AppRoutes.sessionTermination,
        name: 'sessionTermination',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SessionTerminationScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
    ],
  );
});

// Custom Transitions
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: animation,
    child: child,
  );
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const begin = Offset(1.0, 0.0);
  const end = Offset.zero;
  const curve = Curves.easeInOutCubic;
  
  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  var offsetAnimation = animation.drive(tween);
  
  return SlideTransition(
    position: offsetAnimation,
    child: child,
  );
}

Widget _scaleTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return ScaleTransition(
    scale: Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    ),
    child: FadeTransition(
      opacity: animation,
      child: child,
    ),
  );
}

Widget _vaultTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return ScaleTransition(
    scale: Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
    ),
    child: FadeTransition(
      opacity: animation,
      child: child,
    ),
  );
}
