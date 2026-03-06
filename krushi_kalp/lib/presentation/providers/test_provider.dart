import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/mock_test.dart';
import '../../data/services/test_service.dart';
import '../../data/services/auth_service.dart';

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
    } catch (e) {
      debugPrint('TestProvider: Error loading from cache: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData =
          json.encode(_userTests.map((t) => t.toJson()).toList());
      await prefs.setString(_purchasedTestsKey, encodedData);
      debugPrint('TestProvider: Saved ${_userTests.length} tests to cache');
    } catch (e) {
      debugPrint('TestProvider: Error saving to cache: $e');
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

    try {
      final results = await Future.wait([
        TestService.instance.fetchAllTestsRaw(),
        fetchPurchasedStatus(),
      ]);

      final response = results[0] as List<dynamic>;
      List<MockTest> fetchedTests = await compute(_parseMockTests, response);

      fetchedTests = await _signUrls(fetchedTests);
      _cachedTests = fetchedTests;
      filterAndSortTests();
    } catch (e) {
      debugPrint('TestProvider: Error fetching tests: $e');
      _errorMessage = 'Failed to load tests. Please check your connection.';
    } finally {
      _setLoading(false);
    }
  }

  Future<List<MockTest>> _signUrls(List<MockTest> tests) async {
    return await Future.wait(
      tests.map((test) async {
        if (test.coverImagePath != null) {
          try {
            final freshUrl = await TestService.instance
                .getSignedUrl(test.coverImagePath!, 'mock_test');
            return test.copyWith(signedUrl: freshUrl);
          } catch (e) {
            return test;
          }
        }
        return test;
      }),
    );
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
    } catch (e) {
      debugPrint("Error fetching purchased status: $e");
    }
  }

  Future<void> fetchUserTests(String userId) async {
    _setLoading(true);
    _errorMessage = '';
    try {
      _userTests = await TestService.instance.fetchUserTests(userId);
      _purchasedTestIds = _userTests.map((t) => t.id).toSet();
      _saveToPrefs();
    } catch (e) {
      debugPrint("Error fetching user tests: $e");
      _errorMessage = 'Error loading your tests: $e';
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

// Top-level function for background isolate JSON parsing
List<MockTest> _parseMockTests(List<dynamic> jsonList) {
  return jsonList.map((json) => MockTest.fromJson(json)).toList();
}
