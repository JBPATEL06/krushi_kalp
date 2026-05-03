// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ResourceNotifier)
final resourceProvider = ResourceNotifierProvider._();

final class ResourceNotifierProvider
    extends $NotifierProvider<ResourceNotifier, ResourceState> {
  ResourceNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'resourceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$resourceNotifierHash();

  @$internal
  @override
  ResourceNotifier create() => ResourceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResourceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResourceState>(value),
    );
  }
}

String _$resourceNotifierHash() => r'40e0f9084e55f56a36a0ceb34bdbcf7753e09a26';

abstract class _$ResourceNotifier extends $Notifier<ResourceState> {
  ResourceState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ResourceState, ResourceState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ResourceState, ResourceState>,
        ResourceState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
