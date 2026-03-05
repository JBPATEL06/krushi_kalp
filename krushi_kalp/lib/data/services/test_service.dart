import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/question.dart';
import '../../utils/retry_helper.dart';
import 'cart_service.dart';

class TestService {
  static final _supabase = Supabase.instance.client;

  // --- MOCK TESTS READING ---

  static Future<List<MockTest>> fetchMockTests() async {
    try {
      final response = await RetryHelper.run(() => _supabase
          .from('mock_tests')
          .select()
          .order('created_at', ascending: false));

      final List<dynamic> data = response;
      List<MockTest> tests = await compute(_parseMockTests, data);

      return await _populateSignedUrls(tests);
    } catch (e) {
      debugPrint('Error fetching mock tests: $e');
      throw Exception('Failed to load tests: $e');
    }
  }

  static Future<MockTest?> fetchMockTestById(int testId) async {
    try {
      final response = await _supabase
          .from('mock_tests')
          .select()
          .eq('test_id', testId)
          .maybeSingle();

      if (response == null) return null;
      final test = MockTest.fromJson(response);
      final List<MockTest> withUrl = await _populateSignedUrls([test]);
      return withUrl.first;
    } catch (e) {
      debugPrint('Error fetching mock test by id: $e');
      return null;
    }
  }

  static Future<List<String>> fetchCategories() async {
    try {
      final response = await _supabase.from('mock_tests').select('category');

      final List<String> categories = (response as List)
          .map((e) => e['category'] as String)
          .toSet() // Deduplicate
          .toList();

      return categories;
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  static Future<List<String>> fetchLanguages() async {
    try {
      final response = await _supabase.from('mock_tests').select('language');

      final List<String> languages = (response as List)
          .map((e) => e['language'] as String)
          .where((l) => l.isNotEmpty)
          .toSet() // Deduplicate
          .toList();

      // Ensure defaults exist as requested
      final defaults = ['English', 'Gujarati'];
      for (var d in defaults) {
        if (!languages.contains(d)) languages.add(d);
      }
      return languages;
    } catch (e) {
      debugPrint('Error fetching languages: $e');
      return ['English', 'Gujarati'];
    }
  }

  static Stream<List<MockTest>> streamMockTests() {
    return _supabase
        .from('mock_tests')
        .stream(primaryKey: ['test_id'])
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          List<MockTest> tests =
              await compute(_parseMockTests, data as List<dynamic>);
          return await _populateSignedUrls(tests);
        });
  }

  static Future<List<Question>> fetchQuestions(String filePath) async {
    try {
      final Uint8List fileBytes =
          await _supabase.storage.from('mock_test').download(filePath);
      final String jsonString = utf8.decode(fileBytes);
      return await compute(_decodeAndParseQuestions, jsonString);
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      throw Exception('Failed to load questions: $e');
    }
  }

  // --- MOCK TESTS ADMIN (WRITE) ---

  static Future<void> deleteMockTest(int testId) async {
    try {
      // 1. Fetch test details to get file paths (for Storage deletion)
      final testRow = await _supabase
          .from('mock_tests')
          .select()
          .eq('test_id', testId)
          .maybeSingle();

      if (testRow != null) {
        final filePath = testRow['file_path'] as String?;
        final coverImagePath = testRow['cover_image_path'] as String?;

        if (filePath != null && filePath.isNotEmpty) {
          try {
            await _supabase.storage.from('mock_test').remove([filePath]);
          } catch (_) {}
        }
        if (coverImagePath != null && coverImagePath.isNotEmpty) {
          String cleanPath = coverImagePath.replaceAll('mock_test/', '');
          try {
            await _supabase.storage.from('mock_test').remove([cleanPath]);
          } catch (_) {}
        }
      }

      await _supabase.from('mock_tests').delete().eq('test_id', testId);
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw Exception(
            'Cannot delete this test because it has been purchased by one or more users.');
      }
      debugPrint('Error deleting mock test (Postgrest): $e');
      throw Exception('Failed to delete test: ${e.message}');
    } catch (e) {
      debugPrint('Error deleting mock test: $e');
      throw Exception('Failed to delete test: $e');
    }
  }

  static Future<void> updateMockTest(
      int testId, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('mock_tests').update(updates).eq('test_id', testId);
    } catch (e) {
      debugPrint('Error updating mock test: $e');
      throw Exception('Failed to update test: $e');
    }
  }

  // --- RESULTS ---

  static Future<int?> submitTestResult({
    required int testId,
    required double score,
    required int totalMarks,
    required String authUserId,
    required String language,
  }) async {
    try {
      final response = await _supabase
          .from('results')
          .insert({
            'user_id': authUserId,
            'test_id': testId,
            'score_obtained': score,
            'is_passed': totalMarks > 0 ? (score / totalMarks) >= 0.40 : false,
            'attempt_date': DateTime.now().toUtc().toIso8601String(),
            'language': language,
          })
          .select('result_id')
          .single();

      return response['result_id'] as int?;
    } catch (e) {
      debugPrint('Error submitting result: $e');
      throw Exception('Failed to submit result: $e');
    }
  }

  static Future<List<dynamic>> fetchUserResults(String authUserId) async {
    try {
      final response = await _supabase
          .from('results')
          .select('*, mock_tests(title, total_marks)')
          .eq('user_id', authUserId)
          .order('attempt_date', ascending: false);
      return response as List<dynamic>;
    } catch (e) {
      debugPrint('Error fetching results: $e');
      throw Exception('Failed to load history: $e');
    }
  }

  static Future<Map<String, dynamic>?> fetchLatestResult(
      String authUserId) async {
    try {
      final response = await _supabase
          .from('results')
          .select('*, mock_tests(title)')
          .eq('user_id', authUserId)
          .order('attempt_date', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching latest result: $e');
      return null;
    }
  }

  static Future<bool> deleteTestResult(int resultId) async {
    try {
      final user = _supabase.auth.currentUser;
      final userId = user?.id;

      debugPrint('TestService: Attempting to delete result ID: $resultId');
      debugPrint('TestService: Current User ID: $userId');

      // 1. First, check if the record exists at all (helps differentiate between RLS and missing data)
      final existing = await _supabase
          .from('results')
          .select('user_id')
          .eq('result_id', resultId)
          .maybeSingle();

      if (existing == null) {
        debugPrint('TestService: Result ID $resultId not found in database.');
        return false;
      }

      final rowOwnerId = existing['user_id'] as String?;
      debugPrint('TestService: Row Owner ID: $rowOwnerId');

      if (userId != rowOwnerId) {
        debugPrint(
            'TestService: User $userId is NOT the owner of row $resultId. Deletion will likely fail due to RLS.');
      }

      // 2. Perform the deletion
      final response = await _supabase
          .from('results')
          .delete()
          .eq('result_id', resultId)
          .select();

      if ((response as List).isEmpty) {
        debugPrint(
            'TestService: Deletion failed or no rows matched for ID: $resultId. This strongly suggests an RLS (Policy) restriction.');
        return false;
      }

      debugPrint(
          'TestService: Successfully deleted ${response.length} row(s) for result ID: $resultId');
      return true;
    } catch (e) {
      debugPrint('Error deleting result: $e');
      // If we get an explicit error (like 403), it's definitely RLS
      return false;
    }
  }

  // --- PURCHASES & CART ---

  static Stream<List<MockTest>> streamPurchasedTests() {
    final authUserId = _supabase.auth.currentUser?.id;
    if (authUserId == null) return Stream.value([]);

    return _supabase
        .from('orders')
        .stream(primaryKey: ['order_id'])
        .eq('user_id', authUserId)
        .order('created_at', ascending: false)
        .asyncMap((orders) async {
          try {
            final successOrders = orders
                .where((o) =>
                    o['status'] == 'SUCCESS' || o['status'] == 'COMPLETED')
                .toList();
            if (successOrders.isEmpty) return <MockTest>[];

            final orderIds = successOrders.map((o) => o['order_id']).toList();

            final itemsResponse = await _supabase
                .from('order_items')
                .select('test_id')
                .inFilter('order_id', orderIds);

            final testIds = (itemsResponse as List)
                .where((i) => i['test_id'] != null)
                .map((i) => i['test_id'] as int)
                .toSet()
                .toList();

            if (testIds.isEmpty) return <MockTest>[];

            final testsResponse = await _supabase
                .from('mock_tests')
                .select()
                .inFilter('test_id', testIds);

            final List<MockTest> purchasedTests =
                await compute(_parseMockTests, testsResponse as List<dynamic>);

            return await _populateSignedUrls(purchasedTests);
          } catch (e) {
            debugPrint("Stream Purchased Error: $e");
            return <MockTest>[];
          }
        });
  }

  static Future<List<MockTest>> fetchPurchasedTests(String authUserId) async {
    try {
      // 1. Fetch successful orders
      final ordersResponse = await _supabase
          .from('orders')
          .select('order_id')
          .eq('user_id', authUserId)
          .inFilter('status', ['SUCCESS', 'COMPLETED']).order('created_at',
              ascending: false);

      debugPrint(
          'TestService: Found ${ordersResponse.length} orders for user $authUserId');

      final orderIds =
          (ordersResponse as List).map((o) => o['order_id']).toList();
      if (orderIds.isEmpty) {
        debugPrint('TestService: No orders found.');
        return [];
      }

      // 2. Fetch items for these orders
      final itemsResponse = await _supabase
          .from('order_items')
          .select('test_id')
          .inFilter('order_id', orderIds);

      debugPrint('TestService: Found ${itemsResponse.length} order items.');

      final testIds = (itemsResponse as List)
          .where((i) => i['test_id'] != null)
          .map((i) => i['test_id'] as int)
          .toSet()
          .toList();

      if (testIds.isEmpty) {
        debugPrint('TestService: No test IDs found in order items.');
        return [];
      }

      debugPrint('TestService: Fetching specific tests: $testIds');

      // 3. Fetch Tests
      final testsResponse = await _supabase
          .from('mock_tests')
          .select()
          .inFilter('test_id', testIds);

      debugPrint(
          'TestService: Found ${testsResponse.length} actual tests from DB.');

      final List<MockTest> purchasedTests =
          await compute(_parseMockTests, testsResponse as List<dynamic>);

      return await _populateSignedUrls(purchasedTests);
    } catch (e) {
      debugPrint('Error fetching purchased tests: $e');
      throw Exception('Failed to load purchased tests: $e');
    }
  }

  // Backwards compatibility for legacy checkout flow (if used)
  static Future<void> purchaseMockTest({
    required int testId,
    required double amount,
    required String authUserId,
  }) async {
    try {
      final newOrder = await _supabase
          .from('orders')
          .insert({
            'user_id': authUserId,
            'status': 'SUCCESS',
            'total_amount': amount,
            'payment_gateway_id':
                'manual_legacy_${DateTime.now().millisecondsSinceEpoch}',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('order_id')
          .single();

      final orderId = newOrder['order_id'];

      await _supabase.from('order_items').insert({
        'order_id': orderId,
        'test_id': testId,
        'price_at_purchase': amount,
      });
    } catch (e) {
      debugPrint('Error purchasing test (legacy): $e');
      throw Exception('Failed to purchase test: $e');
    }
  }

  static Future<void> claimFreeTest({
    required int testId,
    required String authUserId,
  }) async {
    try {
      // 1. Check if already purchased/claimed
      final existingOrder = await _supabase
          .from('order_items')
          .select('order_id')
          .eq('test_id', testId)
          .eq('orders.user_id', authUserId)
          .eq('orders.status', 'SUCCESS')
          .maybeSingle();

      if (existingOrder != null) {
        debugPrint('TestService: Test $testId already claimed.');
        return;
      }

      // 2. Create SUCCESS order directly
      final newOrder = await _supabase
          .from('orders')
          .insert({
            'user_id': authUserId,
            'status': 'SUCCESS',
            'total_amount': 0,
            'payment_gateway_id': 'FREE_CLAIM',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('order_id')
          .single();

      final orderId = newOrder['order_id'];

      // 3. Add Item
      await _supabase.from('order_items').insert({
        'order_id': orderId,
        'test_id': testId,
        'price_at_purchase': 0,
      });
    } catch (e) {
      debugPrint('Error claiming free test: $e');
      throw Exception('Failed to claim test: $e');
    }
  }

  static Future<void> addToCart({
    required int testId,
    required double price,
    required String authUserId,
  }) async {
    // Delegate to CartService
    await CartService.addToCart(
      authUserId: authUserId,
      testId: testId,
      price: price,
    );
  }

  // --- DIRECT BUY FLOW ---
  static Future<String> createDirectOrder({
    required int testId,
    required double price,
    required String authUserId,
  }) async {
    try {
      // 0. OWNERSHIP CHECK
      final isOwned = await CartService.checkOwnership(
        userId: authUserId,
        testId: testId,
      );

      if (isOwned) {
        throw Exception("You already own this item.");
      }

      // Create a specific order for Direct Checkout
      final newOrder = await _supabase
          .from('orders')
          .insert({
            'user_id': authUserId,
            'status': 'DIRECT_CHECKOUT',
            'total_amount': price,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('order_id')
          .single();

      final orderId = newOrder['order_id'];

      await _supabase.from('order_items').insert({
        'order_id': orderId,
        'test_id': testId,
        'price_at_purchase': price,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      return orderId;
    } catch (e) {
      debugPrint('Error creating direct order: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<void> checkout({
    required String orderId,
    required String paymentId,
    required double amount,
    int? offerId,
    double discountAmount = 0,
    required String userId,
    String paymentGateway = 'Razorpay', // NEW Param with default
  }) async {
    try {
      debugPrint(
          'TestService: Completing checkout for Order $orderId (User: $userId, Offer: $offerId)');

      // 1. Mark Order as Success
      final orderResponse = await _supabase
          .from('orders')
          .update({
            'status': 'SUCCESS',
            'payment_gateway_id': paymentId,
            'total_amount': amount,
            'offer_id': offerId,
            'discount_amount': discountAmount,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('order_id', orderId)
          .select();

      debugPrint(
          'TestService: Order Update Status: ${orderResponse.isNotEmpty ? "Success" : "Failed (Empty Response)"}');

      // 2. CLEANUP CART (PENDING ORDER)
      // If this was a Direct Buy or just a purchase, ensure the item is removed from Cart (PENDING order) if it exists there.
      try {
        // Find which mock tests were in this successful order
        final fileItems = await _supabase
            .from('order_items')
            .select('test_id')
            .eq('order_id', orderId);

        final purchasedTestIds = (fileItems as List)
            .where((i) => i['test_id'] != null)
            .map((i) => i['test_id'] as int)
            .toList();

        if (purchasedTestIds.isNotEmpty) {
          // Find user's PENDING order (Cart)
          final pendingOrder = await _supabase
              .from('orders')
              .select('order_id')
              .eq('user_id', userId)
              .eq('status', 'PENDING')
              .maybeSingle();

          if (pendingOrder != null) {
            final cartOrderId = pendingOrder['order_id'];
            // Remove these specific tests from the cart order
            await _supabase
                .from('order_items')
                .delete()
                .eq('order_id', cartOrderId)
                .inFilter('test_id', purchasedTestIds);
            debugPrint(
                'TestService: Cleaned up ${purchasedTestIds.length} items from Cart (Order: $cartOrderId)');
          }
        }
      } catch (cleanupError) {
        debugPrint(
            "TestService: Warning - Cart cleanup failed (non-critical): $cleanupError");
      }

      // 3. Log redemption
      if (offerId != null) {
        try {
          debugPrint('TestService: Logging redemption for Offer $offerId...');
          await _supabase.from('offer_redemptions').insert({
            'offer_id': offerId,
            'user_id': userId,
            'order_id': orderId,
            'discount_amount': discountAmount,
            'redeemed_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (e) {
          debugPrint("TestService: Redemption log error (likely RLS): $e");
          // Don't throw here to avoid failing the whole checkout if only logging fails
        }
      }
    } catch (e) {
      debugPrint('TestService: Detailed Checkout error: $e');
      throw Exception('Checkout failed: $e');
    }
  }

  // --- ORDER LEVEL COUPON LOGIC ---
  static Future<void> applyCouponToOrder(String orderId, int offerId) async {
    try {
      await _supabase.from('orders').update({
        'offer_id': offerId,
        'updated_at': DateTime.now().toUtc().toIso8601String()
      }).eq('order_id', orderId);
    } catch (e) {
      debugPrint('Error applying coupon to order: $e');
      throw Exception('Failed to apply coupon');
    }
  }

  static Future<void> removeCouponFromOrder(String orderId) async {
    try {
      await _supabase.from('orders').update({
        'offer_id': null,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('order_id', orderId);
    } catch (e) {
      debugPrint('Error removing coupon from order: $e');
    }
  }

  // --- PER ITEM COUPON LOGIC (DEPRECATED but kept for now if needed, though we are moving away) ---
  // We can remove the old per-item methods or leave them unused for safety until full transition.
  // For cleanliness, I will comment them out or just leave them as is but we won't call them from UI.

  static Future<List<MockTest>> _populateSignedUrls(
      List<MockTest> tests) async {
    return await Future.wait(
      tests.map((test) async {
        String? contentUrl;
        String? imageUrl;

        // 1. Generate Content URL (JSON)
        if (test.filePath.isNotEmpty) {
          try {
            // Use filePath directly (assuming it matches download() logic)
            // Debug log to confirm what path we are trying
            debugPrint(
                "TestService: Generating signed URL for content path: '${test.filePath}'");

            contentUrl = await _supabase.storage
                .from('mock_test')
                .createSignedUrl(test.filePath, 60 * 60 * 24);
          } catch (e) {
            debugPrint(
                "Error generating content URL for ${test.title} (path: ${test.filePath}): $e");
            // Fallback 1: Try stripping 'mock_test/' if it exists
            if (test.filePath.startsWith('mock_test/')) {
              try {
                final stripped = test.filePath.replaceAll('mock_test/', '');
                debugPrint(
                    "TestService: Retrying with stripped path: '$stripped'");
                contentUrl = await _supabase.storage
                    .from('mock_test')
                    .createSignedUrl(stripped, 60 * 60 * 24);
              } catch (_) {}
            }

            // Fallback 2: Try adding 'resources/' prefix if not there
            if (contentUrl == null && !test.filePath.startsWith('resources/')) {
              try {
                final prefixed = 'resources/${test.filePath}';
                debugPrint(
                    "TestService: Retrying with resources/ prefix: '$prefixed'");
                contentUrl = await _supabase.storage
                    .from('mock_test')
                    .createSignedUrl(prefixed, 60 * 60 * 24);
              } catch (_) {}
            }
          }
        }

        // 2. Generate Image URL
        if (test.coverImagePath != null && test.coverImagePath!.isNotEmpty) {
          try {
            String path =
                test.coverImagePath!.replaceAll('mock_test/', ''); // Safety
            imageUrl = await _supabase.storage
                .from('mock_test')
                .createSignedUrl(path, 60 * 60 * 24);
          } catch (e) {
            debugPrint("Error generating image URL for ${test.title}: $e");
          }
        }

        return test.copyWith(
          contentUrl: contentUrl,
          signedUrl:
              imageUrl, // Mapping Image URL to signedUrl for UI compatibility
        );
      }),
    );
  }
}

// Top-level functions for background isolate JSON parsing

List<MockTest> _parseMockTests(List<dynamic> jsonList) {
  return jsonList.map((json) => MockTest.fromJson(json)).toList();
}

List<Question> _decodeAndParseQuestions(String jsonString) {
  final List<dynamic> jsonList = jsonDecode(jsonString);
  return jsonList.map((q) => Question.fromJson(q)).toList();
}
