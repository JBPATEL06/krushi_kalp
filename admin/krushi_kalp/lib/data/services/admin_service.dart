import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../../utils/network_utils.dart'; // Import NetworkUtils

class AdminService {
  static final _supabase = Supabase.instance.client;

  // Fetch all users for Admin User Selector
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response =
          await _supabase.from('users').select('id, email, username');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) {
        debugPrint('AdminService: Network Error fetching all users.');
        return [];
      }
      debugPrint('AdminService: Error fetching all users: $e');
      return [];
    }
  }

  // Lookup User ID by Email
  static Future<String?> getUserIdByEmail(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (response != null) {
        return response['id'] as String;
      }
      return null;
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) return null;
      debugPrint('AdminService: Error looking up user: $e');
      return null;
    }
  }

  /// Streams aggregated stats for the Analysis Page
  static Stream<Map<String, dynamic>> streamDashboardStats() {
    // 1. Mock Tests Stream
    final testsStream =
        _supabase.from('mock_tests').stream(primaryKey: ['test_id']);

    // 2. Resources Stream
    final resourcesStream =
        _supabase.from('resources').stream(primaryKey: ['id']);

    // 3. Users Stream
    final usersStream = _supabase.from('users').stream(primaryKey: ['id']);

    // 4. Orders Stream (Success Only)
    final ordersStream = _supabase
        .from('orders')
        .stream(primaryKey: ['order_id']).eq('status', 'SUCCESS');

    // 5. Active Offers Stream
    final offersStream = _supabase
        .from('offers')
        .stream(primaryKey: ['offer_id']).eq('is_active', true);

    // 6. Order Items Stream
    final itemsStream =
        _supabase.from('order_items').stream(primaryKey: ['item_id']);

    return CombineLatestStream.list([
      testsStream,
      resourcesStream,
      usersStream,
      ordersStream,
      offersStream,
      itemsStream,
    ]).map((data) {
      final tests = data[0];
      final resources = data[1];
      final users = data[2];
      final orders = data[3];
      final offers = data[4];
      final allItems = data[5];

      // Get successful order IDs
      final successOrderIds = orders.map((o) => o['order_id']).toSet();

      // Filter items that belong to successful orders
      final successItems =
          allItems.where((item) => successOrderIds.contains(item['order_id']));

      final testSalesCount =
          successItems.where((item) => item['test_id'] != null).length;
      final resourceSalesCount =
          successItems.where((item) => item['resource_id'] != null).length;

      // Calculate Revenue
      final double revenue = orders.fold(
          0.0, (sum, item) => sum + (item['total_amount'] as num).toDouble());

      return {
        'totalTests': tests.length,
        'totalResources': resources.length,
        'totalUsers': users.length,
        'totalPurchased': orders.length,
        'testSales': testSalesCount,
        'resourceSales': resourceSalesCount,
        'revenue': revenue,
        'activeOffers': offers.length,
      };
    });
  }

  // DEPRECATED: Kept to prevent build errors during migration. Use streamDashboardStats instead.
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final testsCount = await _supabase.from('mock_tests').count();
      final usersCount = await _supabase.from('users').count();
      final activeOffersCount = await _supabase
          .from('offers')
          .count(CountOption.exact)
          .eq('is_active', true);

      final ordersResponse = await _supabase
          .from('orders')
          .select('total_amount')
          .eq('status', 'SUCCESS');
      double revenue = 0.0;
      for (var o in ordersResponse) {
        revenue += (o['total_amount'] as num).toDouble();
      }

      return {
        'totalTests': testsCount,
        'totalUsers': usersCount,
        'totalPurchased': ordersResponse.length,
        'revenue': revenue,
        'activeOffers': activeOffersCount,
      };
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) {
        debugPrint('AdminService: Network Error fetching stats.');
        return {
          'totalTests': 0,
          'totalUsers': 0,
          'totalPurchased': 0,
          'revenue': 0.0,
          'activeOffers': 0,
        };
      }
      debugPrint('AdminService: Error fetching stats: $e');
      return {
        'totalTests': 0,
        'totalUsers': 0,
        'totalPurchased': 0,
        'revenue': 0.0,
        'activeOffers': 0,
      };
    }
  }

  /// Streams top performing users (Requires fetching results + tests + users)
  /// Note: Complex joins in Realtime are not supported directly.
  /// We will stream Results and fetch related data efficiently.
  /// For "Top Users", we need: Results -> join MockTest (total_marks) & User.
  static Stream<List<Map<String, dynamic>>> streamTopUsers() {
    return _supabase
        .from('results')
        .stream(primaryKey: ['result_id']).asyncMap((results) async {
      if (results.isEmpty) return [];

      // We need to fetch Users and MockTests to act as a "Join"
      // Optimization: Fetch only unique IDs involved in these results
      final userIds = results.map((r) => r['user_id']).toSet().toList();
      final testIds = results.map((r) => r['test_id']).toSet().toList();

      // Fetch Users
      final usersResponse = await _supabase
          .from('users')
          .select('id, username, email')
          .inFilter('id', userIds);
      final userMap = {for (var u in usersResponse) u['id']: u};

      // Fetch Tests (for Total Marks)
      final testsResponse = await _supabase
          .from('mock_tests')
          .select('test_id, total_marks')
          .inFilter('test_id', testIds);
      final testMap = {for (var t in testsResponse) t['test_id']: t};

      final Map<String, Map<String, dynamic>> userStats = {};

      for (var r in results) {
        final userId = r['user_id'];
        final testId = r['test_id'];
        final user = userMap[userId];
        final test = testMap[testId];

        if (user == null) continue;

        final email = user['email'] ?? 'Unknown';
        final username = user['username'] ?? 'User';
        final score = (r['score_obtained'] as num).toDouble();
        final total =
            test != null ? (test['total_marks'] as num).toDouble() : 0.0;

        if (!userStats.containsKey(email)) {
          userStats[email] = {
            'username': username,
            'email': email,
            'totalScore': 0.0,
            'totalMax': 0.0,
            'testsTaken': 0,
          };
        }
        userStats[email]!['totalScore'] += score;
        userStats[email]!['totalMax'] += total;
        userStats[email]!['testsTaken'] += 1;
      }

      final List<Map<String, dynamic>> sortedUsers = userStats.values.toList();
      sortedUsers.sort((a, b) {
        double pctA = a['totalMax'] > 0 ? (a['totalScore'] / a['totalMax']) : 0;
        double pctB = b['totalMax'] > 0 ? (b['totalScore'] / b['totalMax']) : 0;
        return pctB.compareTo(pctA);
      });

      return sortedUsers.take(10).toList();
    });
  }

  /// Streams top performing tests (based on sales)
  /// Listens to ORDERS stream (safer) then fetches items.
  /// Streams top performing tests (based on sales)
  /// Listens to ORDERS stream (safer) then fetches items.
  /// Streams top performing tests (based on sales)
  /// LISTENS TO ORDER_ITEMS DIRECTLY (Simpler Logic)
  static Stream<List<Map<String, dynamic>>> streamTopTests() {
    return _supabase
        .from('order_items')
        .stream(primaryKey: ['item_id']).asyncMap((items) async {
      debugPrint(
          'AdminService: StreamTopTests: Received ${items.length} items from stream.');

      if (items.isEmpty) return [];

      // 1. Aggregate Sales by Test ID
      final Map<int, int> testSalesCount = {};

      for (var item in items) {
        final tId = item['test_id'];
        // Handle potential string/int types
        int? id;
        if (tId is int)
          id = tId;
        else if (tId is String) id = int.tryParse(tId);

        if (id != null) {
          testSalesCount[id] = (testSalesCount[id] ?? 0) + 1;
        }
      }

      if (testSalesCount.isEmpty) {
        debugPrint(
            'AdminService: StreamTopTests: No valid Test IDs found in items.');
        return [];
      }

      // 2. Identify Top 3 Test IDs
      final sortedIDs = testSalesCount.keys.toList()
        ..sort((a, b) => testSalesCount[b]!.compareTo(testSalesCount[a]!));

      final top3IDs = sortedIDs.take(3).toList();
      debugPrint('AdminService: StreamTopTests: Top 3 Test IDs: $top3IDs');

      if (top3IDs.isEmpty) return [];

      // 3. Fetch Test Details for Top 3
      try {
        final testsResponse = await _supabase
            .from('mock_tests')
            .select('test_id, title, category, price')
            .inFilter('test_id', top3IDs);

        final testMap = {for (var t in testsResponse) t['test_id']: t};
        final List<Map<String, dynamic>> result = [];

        for (var id in top3IDs) {
          final test = testMap[id];
          if (test == null) {
            debugPrint(
                'AdminService: StreamTopTests: Warning - Test $id not found in DB.');
            continue;
          }

          result.add({
            'id': id,
            'title': test['title'],
            'category': test['category'],
            'price': (test['price'] as num?)?.toDouble() ?? 0.0,
            'sales': testSalesCount[id] ?? 0,
          });
        }

        // Ensure result respects the sales order (map verification)
        result.sort((a, b) => b['sales'].compareTo(a['sales']));

        // 4. Add Image URL
        for (var t in result) {
          final testId = t['id'];
          try {
            final signedUrl = await _supabase.storage
                .from('mock_test')
                .createSignedUrl('mock_test_cover/$testId.jpg', 60 * 60);
            t['image_url'] = signedUrl;
          } catch (e) {
            debugPrint(
                'AdminService: Could not generate signed URL for Test $testId: $e');
            t['image_url'] = null;
          }
        }

        return result;
      } catch (e) {
        debugPrint(
            'AdminService: StreamTopTests: Error fetching mock_tests details: $e');
        return [];
      }
    });
  }

  // KEEPING LEGACY METHODS FOR BACKWARD COMPATIBILITY IF NEEDED (or we can remove them)
  // Currently skipping removal to strictly follow safety, but we will use the new ones.
  // ... (Existing Methods below)

  /// Fetches top performing users based on quiz scores
  static Future<List<Map<String, dynamic>>> getTopUsers() async {
    try {
      // Fetch results with user details AND test details (for total_marks)
      final response = await _supabase.from('results').select(
          'score_obtained, mock_tests(total_marks), users(username, email)');

      final Map<String, Map<String, dynamic>> userStats = {};

      for (var r in response) {
        final user = r['users'];
        final test = r['mock_tests'];
        if (user == null) continue;

        final email = user['email'] ?? 'Unknown';
        final username = user['username'] ?? 'User';
        final score = (r['score_obtained'] as num).toDouble();
        final total =
            test != null ? (test['total_marks'] as num).toDouble() : 0.0;

        if (!userStats.containsKey(email)) {
          userStats[email] = {
            'username': username,
            'email': email,
            'totalScore': 0.0,
            'totalMax': 0.0,
            'testsTaken': 0,
          };
        }
        userStats[email]!['totalScore'] += score;
        userStats[email]!['totalMax'] += total;
        userStats[email]!['testsTaken'] += 1;
      }

      final List<Map<String, dynamic>> sortedUsers = userStats.values.toList();
      sortedUsers.sort((a, b) {
        double pctA = a['totalMax'] > 0 ? (a['totalScore'] / a['totalMax']) : 0;
        double pctB = b['totalMax'] > 0 ? (b['totalScore'] / b['totalMax']) : 0;
        return pctB.compareTo(pctA);
      });

      return sortedUsers.take(10).toList();
    } catch (e) {
      debugPrint('AdminService User Ranking Error: $e');
      return [];
    }
  }

  /// Fetches all users with their activity data for filtering
  static Future<List<Map<String, dynamic>>> getAllUsersWithActivity() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, email, username, created_at');

      final List<Map<String, dynamic>> users =
          List<Map<String, dynamic>>.from(response);

      if (users.isEmpty) return [];

      final userIds = users.map((u) => u['id']).toList();

      // Batch fetch latest results for all users
      // Note: Supabase doesn't easily support DISTINCT ON in select() via dart
      // So we fetch all results for these users and process locally,
      // OR we just fetch the latest for each in a more optimized way.
      // For simplicity and speed, we'll fetch the latest result for each user ID.
      final lastResultsResponse = await _supabase
          .from('results')
          .select('user_id, attempt_date')
          .inFilter('user_id', userIds)
          .order('attempt_date', ascending: false);

      final Map<String, String> lastActiveMap = {};
      for (var res in lastResultsResponse) {
        final uid = res['user_id'] as String;
        if (!lastActiveMap.containsKey(uid)) {
          lastActiveMap[uid] = res['attempt_date'] as String;
        }
      }

      return users.map((user) {
        return {
          ...user,
          'last_active': lastActiveMap[user['id']],
        };
      }).toList();
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) {
        debugPrint('AdminService: Network Error fetching detailed users.');
        return [];
      }
      debugPrint('AdminService: Error fetching detailed users: $e');
      return [];
    }
  }

  /// Fetches all successful orders with user details
  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, users(email, username)')
          .eq('status', 'SUCCESS')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) return [];
      debugPrint('AdminService: Error fetching orders: $e');
      return [];
    }
  }

  /// Streams all successful orders with user details (Manual Join)
  static Stream<List<Map<String, dynamic>>> streamAllOrders() {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['order_id'])
        .eq('status', 'SUCCESS')
        .order('created_at', ascending: false)
        .asyncMap((orders) async {
          if (orders.isEmpty) return [];

          final userIds = orders.map((o) => o['user_id']).toSet().toList();
          if (userIds.isEmpty) {
            return orders; // Should not happen if orders not empty
          }

          try {
            final users = await _supabase
                .from('users')
                .select('id, email, username')
                .inFilter('id', userIds);
            final userMap = {for (var u in users) u['id']: u};

            return orders.map((o) {
              final user = userMap[o['user_id']];
              return {...o, 'users': user};
            }).toList();
          } catch (e) {
            // If fetching users fails, just return orders without user info to avoid stream crash
            return orders;
          }
        });
  }

  /// Fetches detailed user profile including phone number
  static Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*') // Just select everything from users table
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) return null;
      debugPrint('AdminService: Error fetching user details: $e');
      return null;
    }
  }

  /// Fetches a user's purchase history
  static Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('user_id', userId)
          .eq('status', 'SUCCESS')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('AdminService: Error fetching user orders: $e');
      return [];
    }
  }

  /// Fetches a user's test results
  static Future<List<Map<String, dynamic>>> getUserResults(
      String userId) async {
    try {
      final response = await _supabase
          .from('results')
          .select('*, mock_tests(title, total_marks)')
          .eq('user_id', userId)
          .order('attempt_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('AdminService: Error fetching user results: $e');
      return [];
    }
  }

  /// Promotes a user to Admin role
  static Future<void> promoteToAdmin(String userId) async {
    try {
      await _supabase.from('users').update({'role': 'Admin'}).eq('id', userId);
    } catch (e) {
      print('AdminService: Error promoting user: $e');
      rethrow;
    }
  }

  /// Demotes an Admin to Student role
  static Future<void> demoteToUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({'role': 'Student'}).eq('id', userId);
    } catch (e) {
      print('AdminService: Error demoting user: $e');
      rethrow;
    }
  }

  /// Streams all users with basic info
  static Stream<List<Map<String, dynamic>>> streamUsers() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((users) async {
          if (users.isEmpty) return [];

          final userIds = users.map((u) => u['id']).toList();

          try {
            // Batch fetch latest results for these users
            final lastResultsResponse = await _supabase
                .from('results')
                .select('user_id, attempt_date')
                .inFilter('user_id', userIds)
                .order('attempt_date', ascending: false);

            final Map<String, String> lastActiveMap = {};
            for (var res in lastResultsResponse) {
              final uid = res['user_id'] as String;
              if (!lastActiveMap.containsKey(uid)) {
                lastActiveMap[uid] = res['attempt_date'] as String;
              }
            }

            return users.map((user) {
              return {
                ...user,
                'last_active': lastActiveMap[user['id']],
              };
            }).toList();
          } catch (e) {
            debugPrint('AdminService: Error enriching stream: $e');
            return users;
          }
        });
  }

  /// Streams detailed user profile
  static Stream<Map<String, dynamic>> streamUserDetails(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((event) => event.first);
  }

  /// Streams user orders
  static Stream<List<Map<String, dynamic>>> streamUserOrders(String userId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['order_id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
            (orders) => orders.where((o) => o['status'] == 'SUCCESS').toList());
  }

  /// Streams user results
  static Stream<List<Map<String, dynamic>>> streamUserResults(String userId) {
    return _supabase
        .from('results')
        .stream(primaryKey: ['result_id'])
        .eq('user_id', userId)
        .order('attempt_date', ascending: false)
        .asyncMap((results) async {
          // We need mock test titles. Streaming doesn't join.
          // We must fetch titles for these results.
          if (results.isEmpty) return [];

          final testIds = results.map((r) => r['test_id']).toSet().toList();
          final tests = await _supabase
              .from('mock_tests')
              .select('test_id, title, total_marks')
              .inFilter('test_id', testIds);

          final testMap = {for (var t in tests) t['test_id']: t};

          return results.map((r) {
            final test = testMap[r['test_id']];
            return {
              ...r,
              'mock_tests': test // Manually join
            };
          }).toList();
        });
  }

  /// Deletes a user account (Admin only)
  static Future<void> deleteUser(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);
    } catch (e) {
      debugPrint('AdminService: Error deleting user: $e');
      rethrow;
    }
  }

  // Get analytic stats for a specific Resource Type (Category level)
  static Future<Map<String, dynamic>> getResourceTypeStats(String type) async {
    try {
      // 1. Total count of resources of this type
      final countRes = await _supabase
          .from('resources')
          .select('id')
          .eq('type', type)
          .count(CountOption.exact);

      // 2. Total sales of resources of this type
      final salesRes = await _supabase.from('order_items').select('''
            item_id,
            resources:resource_id!inner(type)
          ''').eq('resources.type', type);

      return {
        'totalCount': countRes.count,
        'salesCount': (salesRes as List).length,
      };
    } catch (e) {
      debugPrint('AdminService: Error fetching Type stats: $e');
      return {'totalCount': 0, 'salesCount': 0};
    }
  }

  // Get analytic stats for a specific Resource Item (Single item level)
  static Future<Map<String, dynamic>> getResourceItemStats(
      int resourceId) async {
    try {
      // 1. Get current price/details
      final itemRes = await _supabase
          .from('resources')
          .select('price')
          .eq('id', resourceId)
          .single();

      // 2. Get sales count
      final salesRes = await _supabase
          .from('order_items')
          .select('item_id')
          .eq('resource_id', resourceId)
          .count(CountOption.exact);

      return {
        'price': (itemRes['price'] as num?)?.toDouble() ?? 0.0,
        'salesCount': salesRes.count,
      };
    } catch (e) {
      debugPrint('AdminService: Error fetching Item stats: $e');
      return {'price': 0.0, 'salesCount': 0};
    }
  }

  // Fetch detailed order history for Revenue Page
  static Future<List<Map<String, dynamic>>> fetchAllOrdersWithDetails() async {
    try {
      final response = await _supabase.from('orders').select('''
            *,
            users:user_id (username, email),
            offers:offer_id (code, discount_value, discount_type),
            order_items (
              price_at_purchase,
              test_id,
              resource_id,
              mock_tests (title),
              resources (title, type)
            )
          ''').eq('status', 'SUCCESS').order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) {
        debugPrint('AdminService: Network Error fetching order details.');
        return [];
      }
      debugPrint('AdminService: Error fetching order details: $e');
      rethrow;
    }
  }
}
