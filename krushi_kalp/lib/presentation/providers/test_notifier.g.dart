// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TestNotifier)
final testProvider = TestNotifierProvider._();

final class TestNotifierProvider
    extends $NotifierProvider<TestNotifier, TestState> {
  TestNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'testProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$testNotifierHash();

  @$internal
  @override
  TestNotifier create() => TestNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TestState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TestState>(value),
    );
  }
}

String _$testNotifierHash() => r'0b47b012f7a71aee8a9e255cef25d19a1bdcd81f';

abstract class _$TestNotifier extends $Notifier<TestState> {
  TestState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TestState, TestState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<TestState, TestState>, TestState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(testCategories)
final testCategoriesProvider = TestCategoriesProvider._();

final class TestCategoriesProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  TestCategoriesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'testCategoriesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$testCategoriesHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return testCategories(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$testCategoriesHash() => r'0c1fa935c9f0b7425f761576e555ed378f8d5f0e';
