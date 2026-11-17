// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';

/// Glassmorphic container with blur effect and gradient border
/// Used throughout the app for premium futuristic UI
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 10,
    this.opacity = 0.1,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: AppTheme.electricCyan.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(opacity),
                      Colors.white.withOpacity(opacity * 0.5),
                    ],
                  ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppTheme.electricCyan.withOpacity(0.2),
                width: borderWidth,
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Animated glassmorphic container with hover effects
class AnimatedGlassmorphicContainer extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const AnimatedGlassmorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.onTap,
  });

  @override
  State<AnimatedGlassmorphicContainer> createState() =>
      _AnimatedGlassmorphicContainerState();
}

class _AnimatedGlassmorphicContainerState
    extends State<AnimatedGlassmorphicContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.1, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GlassmorphicContainer(
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              margin: widget.margin,
              borderRadius: widget.borderRadius,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricCyan.withOpacity(_glowAnimation.value),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
