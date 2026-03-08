import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/mock_test.dart';
import '../../data/services/test_service.dart';
import '../../data/services/auth_service.dart';
import '../../utils/crashlytics_service.dart';

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
        debugPrint(
            'TestProvider: Loaded ${_userTests.length} tests from cache');
        notifyListeners();
      }
    } catch (e, stack) {
      debugPrint('TestProvider: Error loading from cache: $e');
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
      final results = await Future.wait([
        TestService.instance.fetchMockTests(),
        fetchPurchasedStatus(),
      ]);

      final fetchedTests = results[0] as List<MockTest>;
      _cachedTests = fetchedTests;
      filterAndSortTests();
    } catch (e, stack) {
      _errorMessage = 'Failed to load tests. Please check your connection.';
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'TestProvider: fetchTests');
    } finally {
      _setLoading(false);
    }
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
