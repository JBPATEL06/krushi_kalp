// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NetworkNotifier)
final networkProvider = NetworkNotifierProvider._();

final class NetworkNotifierProvider
    extends $NotifierProvider<NetworkNotifier, bool> {
  NetworkNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'networkProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$networkNotifierHash();

  @$internal
  @override
  NetworkNotifier create() => NetworkNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$networkNotifierHash() => r'cb6b79606aed832a20582b7b498a14e44e9d232c';

abstract class _$NetworkNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
