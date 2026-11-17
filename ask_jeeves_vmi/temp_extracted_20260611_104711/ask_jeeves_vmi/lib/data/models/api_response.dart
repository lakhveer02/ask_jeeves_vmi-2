import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

/// Generic API Response wrapper
@Freezed(genericArgumentFactories: true)
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required bool success,
    T? data,
    String? error,
    String? message,
    String? errorCode,
  }) = _ApiResponse<T>;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);
}

/// Auth Response Models
@freezed
class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required UserData user,
    required AuthTokens tokens,
    required SessionData session,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

@freezed
class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    required String tokenType,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}

@freezed
class UserData with _$UserData {
  const factory UserData({
    required String id,
    required String email,
    required String fullName,
    String? organization,
    required String role,
    required bool isActive,
    required bool mfaEnabled,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
}

@freezed
class SessionData with _$SessionData {
  const factory SessionData({
    required String id,
    String? deviceId,
    String? deviceName,
    String? ipAddress,
    required DateTime expiresAt,
  }) = _SessionData;

  factory SessionData.fromJson(Map<String, dynamic> json) =>
      _$SessionDataFromJson(json);
}

/// Vault Response Models
@freezed
class VaultResponse with _$VaultResponse {
  const factory VaultResponse({
    required VaultData vault,
    required WebRtcConfig webrtc,
  }) = _VaultResponse;

  factory VaultResponse.fromJson(Map<String, dynamic> json) =>
      _$VaultResponseFromJson(json);
}

@freezed
class VaultData with _$VaultData {
  const factory VaultData({
    required String id,
    required String status,
    required String webrtcRoomId,
    required String streamToken,
  }) = _VaultData;

  factory VaultData.fromJson(Map<String, dynamic> json) =>
      _$VaultDataFromJson(json);
}

@freezed
class WebRtcConfig with _$WebRtcConfig {
  const factory WebRtcConfig({
    required List<IceServer> iceServers,
  }) = _WebRtcConfig;

  factory WebRtcConfig.fromJson(Map<String, dynamic> json) =>
      _$WebRtcConfigFromJson(json);
}

@freezed
class IceServer with _$IceServer {
  const factory IceServer({
    required List<String> urls,
    String? username,
    String? credential,
  }) = _IceServer;

  factory IceServer.fromJson(Map<String, dynamic> json) =>
      _$IceServerFromJson(json);
}

@freezed
class VaultStatusResponse with _$VaultStatusResponse {
  const factory VaultStatusResponse({
    required String id,
    required String status,
    required DateTime startedAt,
    required DateTime lastHeartbeatAt,
    String? containerId,
    Map<String, dynamic>? metadata,
  }) = _VaultStatusResponse;

  factory VaultStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$VaultStatusResponseFromJson(json);
}

/// Geofence Response Models
@freezed
class GeofenceValidationResponse with _$GeofenceValidationResponse {
  const factory GeofenceValidationResponse({
    required bool isValid,
    String? validationReason,
    String? matchedZoneId,
    String? zoneName,
  }) = _GeofenceValidationResponse;

  factory GeofenceValidationResponse.fromJson(Map<String, dynamic> json) =>
      _$GeofenceValidationResponseFromJson(json);
}

/// Error Response Model
@freezed
class ErrorResponse with _$ErrorResponse {
  const factory ErrorResponse({
    required String error,
    String? message,
    String? errorCode,
    int? statusCode,
  }) = _ErrorResponse;

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);
}
