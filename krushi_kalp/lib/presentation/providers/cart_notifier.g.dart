// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CartNotifier)
final cartProvider = CartNotifierProvider._();

final class CartNotifierProvider
    extends $NotifierProvider<CartNotifier, CartState> {
  CartNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'cartProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$cartNotifierHash();

  @$internal
  @override
  CartNotifier create() => CartNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CartState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CartState>(value),
    );
  }
}

String _$cartNotifierHash() => r'e1ecded49e9c3955b61482dc3b5d23fa9d3a0d5c';

abstract class _$CartNotifier extends $Notifier<CartState> {
  CartState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CartState, CartState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<CartState, CartState>, CartState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
