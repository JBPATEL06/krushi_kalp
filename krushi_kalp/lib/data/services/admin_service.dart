import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../../utils/supabase_url_helper.dart';
import '../../utils/crashlytics_service.dart';
import '../../utils/retry_helper.dart';

class AdminService {
  static final _supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase.from('users').select('id, email, username');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_service');
      return [];
    }
  }

  static Future<String?> getUserIdByEmail(String email) async {
    try {
      final response = await _supabase.from('users').select('id').eq('email', email).maybeSingle();
      return response?['id'] as String?;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_service');
      return null;
    }
  }

  static Stream<Map<String, dynamic>> streamDashboardStats() {
    return Stream.periodic(const Duration(seconds: 30))
        .startWith(null)
        .asyncMap((_) async {
      try {
        final List<Future<dynamic>> futures = [
          _supabase.from('mock_tests').count(CountOption.exact),
          _supabase.from('resources').count(CountOption.exact),
          _supabase.from('users').count(CountOption.exact),
          _supabase.from('offers').count(CountOption.exact).eq('is_active', true),
          _supabase.from('order_items').count(CountOption.exact),
          _supabase.from('order_items').count(CountOption.exact).not('test_id', 'is', null),
          _supabase.from('order_items').count(CountOption.exact).not('resource_id', 'is', null),
        ];

        final results = await RetryHelper.run(
          () async => await Future.wait(futures),
          maxRetries: 3,
          initialDelay: const Duration(seconds: 2),
        );

        double revenue = 0.0;
        int totalPurchased = 0;

        try {
          final rpcRevenue = await _supabase.rpc('calculate_total_revenue');
          revenue = (rpcRevenue as num).toDouble();
          final ordersCount = await _supabase.from('orders').count(CountOption.exact).eq('status', 'SUCCESS');
          totalPurchased = ordersCount;
        } catch (e, stack) {
          CrashlyticsService.instance.recordError(e, stack, reason: 'admin_service_stats_rpc');
          final ordersList = await _supabase.from('orders').select('total_amount').eq('status', 'SUCCESS');
          totalPurchased = ordersList.length;
          revenue = ordersList.fold(0.0, (sum, item) => sum + (item['total_amount'] as num).toDouble());
        }

        return {
          'totalTests': results[0] as int,
          'totalResources': results[1] as int,
          'totalUsers': results[2] as int,
          'totalPurchased': totalPurchased,
          'testSales': results[5] as int,
          'resourceSales': results[6] as int,
          'revenue': revenue,
          'activeOffers': results[3] as int,
        };
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'admin_service_dashboard_stream');
        return {
          'totalTests': 0, 'totalResources': 0, 'totalUsers': 0, 'totalPurchased': 0,
          'testSales': 0, 'resourceSales': 0, 'revenue': 0.0, 'activeOffers': 0,
        };
      }
    });
  }

  static Stream<List<Map<String, dynamic>>> streamTopUsers() {
    return Stream.periodic(const Duration(seconds: 60))
        .startWith(null)
        .asyncMap((_) async {
      try {
        final results = await RetryHelper.run(
          () async => await _supabase.from('results').select('user_id, test_id, score_obtained').order('attempt_date', ascending: false).limit(100),
          maxRetries: 2,
        );
        if (results.isEmpty) return [];

        final userIds = results.map((r) => r['user_id']).toSet().toList();
        final testIds = results.map((r) => r['test_id']).toSet().toList();

        final usersResponse = await _supabase.from('users').select('id, username, email').inFilter('id', userIds);
        final userMap = {for (var u in usersResponse) u['id']: u};

        final testsResponse = await _supabase.from('mock_tests').select('test_id, total_marks').inFilter('test_id', testIds);
        final testMap = {for (var t in testsResponse) t['test_id']: t};

        final Map<String, Map<String, dynamic>> userStats = {};
        for (var r in results) {
          final user = userMap[r['user_id']];
          final test = testMap[r['test_id']];
          if (user == null) continue;

          final email = user['email'] ?? 'Unknown';
          final score = (r['score_obtained'] as num).toDouble();
          final total = test != null ? (test['total_marks'] as num).toDouble() : 0.0;

          if (!userStats.containsKey(email)) {
            userStats[email] = { 'username': user['username'] ?? 'User', 'email': email, 'totalScore': 0.0, 'totalMax': 0.0, 'testsTaken': 0 };
          }
          userStats[email]!['totalScore'] += score;
          userStats[email]!['totalMax'] += total;
          userStats[email]!['testsTaken'] += 1;
        }

        final sortedUsers = userStats.values.toList();
        sortedUsers.sort((a, b) {
          double pctA = a['totalMax'] > 0 ? (a['totalScore'] / a['totalMax']) : 0;
          double pctB = b['totalMax'] > 0 ? (b['totalScore'] / b['totalMax']) : 0;
          return pctB.compareTo(pctA);
        });
        return sortedUsers.take(10).toList();
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'admin_service_top_users');
        return [];
      }
    });
  }

  static Stream<List<Map<String, dynamic>>> streamTopTests() {
    return Stream.periodic(const Duration(seconds: 60))
        .startWith(null)
        .asyncMap((_) async {
      try {
        final items = await RetryHelper.run(
          () async => await _supabase.from('order_items').select('test_id').not('test_id', 'is', null).limit(200),
          maxRetries: 2,
        );
        if (items.isEmpty) return [];

        final Map<int, int> testSalesCount = {};
        for (var item in items) {
          final id = item['test_id'] as int?;
          if (id != null) testSalesCount[id] = (testSalesCount[id] ?? 0) + 1;
        }

        final sortedIDs = testSalesCount.keys.toList()..sort((a, b) => testSalesCount[b]!.compareTo(testSalesCount[a]!));
        final top3IDs = sortedIDs.take(3).toList();
        if (top3IDs.isEmpty) return [];

        final testsResponse = await _supabase
            .from('mock_tests')
            .select('test_id, title, category, price, cover_image_path')
            .inFilter('test_id', top3IDs);
        final testMap = {for (var t in testsResponse) t['test_id']: t};
        final List<Map<String, dynamic>> result = [];

        for (var id in top3IDs) {
          final test = testMap[id];
          if (test == null) continue;
          
          String? signedUrl;
          final rawImagePath = test['cover_image_path'] as String?;
          if (rawImagePath != null && rawImagePath.isNotEmpty) {
            final cleanPath = SupabaseUrlHelper.extractPathFromUrl(rawImagePath, 'mock_test');
            signedUrl = await SupabaseUrlHelper().getFreshSignedUrl('mock_test', cleanPath);
          }

          result.add({
            'id': id,
            'title': test['title'],
            'category': test['category'],
            'price': (test['price'] as num?)?.toDouble() ?? 0.0,
            'sales': testSalesCount[id] ?? 0,
            'image_url': signedUrl,
          });
        }
        return result;
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'admin_service_top_tests');
        return [];
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getAllUsersWithActivity() async {
    try {
      final users = await _supabase.from('users').select('id, email, username, created_at');
      if (users.isEmpty) return [];

      final userIds = users.map((u) => u['id']).toList();
      final lastResultsResponse = await _supabase.from('results').select('user_id, attempt_date').inFilter('user_id', userIds).order('attempt_date', ascending: false);

      final Map<String, String> lastActiveMap = {};
      for (var res in lastResultsResponse) {
        final uid = res['user_id'] as String;
        if (!lastActiveMap.containsKey(uid)) lastActiveMap[uid] = res['attempt_date'] as String;
      }

      return users.map((user) => { ...user, 'last_active': lastActiveMap[user['id']] }).toList();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_service_activity');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try { return await _supabase.from('users').select('*').eq('id', userId).single(); }
    catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_service_user_details');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final response = await _supabase.from('orders').select('*').eq('user_id', userId).eq('status', 'SUCCESS').order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) { return []; }
  }

  static Future<List<Map<String, dynamic>>> getUserResults(String userId) async {
    try {
      final response = await _supabase.from('results').select('*, mock_tests(title, total_marks)').eq('user_id', userId).order('attempt_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) { return []; }
  }

  static Future<void> promoteToAdmin(String userId) async {
    await _supabase.from('users').update({'role': 'Admin'}).eq('id', userId);
  }

  static Future<void> demoteToUser(String userId) async {
    await _supabase.from('users').update({'role': 'Student'}).eq('id', userId);
  }

  static Stream<List<Map<String, dynamic>>> streamUsers() {
    return Stream.periodic(const Duration(seconds: 60))
        .startWith(null)
        .asyncMap((_) async {
      try {
        final users = await _supabase.from('users').select('id, email, username, created_at').order('created_at', ascending: false).limit(100);
        if (users.isEmpty) return [];

        final userIds = users.map((u) => u['id']).toList();
        final lastResultsResponse = await _supabase.from('results').select('user_id, attempt_date').inFilter('user_id', userIds).order('attempt_date', ascending: false);

        final Map<String, String> lastActiveMap = {};
        for (var res in lastResultsResponse) {
          final uid = res['user_id'] as String;
          if (!lastActiveMap.containsKey(uid)) lastActiveMap[uid] = res['attempt_date'] as String;
        }

        return users.map((user) => { ...user, 'last_active': lastActiveMap[user['id']] }).toList();
      } catch (e) { return []; }
    });
  }

  static Future<List<Map<String, dynamic>>> getPaginatedUsers({ required int offset, required int limit, String? searchQuery, String? statusFilter }) async {
    try {
      var query = _supabase.from('users').select('id, email, username, created_at');
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('username.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }
      final users = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
      if (users.isEmpty) return [];

      final userIds = users.map((u) => u['id']).toList();
      final lastResultsResponse = await _supabase.from('results').select('user_id, attempt_date').inFilter('user_id', userIds).order('attempt_date', ascending: false);

      final Map<String, String> lastActiveMap = {};
      for (var res in lastResultsResponse) {
        final uid = res['user_id'] as String;
        if (!lastActiveMap.containsKey(uid)) lastActiveMap[uid] = res['attempt_date'] as String;
      }

      var resultList = users.map((user) => { ...user, 'last_active': lastActiveMap[user['id']] }).toList();
      if (statusFilter == 'Active') {
        final threshold = DateTime.now().subtract(const Duration(days: 15));
        resultList = resultList.where((u) {
          final last = DateTime.tryParse(u['last_active'] ?? '');
          return last != null && last.isAfter(threshold);
        }).toList();
      }
      return resultList;
    } catch (e) { return []; }
  }

  static Stream<Map<String, dynamic>> streamUserDetails(String userId) {
    return _supabase.from('users').stream(primaryKey: ['id']).eq('id', userId).map((event) => event.first);
  }

  static Stream<List<Map<String, dynamic>>> streamUserOrders(String userId) {
    return _supabase.from('orders').stream(primaryKey: ['order_id']).eq('user_id', userId).order('created_at', ascending: false).map((orders) => orders.where((o) => o['status'] == 'SUCCESS').toList());
  }

  static Stream<List<Map<String, dynamic>>> streamUserResults(String userId) {
    return _supabase.from('results').stream(primaryKey: ['result_id']).eq('user_id', userId).order('attempt_date', ascending: false).asyncMap((results) async {
      if (results.isEmpty) return [];
      final testIds = results.map((r) => r['test_id']).toSet().toList();
      final tests = await _supabase.from('mock_tests').select('test_id, title, total_marks').inFilter('test_id', testIds);
      final testMap = {for (var t in tests) t['test_id']: t};
      return results.map((r) => { ...r, 'mock_tests': testMap[r['test_id']] }).toList();
    });
  }

  static Future<void> deleteUser(String userId) async {
    await _supabase.rpc('admin_hard_delete_user', params: {'target_user_id': userId});
  }

  static Future<Map<String, dynamic>> getResourceTypeStats(String type) async {
    try {
      final res = await _supabase.from('resources').select('id').eq('type', type).count(CountOption.exact);
      final sales = await _supabase.from('order_items').select('item_id, resources!inner(type)').eq('resources.type', type);
      return { 'totalCount': res.count, 'salesCount': (sales as List).length };
    } catch (e) { return {'totalCount': 0, 'salesCount': 0}; }
  }

  static Future<Map<String, dynamic>> getResourceItemStats(int resourceId) async {
    try {
      final itemRes = await _supabase.from('resources').select('price').eq('id', resourceId).single();
      final salesRes = await _supabase.from('order_items').select('item_id').eq('resource_id', resourceId).count(CountOption.exact);
      return { 'price': (itemRes['price'] as num?)?.toDouble() ?? 0.0, 'salesCount': salesRes.count };
    } catch (e) { return {'price': 0.0, 'salesCount': 0}; }
  }

  static Future<Map<String, dynamic>> getMockTestItemStats(int testId) async {
    try {
      final itemRes = await _supabase.from('mock_tests').select('price').eq('test_id', testId).single();
      final salesRes = await _supabase.from('order_items').select('item_id').eq('test_id', testId).count(CountOption.exact);
      return { 'price': (itemRes['price'] as num?)?.toDouble() ?? 0.0, 'salesCount': salesRes.count };
    } catch (e) { return {'price': 0.0, 'salesCount': 0}; }
  }

  static Future<Map<String, dynamic>?> fetchOrderById(String orderId) async {
    try {
      return await _supabase.from('orders').select('*, users:user_id(username, email, phonenumber), offers:offer_id(code, discount_value, discount_type), order_items(*, mock_tests(title), resources(title, type))').eq('order_id', orderId).maybeSingle();
    } catch (e) { return null; }
  }

  static Future<List<Map<String, dynamic>>> fetchPaginatedOrders({ required int offset, required int limit, String? searchQuery }) async {
    try {
      var query = _supabase.from('orders').select('*, users:user_id(username, email), offers:offer_id(code, discount_value, discount_type), order_items(*, mock_tests(title), resources(title, type))').eq('status', 'SUCCESS');
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('order_id.ilike.%$searchQuery%,payment_id.ilike.%$searchQuery%');
      }
      final response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) { return []; }
  }

  static Future<List<Map<String, dynamic>>> fetchAllOrdersWithDetails() async {
    try {
      final response = await _supabase.from('orders').select('*, users:user_id(username, email), offers:offer_id(code, discount_value, discount_type), order_items(*, mock_tests(title), resources(title, type))').eq('status', 'SUCCESS').order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) { return []; }
  }

  /// Manually grants access to a user for a specific item (test or resource).
  static Future<bool> grantAccess({
    required String userId,
    required int itemId,
    required String itemType,
  }) async {
    try {
      // 1. Fetch item snapshot for historical integrity
      Map<String, dynamic> itemSnapshot = {};
      if (itemType == 'test') {
        final test = await _supabase.from('mock_tests').select().eq('test_id', itemId).maybeSingle();
        if (test != null) itemSnapshot = test;
      } else if (itemType == 'resource') {
        final resource = await _supabase.from('resources').select().eq('id', itemId).maybeSingle();
        if (resource != null) itemSnapshot = resource;
      }

      // 2. Upsert into access table using the unique constraint
      await _supabase.from('access').upsert({
        'user_id': userId,
        'item_id': itemId,
        'item_type': itemType,
        'item_snapshot': itemSnapshot,
        'granted_at': DateTime.now().toIso8601String(),
        'is_active': true,
      }, onConflict: 'user_id, item_type, item_id');
      
      return true;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_grant_access');
      return false;
    }
  }

  /// Manually revokes access from a user.
  static Future<bool> revokeAccess({
    required String userId,
    required int itemId,
    required String itemType,
  }) async {
    try {
      await _supabase
          .from('access')
          .delete()
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .eq('item_type', itemType);
      return true;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_revoke_access');
      return false;
    }
  }
}
