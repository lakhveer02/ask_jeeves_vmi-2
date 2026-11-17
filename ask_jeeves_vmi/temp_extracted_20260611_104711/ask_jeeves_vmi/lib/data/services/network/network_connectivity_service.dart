/// Network Connectivity Monitoring Service
/// Monitors internet connection status in real-time
library;

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Current connectivity status
  bool _isConnected = true;
  
  // Callbacks for connection changes
  VoidCallback? onConnectionLost;
  VoidCallback? onConnectionRestored;
  
  /// Get current connection status
  bool get isConnected => _isConnected;
  
  /// Initialize and start monitoring
  Future<void> initialize() async {
    debugPrint('[NetworkConnectivity] 🌐 Initializing network monitoring...');
    
    // Check initial connectivity
    await _checkInitialConnectivity();
    
    // Start monitoring
    startMonitoring();
  }
  
  /// Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isConnected = _hasInternetConnection(results);
      debugPrint('[NetworkConnectivity] Initial status: ${_isConnected ? "Connected" : "Disconnected"}');
    } catch (e) {
      debugPrint('[NetworkConnectivity] ❌ Error checking initial connectivity: $e');
      _isConnected = false;
    }
  }
  
  /// Start monitoring connectivity changes
  void startMonitoring() {
    debugPrint('[NetworkConnectivity] 📡 Starting connectivity monitoring...');
    
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (error) {
        debugPrint('[NetworkConnectivity] ❌ Connectivity stream error: $error');
      },
    );
  }
  
  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = _hasInternetConnection(results);
    
    debugPrint('[NetworkConnectivity] 🔄 Connectivity changed:');
    debugPrint('  Results: ${results.map((r) => r.name).join(", ")}');
    debugPrint('  Was connected: $wasConnected');
    debugPrint('  Now connected: $_isConnected');
    
    // Connection lost
    if (wasConnected && !_isConnected) {
      debugPrint('[NetworkConnectivity] 🔴 CONNECTION LOST');
      onConnectionLost?.call();
    }
    
    // Connection restored
    if (!wasConnected && _isConnected) {
      debugPrint('[NetworkConnectivity] 🟢 CONNECTION RESTORED');
      onConnectionRestored?.call();
    }
  }
  
  /// Check if any connectivity result indicates internet connection
  bool _hasInternetConnection(List<ConnectivityResult> results) {
    // No connection at all
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return false;
    }
    
    // Has WiFi, mobile, ethernet, or VPN connection
    return results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);
  }
  
  /// Stop monitoring
  void stopMonitoring() {
    debugPrint('[NetworkConnectivity] 🛑 Stopping connectivity monitoring...');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
  
  /// Dispose and cleanup
  void dispose() {
    debugPrint('[NetworkConnectivity] 🗑️ Disposing network connectivity service');
    stopMonitoring();
    onConnectionLost = null;
    onConnectionRestored = null;
  }
}
