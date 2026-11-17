// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ApiResponse<T> _$ApiResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object?) fromJsonT,
) {
  return _ApiResponse<T>.fromJson(json, fromJsonT);
}

/// @nodoc
mixin _$ApiResponse<T> {
  bool get success => throw _privateConstructorUsedError;
  T? get data => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  String? get errorCode => throw _privateConstructorUsedError;

  /// Serializes this ApiResponse to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      throw _privateConstructorUsedError;

  /// Create a copy of ApiResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApiResponseCopyWith<T, ApiResponse<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiResponseCopyWith<T, $Res> {
  factory $ApiResponseCopyWith(
    ApiResponse<T> value,
    $Res Function(ApiResponse<T>) then,
  ) = _$ApiResponseCopyWithImpl<T, $Res, ApiResponse<T>>;
  @useResult
  $Res call({
    bool success,
    T? data,
    String? error,
    String? message,
    String? errorCode,
  });
}

/// @nodoc
class _$ApiResponseCopyWithImpl<T, $Res, $Val extends ApiResponse<T>>
    implements $ApiResponseCopyWith<T, $Res> {
  _$ApiResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApiResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? data = freezed,
    Object? error = freezed,
    Object? message = freezed,
    Object? errorCode = freezed,
  }) {
    return _then(
      _value.copyWith(
            success: null == success
                ? _value.success
                : success // ignore: cast_nullable_to_non_nullable
                      as bool,
            data: freezed == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as T?,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            message: freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String?,
            errorCode: freezed == errorCode
                ? _value.errorCode
                : errorCode // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ApiResponseImplCopyWith<T, $Res>
    implements $ApiResponseCopyWith<T, $Res> {
  factory _$$ApiResponseImplCopyWith(
    _$ApiResponseImpl<T> value,
    $Res Function(_$ApiResponseImpl<T>) then,
  ) = __$$ApiResponseImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({
    bool success,
    T? data,
    String? error,
    String? message,
    String? errorCode,
  });
}

/// @nodoc
class __$$ApiResponseImplCopyWithImpl<T, $Res>
    extends _$ApiResponseCopyWithImpl<T, $Res, _$ApiResponseImpl<T>>
    implements _$$ApiResponseImplCopyWith<T, $Res> {
  __$$ApiResponseImplCopyWithImpl(
    _$ApiResponseImpl<T> _value,
    $Res Function(_$ApiResponseImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of ApiResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? data = freezed,
    Object? error = freezed,
    Object? message = freezed,
    Object? errorCode = freezed,
  }) {
    return _then(
      _$ApiResponseImpl<T>(
        success: null == success
            ? _value.success
            : success // ignore: cast_nullable_to_non_nullable
                  as bool,
        data: freezed == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as T?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
        errorCode: freezed == errorCode
            ? _value.errorCode
            : errorCode // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)
class _$ApiResponseImpl<T> implements _ApiResponse<T> {
  const _$ApiResponseImpl({
    required this.success,
    this.data,
    this.error,
    this.message,
    this.errorCode,
  });

  factory _$ApiResponseImpl.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$$ApiResponseImplFromJson(json, fromJsonT);

  @override
  final bool success;
  @override
  final T? data;
  @override
  final String? error;
  @override
  final String? message;
  @override
  final String? errorCode;

  @override
  String toString() {
    return 'ApiResponse<$T>(success: $success, data: $data, error: $error, message: $message, errorCode: $errorCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiResponseImpl<T> &&
            (identical(other.success, success) || other.success == success) &&
            const DeepCollectionEquality().equals(other.data, data) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.errorCode, errorCode) ||
                other.errorCode == errorCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    success,
    const DeepCollectionEquality().hash(data),
    error,
    message,
    errorCode,
  );

  /// Create a copy of ApiResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiResponseImplCopyWith<T, _$ApiResponseImpl<T>> get copyWith =>
      __$$ApiResponseImplCopyWithImpl<T, _$ApiResponseImpl<T>>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return _$$ApiResponseImplToJson<T>(this, toJsonT);
  }
}

abstract class _ApiResponse<T> implements ApiResponse<T> {
  const factory _ApiResponse({
    required final bool success,
    final T? data,
    final String? error,
    final String? message,
    final String? errorCode,
  }) = _$ApiResponseImpl<T>;

  factory _ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) = _$ApiResponseImpl<T>.fromJson;

  @override
  bool get success;
  @override
  T? get data;
  @override
  String? get error;
  @override
  String? get message;
  @override
  String? get errorCode;

  /// Create a copy of ApiResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiResponseImplCopyWith<T, _$ApiResponseImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) {
  return _LoginResponse.fromJson(json);
}

/// @nodoc
mixin _$LoginResponse {
  UserData get user => throw _privateConstructorUsedError;
  AuthTokens get tokens => throw _privateConstructorUsedError;
  SessionData get session => throw _privateConstructorUsedError;

  /// Serializes this LoginResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoginResponseCopyWith<LoginResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoginResponseCopyWith<$Res> {
  factory $LoginResponseCopyWith(
    LoginResponse value,
    $Res Function(LoginResponse) then,
  ) = _$LoginResponseCopyWithImpl<$Res, LoginResponse>;
  @useResult
  $Res call({UserData user, AuthTokens tokens, SessionData session});

  $UserDataCopyWith<$Res> get user;
  $AuthTokensCopyWith<$Res> get tokens;
  $SessionDataCopyWith<$Res> get session;
}

/// @nodoc
class _$LoginResponseCopyWithImpl<$Res, $Val extends LoginResponse>
    implements $LoginResponseCopyWith<$Res> {
  _$LoginResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? tokens = null,
    Object? session = null,
  }) {
    return _then(
      _value.copyWith(
            user: null == user
                ? _value.user
                : user // ignore: cast_nullable_to_non_nullable
                      as UserData,
            tokens: null == tokens
                ? _value.tokens
                : tokens // ignore: cast_nullable_to_non_nullable
                      as AuthTokens,
            session: null == session
                ? _value.session
                : session // ignore: cast_nullable_to_non_nullable
                      as SessionData,
          )
          as $Val,
    );
  }

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserDataCopyWith<$Res> get user {
    return $UserDataCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthTokensCopyWith<$Res> get tokens {
    return $AuthTokensCopyWith<$Res>(_value.tokens, (value) {
      return _then(_value.copyWith(tokens: value) as $Val);
    });
  }

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SessionDataCopyWith<$Res> get session {
    return $SessionDataCopyWith<$Res>(_value.session, (value) {
      return _then(_value.copyWith(session: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LoginResponseImplCopyWith<$Res>
    implements $LoginResponseCopyWith<$Res> {
  factory _$$LoginResponseImplCopyWith(
    _$LoginResponseImpl value,
    $Res Function(_$LoginResponseImpl) then,
  ) = __$$LoginResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({UserData user, AuthTokens tokens, SessionData session});

  @override
  $UserDataCopyWith<$Res> get user;
  @override
  $AuthTokensCopyWith<$Res> get tokens;
  @override
  $SessionDataCopyWith<$Res> get session;
}

/// @nodoc
class __$$LoginResponseImplCopyWithImpl<$Res>
    extends _$LoginResponseCopyWithImpl<$Res, _$LoginResponseImpl>
    implements _$$LoginResponseImplCopyWith<$Res> {
  __$$LoginResponseImplCopyWithImpl(
    _$LoginResponseImpl _value,
    $Res Function(_$LoginResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? tokens = null,
    Object? session = null,
  }) {
    return _then(
      _$LoginResponseImpl(
        user: null == user
            ? _value.user
            : user // ignore: cast_nullable_to_non_nullable
                  as UserData,
        tokens: null == tokens
            ? _value.tokens
            : tokens // ignore: cast_nullable_to_non_nullable
                  as AuthTokens,
        session: null == session
            ? _value.session
            : session // ignore: cast_nullable_to_non_nullable
                  as SessionData,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LoginResponseImpl implements _LoginResponse {
  const _$LoginResponseImpl({
    required this.user,
    required this.tokens,
    required this.session,
  });

  factory _$LoginResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoginResponseImplFromJson(json);

  @override
  final UserData user;
  @override
  final AuthTokens tokens;
  @override
  final SessionData session;

  @override
  String toString() {
    return 'LoginResponse(user: $user, tokens: $tokens, session: $session)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginResponseImpl &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.tokens, tokens) || other.tokens == tokens) &&
            (identical(other.session, session) || other.session == session));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, user, tokens, session);

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginResponseImplCopyWith<_$LoginResponseImpl> get copyWith =>
      __$$LoginResponseImplCopyWithImpl<_$LoginResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LoginResponseImplToJson(this);
  }
}

abstract class _LoginResponse implements LoginResponse {
  const factory _LoginResponse({
    required final UserData user,
    required final AuthTokens tokens,
    required final SessionData session,
  }) = _$LoginResponseImpl;

  factory _LoginResponse.fromJson(Map<String, dynamic> json) =
      _$LoginResponseImpl.fromJson;

  @override
  UserData get user;
  @override
  AuthTokens get tokens;
  @override
  SessionData get session;

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginResponseImplCopyWith<_$LoginResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) {
  return _AuthTokens.fromJson(json);
}

/// @nodoc
mixin _$AuthTokens {
  String get accessToken => throw _privateConstructorUsedError;
  String get refreshToken => throw _privateConstructorUsedError;
  int get expiresIn => throw _privateConstructorUsedError;
  String get tokenType => throw _privateConstructorUsedError;

  /// Serializes this AuthTokens to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthTokensCopyWith<AuthTokens> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthTokensCopyWith<$Res> {
  factory $AuthTokensCopyWith(
    AuthTokens value,
    $Res Function(AuthTokens) then,
  ) = _$AuthTokensCopyWithImpl<$Res, AuthTokens>;
  @useResult
  $Res call({
    String accessToken,
    String refreshToken,
    int expiresIn,
    String tokenType,
  });
}

/// @nodoc
class _$AuthTokensCopyWithImpl<$Res, $Val extends AuthTokens>
    implements $AuthTokensCopyWith<$Res> {
  _$AuthTokensCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? expiresIn = null,
    Object? tokenType = null,
  }) {
    return _then(
      _value.copyWith(
            accessToken: null == accessToken
                ? _value.accessToken
                : accessToken // ignore: cast_nullable_to_non_nullable
                      as String,
            refreshToken: null == refreshToken
                ? _value.refreshToken
                : refreshToken // ignore: cast_nullable_to_non_nullable
                      as String,
            expiresIn: null == expiresIn
                ? _value.expiresIn
                : expiresIn // ignore: cast_nullable_to_non_nullable
                      as int,
            tokenType: null == tokenType
                ? _value.tokenType
                : tokenType // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthTokensImplCopyWith<$Res>
    implements $AuthTokensCopyWith<$Res> {
  factory _$$AuthTokensImplCopyWith(
    _$AuthTokensImpl value,
    $Res Function(_$AuthTokensImpl) then,
  ) = __$$AuthTokensImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String accessToken,
    String refreshToken,
    int expiresIn,
    String tokenType,
  });
}

/// @nodoc
class __$$AuthTokensImplCopyWithImpl<$Res>
    extends _$AuthTokensCopyWithImpl<$Res, _$AuthTokensImpl>
    implements _$$AuthTokensImplCopyWith<$Res> {
  __$$AuthTokensImplCopyWithImpl(
    _$AuthTokensImpl _value,
    $Res Function(_$AuthTokensImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? expiresIn = null,
    Object? tokenType = null,
  }) {
    return _then(
      _$AuthTokensImpl(
        accessToken: null == accessToken
            ? _value.accessToken
            : accessToken // ignore: cast_nullable_to_non_nullable
                  as String,
        refreshToken: null == refreshToken
            ? _value.refreshToken
            : refreshToken // ignore: cast_nullable_to_non_nullable
                  as String,
        expiresIn: null == expiresIn
            ? _value.expiresIn
            : expiresIn // ignore: cast_nullable_to_non_nullable
                  as int,
        tokenType: null == tokenType
            ? _value.tokenType
            : tokenType // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthTokensImpl implements _AuthTokens {
  const _$AuthTokensImpl({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory _$AuthTokensImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthTokensImplFromJson(json);

  @override
  final String accessToken;
  @override
  final String refreshToken;
  @override
  final int expiresIn;
  @override
  final String tokenType;

  @override
  String toString() {
    return 'AuthTokens(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, tokenType: $tokenType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthTokensImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken) &&
            (identical(other.expiresIn, expiresIn) ||
                other.expiresIn == expiresIn) &&
            (identical(other.tokenType, tokenType) ||
                other.tokenType == tokenType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, accessToken, refreshToken, expiresIn, tokenType);

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthTokensImplCopyWith<_$AuthTokensImpl> get copyWith =>
      __$$AuthTokensImplCopyWithImpl<_$AuthTokensImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthTokensImplToJson(this);
  }
}

abstract class _AuthTokens implements AuthTokens {
  const factory _AuthTokens({
    required final String accessToken,
    required final String refreshToken,
    required final int expiresIn,
    required final String tokenType,
  }) = _$AuthTokensImpl;

  factory _AuthTokens.fromJson(Map<String, dynamic> json) =
      _$AuthTokensImpl.fromJson;

  @override
  String get accessToken;
  @override
  String get refreshToken;
  @override
  int get expiresIn;
  @override
  String get tokenType;

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthTokensImplCopyWith<_$AuthTokensImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserData _$UserDataFromJson(Map<String, dynamic> json) {
  return _UserData.fromJson(json);
}

/// @nodoc
mixin _$UserData {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get fullName => throw _privateConstructorUsedError;
  String? get organization => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  bool get mfaEnabled => throw _privateConstructorUsedError;

  /// Serializes this UserData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserDataCopyWith<UserData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserDataCopyWith<$Res> {
  factory $UserDataCopyWith(UserData value, $Res Function(UserData) then) =
      _$UserDataCopyWithImpl<$Res, UserData>;
  @useResult
  $Res call({
    String id,
    String email,
    String fullName,
    String? organization,
    String role,
    bool isActive,
    bool mfaEnabled,
  });
}

/// @nodoc
class _$UserDataCopyWithImpl<$Res, $Val extends UserData>
    implements $UserDataCopyWith<$Res> {
  _$UserDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? fullName = null,
    Object? organization = freezed,
    Object? role = null,
    Object? isActive = null,
    Object? mfaEnabled = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            fullName: null == fullName
                ? _value.fullName
                : fullName // ignore: cast_nullable_to_non_nullable
                      as String,
            organization: freezed == organization
                ? _value.organization
                : organization // ignore: cast_nullable_to_non_nullable
                      as String?,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            mfaEnabled: null == mfaEnabled
                ? _value.mfaEnabled
                : mfaEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserDataImplCopyWith<$Res>
    implements $UserDataCopyWith<$Res> {
  factory _$$UserDataImplCopyWith(
    _$UserDataImpl value,
    $Res Function(_$UserDataImpl) then,
  ) = __$$UserDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String email,
    String fullName,
    String? organization,
    String role,
    bool isActive,
    bool mfaEnabled,
  });
}

/// @nodoc
class __$$UserDataImplCopyWithImpl<$Res>
    extends _$UserDataCopyWithImpl<$Res, _$UserDataImpl>
    implements _$$UserDataImplCopyWith<$Res> {
  __$$UserDataImplCopyWithImpl(
    _$UserDataImpl _value,
    $Res Function(_$UserDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? fullName = null,
    Object? organization = freezed,
    Object? role = null,
    Object? isActive = null,
    Object? mfaEnabled = null,
  }) {
    return _then(
      _$UserDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        fullName: null == fullName
            ? _value.fullName
            : fullName // ignore: cast_nullable_to_non_nullable
                  as String,
        organization: freezed == organization
            ? _value.organization
            : organization // ignore: cast_nullable_to_non_nullable
                  as String?,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        mfaEnabled: null == mfaEnabled
            ? _value.mfaEnabled
            : mfaEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserDataImpl implements _UserData {
  const _$UserDataImpl({
    required this.id,
    required this.email,
    required this.fullName,
    this.organization,
    required this.role,
    required this.isActive,
    required this.mfaEnabled,
  });

  factory _$UserDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserDataImplFromJson(json);

  @override
  final String id;
  @override
  final String email;
  @override
  final String fullName;
  @override
  final String? organization;
  @override
  final String role;
  @override
  final bool isActive;
  @override
  final bool mfaEnabled;

  @override
  String toString() {
    return 'UserData(id: $id, email: $email, fullName: $fullName, organization: $organization, role: $role, isActive: $isActive, mfaEnabled: $mfaEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.organization, organization) ||
                other.organization == organization) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.mfaEnabled, mfaEnabled) ||
                other.mfaEnabled == mfaEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    email,
    fullName,
    organization,
    role,
    isActive,
    mfaEnabled,
  );

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserDataImplCopyWith<_$UserDataImpl> get copyWith =>
      __$$UserDataImplCopyWithImpl<_$UserDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserDataImplToJson(this);
  }
}

abstract class _UserData implements UserData {
  const factory _UserData({
    required final String id,
    required final String email,
    required final String fullName,
    final String? organization,
    required final String role,
    required final bool isActive,
    required final bool mfaEnabled,
  }) = _$UserDataImpl;

  factory _UserData.fromJson(Map<String, dynamic> json) =
      _$UserDataImpl.fromJson;

  @override
  String get id;
  @override
  String get email;
  @override
  String get fullName;
  @override
  String? get organization;
  @override
  String get role;
  @override
  bool get isActive;
  @override
  bool get mfaEnabled;

  /// Create a copy of UserData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserDataImplCopyWith<_$UserDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SessionData _$SessionDataFromJson(Map<String, dynamic> json) {
  return _SessionData.fromJson(json);
}

/// @nodoc
mixin _$SessionData {
  String get id => throw _privateConstructorUsedError;
  String? get deviceId => throw _privateConstructorUsedError;
  String? get deviceName => throw _privateConstructorUsedError;
  String? get ipAddress => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;

  /// Serializes this SessionData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SessionData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionDataCopyWith<SessionData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionDataCopyWith<$Res> {
  factory $SessionDataCopyWith(
    SessionData value,
    $Res Function(SessionData) then,
  ) = _$SessionDataCopyWithImpl<$Res, SessionData>;
  @useResult
  $Res call({
    String id,
    String? deviceId,
    String? deviceName,
    String? ipAddress,
    DateTime expiresAt,
  });
}

/// @nodoc
class _$SessionDataCopyWithImpl<$Res, $Val extends SessionData>
    implements $SessionDataCopyWith<$Res> {
  _$SessionDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceId = freezed,
    Object? deviceName = freezed,
    Object? ipAddress = freezed,
    Object? expiresAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            deviceId: freezed == deviceId
                ? _value.deviceId
                : deviceId // ignore: cast_nullable_to_non_nullable
                      as String?,
            deviceName: freezed == deviceName
                ? _value.deviceName
                : deviceName // ignore: cast_nullable_to_non_nullable
                      as String?,
            ipAddress: freezed == ipAddress
                ? _value.ipAddress
                : ipAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            expiresAt: null == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SessionDataImplCopyWith<$Res>
    implements $SessionDataCopyWith<$Res> {
  factory _$$SessionDataImplCopyWith(
    _$SessionDataImpl value,
    $Res Function(_$SessionDataImpl) then,
  ) = __$$SessionDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? deviceId,
    String? deviceName,
    String? ipAddress,
    DateTime expiresAt,
  });
}

/// @nodoc
class __$$SessionDataImplCopyWithImpl<$Res>
    extends _$SessionDataCopyWithImpl<$Res, _$SessionDataImpl>
    implements _$$SessionDataImplCopyWith<$Res> {
  __$$SessionDataImplCopyWithImpl(
    _$SessionDataImpl _value,
    $Res Function(_$SessionDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SessionData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceId = freezed,
    Object? deviceName = freezed,
    Object? ipAddress = freezed,
    Object? expiresAt = null,
  }) {
    return _then(
      _$SessionDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: freezed == deviceId
            ? _value.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        deviceName: freezed == deviceName
            ? _value.deviceName
            : deviceName // ignore: cast_nullable_to_non_nullable
                  as String?,
        ipAddress: freezed == ipAddress
            ? _value.ipAddress
            : ipAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        expiresAt: null == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionDataImpl implements _SessionData {
  const _$SessionDataImpl({
    required this.id,
    this.deviceId,
    this.deviceName,
    this.ipAddress,
    required this.expiresAt,
  });

  factory _$SessionDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionDataImplFromJson(json);

  @override
  final String id;
  @override
  final String? deviceId;
  @override
  final String? deviceName;
  @override
  final String? ipAddress;
  @override
  final DateTime expiresAt;

  @override
  String toString() {
    return 'SessionData(id: $id, deviceId: $deviceId, deviceName: $deviceName, ipAddress: $ipAddress, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.deviceName, deviceName) ||
                other.deviceName == deviceName) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, deviceId, deviceName, ipAddress, expiresAt);

  /// Create a copy of SessionData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionDataImplCopyWith<_$SessionDataImpl> get copyWith =>
      __$$SessionDataImplCopyWithImpl<_$SessionDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionDataImplToJson(this);
  }
}

abstract class _SessionData implements SessionData {
  const factory _SessionData({
    required final String id,
    final String? deviceId,
    final String? deviceName,
    final String? ipAddress,
    required final DateTime expiresAt,
  }) = _$SessionDataImpl;

  factory _SessionData.fromJson(Map<String, dynamic> json) =
      _$SessionDataImpl.fromJson;

  @override
  String get id;
  @override
  String? get deviceId;
  @override
  String? get deviceName;
  @override
  String? get ipAddress;
  @override
  DateTime get expiresAt;

  /// Create a copy of SessionData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionDataImplCopyWith<_$SessionDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VaultResponse _$VaultResponseFromJson(Map<String, dynamic> json) {
  return _VaultResponse.fromJson(json);
}

/// @nodoc
mixin _$VaultResponse {
  VaultData get vault => throw _privateConstructorUsedError;
  WebRtcConfig get webrtc => throw _privateConstructorUsedError;

  /// Serializes this VaultResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VaultResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VaultResponseCopyWith<VaultResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VaultResponseCopyWith<$Res> {
  factory $VaultResponseCopyWith(
    VaultResponse value,
    $Res Function(VaultResponse) then,
  ) = _$VaultResponseCopyWithImpl<$Res, VaultResponse>;
  @useResult
  $Res call({VaultData vault, WebRtcConfig webrtc});

  $VaultDataCopyWith<$Res> get vault;
  $WebRtcConfigCopyWith<$Res> get webrtc;
}

/// @nodoc
class _$VaultResponseCopyWithImpl<$Res, $Val extends VaultResponse>
    implements $VaultResponseCopyWith<$Res> {
  _$VaultResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VaultResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? vault = null, Object? webrtc = null}) {
    return _then(
      _value.copyWith(
            vault: null == vault
                ? _value.vault
                : vault // ignore: cast_nullable_to_non_nullable
                      as VaultData,
            webrtc: null == webrtc
                ? _value.webrtc
                : webrtc // ignore: cast_nullable_to_non_nullable
                      as WebRtcConfig,
          )
          as $Val,
    );
  }

  /// Create a copy of VaultResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VaultDataCopyWith<$Res> get vault {
    return $VaultDataCopyWith<$Res>(_value.vault, (value) {
      return _then(_value.copyWith(vault: value) as $Val);
    });
  }

  /// Create a copy of VaultResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WebRtcConfigCopyWith<$Res> get webrtc {
    return $WebRtcConfigCopyWith<$Res>(_value.webrtc, (value) {
      return _then(_value.copyWith(webrtc: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VaultResponseImplCopyWith<$Res>
    implements $VaultResponseCopyWith<$Res> {
  factory _$$VaultResponseImplCopyWith(
    _$VaultResponseImpl value,
    $Res Function(_$VaultResponseImpl) then,
  ) = __$$VaultResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({VaultData vault, WebRtcConfig webrtc});

  @override
  $VaultDataCopyWith<$Res> get vault;
  @override
  $WebRtcConfigCopyWith<$Res> get webrtc;
}

/// @nodoc
class __$$VaultResponseImplCopyWithImpl<$Res>
    extends _$VaultResponseCopyWithImpl<$Res, _$VaultResponseImpl>
    implements _$$VaultResponseImplCopyWith<$Res> {
  __$$VaultResponseImplCopyWithImpl(
    _$VaultResponseImpl _value,
    $Res Function(_$VaultResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VaultResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? vault = null, Object? webrtc = null}) {
    return _then(
      _$VaultResponseImpl(
        vault: null == vault
            ? _value.vault
            : vault // ignore: cast_nullable_to_non_nullable
                  as VaultData,
        webrtc: null == webrtc
            ? _value.webrtc
            : webrtc // ignore: cast_nullable_to_non_nullable
                  as WebRtcConfig,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VaultResponseImpl implements _VaultResponse {
  const _$VaultResponseImpl({required this.vault, required this.webrtc});

  factory _$VaultResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$VaultResponseImplFromJson(json);

  @override
  final VaultData vault;
  @override
  final WebRtcConfig webrtc;

  @override
  String toString() {
    return 'VaultResponse(vault: $vault, webrtc: $webrtc)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VaultResponseImpl &&
            (identical(other.vault, vault) || other.vault == vault) &&
            (identical(other.webrtc, webrtc) || other.webrtc == webrtc));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, vault, webrtc);

  /// Create a copy of VaultResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VaultResponseImplCopyWith<_$VaultResponseImpl> get copyWith =>
      __$$VaultResponseImplCopyWithImpl<_$VaultResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VaultResponseImplToJson(this);
  }
}

abstract class _VaultResponse implements VaultResponse {
  const factory _VaultResponse({
    required final VaultData vault,
    required final WebRtcConfig webrtc,
  }) = _$VaultResponseImpl;

  factory _VaultResponse.fromJson(Map<String, dynamic> json) =
      _$VaultResponseImpl.fromJson;

  @override
  VaultData get vault;
  @override
  WebRtcConfig get webrtc;

  /// Create a copy of VaultResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VaultResponseImplCopyWith<_$VaultResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VaultData _$VaultDataFromJson(Map<String, dynamic> json) {
  return _VaultData.fromJson(json);
}

/// @nodoc
mixin _$VaultData {
  String get id => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get webrtcRoomId => throw _privateConstructorUsedError;
  String get streamToken => throw _privateConstructorUsedError;

  /// Serializes this VaultData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VaultData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VaultDataCopyWith<VaultData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VaultDataCopyWith<$Res> {
  factory $VaultDataCopyWith(VaultData value, $Res Function(VaultData) then) =
      _$VaultDataCopyWithImpl<$Res, VaultData>;
  @useResult
  $Res call({
    String id,
    String status,
    String webrtcRoomId,
    String streamToken,
  });
}

/// @nodoc
class _$VaultDataCopyWithImpl<$Res, $Val extends VaultData>
    implements $VaultDataCopyWith<$Res> {
  _$VaultDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VaultData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? webrtcRoomId = null,
    Object? streamToken = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            webrtcRoomId: null == webrtcRoomId
                ? _value.webrtcRoomId
                : webrtcRoomId // ignore: cast_nullable_to_non_nullable
                      as String,
            streamToken: null == streamToken
                ? _value.streamToken
                : streamToken // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VaultDataImplCopyWith<$Res>
    implements $VaultDataCopyWith<$Res> {
  factory _$$VaultDataImplCopyWith(
    _$VaultDataImpl value,
    $Res Function(_$VaultDataImpl) then,
  ) = __$$VaultDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String status,
    String webrtcRoomId,
    String streamToken,
  });
}

/// @nodoc
class __$$VaultDataImplCopyWithImpl<$Res>
    extends _$VaultDataCopyWithImpl<$Res, _$VaultDataImpl>
    implements _$$VaultDataImplCopyWith<$Res> {
  __$$VaultDataImplCopyWithImpl(
    _$VaultDataImpl _value,
    $Res Function(_$VaultDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VaultData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? webrtcRoomId = null,
    Object? streamToken = null,
  }) {
    return _then(
      _$VaultDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        webrtcRoomId: null == webrtcRoomId
            ? _value.webrtcRoomId
            : webrtcRoomId // ignore: cast_nullable_to_non_nullable
                  as String,
        streamToken: null == streamToken
            ? _value.streamToken
            : streamToken // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VaultDataImpl implements _VaultData {
  const _$VaultDataImpl({
    required this.id,
    required this.status,
    required this.webrtcRoomId,
    required this.streamToken,
  });

  factory _$VaultDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$VaultDataImplFromJson(json);

  @override
  final String id;
  @override
  final String status;
  @override
  final String webrtcRoomId;
  @override
  final String streamToken;

  @override
  String toString() {
    return 'VaultData(id: $id, status: $status, webrtcRoomId: $webrtcRoomId, streamToken: $streamToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VaultDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.webrtcRoomId, webrtcRoomId) ||
                other.webrtcRoomId == webrtcRoomId) &&
            (identical(other.streamToken, streamToken) ||
                other.streamToken == streamToken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, status, webrtcRoomId, streamToken);

  /// Create a copy of VaultData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VaultDataImplCopyWith<_$VaultDataImpl> get copyWith =>
      __$$VaultDataImplCopyWithImpl<_$VaultDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VaultDataImplToJson(this);
  }
}

abstract class _VaultData implements VaultData {
  const factory _VaultData({
    required final String id,
    required final String status,
    required final String webrtcRoomId,
    required final String streamToken,
  }) = _$VaultDataImpl;

  factory _VaultData.fromJson(Map<String, dynamic> json) =
      _$VaultDataImpl.fromJson;

  @override
  String get id;
  @override
  String get status;
  @override
  String get webrtcRoomId;
  @override
  String get streamToken;

  /// Create a copy of VaultData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VaultDataImplCopyWith<_$VaultDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WebRtcConfig _$WebRtcConfigFromJson(Map<String, dynamic> json) {
  return _WebRtcConfig.fromJson(json);
}

/// @nodoc
mixin _$WebRtcConfig {
  List<IceServer> get iceServers => throw _privateConstructorUsedError;

  /// Serializes this WebRtcConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WebRtcConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WebRtcConfigCopyWith<WebRtcConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WebRtcConfigCopyWith<$Res> {
  factory $WebRtcConfigCopyWith(
    WebRtcConfig value,
    $Res Function(WebRtcConfig) then,
  ) = _$WebRtcConfigCopyWithImpl<$Res, WebRtcConfig>;
  @useResult
  $Res call({List<IceServer> iceServers});
}

/// @nodoc
class _$WebRtcConfigCopyWithImpl<$Res, $Val extends WebRtcConfig>
    implements $WebRtcConfigCopyWith<$Res> {
  _$WebRtcConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WebRtcConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? iceServers = null}) {
    return _then(
      _value.copyWith(
            iceServers: null == iceServers
                ? _value.iceServers
                : iceServers // ignore: cast_nullable_to_non_nullable
                      as List<IceServer>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WebRtcConfigImplCopyWith<$Res>
    implements $WebRtcConfigCopyWith<$Res> {
  factory _$$WebRtcConfigImplCopyWith(
    _$WebRtcConfigImpl value,
    $Res Function(_$WebRtcConfigImpl) then,
  ) = __$$WebRtcConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<IceServer> iceServers});
}

/// @nodoc
class __$$WebRtcConfigImplCopyWithImpl<$Res>
    extends _$WebRtcConfigCopyWithImpl<$Res, _$WebRtcConfigImpl>
    implements _$$WebRtcConfigImplCopyWith<$Res> {
  __$$WebRtcConfigImplCopyWithImpl(
    _$WebRtcConfigImpl _value,
    $Res Function(_$WebRtcConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WebRtcConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? iceServers = null}) {
    return _then(
      _$WebRtcConfigImpl(
        iceServers: null == iceServers
            ? _value._iceServers
            : iceServers // ignore: cast_nullable_to_non_nullable
                  as List<IceServer>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WebRtcConfigImpl implements _WebRtcConfig {
  const _$WebRtcConfigImpl({required final List<IceServer> iceServers})
    : _iceServers = iceServers;

  factory _$WebRtcConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$WebRtcConfigImplFromJson(json);

  final List<IceServer> _iceServers;
  @override
  List<IceServer> get iceServers {
    if (_iceServers is EqualUnmodifiableListView) return _iceServers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_iceServers);
  }

  @override
  String toString() {
    return 'WebRtcConfig(iceServers: $iceServers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WebRtcConfigImpl &&
            const DeepCollectionEquality().equals(
              other._iceServers,
              _iceServers,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_iceServers),
  );

  /// Create a copy of WebRtcConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WebRtcConfigImplCopyWith<_$WebRtcConfigImpl> get copyWith =>
      __$$WebRtcConfigImplCopyWithImpl<_$WebRtcConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WebRtcConfigImplToJson(this);
  }
}

abstract class _WebRtcConfig implements WebRtcConfig {
  const factory _WebRtcConfig({required final List<IceServer> iceServers}) =
      _$WebRtcConfigImpl;

  factory _WebRtcConfig.fromJson(Map<String, dynamic> json) =
      _$WebRtcConfigImpl.fromJson;

  @override
  List<IceServer> get iceServers;

  /// Create a copy of WebRtcConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WebRtcConfigImplCopyWith<_$WebRtcConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IceServer _$IceServerFromJson(Map<String, dynamic> json) {
  return _IceServer.fromJson(json);
}

/// @nodoc
mixin _$IceServer {
  List<String> get urls => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  String? get credential => throw _privateConstructorUsedError;

  /// Serializes this IceServer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IceServer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IceServerCopyWith<IceServer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IceServerCopyWith<$Res> {
  factory $IceServerCopyWith(IceServer value, $Res Function(IceServer) then) =
      _$IceServerCopyWithImpl<$Res, IceServer>;
  @useResult
  $Res call({List<String> urls, String? username, String? credential});
}

/// @nodoc
class _$IceServerCopyWithImpl<$Res, $Val extends IceServer>
    implements $IceServerCopyWith<$Res> {
  _$IceServerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IceServer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? urls = null,
    Object? username = freezed,
    Object? credential = freezed,
  }) {
    return _then(
      _value.copyWith(
            urls: null == urls
                ? _value.urls
                : urls // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            username: freezed == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String?,
            credential: freezed == credential
                ? _value.credential
                : credential // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$IceServerImplCopyWith<$Res>
    implements $IceServerCopyWith<$Res> {
  factory _$$IceServerImplCopyWith(
    _$IceServerImpl value,
    $Res Function(_$IceServerImpl) then,
  ) = __$$IceServerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> urls, String? username, String? credential});
}

/// @nodoc
class __$$IceServerImplCopyWithImpl<$Res>
    extends _$IceServerCopyWithImpl<$Res, _$IceServerImpl>
    implements _$$IceServerImplCopyWith<$Res> {
  __$$IceServerImplCopyWithImpl(
    _$IceServerImpl _value,
    $Res Function(_$IceServerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IceServer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? urls = null,
    Object? username = freezed,
    Object? credential = freezed,
  }) {
    return _then(
      _$IceServerImpl(
        urls: null == urls
            ? _value._urls
            : urls // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        username: freezed == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String?,
        credential: freezed == credential
            ? _value.credential
            : credential // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IceServerImpl implements _IceServer {
  const _$IceServerImpl({
    required final List<String> urls,
    this.username,
    this.credential,
  }) : _urls = urls;

  factory _$IceServerImpl.fromJson(Map<String, dynamic> json) =>
      _$$IceServerImplFromJson(json);

  final List<String> _urls;
  @override
  List<String> get urls {
    if (_urls is EqualUnmodifiableListView) return _urls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_urls);
  }

  @override
  final String? username;
  @override
  final String? credential;

  @override
  String toString() {
    return 'IceServer(urls: $urls, username: $username, credential: $credential)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IceServerImpl &&
            const DeepCollectionEquality().equals(other._urls, _urls) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.credential, credential) ||
                other.credential == credential));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_urls),
    username,
    credential,
  );

  /// Create a copy of IceServer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IceServerImplCopyWith<_$IceServerImpl> get copyWith =>
      __$$IceServerImplCopyWithImpl<_$IceServerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IceServerImplToJson(this);
  }
}

abstract class _IceServer implements IceServer {
  const factory _IceServer({
    required final List<String> urls,
    final String? username,
    final String? credential,
  }) = _$IceServerImpl;

  factory _IceServer.fromJson(Map<String, dynamic> json) =
      _$IceServerImpl.fromJson;

  @override
  List<String> get urls;
  @override
  String? get username;
  @override
  String? get credential;

  /// Create a copy of IceServer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IceServerImplCopyWith<_$IceServerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VaultStatusResponse _$VaultStatusResponseFromJson(Map<String, dynamic> json) {
  return _VaultStatusResponse.fromJson(json);
}

/// @nodoc
mixin _$VaultStatusResponse {
  String get id => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime get lastHeartbeatAt => throw _privateConstructorUsedError;
  String? get containerId => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this VaultStatusResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VaultStatusResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VaultStatusResponseCopyWith<VaultStatusResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VaultStatusResponseCopyWith<$Res> {
  factory $VaultStatusResponseCopyWith(
    VaultStatusResponse value,
    $Res Function(VaultStatusResponse) then,
  ) = _$VaultStatusResponseCopyWithImpl<$Res, VaultStatusResponse>;
  @useResult
  $Res call({
    String id,
    String status,
    DateTime startedAt,
    DateTime lastHeartbeatAt,
    String? containerId,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class _$VaultStatusResponseCopyWithImpl<$Res, $Val extends VaultStatusResponse>
    implements $VaultStatusResponseCopyWith<$Res> {
  _$VaultStatusResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VaultStatusResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? startedAt = null,
    Object? lastHeartbeatAt = null,
    Object? containerId = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            startedAt: null == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            lastHeartbeatAt: null == lastHeartbeatAt
                ? _value.lastHeartbeatAt
                : lastHeartbeatAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            containerId: freezed == containerId
                ? _value.containerId
                : containerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VaultStatusResponseImplCopyWith<$Res>
    implements $VaultStatusResponseCopyWith<$Res> {
  factory _$$VaultStatusResponseImplCopyWith(
    _$VaultStatusResponseImpl value,
    $Res Function(_$VaultStatusResponseImpl) then,
  ) = __$$VaultStatusResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String status,
    DateTime startedAt,
    DateTime lastHeartbeatAt,
    String? containerId,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class __$$VaultStatusResponseImplCopyWithImpl<$Res>
    extends _$VaultStatusResponseCopyWithImpl<$Res, _$VaultStatusResponseImpl>
    implements _$$VaultStatusResponseImplCopyWith<$Res> {
  __$$VaultStatusResponseImplCopyWithImpl(
    _$VaultStatusResponseImpl _value,
    $Res Function(_$VaultStatusResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VaultStatusResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? startedAt = null,
    Object? lastHeartbeatAt = null,
    Object? containerId = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _$VaultStatusResponseImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        startedAt: null == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        lastHeartbeatAt: null == lastHeartbeatAt
            ? _value.lastHeartbeatAt
            : lastHeartbeatAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        containerId: freezed == containerId
            ? _value.containerId
            : containerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VaultStatusResponseImpl implements _VaultStatusResponse {
  const _$VaultStatusResponseImpl({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.lastHeartbeatAt,
    this.containerId,
    final Map<String, dynamic>? metadata,
  }) : _metadata = metadata;

  factory _$VaultStatusResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$VaultStatusResponseImplFromJson(json);

  @override
  final String id;
  @override
  final String status;
  @override
  final DateTime startedAt;
  @override
  final DateTime lastHeartbeatAt;
  @override
  final String? containerId;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'VaultStatusResponse(id: $id, status: $status, startedAt: $startedAt, lastHeartbeatAt: $lastHeartbeatAt, containerId: $containerId, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VaultStatusResponseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.lastHeartbeatAt, lastHeartbeatAt) ||
                other.lastHeartbeatAt == lastHeartbeatAt) &&
            (identical(other.containerId, containerId) ||
                other.containerId == containerId) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    status,
    startedAt,
    lastHeartbeatAt,
    containerId,
    const DeepCollectionEquality().hash(_metadata),
  );

  /// Create a copy of VaultStatusResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VaultStatusResponseImplCopyWith<_$VaultStatusResponseImpl> get copyWith =>
      __$$VaultStatusResponseImplCopyWithImpl<_$VaultStatusResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$VaultStatusResponseImplToJson(this);
  }
}

abstract class _VaultStatusResponse implements VaultStatusResponse {
  const factory _VaultStatusResponse({
    required final String id,
    required final String status,
    required final DateTime startedAt,
    required final DateTime lastHeartbeatAt,
    final String? containerId,
    final Map<String, dynamic>? metadata,
  }) = _$VaultStatusResponseImpl;

  factory _VaultStatusResponse.fromJson(Map<String, dynamic> json) =
      _$VaultStatusResponseImpl.fromJson;

  @override
  String get id;
  @override
  String get status;
  @override
  DateTime get startedAt;
  @override
  DateTime get lastHeartbeatAt;
  @override
  String? get containerId;
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of VaultStatusResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VaultStatusResponseImplCopyWith<_$VaultStatusResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GeofenceValidationResponse _$GeofenceValidationResponseFromJson(
  Map<String, dynamic> json,
) {
  return _GeofenceValidationResponse.fromJson(json);
}

/// @nodoc
mixin _$GeofenceValidationResponse {
  bool get isValid => throw _privateConstructorUsedError;
  String? get validationReason => throw _privateConstructorUsedError;
  String? get matchedZoneId => throw _privateConstructorUsedError;
  String? get zoneName => throw _privateConstructorUsedError;

  /// Serializes this GeofenceValidationResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GeofenceValidationResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GeofenceValidationResponseCopyWith<GeofenceValidationResponse>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GeofenceValidationResponseCopyWith<$Res> {
  factory $GeofenceValidationResponseCopyWith(
    GeofenceValidationResponse value,
    $Res Function(GeofenceValidationResponse) then,
  ) =
      _$GeofenceValidationResponseCopyWithImpl<
        $Res,
        GeofenceValidationResponse
      >;
  @useResult
  $Res call({
    bool isValid,
    String? validationReason,
    String? matchedZoneId,
    String? zoneName,
  });
}

/// @nodoc
class _$GeofenceValidationResponseCopyWithImpl<
  $Res,
  $Val extends GeofenceValidationResponse
>
    implements $GeofenceValidationResponseCopyWith<$Res> {
  _$GeofenceValidationResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GeofenceValidationResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isValid = null,
    Object? validationReason = freezed,
    Object? matchedZoneId = freezed,
    Object? zoneName = freezed,
  }) {
    return _then(
      _value.copyWith(
            isValid: null == isValid
                ? _value.isValid
                : isValid // ignore: cast_nullable_to_non_nullable
                      as bool,
            validationReason: freezed == validationReason
                ? _value.validationReason
                : validationReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            matchedZoneId: freezed == matchedZoneId
                ? _value.matchedZoneId
                : matchedZoneId // ignore: cast_nullable_to_non_nullable
                      as String?,
            zoneName: freezed == zoneName
                ? _value.zoneName
                : zoneName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GeofenceValidationResponseImplCopyWith<$Res>
    implements $GeofenceValidationResponseCopyWith<$Res> {
  factory _$$GeofenceValidationResponseImplCopyWith(
    _$GeofenceValidationResponseImpl value,
    $Res Function(_$GeofenceValidationResponseImpl) then,
  ) = __$$GeofenceValidationResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isValid,
    String? validationReason,
    String? matchedZoneId,
    String? zoneName,
  });
}

/// @nodoc
class __$$GeofenceValidationResponseImplCopyWithImpl<$Res>
    extends
        _$GeofenceValidationResponseCopyWithImpl<
          $Res,
          _$GeofenceValidationResponseImpl
        >
    implements _$$GeofenceValidationResponseImplCopyWith<$Res> {
  __$$GeofenceValidationResponseImplCopyWithImpl(
    _$GeofenceValidationResponseImpl _value,
    $Res Function(_$GeofenceValidationResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GeofenceValidationResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isValid = null,
    Object? validationReason = freezed,
    Object? matchedZoneId = freezed,
    Object? zoneName = freezed,
  }) {
    return _then(
      _$GeofenceValidationResponseImpl(
        isValid: null == isValid
            ? _value.isValid
            : isValid // ignore: cast_nullable_to_non_nullable
                  as bool,
        validationReason: freezed == validationReason
            ? _value.validationReason
            : validationReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        matchedZoneId: freezed == matchedZoneId
            ? _value.matchedZoneId
            : matchedZoneId // ignore: cast_nullable_to_non_nullable
                  as String?,
        zoneName: freezed == zoneName
            ? _value.zoneName
            : zoneName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GeofenceValidationResponseImpl implements _GeofenceValidationResponse {
  const _$GeofenceValidationResponseImpl({
    required this.isValid,
    this.validationReason,
    this.matchedZoneId,
    this.zoneName,
  });

  factory _$GeofenceValidationResponseImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$GeofenceValidationResponseImplFromJson(json);

  @override
  final bool isValid;
  @override
  final String? validationReason;
  @override
  final String? matchedZoneId;
  @override
  final String? zoneName;

  @override
  String toString() {
    return 'GeofenceValidationResponse(isValid: $isValid, validationReason: $validationReason, matchedZoneId: $matchedZoneId, zoneName: $zoneName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GeofenceValidationResponseImpl &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            (identical(other.validationReason, validationReason) ||
                other.validationReason == validationReason) &&
            (identical(other.matchedZoneId, matchedZoneId) ||
                other.matchedZoneId == matchedZoneId) &&
            (identical(other.zoneName, zoneName) ||
                other.zoneName == zoneName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    isValid,
    validationReason,
    matchedZoneId,
    zoneName,
  );

  /// Create a copy of GeofenceValidationResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GeofenceValidationResponseImplCopyWith<_$GeofenceValidationResponseImpl>
  get copyWith =>
      __$$GeofenceValidationResponseImplCopyWithImpl<
        _$GeofenceValidationResponseImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GeofenceValidationResponseImplToJson(this);
  }
}

abstract class _GeofenceValidationResponse
    implements GeofenceValidationResponse {
  const factory _GeofenceValidationResponse({
    required final bool isValid,
    final String? validationReason,
    final String? matchedZoneId,
    final String? zoneName,
  }) = _$GeofenceValidationResponseImpl;

  factory _GeofenceValidationResponse.fromJson(Map<String, dynamic> json) =
      _$GeofenceValidationResponseImpl.fromJson;

  @override
  bool get isValid;
  @override
  String? get validationReason;
  @override
  String? get matchedZoneId;
  @override
  String? get zoneName;

  /// Create a copy of GeofenceValidationResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GeofenceValidationResponseImplCopyWith<_$GeofenceValidationResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) {
  return _ErrorResponse.fromJson(json);
}

/// @nodoc
mixin _$ErrorResponse {
  String get error => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  String? get errorCode => throw _privateConstructorUsedError;
  int? get statusCode => throw _privateConstructorUsedError;

  /// Serializes this ErrorResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ErrorResponseCopyWith<ErrorResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ErrorResponseCopyWith<$Res> {
  factory $ErrorResponseCopyWith(
    ErrorResponse value,
    $Res Function(ErrorResponse) then,
  ) = _$ErrorResponseCopyWithImpl<$Res, ErrorResponse>;
  @useResult
  $Res call({
    String error,
    String? message,
    String? errorCode,
    int? statusCode,
  });
}

/// @nodoc
class _$ErrorResponseCopyWithImpl<$Res, $Val extends ErrorResponse>
    implements $ErrorResponseCopyWith<$Res> {
  _$ErrorResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = null,
    Object? message = freezed,
    Object? errorCode = freezed,
    Object? statusCode = freezed,
  }) {
    return _then(
      _value.copyWith(
            error: null == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String,
            message: freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String?,
            errorCode: freezed == errorCode
                ? _value.errorCode
                : errorCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            statusCode: freezed == statusCode
                ? _value.statusCode
                : statusCode // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ErrorResponseImplCopyWith<$Res>
    implements $ErrorResponseCopyWith<$Res> {
  factory _$$ErrorResponseImplCopyWith(
    _$ErrorResponseImpl value,
    $Res Function(_$ErrorResponseImpl) then,
  ) = __$$ErrorResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String error,
    String? message,
    String? errorCode,
    int? statusCode,
  });
}

/// @nodoc
class __$$ErrorResponseImplCopyWithImpl<$Res>
    extends _$ErrorResponseCopyWithImpl<$Res, _$ErrorResponseImpl>
    implements _$$ErrorResponseImplCopyWith<$Res> {
  __$$ErrorResponseImplCopyWithImpl(
    _$ErrorResponseImpl _value,
    $Res Function(_$ErrorResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = null,
    Object? message = freezed,
    Object? errorCode = freezed,
    Object? statusCode = freezed,
  }) {
    return _then(
      _$ErrorResponseImpl(
        error: null == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String,
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
        errorCode: freezed == errorCode
            ? _value.errorCode
            : errorCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        statusCode: freezed == statusCode
            ? _value.statusCode
            : statusCode // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ErrorResponseImpl implements _ErrorResponse {
  const _$ErrorResponseImpl({
    required this.error,
    this.message,
    this.errorCode,
    this.statusCode,
  });

  factory _$ErrorResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ErrorResponseImplFromJson(json);

  @override
  final String error;
  @override
  final String? message;
  @override
  final String? errorCode;
  @override
  final int? statusCode;

  @override
  String toString() {
    return 'ErrorResponse(error: $error, message: $message, errorCode: $errorCode, statusCode: $statusCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorResponseImpl &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.errorCode, errorCode) ||
                other.errorCode == errorCode) &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, error, message, errorCode, statusCode);

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorResponseImplCopyWith<_$ErrorResponseImpl> get copyWith =>
      __$$ErrorResponseImplCopyWithImpl<_$ErrorResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ErrorResponseImplToJson(this);
  }
}

abstract class _ErrorResponse implements ErrorResponse {
  const factory _ErrorResponse({
    required final String error,
    final String? message,
    final String? errorCode,
    final int? statusCode,
  }) = _$ErrorResponseImpl;

  factory _ErrorResponse.fromJson(Map<String, dynamic> json) =
      _$ErrorResponseImpl.fromJson;

  @override
  String get error;
  @override
  String? get message;
  @override
  String? get errorCode;
  @override
  int? get statusCode;

  /// Create a copy of ErrorResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorResponseImplCopyWith<_$ErrorResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
