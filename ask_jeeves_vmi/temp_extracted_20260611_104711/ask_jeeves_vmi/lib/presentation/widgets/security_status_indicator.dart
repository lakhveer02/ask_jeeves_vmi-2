import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ask_jeeves_vmi/security/providers/security_providers.dart';
import 'package:ask_jeeves_vmi/security/services/realtime_security_monitor.dart' as rtm;
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';

/// Security Status Indicator Widget
/// Displays real-time security status with visual feedback
class SecurityStatusIndicator extends ConsumerWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const SecurityStatusIndicator({
    super.key,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitor = ref.watch(realtimeSecurityMonitorProvider);
    final status = monitor.getStatus();
    final trustScore = monitor.getTrustScore();
    final isMonitoring = monitor.isMonitoring;

    return GestureDetector(
      onTap: onTap ?? () => _showSecurityDetails(context, monitor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.deepBlack.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: status.color.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: status.color.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status icon with pulse animation
            _buildStatusIcon(status, isMonitoring),
            const SizedBox(width: 8),
            
            // Status text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status.displayName,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                if (showDetails) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Trust: $trustScore%',
                    style: TextStyle(
                      color: AppTheme.ghostWhite.withOpacity(0.7),
                      fontSize: 10,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ],
              ],
            ),
            
            // Monitoring indicator
            if (isMonitoring) ...[
              const SizedBox(width: 8),
              _buildMonitoringIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(rtm.SecurityStatus status, bool isMonitoring) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        status.icon,
        size: 16,
        color: status.color,
      ),
    );
  }

  Widget _buildMonitoringIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.electricCyan,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricCyan.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
      onEnd: () {
        // Loop animation
      },
    );
  }

  void _showSecurityDetails(BuildContext context, rtm.RealtimeSecurityMonitor monitor) {
    final stats = monitor.getStats();
    final criticalThreats = monitor.getCriticalThreats();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.deepBlack,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: AppTheme.electricCyan.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  stats.currentStatus.icon,
                  color: stats.currentStatus.color,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Status',
                        style: TextStyle(
                          color: AppTheme.ghostWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      Text(
                        stats.currentStatus.displayName,
                        style: TextStyle(
                          color: stats.currentStatus.color,
                          fontSize: 14,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.ghostWhite),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Trust Score
            _buildDetailRow(
              'Trust Score',
              '${stats.currentTrustScore}%',
              Icons.verified_user_outlined,
              _getTrustScoreColor(stats.currentTrustScore),
            ),
            const SizedBox(height: 12),

            // Monitoring Status
            _buildDetailRow(
              'Monitoring',
              stats.isActive ? 'Active' : 'Inactive',
              Icons.radar,
              stats.isActive ? AppTheme.successGreen : AppTheme.warningOrange,
            ),
            const SizedBox(height: 12),

            // Checks Performed
            _buildDetailRow(
              'Checks Performed',
              '${stats.checksPerformed}',
              Icons.fact_check_outlined,
              AppTheme.electricCyan,
            ),
            const SizedBox(height: 12),

            // Threats Detected
            _buildDetailRow(
              'Threats Detected',
              '${stats.totalThreats}',
              Icons.warning_amber_outlined,
              stats.totalThreats > 0 ? AppTheme.warningOrange : AppTheme.successGreen,
            ),

            // Critical Threats
            if (criticalThreats.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warningRed.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.dangerous_outlined,
                          color: AppTheme.warningRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Critical Threats',
                          style: TextStyle(
                            color: AppTheme.warningRed,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...criticalThreats.map((threat) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '• ${threat.message}',
                        style: TextStyle(
                          color: AppTheme.ghostWhite.withOpacity(0.9),
                          fontSize: 12,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],

            // Uptime
            if (stats.isActive) ...[
              const SizedBox(height: 16),
              Text(
                'Uptime: ${_formatDuration(stats.uptime)}',
                style: TextStyle(
                  color: AppTheme.ghostWhite.withOpacity(0.6),
                  fontSize: 12,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.ghostWhite.withOpacity(0.8),
              fontSize: 14,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
      ],
    );
  }

  Color _getTrustScoreColor(int score) {
    if (score >= 80) return AppTheme.successGreen;
    if (score >= 60) return AppTheme.electricCyan;
    if (score >= 40) return AppTheme.warningOrange;
    return AppTheme.warningRed;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

/// Compact Security Badge (for app bars)
class SecurityBadge extends ConsumerWidget {
  const SecurityBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitor = ref.watch(realtimeSecurityMonitorProvider);
    final status = monitor.getStatus();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status.color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 14,
            color: status.color,
          ),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: status.color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
        ],
      ),
    );
  }
}
