// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vault_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$VaultState {
  bool get isInitializing => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  bool get isTerminating => throw _privateConstructorUsedError;
  VaultData? get vault => throw _privateConstructorUsedError;
  WebRtcConfig? get webrtcConfig => throw _privateConstructorUsedError;
  VaultStatusResponse? get status => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  Timer? get heartbeatTimer => throw _privateConstructorUsedError;

  /// Create a copy of VaultState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VaultStateCopyWith<VaultState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VaultStateCopyWith<$Res> {
  factory $VaultStateCopyWith(
    VaultState value,
    $Res Function(VaultState) then,
  ) = _$VaultStateCopyWithImpl<$Res, VaultState>;
  @useResult
  $Res call({
    bool isInitializing,
    bool isActive,
    bool isTerminating,
    VaultData? vault,
    WebRtcConfig? webrtcConfig,
    VaultStatusResponse? status,
    String? error,
    Timer? heartbeatTimer,
  });

  $VaultDataCopyWith<$Res>? get vault;
  $WebRtcConfigCopyWith<$Res>? get webrtcConfig;
  $VaultStatusResponseCopyWith<$Res>? get status;
}

/// @nodoc
class _$VaultStateCopyWithImpl<$Res, $Val extends VaultState>
    implements $VaultStateCopyWith<$Res> {
  _$VaultStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VaultState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInitializing = null,
    Object? isActive = null,
    Object? isTerminating = null,
    Object? vault = freezed,
    Object? webrtcConfig = freezed,
    Object? status = freezed,
    Object? error = freezed,
    Object? heartbeatTimer = freezed,
  }) {
    return _then(
      _value.copyWith(
            isInitializing: null == isInitializing
                ? _value.isInitializing
                : isInitializing // ignore: cast_nullable_to_non_nullable
                      as bool,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            isTerminating: null == isTerminating
                ? _value.isTerminating
                : isTerminating // ignore: cast_nullable_to_non_nullable
                      as bool,
            vault: freezed == vault
                ? _value.vault
                : vault // ignore: cast_nullable_to_non_nullable
                      as VaultData?,
            webrtcConfig: freezed == webrtcConfig
                ? _value.webrtcConfig
                : webrtcConfig // ignore: cast_nullable_to_non_nullable
                      as WebRtcConfig?,
            status: freezed == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as VaultStatusResponse?,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            heartbeatTimer: freezed == heartbeatTimer
                ? _value.heartbeatTimer
                : heartbeatTimer // ignore: cast_nullable_to_non_nullable
                      as Timer?,
          )
          as $Val,
    );
  }

  /// Create a copy of VaultState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VaultDataCopyWith<$Res>? get vault {
    if (_value.vault == null) {
      return null;
    }

    return $VaultDataCopyWith<$Res>(_value.vault!, (value) {
      return _then(_value.copyWith(vault: value) as $Val);
    });
  }

  /// Create a copy of VaultState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WebRtcConfigCopyWith<$Res>? get webrtcConfig {
    if (_value.webrtcConfig == null) {
      return null;
    }

    return $WebRtcConfigCopyWith<$Res>(_value.webrtcConfig!, (value) {
      return _then(_value.copyWith(webrtcConfig: value) as $Val);
    });
  }

  /// Create a copy of VaultState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VaultStatusResponseCopyWith<$Res>? get status {
    if (_value.status == null) {
      return null;
    }

    return $VaultStatusResponseCopyWith<$Res>(_value.status!, (value) {
      return _then(_value.copyWith(status: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VaultStateImplCopyWith<$Res>
    implements $VaultStateCopyWith<$Res> {
  factory _$$VaultStateImplCopyWith(
    _$VaultStateImpl value,
    $Res Function(_$VaultStateImpl) then,
  ) = __$$VaultStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isInitializing,
    bool isActive,
    bool isTerminating,
    VaultData? vault,
    WebRtcConfig? webrtcConfig,
    VaultStatusResponse? status,
    String? error,
    Timer? heartbeatTimer,
  });

  @override
  $VaultDataCopyWith<$Res>? get vault;
  @override
  $WebRtcConfigCopyWith<$Res>? get webrtcConfig;
  @override
  $VaultStatusResponseCopyWith<$Res>? get status;
}

/// @nodoc
class __$$VaultStateImplCopyWithImpl<$Res>
    extends _$VaultStateCopyWithImpl<$Res, _$VaultStateImpl>
    implements _$$VaultStateImplCopyWith<$Res> {
  __$$VaultStateImplCopyWithImpl(
    _$VaultStateImpl _value,
    $Res Function(_$VaultStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VaultState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInitializing = null,
    Object? isActive = null,
    Object? isTerminating = null,
    Object? vault = freezed,
    Object? webrtcConfig = freezed,
    Object? status = freezed,
    Object? error = freezed,
    Object? heartbeatTimer = freezed,
  }) {
    return _then(
      _$VaultStateImpl(
        isInitializing: null == isInitializing
            ? _value.isInitializing
            : isInitializing // ignore: cast_nullable_to_non_nullable
                  as bool,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        isTerminating: null == isTerminating
            ? _value.isTerminating
            : isTerminating // ignore: cast_nullable_to_non_nullable
                  as bool,
        vault: freezed == vault
            ? _value.vault
            : vault // ignore: cast_nullable_to_non_nullable
                  as VaultData?,
        webrtcConfig: freezed == webrtcConfig
            ? _value.webrtcConfig
            : webrtcConfig // ignore: cast_nullable_to_non_nullable
                  as WebRtcConfig?,
        status: freezed == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as VaultStatusResponse?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        heartbeatTimer: freezed == heartbeatTimer
            ? _value.heartbeatTimer
            : heartbeatTimer // ignore: cast_nullable_to_non_nullable
                  as Timer?,
      ),
    );
  }
}

/// @nodoc

class _$VaultStateImpl implements _VaultState {
  const _$VaultStateImpl({
    this.isInitializing = false,
    this.isActive = false,
    this.isTerminating = false,
    this.vault,
    this.webrtcConfig,
    this.status,
    this.error,
    this.heartbeatTimer,
  });

  @override
  @JsonKey()
  final bool isInitializing;
  @override
  @JsonKey()
  final bool isActive;
  @override
  @JsonKey()
  final bool isTerminating;
  @override
  final VaultData? vault;
  @override
  final WebRtcConfig? webrtcConfig;
  @override
  final VaultStatusResponse? status;
  @override
  final String? error;
  @override
  final Timer? heartbeatTimer;

  @override
  String toString() {
    return 'VaultState(isInitializing: $isInitializing, isActive: $isActive, isTerminating: $isTerminating, vault: $vault, webrtcConfig: $webrtcConfig, status: $status, error: $error, heartbeatTimer: $heartbeatTimer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VaultStateImpl &&
            (identical(other.isInitializing, isInitializing) ||
                other.isInitializing == isInitializing) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.isTerminating, isTerminating) ||
                other.isTerminating == isTerminating) &&
            (identical(other.vault, vault) || other.vault == vault) &&
            (identical(other.webrtcConfig, webrtcConfig) ||
                other.webrtcConfig == webrtcConfig) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.heartbeatTimer, heartbeatTimer) ||
                other.heartbeatTimer == heartbeatTimer));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isInitializing,
    isActive,
    isTerminating,
    vault,
    webrtcConfig,
    status,
    error,
    heartbeatTimer,
  );

  /// Create a copy of VaultState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VaultStateImplCopyWith<_$VaultStateImpl> get copyWith =>
      __$$VaultStateImplCopyWithImpl<_$VaultStateImpl>(this, _$identity);
}

abstract class _VaultState implements VaultState {
  const factory _VaultState({
    final bool isInitializing,
    final bool isActive,
    final bool isTerminating,
    final VaultData? vault,
    final WebRtcConfig? webrtcConfig,
    final VaultStatusResponse? status,
    final String? error,
    final Timer? heartbeatTimer,
  }) = _$VaultStateImpl;

  @override
  bool get isInitializing;
  @override
  bool get isActive;
  @override
  bool get isTerminating;
  @override
  VaultData? get vault;
  @override
  WebRtcConfig? get webrtcConfig;
  @override
  VaultStatusResponse? get status;
  @override
  String? get error;
  @override
  Timer? get heartbeatTimer;

  /// Create a copy of VaultState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VaultStateImplCopyWith<_$VaultStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
