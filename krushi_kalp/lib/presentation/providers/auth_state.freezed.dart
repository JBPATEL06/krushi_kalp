// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AuthState {
  User? get user => throw _privateConstructorUsedError;
  String? get role => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isAuthCheckComplete => throw _privateConstructorUsedError;
  bool get isPasswordRecovery => throw _privateConstructorUsedError;
  String? get localSessionId => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AuthStateCopyWith<AuthState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthStateCopyWith<$Res> {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) then) =
      _$AuthStateCopyWithImpl<$Res, AuthState>;
  @useResult
  $Res call(
      {User? user,
      String? role,
      String? username,
      bool isLoading,
      bool isAuthCheckComplete,
      bool isPasswordRecovery,
      String? localSessionId,
      String? errorMessage});
}

/// @nodoc
class _$AuthStateCopyWithImpl<$Res, $Val extends AuthState>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = freezed,
    Object? role = freezed,
    Object? username = freezed,
    Object? isLoading = null,
    Object? isAuthCheckComplete = null,
    Object? isPasswordRecovery = null,
    Object? localSessionId = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as User?,
      role: freezed == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAuthCheckComplete: null == isAuthCheckComplete
          ? _value.isAuthCheckComplete
          : isAuthCheckComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      isPasswordRecovery: null == isPasswordRecovery
          ? _value.isPasswordRecovery
          : isPasswordRecovery // ignore: cast_nullable_to_non_nullable
              as bool,
      localSessionId: freezed == localSessionId
          ? _value.localSessionId
          : localSessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuthStateImplCopyWith<$Res>
    implements $AuthStateCopyWith<$Res> {
  factory _$$AuthStateImplCopyWith(
          _$AuthStateImpl value, $Res Function(_$AuthStateImpl) then) =
      __$$AuthStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {User? user,
      String? role,
      String? username,
      bool isLoading,
      bool isAuthCheckComplete,
      bool isPasswordRecovery,
      String? localSessionId,
      String? errorMessage});
}

/// @nodoc
class __$$AuthStateImplCopyWithImpl<$Res>
    extends _$AuthStateCopyWithImpl<$Res, _$AuthStateImpl>
    implements _$$AuthStateImplCopyWith<$Res> {
  __$$AuthStateImplCopyWithImpl(
      _$AuthStateImpl _value, $Res Function(_$AuthStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = freezed,
    Object? role = freezed,
    Object? username = freezed,
    Object? isLoading = null,
    Object? isAuthCheckComplete = null,
    Object? isPasswordRecovery = null,
    Object? localSessionId = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_$AuthStateImpl(
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as User?,
      role: freezed == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAuthCheckComplete: null == isAuthCheckComplete
          ? _value.isAuthCheckComplete
          : isAuthCheckComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      isPasswordRecovery: null == isPasswordRecovery
          ? _value.isPasswordRecovery
          : isPasswordRecovery // ignore: cast_nullable_to_non_nullable
              as bool,
      localSessionId: freezed == localSessionId
          ? _value.localSessionId
          : localSessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$AuthStateImpl extends _AuthState {
  const _$AuthStateImpl(
      {this.user,
      this.role,
      this.username,
      this.isLoading = false,
      this.isAuthCheckComplete = false,
      this.isPasswordRecovery = false,
      this.localSessionId,
      this.errorMessage})
      : super._();

  @override
  final User? user;
  @override
  final String? role;
  @override
  final String? username;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isAuthCheckComplete;
  @override
  @JsonKey()
  final bool isPasswordRecovery;
  @override
  final String? localSessionId;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'AuthState(user: $user, role: $role, username: $username, isLoading: $isLoading, isAuthCheckComplete: $isAuthCheckComplete, isPasswordRecovery: $isPasswordRecovery, localSessionId: $localSessionId, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthStateImpl &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isAuthCheckComplete, isAuthCheckComplete) ||
                other.isAuthCheckComplete == isAuthCheckComplete) &&
            (identical(other.isPasswordRecovery, isPasswordRecovery) ||
                other.isPasswordRecovery == isPasswordRecovery) &&
            (identical(other.localSessionId, localSessionId) ||
                other.localSessionId == localSessionId) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(runtimeType, user, role, username, isLoading,
      isAuthCheckComplete, isPasswordRecovery, localSessionId, errorMessage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      __$$AuthStateImplCopyWithImpl<_$AuthStateImpl>(this, _$identity);
}

abstract class _AuthState extends AuthState {
  const factory _AuthState(
      {final User? user,
      final String? role,
      final String? username,
      final bool isLoading,
      final bool isAuthCheckComplete,
      final bool isPasswordRecovery,
      final String? localSessionId,
      final String? errorMessage}) = _$AuthStateImpl;
  const _AuthState._() : super._();

  @override
  User? get user;
  @override
  String? get role;
  @override
  String? get username;
  @override
  bool get isLoading;
  @override
  bool get isAuthCheckComplete;
  @override
  bool get isPasswordRecovery;
  @override
  String? get localSessionId;
  @override
  String? get errorMessage;
  @override
  @JsonKey(ignore: true)
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
