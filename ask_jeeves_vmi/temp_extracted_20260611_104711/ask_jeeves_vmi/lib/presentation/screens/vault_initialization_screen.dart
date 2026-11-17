// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:ask_jeeves_vmi/presentation/widgets/glassmorphic_container.dart';
import 'package:ask_jeeves_vmi/core/router/app_router.dart';
import 'package:ask_jeeves_vmi/data/providers/vault_provider.dart';

/// Cinematic vault initialization with neural mesh animation
class VaultInitializationScreen extends ConsumerStatefulWidget {
  const VaultInitializationScreen({super.key});

  @override
  ConsumerState<VaultInitializationScreen> createState() =>
      _VaultInitializationScreenState();
}

class _VaultInitializationScreenState
    extends ConsumerState<VaultInitializationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _progress = 0.0;
  String _currentStep = 'Initializing...';
  bool _isComplete = false;

  final List<Map<String, dynamic>> _steps = [
    {'name': 'Creating Secure Vault', 'duration': 800},
    {'name': 'Initializing Encryption', 'duration': 700},
    {'name': 'Establishing Secure Channel', 'duration': 900},
    {'name': 'Activating AI Core', 'duration': 1000},
    {'name': 'Loading Workspace', 'duration': 600},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _controller.forward();
    
    // Delay vault initialization to avoid modifying provider during build
    Future.microtask(() => _initializeVault());
  }

  Future<void> _initializeVault() async {
    try {
      // Step 1: Create vault on backend
      setState(() {
        _currentStep = 'Creating Secure Vault';
        _progress = 0.2;
      });

      await ref.read(vaultProvider.notifier).createVault();
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 2: Initialize encryption
      setState(() {
        _currentStep = 'Initializing Encryption';
        _progress = 0.4;
      });
      await Future.delayed(const Duration(milliseconds: 700));

      // Step 3: Establish secure channel
      setState(() {
        _currentStep = 'Establishing Secure Channel';
        _progress = 0.6;
      });
      await Future.delayed(const Duration(milliseconds: 900));

      // Step 4: Activate AI core
      setState(() {
        _currentStep = 'Activating AI Core';
        _progress = 0.8;
      });
      await Future.delayed(const Duration(milliseconds: 1000));

      // Step 5: Load workspace
      setState(() {
        _currentStep = 'Loading Workspace';
        _progress = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 600));

      setState(() {
        _isComplete = true;
      });

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        context.go(AppRoutes.aiChat);
      }
    } catch (e) {
      debugPrint('[VaultInit] Error initializing vault: $e');
      setState(() {
        _currentStep = 'Initialization failed';
        _isComplete = false;
      });
      
      // Show error and go back to login
      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go(AppRoutes.login);
          }
        });
      }
    }
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
              final screenHeight = constraints.maxHeight;
              // Smaller, more reasonable sizes
              final outerRingSize = screenHeight > 700 ? 120.0 : 90.0;
              final middleRingSize = screenHeight > 700 ? 90.0 : 70.0;
              final coreSize = screenHeight > 700 ? 60.0 : 50.0;
              final coreIconSize = screenHeight > 700 ? 30.0 : 25.0;
              final spacing1 = screenHeight > 700 ? 32.0 : 16.0;
              final spacing2 = screenHeight > 700 ? 16.0 : 8.0;
              final spacing3 = screenHeight > 700 ? 24.0 : 12.0;
              final padding = screenHeight > 700 ? 20.0 : 12.0;
              
              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Vault icon with animation - smaller sizes
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        Container(
                          width: outerRingSize,
                          height: outerRingSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.electricCyan.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                        )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .rotate(duration: 4000.ms),

                        // Middle ring
                        Container(
                          width: middleRingSize,
                          height: middleRingSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.mercuryTeal.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                        )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .rotate(
                              duration: 3000.ms,
                              begin: 1,
                              end: 0,
                            ),

                        // Core
                        Container(
                          width: coreSize,
                          height: coreSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _isComplete
                                ? LinearGradient(
                                    colors: [
                                      AppTheme.successGreen,
                                      AppTheme.mercuryTeal,
                                    ],
                                  )
                                : AppTheme.vaultGradient,
                            boxShadow: [
                              BoxShadow(
                                color: (_isComplete
                                        ? AppTheme.successGreen
                                        : AppTheme.electricCyan)
                                    .withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isComplete ? Icons.check : Icons.lock,
                            size: coreIconSize,
                            color: AppTheme.deepBlack,
                          ),
                        )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .shimmer(duration: 2000.ms),
                      ],
                    ),

                    SizedBox(height: spacing1),

                    // Status text
                    Text(
                      _isComplete
                          ? 'Vault Initialized'
                          : 'Initializing Vault',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),

                    SizedBox(height: spacing2),

                    Text(
                      _currentStep,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.electricCyan,
                          ),
                    ),

                    SizedBox(height: spacing3),

                    // Progress container - Flexible to fit available space
                    Flexible(
                      child: GlassmorphicContainer(
                        padding: EdgeInsets.all(screenHeight > 700 ? 20 : 12),
                        borderRadius: AppTheme.radiusLarge,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 6,
                                backgroundColor:
                                    AppTheme.electricCyan.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _isComplete
                                      ? AppTheme.successGreen
                                      : AppTheme.electricCyan,
                                ),
                              ),
                            ),

                            SizedBox(height: spacing2),

                            // Steps list - Flexible to fit available space
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _steps.length,
                                itemBuilder: (context, index) {
                                  final step = _steps[index];
                                  final isCompleted =
                                      _progress > (index / _steps.length);
                                  final isCurrent = _currentStep == step['name'];

                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: screenHeight > 700 ? 4 : 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCompleted
                                              ? Icons.check_circle
                                              : isCurrent
                                                  ? Icons.circle
                                                  : Icons.circle_outlined,
                                          color: isCompleted
                                              ? AppTheme.successGreen
                                              : isCurrent
                                                  ? AppTheme.electricCyan
                                                  : AppTheme.electricCyan
                                                      .withOpacity(0.3),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            step['name'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: isCompleted || isCurrent
                                                      ? AppTheme.ghostWhite
                                                      : AppTheme.ghostWhite
                                                          .withOpacity(0.3),
                                                  fontWeight: isCurrent
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
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
                          Icons.shield_outlined,
                          size: 12,
                          color: AppTheme.electricCyan.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'End-to-End Encrypted',
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
