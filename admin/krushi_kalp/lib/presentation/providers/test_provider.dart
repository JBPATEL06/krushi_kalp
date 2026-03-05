import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/mock_test.dart';
import '../../data/services/test_service.dart';

class TestProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
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
      final response = await _supabase
          .from('mock_tests')
          .select()
          .order('created_at', ascending: false);

      await fetchPurchasedStatus();

      final List<dynamic> data = response;
      List<MockTest> fetchedTests =
          data.map((json) => MockTest.fromJson(json)).toList();

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
            String path = test.coverImagePath!.replaceAll('mock_test/', '');
            final signedUrl = await _supabase.storage
                .from('mock_test')
                .createSignedUrl(path, 60 * 60);

            final freshUrl =
                '$signedUrl&v=${DateTime.now().millisecondsSinceEpoch}';

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
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _purchasedTestIds.clear();
      return;
    }
    try {
      final ordersResponse = await _supabase
          .from('orders')
          .select('order_id')
          .eq('user_id', user.id)
          .inFilter('status', ['SUCCESS', 'COMPLETED']);

      if ((ordersResponse as List).isEmpty) {
        _purchasedTestIds.clear();
        return;
      }

      final orderIds = (ordersResponse).map((o) => o['order_id']).toList();

      final itemsResponse = await _supabase
          .from('order_items')
          .select('test_id')
          .inFilter('order_id', orderIds);

      final ids = (itemsResponse as List)
          .where((i) => i['test_id'] != null)
          .map((i) => i['test_id'] as int)
          .toSet();
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
    try {
      _userTests = await TestService.fetchPurchasedTests(userId);
      _purchasedTestIds = _userTests.map((t) => t.id).toSet();
      _saveToPrefs();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching user tests: $e");
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
        return b.id.compareTo(a.id);
      });
    } else if (sortOption == 'Price: High to Low') {
      temp.sort((a, b) {
        int cmp = b.finalPrice.compareTo(a.finalPrice);
        if (cmp != 0) return cmp;
        return b.id.compareTo(a.id);
      });
    } else {
      temp.sort((a, b) => b.id.compareTo(a.id));
    }

    _allTests = temp;
    Future.microtask(() => notifyListeners());
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    Future.microtask(() => notifyListeners());
  }
}
