import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_notifier.g.dart';

class AdminState {
  final int navIndex;
  final int refreshCounter;

  const AdminState({
    this.navIndex = 0,
    this.refreshCounter = 0,
  });

  AdminState copyWith({
    int? navIndex,
    int? refreshCounter,
  }) {
    return AdminState(
      navIndex: navIndex ?? this.navIndex,
      refreshCounter: refreshCounter ?? this.refreshCounter,
    );
  }
}

@riverpod
class AdminNotifier extends _$AdminNotifier {
  @override
  AdminState build() {
    return const AdminState();
  }

  void setNavIndex(int index) {
    state = state.copyWith(navIndex: index);
  }

  void triggerRefresh() {
    state = state.copyWith(refreshCounter: state.refreshCounter + 1);
  }
}
