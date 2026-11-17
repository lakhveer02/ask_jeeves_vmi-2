// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:ask_jeeves_vmi/core/router/app_router.dart';

/// Cinematic session termination with data destruction animation
class SessionTerminationScreen extends StatefulWidget {
  const SessionTerminationScreen({super.key});

  @override
  State<SessionTerminationScreen> createState() =>
      _SessionTerminationScreenState();
}

class _SessionTerminationScreenState extends State<SessionTerminationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _progress = 0.0;
  String _currentStep = 'Terminating session...';

  final List<String> _steps = [
    'Closing secure connections',
    'Destroying session tokens',
    'Wiping temporary data',
    'Clearing render buffers',
    'Liquidating vault instance',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _controller.forward();
    _terminateSession();
  }

  Future<void> _terminateSession() async {
    for (int i = 0; i < _steps.length; i++) {
      setState(() {
        _currentStep = _steps[i];
        _progress = (i + 1) / _steps.length;
      });

      await Future.delayed(const Duration(milliseconds: 800));
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      context.go(AppRoutes.login);
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
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Destruction animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.dangerGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warningRed.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.delete_forever,
                  size: 60,
                  color: AppTheme.deepBlack,
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .scale(
                    duration: 1000.ms,
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(0.8, 0.8),
                  )
                  .then()
                  .scale(
                    duration: 1000.ms,
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                  ),

              const SizedBox(height: 48),

              Text(
                'Terminating Session',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: 16),

              Text(
                _currentStep,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.warningRed,
                    ),
              ),

              const SizedBox(height: 48),

              // Progress bar
              SizedBox(
                width: 300,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppTheme.warningRed.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.warningRed,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
