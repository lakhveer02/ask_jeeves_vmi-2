// MOCK IMPLEMENTATION - Using test data instead of real API calls
// This allows the app to run without a backend server for testing/demo purposes

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ask_jeeves_vmi/core/config/api_constants.dart';
import 'package:ask_jeeves_vmi/data/models/api_response.dart';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';
import 'package:ask_jeeves_vmi/security/services/device_identity_service.dart';
import 'package:ask_jeeves_vmi/data/services/api/api_client.dart'; // For ApiException
import 'package:uuid/uuid.dart';

part 'auth_provider.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isAuthenticated,
    @Default(false) bool isLoading,
    UserData? user,
    SessionData? session,
    String? error,
    String? deviceId,
  }) = _AuthState;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _storage;
  final DeviceIdentityService _deviceIdentity;

  AuthNotifier(this._storage, this._deviceIdentity)
      : super(const AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Check if user is already authenticated
    final accessToken = await _storage.read(ApiConstants.storageKeyAccessToken);
    final deviceId = await _deviceIdentity.getOrCreateDeviceId();

    state = state.copyWith(deviceId: deviceId);

    if (accessToken != null) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  /// Login with email and password (Mock Implementation)
  Future<void> login({
    required String email,
    required String password,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final deviceId = state.deviceId ?? await _deviceIdentity.getOrCreateDeviceId();
      final deviceName = await _deviceIdentity.getOrCreateDeviceName();

      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock validation - accept any email/password for testing
      if (email.isEmpty || password.isEmpty) {
        throw ApiException(
          message: 'Email and password are required',
          statusCode: 400,
        );
      }

      // Create mock tokens
      final mockAccessToken = 'mock_access_token_${const Uuid().v4()}';
      final mockRefreshToken = 'mock_refresh_token_${const Uuid().v4()}';
      final mockUserId = const Uuid().v4();
      final mockSessionId = const Uuid().v4();

      // Store tokens
      await _storage.write(
        ApiConstants.storageKeyAccessToken,
        mockAccessToken,
      );
      await _storage.write(
        ApiConstants.storageKeyRefreshToken,
        mockRefreshToken,
      );
      await _storage.write(
        ApiConstants.storageKeyUserId,
        mockUserId,
      );
      await _storage.write(
        ApiConstants.storageKeySessionId,
        mockSessionId,
      );

      // Create mock user data
      final mockUser = UserData(
        id: mockUserId,
        email: email,
        fullName: 'Test User',
        role: 'user',
        organization: 'Test Organization',
        isActive: true,
        mfaEnabled: false,
      );

      // Create mock session data
      final mockSession = SessionData(
        id: mockSessionId,
        deviceId: deviceId,
        deviceName: deviceName,
        ipAddress: '127.0.0.1',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: mockUser,
        session: mockSession,
        error: null,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      rethrow;
    }
  }

  /// Register new user (Mock Implementation)
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? organization,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final deviceId = state.deviceId ?? await _deviceIdentity.getOrCreateDeviceId();
      final deviceName = await _deviceIdentity.getOrCreateDeviceName();

      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock validation
      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        throw ApiException(
          message: 'All fields are required',
          statusCode: 400,
        );
      }

      // Create mock tokens
      final mockAccessToken = 'mock_access_token_${const Uuid().v4()}';
      final mockRefreshToken = 'mock_refresh_token_${const Uuid().v4()}';
      final mockUserId = const Uuid().v4();
      final mockSessionId = const Uuid().v4();

      // Store tokens
      await _storage.write(
        ApiConstants.storageKeyAccessToken,
        mockAccessToken,
      );
      await _storage.write(
        ApiConstants.storageKeyRefreshToken,
        mockRefreshToken,
      );
      await _storage.write(
        ApiConstants.storageKeyUserId,
        mockUserId,
      );
      await _storage.write(
        ApiConstants.storageKeySessionId,
        mockSessionId,
      );

      // Create mock user data
      final mockUser = UserData(
        id: mockUserId,
        email: email,
        fullName: fullName,
        role: 'user',
        organization: organization ?? 'Test Organization',
        isActive: true,
        mfaEnabled: false,
      );

      // Create mock session data
      final mockSession = SessionData(
        id: mockSessionId,
        deviceId: deviceId,
        deviceName: deviceName,
        ipAddress: '127.0.0.1',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: mockUser,
        session: mockSession,
        error: null,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      rethrow;
    }
  }

  /// Logout (Mock Implementation)
  Future<void> logout() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Clear stored tokens
    await _storage.delete(ApiConstants.storageKeyAccessToken);
    await _storage.delete(ApiConstants.storageKeyRefreshToken);
    await _storage.delete(ApiConstants.storageKeyUserId);
    await _storage.delete(ApiConstants.storageKeySessionId);

    state = const AuthState();
  }

  /// Validate geofence (Mock Implementation)
  Future<GeofenceValidationResponse> validateGeofence({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock geofence validation - always return valid for testing
    return const GeofenceValidationResponse(
      isValid: true,
      validationReason: 'Location validated successfully',
      matchedZoneId: 'test-zone-001',
      zoneName: 'Test Office',
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final deviceIdentity = ref.watch(deviceIdentityServiceProvider);
  return AuthNotifier(storage, deviceIdentity);
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
