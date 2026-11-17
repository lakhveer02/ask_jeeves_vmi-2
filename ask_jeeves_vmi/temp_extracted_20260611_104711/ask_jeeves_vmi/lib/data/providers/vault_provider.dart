// MOCK IMPLEMENTATION - Using test data instead of real API calls
// This allows the app to run without a backend server for testing/demo purposes

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ask_jeeves_vmi/data/models/api_response.dart';
import 'package:ask_jeeves_vmi/data/services/api/api_client.dart'; // For ApiException
import 'package:uuid/uuid.dart';

part 'vault_provider.freezed.dart';

@freezed
class VaultState with _$VaultState {
  const factory VaultState({
    @Default(false) bool isInitializing,
    @Default(false) bool isActive,
    @Default(false) bool isTerminating,
    VaultData? vault,
    WebRtcConfig? webrtcConfig,
    VaultStatusResponse? status,
    String? error,
    Timer? heartbeatTimer,
  }) = _VaultState;
}

class VaultNotifier extends StateNotifier<VaultState> {
  Timer? _heartbeatTimer;

  VaultNotifier() : super(const VaultState());

  /// Create and initialize vault (Mock Implementation)
  Future<void> createVault() async {
    state = state.copyWith(isInitializing: true, error: null);

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // Create mock vault data
      final mockVaultId = const Uuid().v4();
      final mockRoomId = const Uuid().v4();
      final mockStreamToken = 'mock_stream_token_${const Uuid().v4()}';

      final mockVault = VaultData(
        id: mockVaultId,
        status: 'active',
        webrtcRoomId: mockRoomId,
        streamToken: mockStreamToken,
      );

      // Create mock WebRTC config
      final mockWebRtcConfig = WebRtcConfig(
        iceServers: [
          IceServer(
            urls: ['stun:stun.l.google.com:19302'],
          ),
          IceServer(
            urls: ['turn:mock-turn-server.com:3478'],
            username: 'mockuser',
            credential: 'mockpass',
          ),
        ],
      );

      state = state.copyWith(
        isInitializing: false,
        isActive: true,
        vault: mockVault,
        webrtcConfig: mockWebRtcConfig,
        error: null,
      );

      // Start heartbeat
      _startHeartbeat();
    } on ApiException catch (e) {
      state = state.copyWith(
        isInitializing: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        error: 'Failed to create vault',
      );
      rethrow;
    }
  }

  /// Get vault status (Mock Implementation)
  Future<void> getStatus() async {
    if (state.vault == null) return;

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Create mock status
      final mockStatus = VaultStatusResponse(
        id: state.vault!.id,
        status: 'active',
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        lastHeartbeatAt: DateTime.now(),
        containerId: 'mock_container_${const Uuid().v4()}',
        metadata: {
          'cpu_usage': '15%',
          'memory_usage': '512MB',
          'uptime': '5m',
        },
      );

      state = state.copyWith(status: mockStatus);
    } catch (e) {
      // Silently fail status check
    }
  }

  /// Terminate vault (Mock Implementation)
  Future<void> terminateVault() async {
    if (state.vault == null) return;

    state = state.copyWith(isTerminating: true, error: null);

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Stop heartbeat
      _stopHeartbeat();

      state = const VaultState();
    } on ApiException catch (e) {
      state = state.copyWith(
        isTerminating: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isTerminating: false,
        error: 'Failed to terminate vault',
      );
      rethrow;
    }
  }

  /// Start heartbeat timer
  void _startHeartbeat() {
    _stopHeartbeat(); // Clear any existing timer

    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendHeartbeat(),
    );
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Send heartbeat to backend (Mock Implementation)
  Future<void> _sendHeartbeat() async {
    if (state.vault == null) return;

    try {
      // Mock heartbeat - just update status
      await getStatus();
    } catch (e) {
      // Silently fail heartbeat
    }
  }

  /// Get stream token (Mock Implementation)
  Future<Map<String, String>> getStreamToken() async {
    if (state.vault == null) {
      throw Exception('No active vault');
    }

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'token': 'mock_stream_token_${const Uuid().v4()}',
      'expires_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    };
  }

  /// Create WebRTC transport (Mock Implementation)
  Future<Map<String, dynamic>> createWebRtcTransport() async {
    if (state.vault == null) {
      throw Exception('No active vault');
    }

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 400));

    return {
      'id': const Uuid().v4(),
      'iceParameters': {
        'usernameFragment': 'mock_user_${const Uuid().v4().substring(0, 8)}',
        'password': 'mock_pass_${const Uuid().v4().substring(0, 16)}',
      },
      'iceCandidates': [
        {
          'foundation': 'mock_foundation',
          'priority': 2130706431,
          'ip': '192.168.1.100',
          'protocol': 'udp',
          'port': 10000,
          'type': 'host',
        },
      ],
      'dtlsParameters': {
        'role': 'auto',
        'fingerprints': [
          {
            'algorithm': 'sha-256',
            'value': 'mock_fingerprint_${const Uuid().v4()}',
          },
        ],
      },
    };
  }

  /// Connect WebRTC transport (Mock Implementation)
  Future<void> connectWebRtcTransport({
    required String transportId,
    required Map<String, dynamic> dtlsParameters,
  }) async {
    if (state.vault == null) {
      throw Exception('No active vault');
    }

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock connection success
  }

  /// Get RTP capabilities (Mock Implementation)
  Future<Map<String, dynamic>> getRtpCapabilities() async {
    if (state.vault == null) {
      throw Exception('No active vault');
    }

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'codecs': [
        {
          'kind': 'video',
          'mimeType': 'video/VP8',
          'clockRate': 90000,
        },
        {
          'kind': 'audio',
          'mimeType': 'audio/opus',
          'clockRate': 48000,
          'channels': 2,
        },
      ],
      'headerExtensions': [],
    };
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _stopHeartbeat();
    super.dispose();
  }
}

/// Vault Provider
final vaultProvider = StateNotifierProvider<VaultNotifier, VaultState>((ref) {
  return VaultNotifier();
});

/// Check if vault is active
final isVaultActiveProvider = Provider<bool>((ref) {
  return ref.watch(vaultProvider).isActive;
});
