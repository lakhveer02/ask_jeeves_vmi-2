import 'package:flutter/material.dart';

/// Visual indicator that shows when user taps on a remote input field
/// Provides feedback that the tap was detected and keyboard will open
class InputTapIndicator extends StatefulWidget {
  final bool isVisible;
  final Offset? position;

  const InputTapIndicator({
    super.key,
    required this.isVisible,
    this.position,
  });

  @override
  State<InputTapIndicator> createState() => _InputTapIndicatorState();
}

class _InputTapIndicatorState extends State<InputTapIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(InputTapIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.reset();
        _controller.forward();
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
    if (!widget.isVisible || widget.position == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: widget.position!.dx - 30,
      top: widget.position!.dy - 30,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue,
                      width: 3,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.keyboard,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
