// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'resource_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ResourceState {
  List<Resource> get ebooks;
  List<Resource> get studyMaterials;
  List<Resource> get pyqs;
  List<Resource> get currentAffairs;
  Set<int> get purchasedResourceIds;
  List<Resource> get purchasedResources;
  bool get isLoading;
  String? get errorMessage;

  /// Create a copy of ResourceState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ResourceStateCopyWith<ResourceState> get copyWith =>
      _$ResourceStateCopyWithImpl<ResourceState>(
          this as ResourceState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ResourceState &&
            const DeepCollectionEquality().equals(other.ebooks, ebooks) &&
            const DeepCollectionEquality()
                .equals(other.studyMaterials, studyMaterials) &&
            const DeepCollectionEquality().equals(other.pyqs, pyqs) &&
            const DeepCollectionEquality()
                .equals(other.currentAffairs, currentAffairs) &&
            const DeepCollectionEquality()
                .equals(other.purchasedResourceIds, purchasedResourceIds) &&
            const DeepCollectionEquality()
                .equals(other.purchasedResources, purchasedResources) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(ebooks),
      const DeepCollectionEquality().hash(studyMaterials),
      const DeepCollectionEquality().hash(pyqs),
      const DeepCollectionEquality().hash(currentAffairs),
      const DeepCollectionEquality().hash(purchasedResourceIds),
      const DeepCollectionEquality().hash(purchasedResources),
      isLoading,
      errorMessage);

  @override
  String toString() {
    return 'ResourceState(ebooks: $ebooks, studyMaterials: $studyMaterials, pyqs: $pyqs, currentAffairs: $currentAffairs, purchasedResourceIds: $purchasedResourceIds, purchasedResources: $purchasedResources, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class $ResourceStateCopyWith<$Res> {
  factory $ResourceStateCopyWith(
          ResourceState value, $Res Function(ResourceState) _then) =
      _$ResourceStateCopyWithImpl;
  @useResult
  $Res call(
      {List<Resource> ebooks,
      List<Resource> studyMaterials,
      List<Resource> pyqs,
      List<Resource> currentAffairs,
      Set<int> purchasedResourceIds,
      List<Resource> purchasedResources,
      bool isLoading,
      String? errorMessage});
}

/// @nodoc
class _$ResourceStateCopyWithImpl<$Res>
    implements $ResourceStateCopyWith<$Res> {
  _$ResourceStateCopyWithImpl(this._self, this._then);

  final ResourceState _self;
  final $Res Function(ResourceState) _then;

  /// Create a copy of ResourceState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ebooks = null,
    Object? studyMaterials = null,
    Object? pyqs = null,
    Object? currentAffairs = null,
    Object? purchasedResourceIds = null,
    Object? purchasedResources = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_self.copyWith(
      ebooks: null == ebooks
          ? _self.ebooks
          : ebooks // ignore: cast_nullable_to_non_nullable
              as List<Resource>,
      studyMaterials: null == studyMaterials
          ? _self.studyMaterials
          : studyMaterials // ignore: cast_nullable_to_non_nullable
              as List<Resource>,
      pyqs: null == pyqs
          ? _self.pyqs
          : pyqs // ignore: cast_nullable_to_non_nullable
              as List<Resource>,
      currentAffairs: null == currentAffairs
          ? _self.currentAffairs
          : currentAffairs // ignore: cast_nullable_to_non_nullable
              as List<Resource>,
      purchasedResourceIds: null == purchasedResourceIds
          ? _self.purchasedResourceIds
          : purchasedResourceIds // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      purchasedResources: null == purchasedResources
          ? _self.purchasedResources
          : purchasedResources // ignore: cast_nullable_to_non_nullable
              as List<Resource>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ResourceState].
extension ResourceStatePatterns on ResourceState {
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
    TResult Function(_ResourceState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ResourceState() when $default != null:
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
    TResult Function(_ResourceState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResourceState():
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
    TResult? Function(_ResourceState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResourceState() when $default != null:
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
            List<Resource> ebooks,
            List<Resource> studyMaterials,
            List<Resource> pyqs,
            List<Resource> currentAffairs,
            Set<int> purchasedResourceIds,
            List<Resource> purchasedResources,
            bool isLoading,
            String? errorMessage)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ResourceState() when $default != null:
        return $default(
            _that.ebooks,
            _that.studyMaterials,
            _that.pyqs,
            _that.currentAffairs,
            _that.purchasedResourceIds,
            _that.purchasedResources,
            _that.isLoading,
            _that.errorMessage);
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
            List<Resource> ebooks,
            List<Resource> studyMaterials,
            List<Resource> pyqs,
            List<Resource> currentAffairs,
            Set<int> purchasedResourceIds,
            List<Resource> purchasedResources,
            bool isLoading,
            String? errorMessage)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResourceState():
        return $default(
            _that.ebooks,
            _that.studyMaterials,
            _that.pyqs,
            _that.currentAffairs,
            _that.purchasedResourceIds,
            _that.purchasedResources,
            _that.isLoading,
            _that.errorMessage);
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
            List<Resource> ebooks,
            List<Resource> studyMaterials,
            List<Resource> pyqs,
            List<Resource> currentAffairs,
            Set<int> purchasedResourceIds,
            List<Resource> purchasedResources,
            bool isLoading,
            String? errorMessage)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResourceState() when $default != null:
        return $default(
            _that.ebooks,
            _that.studyMaterials,
            _that.pyqs,
            _that.currentAffairs,
            _that.purchasedResourceIds,
            _that.purchasedResources,
            _that.isLoading,
            _that.errorMessage);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ResourceState implements ResourceState {
  const _ResourceState(
      {final List<Resource> ebooks = const [],
      final List<Resource> studyMaterials = const [],
      final List<Resource> pyqs = const [],
      final List<Resource> currentAffairs = const [],
      final Set<int> purchasedResourceIds = const {},
      final List<Resource> purchasedResources = const [],
      this.isLoading = false,
      this.errorMessage})
      : _ebooks = ebooks,
        _studyMaterials = studyMaterials,
        _pyqs = pyqs,
        _currentAffairs = currentAffairs,
        _purchasedResourceIds = purchasedResourceIds,
        _purchasedResources = purchasedResources;

  final List<Resource> _ebooks;
  @override
  @JsonKey()
  List<Resource> get ebooks {
    if (_ebooks is EqualUnmodifiableListView) return _ebooks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ebooks);
  }

  final List<Resource> _studyMaterials;
  @override
  @JsonKey()
  List<Resource> get studyMaterials {
    if (_studyMaterials is EqualUnmodifiableListView) return _studyMaterials;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_studyMaterials);
  }

  final List<Resource> _pyqs;
  @override
  @JsonKey()
  List<Resource> get pyqs {
    if (_pyqs is EqualUnmodifiableListView) return _pyqs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pyqs);
  }

  final List<Resource> _currentAffairs;
  @override
  @JsonKey()
  List<Resource> get currentAffairs {
    if (_currentAffairs is EqualUnmodifiableListView) return _currentAffairs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_currentAffairs);
  }

  final Set<int> _purchasedResourceIds;
  @override
  @JsonKey()
  Set<int> get purchasedResourceIds {
    if (_purchasedResourceIds is EqualUnmodifiableSetView)
      return _purchasedResourceIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_purchasedResourceIds);
  }

  final List<Resource> _purchasedResources;
  @override
  @JsonKey()
  List<Resource> get purchasedResources {
    if (_purchasedResources is EqualUnmodifiableListView)
      return _purchasedResources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_purchasedResources);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? errorMessage;

  /// Create a copy of ResourceState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ResourceStateCopyWith<_ResourceState> get copyWith =>
      __$ResourceStateCopyWithImpl<_ResourceState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ResourceState &&
            const DeepCollectionEquality().equals(other._ebooks, _ebooks) &&
            const DeepCollectionEquality()
                .equals(other._studyMaterials, _studyMaterials) &&
            const DeepCollectionEquality().equals(other._pyqs, _pyqs) &&
            const DeepCollectionEquality()
                .equals(other._currentAffairs, _currentAffairs) &&
            const DeepCollectionEquality()
                .equals(other._purchasedResourceIds, _purchasedResourceIds) &&
            const DeepCollectionEquality()
                .equals(other._purchasedResources, _purchasedResources) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_ebooks),
      const DeepCollectionEquality().hash(_studyMaterials),
      const DeepCollectionEquality().hash(_pyqs),
      const DeepCollectionEquality().hash(_currentAffairs),
      const DeepCollectionEquality().hash(_purchasedResourceIds),
      const DeepCollectionEquality().hash(_purchasedResources),
      isLoading,
      errorMessage);

  @override
  String toString() {
    return 'ResourceState(ebooks: $ebooks, studyMaterials: $studyMaterials, pyqs: $pyqs, currentAffairs: $currentAffairs, purchasedResourceIds: $purchasedResourceIds, purchasedResources: $purchasedResources, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class _$ResourceStateCopyWith<$Res>
    implements $ResourceStateCopyWith<$Res> {
  factory _$ResourceStateCopyWith(
          _ResourceState value, $Res Function(_ResourceState) _then) =
      __$ResourceStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<Resource> ebooks,
      List<Resource> studyMaterials,
      List<Resource> pyqs,
      List<Resource> currentAffairs,
      Set<int> purchasedResourceIds,
      List<Resource> purchasedResources,
      bool isLoading,
      String? errorMessage});
}

/// @nodoc
class __$ResourceStateCopyWithImpl<$Res>
    implements _$ResourceStateCopyWith<$Res> {
  __$ResourceStateCopyWithImpl(this._self, this._then);

  final _ResourceState _self;
  final $Res Function(_ResourceState) _then;

  /// Create a copy of ResourceState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? ebooks = null,
    Object? studyMaterials = null,
    Object? pyqs = null,
    Object? currentAffairs = null,
    Object? purchasedResourceIds = null,
    Object? purchasedResources = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_ResourceState(
      ebooks: null == ebooks
          ? _self._ebooks
          : ebooks // ignore: cast_nullable_to_non_nullable
              as List<Resource>,
      studyMaterials: null == studyMaterials
          ? _self._studyMaterials
          : studyMaterials // ignore: cast_nullable_to_non_nullable
              as List<Resource>,
      pyqs: null == pyqs
          ? _self._pyqs
          : pyqs // ignore: cast_nullable_to_non_nullable
              as List<Resource>,
      currentAffairs: null == currentAffairs
          ? _self._currentAffairs
          : currentAffairs // ignore: cast_nullable_to_non_nullable
              as List<Resource>,
      purchasedResourceIds: null == purchasedResourceIds
          ? _self._purchasedResourceIds
          : purchasedResourceIds // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      purchasedResources: null == purchasedResources
          ? _self._purchasedResources
          : purchasedResources // ignore: cast_nullable_to_non_nullable
              as List<Resource>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
