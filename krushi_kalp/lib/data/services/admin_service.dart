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
          _supabase.from('access').count(CountOption.exact),
          _supabase.from('access').count(CountOption.exact).eq('item_type', 'test'),
          _supabase.from('access').count(CountOption.exact).eq('item_type', 'resource'),
        ];

        final results = await RetryHelper.run(
          () async => await Future.wait(futures),
          maxRetries: 3,
          initialDelay: const Duration(seconds: 2),
        );

        double revenue = 0.0;
        int totalPurchased = 0;

        try {
          // Use the new RPC which is migrated to payment table
          final rpcRevenue = await _supabase.rpc('calculate_total_revenue');
          revenue = (rpcRevenue as num).toDouble();
          
          // Count from payment table instead of legacy orders
          final paymentsCount = await _supabase.from('payment').count(CountOption.exact).eq('status', 'SUCCESS');
          totalPurchased = paymentsCount;
        } catch (e, stack) {
          CrashlyticsService.instance.recordError(e, stack, reason: 'admin_service_stats_rpc');
          // Fallback to manual sum from payment table
          final paymentList = await _supabase.from('payment').select('amount').eq('status', 'SUCCESS');
          totalPurchased = paymentList.length;
          revenue = paymentList.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
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
          () async => await _supabase.from('access').select('item_id').eq('item_type', 'test').limit(200),
          maxRetries: 2,
        );
        if (items.isEmpty) return [];

        final Map<int, int> testSalesCount = {};
        for (var item in items) {
          final id = item['item_id'] as int?;
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
      final response = await _supabase.from('payment').select('*').eq('user_id', userId).eq('status', 'SUCCESS').order('created_at', ascending: false);
      // Map 'amount' to 'total_amount' and 'id' to 'order_id' for UI compatibility
      return List<Map<String, dynamic>>.from(response).map((p) => {
        ...p,
        'order_id': p['id'],
        'total_amount': p['amount'],
      }).toList();
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
    return _supabase
        .from('access')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('granted_at', ascending: false)
        .asyncMap((items) async {
          if (items.isEmpty) return [];

          // Fetch associated payment details for discount info
          final paymentIds = items
              .map((i) => i['payment_id'])
              .where((id) => id != null)
              .toSet()
              .toList();
          
          Map<String, dynamic> paymentMap = {};
          if (paymentIds.isNotEmpty) {
            final payments = await _supabase
                .from('payment')
                .select('id, amount, discount_amount, offer_code')
                .inFilter('id', paymentIds);
            paymentMap = {for (var p in payments) p['id'].toString(): p};
          }

          return items.map((item) {
            final snapshot = item['item_snapshot'] as Map<String, dynamic>? ?? {};
            final paymentId = item['payment_id']?.toString();
            final payment = paymentId != null ? paymentMap[paymentId] : null;

            return {
              ...item,
              'item_name': snapshot['title'] ?? 'Untitled Item',
              'created_at': item['granted_at'],
              'payment_details': payment,
            };
          }).toList();
        });
  }

  static Stream<List<Map<String, dynamic>>> streamUserResults(String userId) {
    return _supabase
        .from('results')
        .stream(primaryKey: ['result_id'])
        .eq('user_id', userId)
        .order('attempt_date', ascending: false)
        .asyncMap((results) async {
          if (results.isEmpty) return [];
          final testIds = results.map((r) => r['test_id']).toSet().toList();
          final tests = await _supabase
              .from('mock_tests')
              .select('test_id, title, total_marks')
              .inFilter('test_id', testIds);
          final testMap = {for (var t in tests) t['test_id']: t};
          return results.map((r) => {...r, 'mock_tests': testMap[r['test_id']]}).toList();
        });
  }

  static Future<List<Map<String, dynamic>>> getUserOrdersPaginated(String userId, {int from = 0, int to = 10, String? searchQuery}) async {
    try {
      var query = _supabase
          .from('access')
          .select('*, item_snapshot, payment_id')
          .eq('user_id', userId);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Search in item_snapshot JSONB field
        query = query.ilike('item_snapshot->>title', '%$searchQuery%');
      }

      final items = await query
          .order('granted_at', ascending: false)
          .range(from, to);

      if (items.isEmpty) return [];

      // Fetch associated payment details
      final paymentIds = items
          .map((i) => i['payment_id'])
          .where((id) => id != null)
          .toSet()
          .toList();
      
      Map<String, dynamic> paymentMap = {};
      if (paymentIds.isNotEmpty) {
        final payments = await _supabase
            .from('payment')
            .select('id, amount, discount_amount, offer_code')
            .inFilter('id', paymentIds);
        paymentMap = {for (var p in payments) p['id'].toString(): p};
      }

      return items.map((item) {
        final snapshot = item['item_snapshot'] as Map<String, dynamic>? ?? {};
        final paymentId = item['payment_id']?.toString();
        final payment = paymentId != null ? paymentMap[paymentId] : null;

        return {
          ...item,
          'item_name': snapshot['title'] ?? 'Untitled Item',
          'created_at': item['granted_at'],
          'payment_details': payment,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUserResultsPaginated(String userId, {int from = 0, int to = 10, String? searchQuery}) async {
    try {
      var query = _supabase
          .from('results')
          .select('*, mock_tests!inner(title, total_marks)')
          .eq('user_id', userId);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Filter by the joined mock_tests title
        query = query.ilike('mock_tests.title', '%$searchQuery%');
      }

      final results = await query
          .order('attempt_date', ascending: false)
          .range(from, to);

      return results.map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteUser(String userId) async {
    await _supabase.rpc('admin_hard_delete_user', params: {'target_user_id': userId});
  }

  static Future<Map<String, dynamic>> getResourceTypeStats(String type) async {
    try {
      final res = await _supabase.from('resources').select('id').eq('type', type).count(CountOption.exact);
      // Join with resources to ensure we get current type matches, though we could use snapshots if needed
      final sales = await _supabase.from('access').select('id, resources!inner(type)').eq('item_type', 'resource').eq('resources.type', type);
      return { 'totalCount': res.count, 'salesCount': (sales as List).length };
    } catch (e) { return {'totalCount': 0, 'salesCount': 0}; }
  }

  static Future<Map<String, dynamic>> getResourceItemStats(int resourceId) async {
    try {
      final itemRes = await _supabase.from('resources').select('price').eq('id', resourceId).single();
      final salesRes = await _supabase.from('access').select('id').eq('item_type', 'resource').eq('item_id', resourceId).count(CountOption.exact);
      return { 'price': (itemRes['price'] as num?)?.toDouble() ?? 0.0, 'salesCount': salesRes.count };
    } catch (e) { return {'totalCount': 0, 'salesCount': 0}; }
  }

  static Future<Map<String, dynamic>> getMockTestItemStats(int testId) async {
    try {
      final itemRes = await _supabase.from('mock_tests').select('price').eq('test_id', testId).single();
      final salesRes = await _supabase.from('access').select('id').eq('item_type', 'test').eq('item_id', testId).count(CountOption.exact);
      return { 'price': (itemRes['price'] as num?)?.toDouble() ?? 0.0, 'salesCount': salesRes.count };
    } catch (e) { return {'totalCount': 0, 'salesCount': 0}; }
  }

  static Future<Map<String, dynamic>?> fetchOrderById(String orderId) async {
    try {
      final payment = await _supabase.from('payment').select('*').eq('id', orderId).maybeSingle();
      if (payment == null) return null;

      // Fetch associated access items to simulate order_items
      final accessItems = await _supabase.from('access').select('*').eq('payment_id', orderId);

      return {
        ...payment,
        'order_id': payment['id'],
        'total_amount': payment['amount'],
        'payment_id': payment['gateway_payment_id'],
        'users': payment['user_snapshot'],
        'offers': payment['offer_code'] != null ? {'code': payment['offer_code']} : null,
        'order_items': accessItems.map((a) => {
          'price_at_purchase': a['price_paid'],
          'mock_tests': a['item_type'] == 'test' ? a['item_snapshot'] : null,
          'resources': a['item_type'] == 'resource' ? a['item_snapshot'] : null,
        }).toList(),
      };
    } catch (e) { return null; }
  }

  static Future<List<Map<String, dynamic>>> fetchPaginatedOrders({ required int offset, required int limit, String? searchQuery }) async {
    try {
      var query = _supabase.from('payment').select('*').eq('status', 'SUCCESS');
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('id.ilike.%$searchQuery%,gateway_payment_id.ilike.%$searchQuery%,offer_code.ilike.%$searchQuery%');
      }
      final payments = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
      if (payments.isEmpty) return [];

      // Fetch associated access items
      final paymentIds = payments.map((p) => p['id'] as String).toList();
      final accessItems = await _supabase.from('access').select('*').inFilter('payment_id', paymentIds);

      // Fetch offer details for payments with offer_code
      final offerCodes = payments.map((p) => p['offer_code']).where((c) => c != null).cast<String>().toSet().toList();
      Map<String, Map<String, dynamic>> offersMap = {};
      if (offerCodes.isNotEmpty) {
        final offers = await _supabase.from('offers').select('*').inFilter('code', offerCodes);
        for (var o in offers) {
          offersMap[o['code']] = o;
        }
      }

      final Map<String, List<Map<String, dynamic>>> itemsMap = {};
      for (var item in accessItems) {
        final pid = item['payment_id'] as String;
        itemsMap.putIfAbsent(pid, () => []).add(item);
      }

      return List<Map<String, dynamic>>.from(payments).map((p) {
        final pid = p['id'] as String;
        final items = itemsMap[pid] ?? [];
        final offerCode = p['offer_code'];
        final offerDetails = offerCode != null ? offersMap[offerCode] : null;

        return {
          ...p,
          'order_id': p['id'],
          'total_amount': p['amount'],
          'discount_amount': p['discount_amount'] ?? 0,
          'payment_id': p['gateway_payment_id'],
          'users': p['user_snapshot'],
          'offers': offerDetails,
          'order_items': items.map((a) => {
            'price_at_purchase': a['price_paid'],
            'mock_tests': a['item_type'] == 'test' ? a['item_snapshot'] : null,
            'resources': a['item_type'] == 'resource' ? a['item_snapshot'] : null,
          }).toList(),
        };
      }).toList();
    } catch (e) { return []; }
  }

  static Future<List<Map<String, dynamic>>> fetchAllOrdersWithDetails() async {
    try {
      final payments = await _supabase.from('payment').select('*').eq('status', 'SUCCESS').order('created_at', ascending: false);
      if (payments.isEmpty) return [];

      // Fetch associated access items
      final paymentIds = payments.map((p) => p['id'] as String).toList();
      final accessItems = await _supabase.from('access').select('*').inFilter('payment_id', paymentIds);

      // Fetch offer details for payments with offer_code
      final offerCodes = payments.map((p) => p['offer_code']).where((c) => c != null).cast<String>().toSet().toList();
      Map<String, Map<String, dynamic>> offersMap = {};
      if (offerCodes.isNotEmpty) {
        final offers = await _supabase.from('offers').select('*').inFilter('code', offerCodes);
        for (var o in offers) {
          offersMap[o['code']] = o;
        }
      }

      final Map<String, List<Map<String, dynamic>>> itemsMap = {};
      for (var item in accessItems) {
        final pid = item['payment_id'] as String;
        itemsMap.putIfAbsent(pid, () => []).add(item);
      }

      return List<Map<String, dynamic>>.from(payments).map((p) {
        final pid = p['id'] as String;
        final items = itemsMap[pid] ?? [];
        final offerCode = p['offer_code'];
        final offerDetails = offerCode != null ? offersMap[offerCode] : null;

        return {
          ...p,
          'order_id': p['id'],
          'total_amount': p['amount'],
          'discount_amount': p['discount_amount'] ?? 0,
          'payment_id': p['gateway_payment_id'],
          'users': p['user_snapshot'],
          'offers': offerDetails,
          'order_items': items.map((a) => {
            'price_at_purchase': a['price_paid'],
            'mock_tests': a['item_type'] == 'test' ? a['item_snapshot'] : null,
            'resources': a['item_type'] == 'resource' ? a['item_snapshot'] : null,
          }).toList(),
        };
      }).toList();
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
        'access_type': 'manual_granted',
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

  /// Fetches all mock tests for administration purposes.
  static Future<List<Map<String, dynamic>>> fetchAllMockTests() async {
    try {
      final response = await _supabase.from('mock_tests').select('*').order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Fetches all resources for administration purposes.
  static Future<List<Map<String, dynamic>>> fetchAllResources() async {
    try {
      final response = await _supabase.from('resources').select('*').order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Fetches the IDs of all items a user already has access to.
  static Future<Map<String, Set<int>>> getUserAccessItemIds(String userId) async {
    try {
      final response = await _supabase.from('access').select('item_id, item_type').eq('user_id', userId);
      final Set<int> testIds = {};
      final Set<int> resourceIds = {};
      
      for (var item in response) {
        if (item['item_type'] == 'test') {
          testIds.add(item['item_id'] as int);
        } else {
          resourceIds.add(item['item_id'] as int);
        }
      }
      return {'test': testIds, 'resource': resourceIds};
    } catch (e) {
      return {'test': {}, 'resource': {}};
    }
  }

  /// Grants access to multiple items in a single batch.
  static Future<bool> grantBatchAccess({
    required String userId,
    required List<Map<String, dynamic>> items, // List of {id, type, snapshot}
  }) async {
    try {
      if (items.isEmpty) return true;

      final List<Map<String, dynamic>> payload = items.map((item) => {
        'user_id': userId,
        'item_id': item['id'],
        'item_type': item['type'],
        'item_snapshot': item['snapshot'],
        'granted_at': DateTime.now().toIso8601String(),
        'access_type': 'manual_granted',
        'is_active': true,
      }).toList();

      await _supabase.from('access').upsert(payload, onConflict: 'user_id, item_type, item_id');
      return true;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_grant_batch_access');
      return false;
    }
  }
}
