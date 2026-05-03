// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AdminNotifier)
final adminProvider = AdminNotifierProvider._();

final class AdminNotifierProvider
    extends $NotifierProvider<AdminNotifier, AdminState> {
  AdminNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'adminProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$adminNotifierHash();

  @$internal
  @override
  AdminNotifier create() => AdminNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminState>(value),
    );
  }
}

String _$adminNotifierHash() => r'0d5f6aa9fbb0ced7eb73b59a8f251d75c9d2c4fc';

abstract class _$AdminNotifier extends $Notifier<AdminState> {
  AdminState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AdminState, AdminState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AdminState, AdminState>, AdminState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
