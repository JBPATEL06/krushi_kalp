import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_notifier.g.dart';

class NavigationState {
  final int selectedIndex;
  final String selectedStoreCategory;

  const NavigationState({
    required this.selectedIndex,
    required this.selectedStoreCategory,
  });

  NavigationState copyWith({
    int? selectedIndex,
    String? selectedStoreCategory,
  }) {
    return NavigationState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedStoreCategory: selectedStoreCategory ?? this.selectedStoreCategory,
    );
  }
}

@riverpod
class Navigation extends _$Navigation {
  @override
  NavigationState build() {
    return const NavigationState(
      selectedIndex: 0,
      selectedStoreCategory: 'All',
    );
  }

  void setIndex(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  void setStoreCategory(String category) {
    state = state.copyWith(selectedStoreCategory: category);
  }

  void reset() {
    state = const NavigationState(
      selectedIndex: 0,
      selectedStoreCategory: 'All',
    );
  }
}
