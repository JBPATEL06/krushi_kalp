// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'test_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TestState {
  List<MockTest> get allTests => throw _privateConstructorUsedError;
  List<MockTest> get cachedTests => throw _privateConstructorUsedError;
  List<MockTest> get userTests => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String get errorMessage => throw _privateConstructorUsedError;
  Set<int> get purchasedTestIds => throw _privateConstructorUsedError;
  String get selectedCategory => throw _privateConstructorUsedError;
  String get sortOption => throw _privateConstructorUsedError;
  String get searchQuery => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TestStateCopyWith<TestState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TestStateCopyWith<$Res> {
  factory $TestStateCopyWith(TestState value, $Res Function(TestState) then) =
      _$TestStateCopyWithImpl<$Res, TestState>;
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
class _$TestStateCopyWithImpl<$Res, $Val extends TestState>
    implements $TestStateCopyWith<$Res> {
  _$TestStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      allTests: null == allTests
          ? _value.allTests
          : allTests // ignore: cast_nullable_to_non_nullable
              as List<MockTest>,
      cachedTests: null == cachedTests
          ? _value.cachedTests
          : cachedTests // ignore: cast_nullable_to_non_nullable
              as List<MockTest>,
      userTests: null == userTests
          ? _value.userTests
          : userTests // ignore: cast_nullable_to_non_nullable
              as List<MockTest>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: null == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String,
      purchasedTestIds: null == purchasedTestIds
          ? _value.purchasedTestIds
          : purchasedTestIds // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      selectedCategory: null == selectedCategory
          ? _value.selectedCategory
          : selectedCategory // ignore: cast_nullable_to_non_nullable
              as String,
      sortOption: null == sortOption
          ? _value.sortOption
          : sortOption // ignore: cast_nullable_to_non_nullable
              as String,
      searchQuery: null == searchQuery
          ? _value.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TestStateImplCopyWith<$Res>
    implements $TestStateCopyWith<$Res> {
  factory _$$TestStateImplCopyWith(
          _$TestStateImpl value, $Res Function(_$TestStateImpl) then) =
      __$$TestStateImplCopyWithImpl<$Res>;
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
class __$$TestStateImplCopyWithImpl<$Res>
    extends _$TestStateCopyWithImpl<$Res, _$TestStateImpl>
    implements _$$TestStateImplCopyWith<$Res> {
  __$$TestStateImplCopyWithImpl(
      _$TestStateImpl _value, $Res Function(_$TestStateImpl) _then)
      : super(_value, _then);

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
    return _then(_$TestStateImpl(
      allTests: null == allTests
          ? _value._allTests
          : allTests // ignore: cast_nullable_to_non_nullable
              as List<MockTest>,
      cachedTests: null == cachedTests
          ? _value._cachedTests
          : cachedTests // ignore: cast_nullable_to_non_nullable
              as List<MockTest>,
      userTests: null == userTests
          ? _value._userTests
          : userTests // ignore: cast_nullable_to_non_nullable
              as List<MockTest>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: null == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String,
      purchasedTestIds: null == purchasedTestIds
          ? _value._purchasedTestIds
          : purchasedTestIds // ignore: cast_nullable_to_non_nullable
              as Set<int>,
      selectedCategory: null == selectedCategory
          ? _value.selectedCategory
          : selectedCategory // ignore: cast_nullable_to_non_nullable
              as String,
      sortOption: null == sortOption
          ? _value.sortOption
          : sortOption // ignore: cast_nullable_to_non_nullable
              as String,
      searchQuery: null == searchQuery
          ? _value.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TestStateImpl implements _TestState {
  const _$TestStateImpl(
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

  @override
  String toString() {
    return 'TestState(allTests: $allTests, cachedTests: $cachedTests, userTests: $userTests, isLoading: $isLoading, errorMessage: $errorMessage, purchasedTestIds: $purchasedTestIds, selectedCategory: $selectedCategory, sortOption: $sortOption, searchQuery: $searchQuery)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TestStateImpl &&
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

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TestStateImplCopyWith<_$TestStateImpl> get copyWith =>
      __$$TestStateImplCopyWithImpl<_$TestStateImpl>(this, _$identity);
}

abstract class _TestState implements TestState {
  const factory _TestState(
      {final List<MockTest> allTests,
      final List<MockTest> cachedTests,
      final List<MockTest> userTests,
      final bool isLoading,
      final String errorMessage,
      final Set<int> purchasedTestIds,
      final String selectedCategory,
      final String sortOption,
      final String searchQuery}) = _$TestStateImpl;

  @override
  List<MockTest> get allTests;
  @override
  List<MockTest> get cachedTests;
  @override
  List<MockTest> get userTests;
  @override
  bool get isLoading;
  @override
  String get errorMessage;
  @override
  Set<int> get purchasedTestIds;
  @override
  String get selectedCategory;
  @override
  String get sortOption;
  @override
  String get searchQuery;
  @override
  @JsonKey(ignore: true)
  _$$TestStateImplCopyWith<_$TestStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
