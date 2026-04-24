import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/question.dart';
import '../../domain/models/test_result.dart';
import '../../utils/retry_helper.dart';
import 'cart_service.dart';
import 'auth_service.dart';
import '../../utils/supabase_url_helper.dart';
import 'admin_notification_service.dart';
import '../../utils/crashlytics_service.dart';

/// Service class for managing mock tests, results, and purchases.
class TestService {
  // --- SINGLETON ---
  TestService._();
  static final TestService instance = TestService._();

  final _supabase = Supabase.instance.client;

  /// Deletes a specific test result from the database.
  Future<bool> deleteTestResult(int resultId) async {
    try {
      await _supabase.from('results').delete().eq('result_id', resultId);
      return true;
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'deleteTestResult failed');
      throw Exception('Failed to delete test result: $e');
    }
  }

  // ── MOCK TESTS READING ───────────────────────────────────────────────────

  /// Fetches precise page of mock tests with optional filters.
  Future<List<MockTest>> fetchPaginatedMockTests({
    required int offset,
    required int limit,
    String? searchQuery,
    String? category,
    String? language,
    bool isAdmin = false,
    String sortBy = 'created_at',
    bool ascending = false,
    bool? isFree,
  }) async {
    try {
      var query = _supabase.from('mock_tests').select();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }
      if (category != null && category != 'All') {
        query = query.eq('category', category);
      }
      if (language != null && language != 'All') {
        query = query.eq('language', language);
      }

      if (isFree != null) {
        if (isFree) {
          query = query.eq('price', 0);
        } else {
          query = query.gt('price', 0);
        }
      }

      // Only show public tests in the store, unless admin
      if (!isAdmin) {
        query = query.eq('is_public', true);
      }

      final response = await query
          .order(sortBy, ascending: ascending)
          .range(offset, offset + limit - 1);
      final List<dynamic> data = response;
      List<MockTest> tests = await compute(_parseMockTests, data);

      return await _populateSignedUrls(tests);
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'test_service: fetchPaginatedMockTests');
      return [];
    }
  }

  /// Fetches all available mock tests from the database.
  Future<List<MockTest>> fetchMockTests() async {
    try {
      final response = await RetryHelper.run(() => _supabase
          .from('mock_tests')
          .select()
          .eq('is_public', true)
          .order('created_at', ascending: false));

      final List<dynamic> data = response;
      List<MockTest> tests = await compute(_parseMockTests, data);

      return await _populateSignedUrls(tests);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'test_service');
      throw Exception('Failed to load tests: $e');
    }
  }

  /// Fetches a specific mock test by its ID.
  Future<MockTest?> fetchMockTestById(int testId) async {
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
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'fetchMockTestById failed for ID: $testId');
      return null;
    }
  }

  /// Fetches all unique test categories.
  Future<List<String>> fetchCategories() async {
    try {
      final response = await _supabase.rpc('get_distinct_categories');
      return List<String>.from(response as List);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'test_service');
      final response = await _supabase.from('mock_tests').select('category');
      return (response as List)
          .map((e) => e['category'] as String)
          .toSet()
          .toList();
    }
  }

  /// Fetches all unique test languages.
  Future<List<String>> fetchLanguages() async {
    try {
      final response = await _supabase.rpc('get_distinct_languages');
      final languages = List<String>.from(response as List);
      final defaults = ['English', 'Gujarati'];
      for (var d in defaults) {
        if (!languages.contains(d)) languages.add(d);
      }
      return languages;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'test_service');
      final response = await _supabase.from('mock_tests').select('language');
      final List<String> languages = (response as List)
          .map((e) => e['language'] as String)
          .where((l) => l.isNotEmpty)
          .toSet()
          .toList();
      final defaults = ['English', 'Gujarati'];
      for (var d in defaults) {
        if (!languages.contains(d)) languages.add(d);
      }
      return languages;
    }
  }

  /// Downloads and parses questions for a mock test.
  Future<List<Question>> fetchQuestions(String filePath) async {
    try {
      final Uint8List fileBytes =
          await _supabase.storage.from('mock_test').download(filePath);
      final String jsonString = utf8.decode(fileBytes);
      return await compute(_decodeAndParseQuestions, jsonString);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'test_service');
      throw Exception('Failed to load questions: $e');
    }
  }

  // ── MOCK TESTS ADMIN ─────────────────────────────────────────────────────

  /// Creates a new mock test. Sanitizes storage paths before insertion.
  Future<void> createMockTest(MockTest test) async {
    try {
      final payload = test.toJson();
      if (payload['file_path'] != null) {
        payload['file_path'] = SupabaseUrlHelper.extractPathFromUrl(
            payload['file_path'], 'mock_test');
      }
      if (payload['cover_image_path'] != null) {
        payload['cover_image_path'] = SupabaseUrlHelper.extractPathFromUrl(
            payload['cover_image_path'], 'mock_test');
      }

      await _supabase.from('mock_tests').insert(payload);

      try {
        await AdminNotificationService().sendBroadcast(
          title: '🆕 New Mock Test Available!',
          body: 'Check out the new test: ${test.title}',
        );
      } catch (notiErr, stack) {
        CrashlyticsService.instance.recordError(notiErr, stack, reason: 'Broadcast failed after creating mock test: ${test.title}');
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'test_service');
      throw Exception('Failed to create test: $e');
    }
  }

  /// Deletes a mock test and its associated files.
  Future<void> deleteMockTest(int testId) async {
    try {
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
          } catch (e, stack) {
            CrashlyticsService.instance.recordError(e, stack, reason: 'Storage removal failed for test file: $filePath');
          }
        }
        if (coverImagePath != null && coverImagePath.isNotEmpty) {
          String cleanPath = coverImagePath.replaceAll('mock_test/', '');
          try {
            await _supabase.storage.from('mock_test').remove([cleanPath]);
          } catch (e, stack) {
            CrashlyticsService.instance.recordError(e, stack, reason: 'Storage removal failed for cover image: $cleanPath');
          }
        }
      }

      await _supabase.from('mock_tests').delete().eq('test_id', testId);
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw Exception(
            'Cannot delete this test because it has been purchased by one or more users.');
      }
      throw Exception('Failed to delete test: ${e.message}');
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'test_service');
      throw Exception('Failed to delete test: $e');
    }
  }

  /// Updates an existing mock test.
  Future<void> updateMockTest(int testId, Map<String, dynamic> updates) async {
    try {
      final payload = Map<String, dynamic>.from(updates);
      if (payload['file_path'] != null) {
        payload['file_path'] = SupabaseUrlHelper.extractPathFromUrl(
            payload['file_path'] as String, 'mock_test');
      }
      if (payload['cover_image_path'] != null) {
        payload['cover_image_path'] = SupabaseUrlHelper.extractPathFromUrl(
            payload['cover_image_path'] as String, 'mock_test');
      }

      await _supabase.from('mock_tests').update(payload).eq('test_id', testId);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'test_service');
      throw Exception('Failed to update test: $e');
    }
  }

  // ── RESULTS ──────────────────────────────────────────────────────────────

  /// Replaces storage paths with signed URLs for UI consumption.
  Future<List<MockTest>> _populateSignedUrls(List<MockTest> tests) async {
    return await Future.wait(
      tests.map((test) async {
        String? imageUrl;
        const bucket = 'mock_test';

        // NOTE: We intentionally DO NOT fetch `contentUrl` (JSON file) here
        // to prevent the "Thundering Herd" ANR freeze on app launch. 
        // It is fetched on-demand exactly when the user clicks 'Start Exam'.

        if (test.coverImagePath != null && test.coverImagePath!.isNotEmpty) {
          try {
            final path = SupabaseUrlHelper.extractPathFromUrl(
                test.coverImagePath!, bucket);
            imageUrl = await SupabaseUrlHelper().getFreshSignedUrl(bucket, path);
          } catch (e) {
            // If the cover image is missing (404), fail gracefully and return null.
            // This prevents a single missing image from crashing the entire test dashboard.
            debugPrint('Failed to load signed URL for image ${test.coverImagePath}: $e');
            imageUrl = null;
          }
        }

        return test.copyWith(
          signedUrl: imageUrl,
          contentUrl: null, // Keep it explicitly null representing "unfetched"
        );
      }),
    );
  }

  Future<int?> submitTestResult({
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
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'test_service');
      throw Exception('Failed to submit result: $e');
    }
  }

  Future<List<TestResult>> fetchUserResults(String authUserId) async {
    try {
      final response = await _supabase
          .from('results')
          .select('*, mock_tests(title, total_marks)')
          .eq('user_id', authUserId)
          .order('attempt_date', ascending: false);
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => TestResult.fromJson(json)).toList();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'test_service: fetchUserResults failed');
      throw Exception('Failed to load history: $e');
    }
  }

  // ── PURCHASES ────────────────────────────────────────────────────────────

  Future<Set<int>> fetchPurchasedTestIds(String userId) async {
    try {
      final response = await _supabase
          .from('access')
          .select('item_id')
          .eq('user_id', userId)
          .eq('item_type', 'test');

      return (response as List)
          .map((i) => i['item_id'] as int)
          .toSet();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'fetchPurchasedTestIds failed for user: $userId');
      return {};
    }
  }

  Future<List<MockTest>> fetchUserTests(String authUserId) async {
    try {
      final response = await _supabase
          .from('access')
          .select('item_id')
          .eq('user_id', authUserId)
          .eq('item_type', 'test');

      final testIds = (response as List)
          .map((i) => i['item_id'] as int)
          .toList();

      if (testIds.isEmpty) return [];

      final testsResponse = await _supabase
          .from('mock_tests')
          .select()
          .inFilter('test_id', testIds);

      final List<MockTest> purchasedTests =
          await compute(_parseMockTests, testsResponse as List<dynamic>);

      return await _populateSignedUrls(purchasedTests);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'test_service: fetchUserTests');
      throw Exception('Failed to load purchased tests: $e');
    }
  }

  /// Fetches the most recent test result for a user.
  Future<Map<String, dynamic>?> fetchLatestResult(String authUserId) async {
    try {
      final response = await _supabase
          .from('results')
          .select('*, mock_tests(title)')
          .eq('user_id', authUserId)
          .order('attempt_date', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'fetchLatestResult failed');
      return null;
    }
  }

  /// Listens to purchased tests for real-time UI updates.
  Stream<List<MockTest>> streamPurchasedTests() {
    final authUserId = AuthService.instance.currentUser?.id;
    if (authUserId == null) return Stream.value([]);
    return _supabase
        .from('access')
        .stream(primaryKey: ['access_id'])
        .eq('user_id', authUserId)
        .map((records) => records.where((r) => r['item_type'] == 'test').toList())
        .asyncMap((accessRecords) async {
          try {
            if (accessRecords.isEmpty) return <MockTest>[];
            final testIds = accessRecords.map((o) => o['item_id'] as int).toList();
            
            final testsResponse = await _supabase
                .from('mock_tests')
                .select()
                .inFilter('test_id', testIds);
                
            final List<MockTest> purchasedTests =
                await compute(_parseMockTests, testsResponse as List<dynamic>);
            return await _populateSignedUrls(purchasedTests);
          } catch (e, stack) {
            CrashlyticsService.instance
                .recordError(e, stack, reason: 'streamPurchasedTests failed');
            return <MockTest>[];
          }
        });
  }

  /// Handles free test claims via secure RPC.
  Future<void> claimFreeTest({
    required int testId,
    required String authUserId,
  }) async {
    try {
      // 1. Double check ownership locally first for UX speed
      final isOwned = await CartService.instance.checkOwnership(
        userId: authUserId,
        testId: testId,
      );
      if (isOwned) return;

      // 2. Call secure RPC to grant access (it handles price/active validation)
      final response = await _supabase.rpc('process_item_claim', params: {
        'p_item_id': testId,
        'p_item_type': 'test',
      });

      if (response == null || response['success'] != true) {
        throw Exception(response?['message'] ?? 'Claim failed');
      }
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'claimFreeTest failed');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Initiates a direct purchase for a single test.
  Future<String> createDirectOrder({
    required int testId,
    required double price,
    required String authUserId,
  }) async {
    try {
      final isOwned = await CartService.instance.checkOwnership(
        userId: authUserId,
        testId: testId,
      );
      if (isOwned) throw Exception("You already own this item.");
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
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'test_service');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Completes a purchase transaction.
  Future<void> checkout({
    required String orderId,
    required String paymentId,
    required double amount,
    int? offerId,
    double discountAmount = 0,
    required String userId,
    String paymentGateway = 'Razorpay',
  }) async {
    try {
      // 1. Call the secure RPC to finalize the order and cleanup cart
      await _supabase.rpc('complete_checkout_v1', params: {
        'p_order_id': orderId,
        'p_gateway_payment_id': paymentId,
        'p_amount': amount,
        'p_offer_id': offerId,
        'p_discount_amount': discountAmount,
        'p_user_id': userId,
      });

      // 2. Trigger Admin Notification (Client-side is fine for push notifications)
      try {
        await AdminNotificationService().sendToTopic(
          topic: 'admin_updates',
          title: '🎉 New Sale! (₹$amount)',
          body: 'Order #$orderId has been completed.',
          data: {
            'type': 'sale_alert',
            'order_id': orderId,
            'amount': amount.toString()
          },
        );
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'Admin sale notification failed for order: $orderId');
      }
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'checkout failed');
      throw Exception('Checkout failed: $e');
    }
  }

  /// Legacy admin method for uploading tests with images and JSON.
  Future<void> uploadMockTestWithFiles({
    required Map<String, dynamic> insertData,
    required Uint8List imageBytes,
    required String jsonString,
  }) async {
    final response = await _supabase
        .from('mock_tests')
        .insert(insertData)
        .select('test_id')
        .single();
    final int testId = response['test_id'];
    const imagePath = 'mock_test_cover/';
    final fullImagePath = '$imagePath$testId.jpg';
    await _supabase.storage.from('mock_test').uploadBinary(
          fullImagePath,
          imageBytes,
          fileOptions:
              const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    final jsonBytes = utf8.encode(jsonString);
    final jsonPath = 'mock_test_json_file/$testId.json';
    await _supabase.storage.from('mock_test').uploadBinary(
          jsonPath,
          jsonBytes,
          fileOptions:
              const FileOptions(upsert: true, contentType: 'application/json'),
        );
    await _supabase.from('mock_tests').update({
      'file_path': jsonPath,
      'cover_image_path': fullImagePath,
    }).eq('test_id', testId);
  }

  /// Admin stream for mock test management.
  Stream<List<MockTest>> streamMockTests() {
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

  /// Directly generates a signed URL.
  Future<String?> getSignedUrl(String path, String bucket) async {
    try {
      return await SupabaseUrlHelper().getFreshSignedUrl(bucket, path);
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'getSignedUrl failed');
      return null;
    }
  }

  /// Fetches raw test data for admin tables.
  Future<List<MockTest>> fetchAllTestsRaw() async {
    try {
      final response = await _supabase
          .from('mock_tests')
          .select()
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response as List<dynamic>;
      return await compute(_parseMockTests, data);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'test_service: fetchAllTestsRaw failed');
      rethrow;
    }
  }

  /// Uploads a generated result PDF.
  Future<void> uploadResultPdf(String path, File file) async {
    try {
      await RetryHelper.run(
        () => _supabase.storage.from('mock_test').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        ),
        maxRetries: 3,
        timeout: const Duration(seconds: 45), // PDFs can be up to ~1MB, give it time
      );
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'uploadResultPdf final failure');
      throw Exception('Failed to upload result PDF: $e');
    }
  }

  /// Downloads a result PDF for viewing.
  Future<Uint8List> downloadResultPdf(String bucketPath) async {
    try {
      return await _supabase.storage.from('mock_test').download(bucketPath);
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'downloadResultPdf failed');
      throw Exception('Failed to download result PDF: $e');
    }
  }
}

// ── ISOLATED PARSERS ───────────────────────────────────────────────────────

List<MockTest> _parseMockTests(List<dynamic> jsonList) {
  return jsonList.map((json) => MockTest.fromJson(json)).toList();
}

List<Question> _decodeAndParseQuestions(String jsonString) {
  final List<dynamic> data = json.decode(jsonString);
  return data.map((q) => Question.fromJson(q)).toList();
}
