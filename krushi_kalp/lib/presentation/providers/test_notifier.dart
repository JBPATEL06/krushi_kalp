import 'dart:async';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/mock_test.dart';
import '../../data/services/test_service.dart';
import '../../data/services/auth_service.dart';
import '../../utils/crashlytics_service.dart';
import '../../data/services/local_caching_service.dart';
import '../../data/local/entities/mock_test_entity.dart';
import 'test_state.dart';

part 'test_notifier.g.dart';

@Riverpod(keepAlive: true)
class TestNotifier extends _$TestNotifier {
  static const String _purchasedTestsKey = 'cached_user_purchased_tests';

  @override
  TestState build() {
    // Load from cached settings after build completion ensures safety
    Future(() => _loadFromPrefs());
    return const TestState();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_purchasedTestsKey);
      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        final userTests = jsonList.map((j) => MockTest.fromJson(j)).toList();
        state = state.copyWith(
          userTests: userTests,
          purchasedTestIds: userTests.map((t) => t.id).toSet(),
        );
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'TestNotifier: _loadFromPrefs');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = json.encode(state.userTests.map((t) => t.toJson()).toList());
      await prefs.setString(_purchasedTestsKey, encodedData);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'TestNotifier: _saveToPrefs');
    }
  }

  Future<void> fetchTests({bool forceRefresh = false}) async {
    // Defer to next event loop tick to avoid "setState during build"
    await Future(() {});

    if (!forceRefresh && state.cachedTests.isNotEmpty) {
      _applyFiltering();
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');
    CrashlyticsService.instance.log('TestNotifier: Fetching tests (force: $forceRefresh)');

    try {
      // 1. Instantly load from Isar NoSQL (Local Cache)
      final cachedEntities = await LocalCachingService.getCachedMockTests();
      if (cachedEntities.isNotEmpty && state.cachedTests.isEmpty) {
        final cachedTests = cachedEntities.map((e) => e.toMockTest()).toList();
        state = state.copyWith(cachedTests: cachedTests);
        _applyFiltering();
      }

      // 2. Fetch fresh data from Supabase silently in background
      final results = await Future.wait([
        TestService.instance.fetchMockTests(),
        _fetchPurchasedStatusSilently(),
      ]);

      final fetchedTests = results[0] as List<MockTest>;
      
      // Update state with fresh results
      state = state.copyWith(cachedTests: fetchedTests);

      // 3. Save fresh data to Isar
      if (fetchedTests.isNotEmpty) {
        final entitiesToSave = fetchedTests.map((t) => MockTestEntity.fromMockTest(t)).toList();
        LocalCachingService.saveMockTests(entitiesToSave);
      }

      _applyFiltering();
    } catch (e, stack) {
       CrashlyticsService.instance.recordError(e, stack, reason: 'TestNotifier: fetchTests');
       state = state.copyWith(errorMessage: 'Failed to load tests. Please check connection.');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Set<int>> _fetchPurchasedStatusSilently() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return {};
    try {
      final ids = await TestService.instance.fetchPurchasedTestIds(user.id).timeout(const Duration(seconds: 15));
      state = state.copyWith(purchasedTestIds: ids);
      return ids;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'TestNotifier: _fetchPurchasedStatus');
      return state.purchasedTestIds;
    }
  }

  Future<void> fetchUserTests(String userId) async {
    // Defer to next event loop tick to avoid "setState during build"
    await Future(() {});
    
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final userTests = await TestService.instance.fetchUserTests(userId);
      state = state.copyWith(
        userTests: userTests,
        purchasedTestIds: userTests.map((t) => t.id).toSet(),
      );
      _saveToPrefs();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'TestNotifier: fetchUserTests');
      state = state.copyWith(errorMessage: 'Error loading your tests: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateFilters({String? query, String? category, String? sortOption}) {
    state = state.copyWith(
      searchQuery: query ?? state.searchQuery,
      selectedCategory: category ?? state.selectedCategory,
      sortOption: sortOption ?? state.sortOption,
    );
    _applyFiltering();
  }

  void _applyFiltering() {
    List<MockTest> temp = List.from(state.cachedTests);

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      temp = temp.where((test) => test.title.toLowerCase().contains(query)).toList();
    }

    if (state.selectedCategory != 'All') {
      temp = temp.where((test) => test.category == state.selectedCategory).toList();
    }

    if (state.sortOption == 'Price: Low to High') {
      temp.sort((a, b) {
        int cmp = a.finalPrice.compareTo(b.finalPrice);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });
    } else if (state.sortOption == 'Price: High to Low') {
      temp.sort((a, b) {
        int cmp = b.finalPrice.compareTo(a.finalPrice);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });
    } else {
      temp.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    state = state.copyWith(allTests: temp);
  }

}

@riverpod
List<String> testCategories(Ref ref) {
  final cachedTests =
      ref.watch(testNotifierProvider.select((s) => s.cachedTests));
  final uniqueCategories = cachedTests
      .map((t) => t.category)
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList();
  uniqueCategories.sort();
  return ['All', ...uniqueCategories];
}
