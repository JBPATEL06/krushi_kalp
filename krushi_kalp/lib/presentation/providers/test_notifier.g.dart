// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$testCategoriesHash() => r'e3db387d8a4678ea9a85fad9d18ba35457b009fb';

/// See also [testCategories].
@ProviderFor(testCategories)
final testCategoriesProvider = AutoDisposeProvider<List<String>>.internal(
  testCategories,
  name: r'testCategoriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$testCategoriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TestCategoriesRef = AutoDisposeProviderRef<List<String>>;
String _$testNotifierHash() => r'47bc49268a00b140458e6796ded82f6623a339b7';

/// See also [TestNotifier].
@ProviderFor(TestNotifier)
final testNotifierProvider = NotifierProvider<TestNotifier, TestState>.internal(
  TestNotifier.new,
  name: r'testNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$testNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TestNotifier = Notifier<TestState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
