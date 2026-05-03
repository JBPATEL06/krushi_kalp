// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Navigation)
final navigationProvider = NavigationProvider._();

final class NavigationProvider
    extends $NotifierProvider<Navigation, NavigationState> {
  NavigationProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'navigationProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$navigationHash();

  @$internal
  @override
  Navigation create() => Navigation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NavigationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NavigationState>(value),
    );
  }
}

String _$navigationHash() => r'1a99f8ba116f3068c1ca9cdb7cfd50a9888fb146';

abstract class _$Navigation extends $Notifier<NavigationState> {
  NavigationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<NavigationState, NavigationState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<NavigationState, NavigationState>,
        NavigationState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
