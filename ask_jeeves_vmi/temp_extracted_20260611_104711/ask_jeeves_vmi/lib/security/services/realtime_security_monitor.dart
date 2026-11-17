import 'dart:async';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:ask_jeeves_vmi/security/services/device_attestation_service.dart';
import 'package:ask_jeeves_vmi/security/services/device_security_service.dart';

/// Real-Time Security Monitor
/// Continuously monitors device security status and detects threats in real-time
class RealtimeSecurityMonitor {
  final DeviceAttestationService _attestationService;
  final DeviceSecurityService _securityService;
  
  Timer? _monitoringTimer;
  final Duration _checkInterval;
  
  // Callbacks for security events
  Function(SecurityThreat)? onThreatDetected;
  Function(int)? onTrustScoreChanged;
  Function(SecurityStatus)? onStatusChanged;
  Function()? onJailbreakDetected;
  Function()? onRootDetected;
  Function()? onEmulatorDetected;
  Function()? onDeveloperModeDetected;
  
  // State tracking
  SecurityStatus _currentStatus = SecurityStatus.secure;
  int _lastTrustScore = 100;
  bool _wasJailbroken = false;
  bool _wasDeveloperMode = false;
  bool _wasEmulator = false;
  final List<SecurityThreat> _detectedThreats = [];
  
  // Monitoring state
  bool _isMonitoring = false;
  DateTime? _monitoringStartTime;
  int _checksPerformed = 0;
  int _threatsDetected = 0;
  
  RealtimeSecurityMonitor(
    this._attestationService,
    this._securityService, {
    Duration checkInterval = const Duration(seconds: 10), // Check every 10 seconds
  }) : _checkInterval = checkInterval;

  /// Start real-time security monitoring
  void startMonitoring() {
    if (_isMonitoring) {
      debugPrint('[RealtimeSecurityMonitor] Monitoring already active');
      return;
    }

    debugPrint('[RealtimeSecurityMonitor] 🔐 Starting real-time security monitoring');
    debugPrint('[RealtimeSecurityMonitor] Check interval: ${_checkInterval.inSeconds}s');
    
    _isMonitoring = true;
    _monitoringStartTime = DateTime.now();
    _checksPerformed = 0;
    _threatsDetected = 0;
    
    // Perform initial check immediately
    _performSecurityCheck();
    
    // Schedule periodic checks
    _monitoringTimer = Timer.periodic(_checkInterval, (_) {
      _performSecurityCheck();
    });
    
    debugPrint('[RealtimeSecurityMonitor] ✅ Real-time monitoring started');
  }

  /// Stop real-time security monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;
    
    final duration = _monitoringStartTime != null 
        ? DateTime.now().difference(_monitoringStartTime!)
        : Duration.zero;
    
    debugPrint('[RealtimeSecurityMonitor] 🛑 Security monitoring stopped');
    debugPrint('[RealtimeSecurityMonitor] Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
    debugPrint('[RealtimeSecurityMonitor] Checks performed: $_checksPerformed');
    debugPrint('[RealtimeSecurityMonitor] Threats detected: $_threatsDetected');
  }

  /// Perform comprehensive security check
  Future<void> _performSecurityCheck() async {
    if (!_isMonitoring) return;
    
    _checksPerformed++;
    
    try {
      // Perform device attestation
      final attestation = await _attestationService.attestDevice();
      
      // Perform device security verification
      final verification = await _securityService.verifyDevice();
      
      debugPrint('[RealtimeSecurityMonitor] 🔍 Security Check #$_checksPerformed:');
      debugPrint('  Trust Score: ${attestation.trustScore}');
      debugPrint('  Jailbroken: ${attestation.isJailbroken}');
      debugPrint('  Developer Mode: ${attestation.isDeveloperMode}');
      debugPrint('  Physical Device: ${attestation.deviceInfo['isPhysicalDevice']}');
      debugPrint('  Compromised: ${verification.isCompromised}');
      
      // Check for threats
      _checkForThreats(attestation, verification);
      
      // Update trust score
      if (attestation.trustScore != _lastTrustScore) {
        debugPrint('[RealtimeSecurityMonitor] ⚠️ Trust score changed: $_lastTrustScore → ${attestation.trustScore}');
        _lastTrustScore = attestation.trustScore;
        onTrustScoreChanged?.call(attestation.trustScore);
      }
      
      // Update status
      final newStatus = _determineSecurityStatus(attestation, verification);
      if (newStatus != _currentStatus) {
        debugPrint('[RealtimeSecurityMonitor] 🚨 Security status changed: ${_currentStatus.name} → ${newStatus.name}');
        _currentStatus = newStatus;
        onStatusChanged?.call(newStatus);
      }
      
    } catch (e) {
      debugPrint('[RealtimeSecurityMonitor] ❌ Error during security check: $e');
    }
  }

  /// Check for security threats
  void _checkForThreats(
    DeviceAttestationResult attestation,
    DeviceVerificationResult verification,
  ) {
    final newThreats = <SecurityThreat>[];
    
    // 1. CRITICAL: Jailbreak/Root detection
    if (attestation.isJailbroken && !_wasJailbroken) {
      _wasJailbroken = true;
      _threatsDetected++;
      
      final threat = SecurityThreat(
        type: ThreatType.jailbreak,
        severity: ThreatSeverity.critical,
        message: 'Device is jailbroken/rooted - CRITICAL SECURITY RISK',
        timestamp: DateTime.now(),
        details: {
          'platform': attestation.deviceInfo['platform'],
          'model': attestation.deviceInfo['model'],
          'os_version': attestation.osVersion,
        },
      );
      
      newThreats.add(threat);
      _detectedThreats.add(threat);
      
      debugPrint('[RealtimeSecurityMonitor] 🚨🚨🚨 CRITICAL THREAT DETECTED: JAILBREAK/ROOT');
      onThreatDetected?.call(threat);
      onJailbreakDetected?.call();
      onRootDetected?.call();
    }
    
    // 2. HIGH: Developer mode detection
    if (attestation.isDeveloperMode && !_wasDeveloperMode) {
      _wasDeveloperMode = true;
      _threatsDetected++;
      
      final threat = SecurityThreat(
        type: ThreatType.developerMode,
        severity: ThreatSeverity.high,
        message: 'Developer mode is enabled',
        timestamp: DateTime.now(),
        details: {
          'debug_mode': true,
        },
      );
      
      newThreats.add(threat);
      _detectedThreats.add(threat);
      
      debugPrint('[RealtimeSecurityMonitor] ⚠️ HIGH THREAT: Developer mode enabled');
      onThreatDetected?.call(threat);
      onDeveloperModeDetected?.call();
    }
    
    // 3. HIGH: Emulator detection
    final isPhysicalDevice = attestation.deviceInfo['isPhysicalDevice'] as bool;
    if (!isPhysicalDevice && !_wasEmulator) {
      _wasEmulator = true;
      _threatsDetected++;
      
      final threat = SecurityThreat(
        type: ThreatType.emulator,
        severity: ThreatSeverity.high,
        message: 'Running on emulator/simulator',
        timestamp: DateTime.now(),
        details: {
          'platform': attestation.deviceInfo['platform'],
          'model': attestation.deviceInfo['model'],
        },
      );
      
      newThreats.add(threat);
      _detectedThreats.add(threat);
      
      debugPrint('[RealtimeSecurityMonitor] ⚠️ HIGH THREAT: Emulator detected');
      onThreatDetected?.call(threat);
      onEmulatorDetected?.call();
    }
    
    // 4. MEDIUM: Outdated OS detection
    if (_isOsOutdated(attestation)) {
      final threat = SecurityThreat(
        type: ThreatType.outdatedOS,
        severity: ThreatSeverity.medium,
        message: 'Operating system is outdated',
        timestamp: DateTime.now(),
        details: {
          'os_version': attestation.osVersion,
          'platform': attestation.deviceInfo['platform'],
        },
      );
      
      // Only add if not already detected
      if (!_detectedThreats.any((t) => t.type == ThreatType.outdatedOS)) {
        newThreats.add(threat);
        _detectedThreats.add(threat);
        _threatsDetected++;
        
        debugPrint('[RealtimeSecurityMonitor] ⚠️ MEDIUM THREAT: Outdated OS');
        onThreatDetected?.call(threat);
      }
    }
    
    // 5. HIGH: Low trust score detection
    if (attestation.trustScore < 50) {
      final threat = SecurityThreat(
        type: ThreatType.lowTrustScore,
        severity: ThreatSeverity.high,
        message: 'Device trust score is critically low (${attestation.trustScore}/100)',
        timestamp: DateTime.now(),
        details: {
          'trust_score': attestation.trustScore,
          'threshold': 50,
        },
      );
      
      // Only add if not already detected
      if (!_detectedThreats.any((t) => t.type == ThreatType.lowTrustScore)) {
        newThreats.add(threat);
        _detectedThreats.add(threat);
        _threatsDetected++;
        
        debugPrint('[RealtimeSecurityMonitor] ⚠️ HIGH THREAT: Low trust score');
        onThreatDetected?.call(threat);
      }
    }
    
    // 6. CRITICAL: Device compromised
    if (verification.isCompromised) {
      final threat = SecurityThreat(
        type: ThreatType.deviceCompromised,
        severity: ThreatSeverity.critical,
        message: 'Device integrity compromised',
        timestamp: DateTime.now(),
        details: {
          'verification_failed': true,
        },
      );
      
      // Only add if not already detected
      if (!_detectedThreats.any((t) => t.type == ThreatType.deviceCompromised)) {
        newThreats.add(threat);
        _detectedThreats.add(threat);
        _threatsDetected++;
        
        debugPrint('[RealtimeSecurityMonitor] 🚨 CRITICAL THREAT: Device compromised');
        onThreatDetected?.call(threat);
      }
    }
    
    if (newThreats.isNotEmpty) {
      debugPrint('[RealtimeSecurityMonitor] 🚨 ${newThreats.length} new threat(s) detected in this check');
    }
  }

  /// Determine overall security status
  SecurityStatus _determineSecurityStatus(
    DeviceAttestationResult attestation,
    DeviceVerificationResult verification,
  ) {
    // Critical: Device is jailbroken or compromised
    if (attestation.isJailbroken || verification.isCompromised) {
      return SecurityStatus.compromised;
    }
    
    // Critical: Trust score below 30
    if (attestation.trustScore < 30) {
      return SecurityStatus.critical;
    }
    
    // Warning: Trust score below 60
    if (attestation.trustScore < 60) {
      return SecurityStatus.warning;
    }
    
    // Caution: Developer mode or emulator
    final isPhysicalDevice = attestation.deviceInfo['isPhysicalDevice'] as bool;
    if (attestation.isDeveloperMode || !isPhysicalDevice) {
      return SecurityStatus.caution;
    }
    
    // Secure: All checks passed
    return SecurityStatus.secure;
  }

  bool _isOsOutdated(DeviceAttestationResult attestation) {
    final platform = attestation.deviceInfo['platform'] as String;
    final osVersion = attestation.osVersion;
    
    if (platform == 'android') {
      final sdkInt = attestation.deviceInfo['sdkInt'] as int?;
      return sdkInt != null && sdkInt < 26; // Android 8.0+
    } else if (platform == 'ios') {
      final majorVersion = int.tryParse(osVersion.split('.').first) ?? 0;
      return majorVersion < 14; // iOS 14+
    }
    
    return false;
  }

  /// Get current security status
  SecurityStatus getStatus() => _currentStatus;

  /// Get current trust score
  int getTrustScore() => _lastTrustScore;

  /// Get all detected threats
  List<SecurityThreat> getThreats() => List.unmodifiable(_detectedThreats);

  /// Get threats by severity
  List<SecurityThreat> getThreatsBySeverity(ThreatSeverity severity) {
    return _detectedThreats.where((t) => t.severity == severity).toList();
  }

  /// Get critical threats
  List<SecurityThreat> getCriticalThreats() {
    return getThreatsBySeverity(ThreatSeverity.critical);
  }

  /// Check if device is secure
  bool isSecure() => _currentStatus == SecurityStatus.secure && _lastTrustScore >= 70;

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Get monitoring statistics
  MonitoringStats getStats() {
    return MonitoringStats(
      isActive: _isMonitoring,
      startTime: _monitoringStartTime,
      checksPerformed: _checksPerformed,
      threatsDetected: _threatsDetected,
      currentStatus: _currentStatus,
      currentTrustScore: _lastTrustScore,
      totalThreats: _detectedThreats.length,
    );
  }

  /// Clear all detected threats
  void clearThreats() {
    _detectedThreats.clear();
    _threatsDetected = 0;
    _wasJailbroken = false;
    _wasDeveloperMode = false;
    _wasEmulator = false;
    debugPrint('[RealtimeSecurityMonitor] Threats cleared');
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _detectedThreats.clear();
  }
}

/// Security threat model
class SecurityThreat {
  final ThreatType type;
  final ThreatSeverity severity;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  SecurityThreat({
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'severity': severity.toString(),
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
  };

  @override
  String toString() => 'SecurityThreat($type, $severity): $message';
}

/// Threat types
enum ThreatType {
  jailbreak,
  developerMode,
  emulator,
  outdatedOS,
  lowTrustScore,
  deviceCompromised,
  suspiciousApp,
  networkInterception,
  unknown,
}

/// Threat severity levels
enum ThreatSeverity {
  critical,
  high,
  medium,
  low,
}

/// Security status
enum SecurityStatus {
  secure,
  caution,
  warning,
  critical,
  compromised,
}

/// Monitoring statistics
class MonitoringStats {
  final bool isActive;
  final DateTime? startTime;
  final int checksPerformed;
  final int threatsDetected;
  final SecurityStatus currentStatus;
  final int currentTrustScore;
  final int totalThreats;

  MonitoringStats({
    required this.isActive,
    required this.startTime,
    required this.checksPerformed,
    required this.threatsDetected,
    required this.currentStatus,
    required this.currentTrustScore,
    required this.totalThreats,
  });

  Duration get uptime {
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime!);
  }
}

/// Extension for threat severity
extension ThreatSeverityExt on ThreatSeverity {
  String get displayName {
    switch (this) {
      case ThreatSeverity.critical:
        return 'Critical';
      case ThreatSeverity.high:
        return 'High';
      case ThreatSeverity.medium:
        return 'Medium';
      case ThreatSeverity.low:
        return 'Low';
    }
  }

  int get score {
    switch (this) {
      case ThreatSeverity.critical:
        return 4;
      case ThreatSeverity.high:
        return 3;
      case ThreatSeverity.medium:
        return 2;
      case ThreatSeverity.low:
        return 1;
    }
  }

  Color get color {
    switch (this) {
      case ThreatSeverity.critical:
        return AppTheme.warningRed; // Critical red
      case ThreatSeverity.high:
        return AppTheme.warningOrange; // Warning orange
      case ThreatSeverity.medium:
        return const Color(0xFFFFD60A); // Caution yellow
      case ThreatSeverity.low:
        return AppTheme.electricCyan; // Info cyan
    }
  }
}

/// Extension for security status
extension SecurityStatusExt on SecurityStatus {
  String get displayName {
    switch (this) {
      case SecurityStatus.secure:
        return 'Secure';
      case SecurityStatus.caution:
        return 'Caution';
      case SecurityStatus.warning:
        return 'Warning';
      case SecurityStatus.critical:
        return 'Critical';
      case SecurityStatus.compromised:
        return 'Compromised';
    }
  }

  Color get color {
    switch (this) {
      case SecurityStatus.secure:
        return AppTheme.successGreen; // Success green
      case SecurityStatus.caution:
        return AppTheme.electricCyan; // Electric cyan
      case SecurityStatus.warning:
        return AppTheme.warningOrange; // Warning orange
      case SecurityStatus.critical:
        return AppTheme.warningRed; // Warning red
      case SecurityStatus.compromised:
        return const Color(0xFF8B0000); // Dark red
    }
  }

  IconData get icon {
    switch (this) {
      case SecurityStatus.secure:
        return Icons.shield_outlined;
      case SecurityStatus.caution:
        return Icons.warning_amber_outlined;
      case SecurityStatus.warning:
        return Icons.error_outline;
      case SecurityStatus.critical:
        return Icons.dangerous_outlined;
      case SecurityStatus.compromised:
        return Icons.block;
    }
  }
}
