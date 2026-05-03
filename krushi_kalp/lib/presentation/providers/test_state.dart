import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/mock_test.dart';

part 'test_state.freezed.dart';

@freezed
abstract class TestState with _$TestState {
  const factory TestState({
    @Default([]) List<MockTest> allTests,
    @Default([]) List<MockTest> cachedTests,
    @Default([]) List<MockTest> userTests,
    @Default(false) bool isLoading,
    @Default('') String errorMessage,
    @Default({}) Set<int> purchasedTestIds,
    @Default('All') String selectedCategory,
    @Default('Latest') String sortOption,
    @Default('') String searchQuery,
  }) = _TestState;
}
