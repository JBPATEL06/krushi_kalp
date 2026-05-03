// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'test_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TestState {
  List<MockTest> get allTests;
  List<MockTest> get cachedTests;
  List<MockTest> get userTests;
  bool get isLoading;
  String get errorMessage;
  Set<int> get purchasedTestIds;
  String get selectedCategory;
  String get sortOption;
  String get searchQuery;

  /// Create a copy of TestState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TestStateCopyWith<TestState> get copyWith =>
      _$TestStateCopyWithImpl<TestState>(this as TestState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TestState &&
            const DeepCollectionEquality().equals(other.allTests, allTests) &&
            const DeepCollectionEquality()
                .equals(other.cachedTests, cachedTests) &&
            const DeepCollectionEquality().equals(other.userTests, userTests) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            const DeepCollectionEquality()
                .equals(other.purchasedTestIds, purchasedTestIds) &&
            (identical(other.selectedCategory, selectedCategory) ||
                other.selectedCategory == selectedCategory) &&
            (identical(other.sortOption, sortOption) ||
                other.sortOption == sortOption) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(allTests),
      const DeepCollectionEquality().hash(cachedTests),
      const DeepCollectionEquality().hash(userTests),
      isLoading,
      errorMessage,
      const DeepCollectionEquality().hash(purchasedTestIds),
      selectedCategory,
      sortOption,
      searchQuery);

  @override
  String toString() {
    return 'TestState(allTests: $allTests, cachedTests: $cachedTests, userTests: $userTests, isLoading: $isLoading, errorMessage: $errorMessage, purchasedTestIds: $purchasedTestIds, selectedCategory: $selectedCategory, sortOption: $sortOption, searchQuery: $searchQuery)';
  }
}

/// @nodoc
abstract mixin class $TestStateCopyWith<$Res> {
  factory $TestStateCopyWith(TestState value, $Res Function(TestState) _then) =
      _$TestStateCopyWithImpl;
  @useResult
  $Res call(
      {List<MockTest> allTests,
      List<MockTest> cachedTests,
      List<MockTest> userTests,
      bool isLoading,
      String errorMessage,
      Set<int> purchasedTestIds,
      String selectedCategory,
      String sortOption,
      String searchQuery});
}

/// @nodoc
class _$TestStateCopyWithImpl<$Res> implements $TestStateCopyWith<$Res> {
  _$TestStateCopyWithImpl(this._self, this._then);

  final TestState _self;
  final $Res Function(TestState) _then;

  /// Create a copy of TestState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allTests = null,
    Object? cachedTests = null,
    Object? userTests = null,
    Object? isLoading = null,
    Object? errorMessage = null,
    Object? purchasedTestIds = null,
    Object? selectedCategory = null,
    Object? sortOption = null,
    Object? searchQuery = null,
  }) {
    return _then(_self.copyWith(
      allTests: null == allTests
          ? _self.allTests
          : allTests // ignore: cast_nullable_to_non_nullable
              as List<MockTest>,
      cachedTests: null == cachedTests
          ? _self.cachedTests
          : cachedTests // ignore: cast_nullable_to_non_nullable
              as List<MockTest>,
      userTests: null == userTests
          ? _self.userTests
          : userTests // ignore: cast_nullable_to_non_nullable
              as List<MockTest>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: null == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String,
      purchasedTestIds: null == purchasedTestIds
          ? _self.purchasedTestIds
          : purchasedTestIds // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      selectedCategory: null == selectedCategory
          ? _self.selectedCategory
          : selectedCategory // ignore: cast_nullable_to_non_nullable
              as String,
      sortOption: null == sortOption
          ? _self.sortOption
          : sortOption // ignore: cast_nullable_to_non_nullable
              as String,
      searchQuery: null == searchQuery
          ? _self.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [TestState].
extension TestStatePatterns on TestState {
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
    TResult Function(_TestState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TestState() when $default != null:
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
    TResult Function(_TestState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TestState():
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
    TResult? Function(_TestState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TestState() when $default != null:
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
            List<MockTest> allTests,
            List<MockTest> cachedTests,
            List<MockTest> userTests,
            bool isLoading,
            String errorMessage,
            Set<int> purchasedTestIds,
            String selectedCategory,
            String sortOption,
            String searchQuery)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TestState() when $default != null:
        return $default(
            _that.allTests,
            _that.cachedTests,
            _that.userTests,
            _that.isLoading,
            _that.errorMessage,
            _that.purchasedTestIds,
            _that.selectedCategory,
            _that.sortOption,
            _that.searchQuery);
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
            List<MockTest> allTests,
            List<MockTest> cachedTests,
            List<MockTest> userTests,
            bool isLoading,
            String errorMessage,
            Set<int> purchasedTestIds,
            String selectedCategory,
            String sortOption,
            String searchQuery)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TestState():
        return $default(
            _that.allTests,
            _that.cachedTests,
            _that.userTests,
            _that.isLoading,
            _that.errorMessage,
            _that.purchasedTestIds,
            _that.selectedCategory,
            _that.sortOption,
            _that.searchQuery);
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
            List<MockTest> allTests,
            List<MockTest> cachedTests,
            List<MockTest> userTests,
            bool isLoading,
            String errorMessage,
            Set<int> purchasedTestIds,
            String selectedCategory,
            String sortOption,
            String searchQuery)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TestState() when $default != null:
        return $default(
            _that.allTests,
            _that.cachedTests,
            _that.userTests,
            _that.isLoading,
            _that.errorMessage,
            _that.purchasedTestIds,
            _that.selectedCategory,
            _that.sortOption,
            _that.searchQuery);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TestState implements TestState {
  const _TestState(
      {final List<MockTest> allTests = const [],
      final List<MockTest> cachedTests = const [],
      final List<MockTest> userTests = const [],
      this.isLoading = false,
      this.errorMessage = '',
      final Set<int> purchasedTestIds = const {},
      this.selectedCategory = 'All',
      this.sortOption = 'Latest',
      this.searchQuery = ''})
      : _allTests = allTests,
        _cachedTests = cachedTests,
        _userTests = userTests,
        _purchasedTestIds = purchasedTestIds;

  final List<MockTest> _allTests;
  @override
  @JsonKey()
  List<MockTest> get allTests {
    if (_allTests is EqualUnmodifiableListView) return _allTests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allTests);
  }

  final List<MockTest> _cachedTests;
  @override
  @JsonKey()
  List<MockTest> get cachedTests {
    if (_cachedTests is EqualUnmodifiableListView) return _cachedTests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cachedTests);
  }

  final List<MockTest> _userTests;
  @override
  @JsonKey()
  List<MockTest> get userTests {
    if (_userTests is EqualUnmodifiableListView) return _userTests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_userTests);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final String errorMessage;
  final Set<int> _purchasedTestIds;
  @override
  @JsonKey()
  Set<int> get purchasedTestIds {
    if (_purchasedTestIds is EqualUnmodifiableSetView) return _purchasedTestIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_purchasedTestIds);
  }

  @override
  @JsonKey()
  final String selectedCategory;
  @override
  @JsonKey()
  final String sortOption;
  @override
  @JsonKey()
  final String searchQuery;

  /// Create a copy of TestState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TestStateCopyWith<_TestState> get copyWith =>
      __$TestStateCopyWithImpl<_TestState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TestState &&
            const DeepCollectionEquality().equals(other._allTests, _allTests) &&
            const DeepCollectionEquality()
                .equals(other._cachedTests, _cachedTests) &&
            const DeepCollectionEquality()
                .equals(other._userTests, _userTests) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            const DeepCollectionEquality()
                .equals(other._purchasedTestIds, _purchasedTestIds) &&
            (identical(other.selectedCategory, selectedCategory) ||
                other.selectedCategory == selectedCategory) &&
            (identical(other.sortOption, sortOption) ||
                other.sortOption == sortOption) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_allTests),
      const DeepCollectionEquality().hash(_cachedTests),
      const DeepCollectionEquality().hash(_userTests),
      isLoading,
      errorMessage,
      const DeepCollectionEquality().hash(_purchasedTestIds),
      selectedCategory,
      sortOption,
      searchQuery);

  @override
  String toString() {
    return 'TestState(allTests: $allTests, cachedTests: $cachedTests, userTests: $userTests, isLoading: $isLoading, errorMessage: $errorMessage, purchasedTestIds: $purchasedTestIds, selectedCategory: $selectedCategory, sortOption: $sortOption, searchQuery: $searchQuery)';
  }
}

/// @nodoc
abstract mixin class _$TestStateCopyWith<$Res>
    implements $TestStateCopyWith<$Res> {
  factory _$TestStateCopyWith(
          _TestState value, $Res Function(_TestState) _then) =
      __$TestStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<MockTest> allTests,
      List<MockTest> cachedTests,
      List<MockTest> userTests,
      bool isLoading,
      String errorMessage,
      Set<int> purchasedTestIds,
      String selectedCategory,
      String sortOption,
      String searchQuery});
}

/// @nodoc
class __$TestStateCopyWithImpl<$Res> implements _$TestStateCopyWith<$Res> {
  __$TestStateCopyWithImpl(this._self, this._then);

  final _TestState _self;
  final $Res Function(_TestState) _then;

  /// Create a copy of TestState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? allTests = null,
    Object? cachedTests = null,
    Object? userTests = null,
    Object? isLoading = null,
    Object? errorMessage = null,
    Object? purchasedTestIds = null,
    Object? selectedCategory = null,
    Object? sortOption = null,
    Object? searchQuery = null,
  }) {
    return _then(_TestState(
      allTests: null == allTests
          ? _self._allTests
          : allTests // ignore: cast_nullable_to_non_nullable
              as List<MockTest>,
      cachedTests: null == cachedTests
          ? _self._cachedTests
          : cachedTests // ignore: cast_nullable_to_non_nullable
              as List<MockTest>,
      userTests: null == userTests
          ? _self._userTests
          : userTests // ignore: cast_nullable_to_non_nullable
              as List<MockTest>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: null == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String,
      purchasedTestIds: null == purchasedTestIds
          ? _self._purchasedTestIds
          : purchasedTestIds // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      selectedCategory: null == selectedCategory
          ? _self.selectedCategory
          : selectedCategory // ignore: cast_nullable_to_non_nullable
              as String,
      sortOption: null == sortOption
          ? _self.sortOption
          : sortOption // ignore: cast_nullable_to_non_nullable
              as String,
      searchQuery: null == searchQuery
          ? _self.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
