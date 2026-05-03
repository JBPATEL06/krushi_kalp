// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OfferState {
  List<Offer> get activeOffers;
  bool get isLoading;
  String get errorMessage;

  /// Create a copy of OfferState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $OfferStateCopyWith<OfferState> get copyWith =>
      _$OfferStateCopyWithImpl<OfferState>(this as OfferState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is OfferState &&
            const DeepCollectionEquality()
                .equals(other.activeOffers, activeOffers) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(activeOffers),
      isLoading,
      errorMessage);

  @override
  String toString() {
    return 'OfferState(activeOffers: $activeOffers, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class $OfferStateCopyWith<$Res> {
  factory $OfferStateCopyWith(
          OfferState value, $Res Function(OfferState) _then) =
      _$OfferStateCopyWithImpl;
  @useResult
  $Res call({List<Offer> activeOffers, bool isLoading, String errorMessage});
}

/// @nodoc
class _$OfferStateCopyWithImpl<$Res> implements $OfferStateCopyWith<$Res> {
  _$OfferStateCopyWithImpl(this._self, this._then);

  final OfferState _self;
  final $Res Function(OfferState) _then;

  /// Create a copy of OfferState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeOffers = null,
    Object? isLoading = null,
    Object? errorMessage = null,
  }) {
    return _then(_self.copyWith(
      activeOffers: null == activeOffers
          ? _self.activeOffers
          : activeOffers // ignore: cast_nullable_to_non_nullable
              as List<Offer>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: null == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [OfferState].
extension OfferStatePatterns on OfferState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_OfferState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OfferState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_OfferState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OfferState():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_OfferState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OfferState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            List<Offer> activeOffers, bool isLoading, String errorMessage)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OfferState() when $default != null:
        return $default(
            _that.activeOffers, _that.isLoading, _that.errorMessage);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            List<Offer> activeOffers, bool isLoading, String errorMessage)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OfferState():
        return $default(
            _that.activeOffers, _that.isLoading, _that.errorMessage);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            List<Offer> activeOffers, bool isLoading, String errorMessage)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OfferState() when $default != null:
        return $default(
            _that.activeOffers, _that.isLoading, _that.errorMessage);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _OfferState implements OfferState {
  const _OfferState(
      {final List<Offer> activeOffers = const [],
      this.isLoading = false,
      this.errorMessage = ''})
      : _activeOffers = activeOffers;

  final List<Offer> _activeOffers;
  @override
  @JsonKey()
  List<Offer> get activeOffers {
    if (_activeOffers is EqualUnmodifiableListView) return _activeOffers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activeOffers);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final String errorMessage;

  /// Create a copy of OfferState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$OfferStateCopyWith<_OfferState> get copyWith =>
      __$OfferStateCopyWithImpl<_OfferState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _OfferState &&
            const DeepCollectionEquality()
                .equals(other._activeOffers, _activeOffers) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_activeOffers),
      isLoading,
      errorMessage);

  @override
  String toString() {
    return 'OfferState(activeOffers: $activeOffers, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class _$OfferStateCopyWith<$Res>
    implements $OfferStateCopyWith<$Res> {
  factory _$OfferStateCopyWith(
          _OfferState value, $Res Function(_OfferState) _then) =
      __$OfferStateCopyWithImpl;
  @override
  @useResult
  $Res call({List<Offer> activeOffers, bool isLoading, String errorMessage});
}

/// @nodoc
class __$OfferStateCopyWithImpl<$Res> implements _$OfferStateCopyWith<$Res> {
  __$OfferStateCopyWithImpl(this._self, this._then);

  final _OfferState _self;
  final $Res Function(_OfferState) _then;

  /// Create a copy of OfferState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? activeOffers = null,
    Object? isLoading = null,
    Object? errorMessage = null,
  }) {
    return _then(_OfferState(
      activeOffers: null == activeOffers
          ? _self._activeOffers
          : activeOffers // ignore: cast_nullable_to_non_nullable
              as List<Offer>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: null == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
