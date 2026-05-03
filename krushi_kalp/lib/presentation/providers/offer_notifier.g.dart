// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OfferNotifier)
final offerProvider = OfferNotifierProvider._();

final class OfferNotifierProvider
    extends $NotifierProvider<OfferNotifier, OfferState> {
  OfferNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'offerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$offerNotifierHash();

  @$internal
  @override
  OfferNotifier create() => OfferNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OfferState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OfferState>(value),
    );
  }
}

String _$offerNotifierHash() => r'6f084134f52dcfcc312fde2016eeb84020abead6';

abstract class _$OfferNotifier extends $Notifier<OfferState> {
  OfferState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OfferState, OfferState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<OfferState, OfferState>, OfferState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
