// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApiResponseImpl<T> _$$ApiResponseImplFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => _$ApiResponseImpl<T>(
  success: json['success'] as bool,
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
  error: json['error'] as String?,
  message: json['message'] as String?,
  errorCode: json['errorCode'] as String?,
);

Map<String, dynamic> _$$ApiResponseImplToJson<T>(
  _$ApiResponseImpl<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'success': instance.success,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
  'error': instance.error,
  'message': instance.message,
  'errorCode': instance.errorCode,
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);

_$LoginResponseImpl _$$LoginResponseImplFromJson(Map<String, dynamic> json) =>
    _$LoginResponseImpl(
      user: UserData.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      session: SessionData.fromJson(json['session'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$LoginResponseImplToJson(_$LoginResponseImpl instance) =>
    <String, dynamic>{
      'user': instance.user,
      'tokens': instance.tokens,
      'session': instance.session,
    };

_$AuthTokensImpl _$$AuthTokensImplFromJson(Map<String, dynamic> json) =>
    _$AuthTokensImpl(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      tokenType: json['tokenType'] as String,
    );

Map<String, dynamic> _$$AuthTokensImplToJson(_$AuthTokensImpl instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
      'tokenType': instance.tokenType,
    };

_$UserDataImpl _$$UserDataImplFromJson(Map<String, dynamic> json) =>
    _$UserDataImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      organization: json['organization'] as String?,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      mfaEnabled: json['mfaEnabled'] as bool,
    );

Map<String, dynamic> _$$UserDataImplToJson(_$UserDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'fullName': instance.fullName,
      'organization': instance.organization,
      'role': instance.role,
      'isActive': instance.isActive,
      'mfaEnabled': instance.mfaEnabled,
    };

_$SessionDataImpl _$$SessionDataImplFromJson(Map<String, dynamic> json) =>
    _$SessionDataImpl(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      ipAddress: json['ipAddress'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$$SessionDataImplToJson(_$SessionDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'ipAddress': instance.ipAddress,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };

_$VaultResponseImpl _$$VaultResponseImplFromJson(Map<String, dynamic> json) =>
    _$VaultResponseImpl(
      vault: VaultData.fromJson(json['vault'] as Map<String, dynamic>),
      webrtc: WebRtcConfig.fromJson(json['webrtc'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$VaultResponseImplToJson(_$VaultResponseImpl instance) =>
    <String, dynamic>{'vault': instance.vault, 'webrtc': instance.webrtc};

_$VaultDataImpl _$$VaultDataImplFromJson(Map<String, dynamic> json) =>
    _$VaultDataImpl(
      id: json['id'] as String,
      status: json['status'] as String,
      webrtcRoomId: json['webrtcRoomId'] as String,
      streamToken: json['streamToken'] as String,
    );

Map<String, dynamic> _$$VaultDataImplToJson(_$VaultDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'webrtcRoomId': instance.webrtcRoomId,
      'streamToken': instance.streamToken,
    };

_$WebRtcConfigImpl _$$WebRtcConfigImplFromJson(Map<String, dynamic> json) =>
    _$WebRtcConfigImpl(
      iceServers: (json['iceServers'] as List<dynamic>)
          .map((e) => IceServer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$WebRtcConfigImplToJson(_$WebRtcConfigImpl instance) =>
    <String, dynamic>{'iceServers': instance.iceServers};

_$IceServerImpl _$$IceServerImplFromJson(Map<String, dynamic> json) =>
    _$IceServerImpl(
      urls: (json['urls'] as List<dynamic>).map((e) => e as String).toList(),
      username: json['username'] as String?,
      credential: json['credential'] as String?,
    );

Map<String, dynamic> _$$IceServerImplToJson(_$IceServerImpl instance) =>
    <String, dynamic>{
      'urls': instance.urls,
      'username': instance.username,
      'credential': instance.credential,
    };

_$VaultStatusResponseImpl _$$VaultStatusResponseImplFromJson(
  Map<String, dynamic> json,
) => _$VaultStatusResponseImpl(
  id: json['id'] as String,
  status: json['status'] as String,
  startedAt: DateTime.parse(json['startedAt'] as String),
  lastHeartbeatAt: DateTime.parse(json['lastHeartbeatAt'] as String),
  containerId: json['containerId'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$$VaultStatusResponseImplToJson(
  _$VaultStatusResponseImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'startedAt': instance.startedAt.toIso8601String(),
  'lastHeartbeatAt': instance.lastHeartbeatAt.toIso8601String(),
  'containerId': instance.containerId,
  'metadata': instance.metadata,
};

_$GeofenceValidationResponseImpl _$$GeofenceValidationResponseImplFromJson(
  Map<String, dynamic> json,
) => _$GeofenceValidationResponseImpl(
  isValid: json['isValid'] as bool,
  validationReason: json['validationReason'] as String?,
  matchedZoneId: json['matchedZoneId'] as String?,
  zoneName: json['zoneName'] as String?,
);

Map<String, dynamic> _$$GeofenceValidationResponseImplToJson(
  _$GeofenceValidationResponseImpl instance,
) => <String, dynamic>{
  'isValid': instance.isValid,
  'validationReason': instance.validationReason,
  'matchedZoneId': instance.matchedZoneId,
  'zoneName': instance.zoneName,
};

_$ErrorResponseImpl _$$ErrorResponseImplFromJson(Map<String, dynamic> json) =>
    _$ErrorResponseImpl(
      error: json['error'] as String,
      message: json['message'] as String?,
      errorCode: json['errorCode'] as String?,
      statusCode: (json['statusCode'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ErrorResponseImplToJson(_$ErrorResponseImpl instance) =>
    <String, dynamic>{
      'error': instance.error,
      'message': instance.message,
      'errorCode': instance.errorCode,
      'statusCode': instance.statusCode,
    };
