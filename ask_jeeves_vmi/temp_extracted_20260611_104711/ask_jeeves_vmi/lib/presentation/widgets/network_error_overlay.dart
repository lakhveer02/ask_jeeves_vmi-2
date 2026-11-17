/// Network Error Overlay Widget
/// Shows a user-friendly message when network connection is lost
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NetworkErrorOverlay extends StatelessWidget {
  final bool isVisible;
  
  const NetworkErrorOverlay({
    super.key,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF3366), // Critical red
                const Color(0xFFFF3366).withOpacity(0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3366).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Animated icon
                _buildAnimatedIcon(),
                
                const SizedBox(width: 12),
                
                // Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No Internet Connection',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Please check your network connection',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Close button
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    // User can dismiss temporarily
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      )
          .animate()
          .slideY(
            begin: -1,
            end: 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          )
          .fadeIn(duration: const Duration(milliseconds: 300)),
    );
  }
  
  Widget _buildAnimatedIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.wifi_off_rounded,
        color: Colors.white,
        size: 24,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shake(
          duration: const Duration(milliseconds: 1000),
          hz: 2,
          curve: Curves.easeInOut,
        );
  }
}

/// Network Status Banner (Alternative style - bottom banner)
class NetworkStatusBanner extends StatelessWidget {
  final bool isConnected;
  
  const NetworkStatusBanner({
    super.key,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnected) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3366),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3366).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'You\'re Offline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Check your WiFi or mobile data',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Retry button
                TextButton.icon(
                  onPressed: () {
                    // Trigger manual connectivity check
                  },
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .animate()
          .slideY(
            begin: 1,
            end: 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          )
          .fadeIn(duration: const Duration(milliseconds: 300)),
    );
  }
}
