import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/mock_test.dart';
import '../../data/services/test_service.dart';
import '../../data/services/auth_service.dart';
import '../../utils/crashlytics_service.dart';
import '../../utils/supabase_url_helper.dart';
import '../../data/services/local_caching_service.dart'; // NEW
import '../../data/local/entities/mock_test_entity.dart'; // NEW

class TestProvider with ChangeNotifier {
  static const String _purchasedTestsKey = 'cached_user_purchased_tests';

  List<MockTest> _allTests = [];
  List<MockTest> _cachedTests = [];
  List<MockTest> _userTests = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Set<int> _purchasedTestIds = {};

  TestProvider() {
    _loadFromPrefs();
  }

  List<MockTest> get tests => _allTests;
  Set<int> get purchasedTestIds => _purchasedTestIds;
  List<MockTest> get purchasedTests => _cachedTests
      .where((test) => _purchasedTestIds.contains(test.id))
      .toList();
  List<MockTest> get userTests => _userTests;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  List<String> get categories {
    final uniqueCategories = _cachedTests
        .map((t) => t.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    uniqueCategories.sort();
    return ['All', ...uniqueCategories];
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_purchasedTestsKey);
      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        _userTests = jsonList.map((j) => MockTest.fromJson(j)).toList();
        _purchasedTestIds = _userTests.map((t) => t.id).toSet();
        
        notifyListeners();
      }
    } catch (e, stack) {
      
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'TestProvider: _loadFromPrefs');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData =
          json.encode(_userTests.map((t) => t.toJson()).toList());
      await prefs.setString(_purchasedTestsKey, encodedData);
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'TestProvider: _saveToPrefs');
    }
  }

  Future<void> fetchTests({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedTests.isNotEmpty) {
      _allTests = List.from(_cachedTests);
      _isLoading = false;
      _errorMessage = '';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _errorMessage = '';
    CrashlyticsService.instance
        .log('TestProvider: Fetching tests (force: $forceRefresh)');

    try {
      // 1. Instantly load from Isar NoSQL (Local Cache)
      final cachedEntities = await LocalCachingService.getCachedMockTests();
      if (cachedEntities.isNotEmpty && _cachedTests.isEmpty) {
        _cachedTests = cachedEntities.map((e) => e.toMockTest()).toList();
        filterAndSortTests(); // Update UI instantly with local data
      }

      // 2. Fetch fresh data from Supabase silently in background
      final results = await Future.wait([
        TestService.instance.fetchMockTests(),
        fetchPurchasedStatus(),
      ]);

      final fetchedTests = results[0] as List<MockTest>;
      _cachedTests = fetchedTests;

      // 3. Save fresh data to Isar for next un-networked launch
      if (fetchedTests.isNotEmpty) {
        final entitiesToSave =
            fetchedTests.map((t) => MockTestEntity.fromMockTest(t)).toList();
        LocalCachingService.saveMockTests(entitiesToSave);
      }

      // Step: Perform bulk pre-signing of URLs after fetching the list.
      // This populates the cache in SupabaseUrlHelper so the UI
      // never waits for a network request when the user taps an item.
      _preSignUrls(fetchedTests);

      filterAndSortTests();
    } catch (e, stack) {
      _errorMessage = 'Failed to load tests. Please check your connection.';
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'TestProvider: fetchTests');
    } finally {
      _setLoading(false);
    }
  }

  /// Internal method to trigger background pre-signing of all content URLs.
  void _preSignUrls(List<MockTest> tests) {
    if (tests.isEmpty) return;

    // We start the signing process but don't 'await' it to avoid blocking
    // the UI from rendering the list immediately.
    Future(() async {
      try {
        final List<Future<String>> signFutures = tests
            .where((t) => t.contentUrl?.isNotEmpty ?? false)
            .map((t) => SupabaseUrlHelper()
                .getFreshSignedUrl('mock_test', t.contentUrl!))
            .toList();

        if (signFutures.isNotEmpty) {
          
          await Future.wait(signFutures);
          
        }
      } catch (e) {
        // Silent error for pre-signing as individual taps will retry and report
        
      }
    });
  }

  Future<void> fetchPurchasedStatus() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _purchasedTestIds.clear();
      return;
    }
    try {
      final ids = await TestService.instance.fetchPurchasedTestIds(user.id);
      _purchasedTestIds = ids;

      if (_cachedTests.isNotEmpty) {
        filterAndSortTests();
      }
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'TestProvider: fetchPurchasedStatus');
    }
  }

  Future<void> fetchUserTests(String userId) async {
    _setLoading(true);
    _errorMessage = '';
    try {
      _userTests = await TestService.instance.fetchUserTests(userId);
      _purchasedTestIds = _userTests.map((t) => t.id).toSet();
      _saveToPrefs();

      // Pre-sign content URLs for the user's purchased tests too
      _preSignUrls(_userTests);

      CrashlyticsService.instance
          .log('TestProvider: Fetched ${_userTests.length} user tests');
    } catch (e, stack) {
      _errorMessage = 'Error loading your tests: $e';
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'TestProvider: fetchUserTests');
    } finally {
      _setLoading(false);
    }
  }

  void filterAndSortTests({
    String query = '',
    String category = 'All',
    String sortOption = 'Latest',
  }) {
    List<MockTest> temp = List.from(_cachedTests);

    if (query.isNotEmpty) {
      temp = temp.where((test) {
        final title = test.title.toLowerCase();
        final search = query.toLowerCase();
        return title.contains(search);
      }).toList();
    }

    if (category != 'All') {
      temp = temp.where((test) => test.category == category).toList();
    }

    if (sortOption == 'Price: Low to High') {
      temp.sort((a, b) {
        int cmp = a.finalPrice.compareTo(b.finalPrice);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });
    } else if (sortOption == 'Price: High to Low') {
      temp.sort((a, b) {
        int cmp = b.finalPrice.compareTo(a.finalPrice);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });
    } else {
      temp.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    _allTests = temp;
    Future.microtask(() => notifyListeners());
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    Future.microtask(() => notifyListeners());
  }

  @override
  void dispose() {
    _allTests.clear();
    _cachedTests.clear();
    super.dispose();
  }
}
