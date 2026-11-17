// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';

/// Futuristic holographic button with gradient and glow effects
class HolographicButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final Gradient? gradient;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;

  const HolographicButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 56,
    this.gradient,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  State<HolographicButton> createState() => _HolographicButtonState();
}

class _HolographicButtonState extends State<HolographicButton>
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
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
      onTapDown: widget.isEnabled && !widget.isLoading
          ? (_) => _controller.forward()
          : null,
      onTapUp: widget.isEnabled && !widget.isLoading
          ? (_) {
              _controller.reverse();
              widget.onPressed();
            }
          : null,
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: widget.gradient ?? AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricCyan.withOpacity(_glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isEnabled && !widget.isLoading
                      ? widget.onPressed
                      : null,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.deepBlack,
                              ),
                            ),
                          )
                        else ...[
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: AppTheme.deepBlack,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Flexible(
                            child: Text(
                              widget.text,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SpaceGrotesk',
                                color: AppTheme.deepBlack,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Outline variant of holographic button
class HolographicOutlineButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final IconData? icon;
  final Color? borderColor;

  const HolographicOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 56,
    this.icon,
    this.borderColor,
  });

  @override
  State<HolographicOutlineButton> createState() =>
      _HolographicOutlineButtonState();
}

class _HolographicOutlineButtonState extends State<HolographicOutlineButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: widget.borderColor ?? AppTheme.electricCyan,
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: widget.borderColor ?? AppTheme.electricCyan,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Flexible(
                          child: Text(
                            widget.text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SpaceGrotesk',
                              color: widget.borderColor ?? AppTheme.electricCyan,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
