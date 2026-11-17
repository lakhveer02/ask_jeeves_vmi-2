// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:ask_jeeves_vmi/presentation/widgets/glassmorphic_container.dart';
import 'package:ask_jeeves_vmi/presentation/widgets/holographic_button.dart';
import 'package:ask_jeeves_vmi/core/router/app_router.dart';

/// Onboarding screen showcasing key features
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.security_rounded,
      title: 'Zero-Trust Security',
      description:
          'Military-grade encryption with confidential computing. Your data never leaves the secure vault.',
      gradient: AppTheme.primaryGradient,
    ),
    OnboardingPage(
      icon: Icons.cloud_circle_rounded,
      title: 'Virtual Mobile Infrastructure',
      description:
          'Pixel-streaming technology. Your device becomes a secure visual terminal.',
      gradient: AppTheme.vaultGradient,
    ),
    OnboardingPage(
      icon: Icons.psychology_rounded,
      title: 'Secure AI Workspace',
      description:
          'AI-powered patent analysis, contract intelligence, and compliance monitoring.',
      gradient: LinearGradient(
        colors: [AppTheme.neonPurple, AppTheme.electricCyan],
      ),
    ),
    OnboardingPage(
      icon: Icons.location_on_rounded,
      title: 'Geofence Protection',
      description:
          'Location-based access control. Vault access restricted to authorized zones.',
      gradient: LinearGradient(
        colors: [AppTheme.mercuryTeal, AppTheme.successGreen],
      ),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
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
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppTheme.electricCyan,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: AppTheme.normalAnimation,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppTheme.electricCyan
                          : AppTheme.electricCyan.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: HolographicOutlineButton(
                          text: 'Back',
                          onPressed: () {
                            _pageController.previousPage(
                              duration: AppTheme.normalAnimation,
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: _currentPage == 0 ? 1 : 1,
                      child: HolographicButton(
                        text: _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            context.go(AppRoutes.login);
                          } else {
                            _pageController.nextPage(
                              duration: AppTheme.normalAnimation,
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                       
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = constraints.maxHeight > 600 ? 160.0 : 120.0;
        final iconInnerSize = constraints.maxHeight > 600 ? 80.0 : 60.0;
        final verticalSpacing = constraints.maxHeight > 600 ? 60.0 : 30.0;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with gradient background
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    gradient: page.gradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.electricCyan.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    page.icon,
                    size: iconInnerSize,
                    color: AppTheme.deepBlack,
                  ),
                )
                    .animate()
                    .scale(
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    )
                    .then()
                    .shimmer(
                      duration: 2000.ms,
                      color: AppTheme.electricCyan.withOpacity(0.3),
                    ),

                SizedBox(height: verticalSpacing),

                // Title
                Text(
                  page.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Description
                GlassmorphicContainer(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  borderRadius: AppTheme.radiusLarge,
                  child: Text(
                    page.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                    textAlign: TextAlign.center,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
