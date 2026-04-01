import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/question.dart';
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

  final _supabase = Supabase.instance.client;

  // ΓöÇΓöÇ MOCK TESTS READING ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  /// Fetches all available mock tests from the database.
  Future<List<MockTest>> fetchMockTests() async {
    try {
      final response = await RetryHelper.run(() => _supabase
          .from('mock_tests')
          .select()
          .order('created_at', ascending: false));

      final List<dynamic> data = response;
      List<MockTest> tests = await compute(_parseMockTests, data);

      return await _populateSignedUrls(tests);
    } catch (e) {
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
    } catch (e) {
      return null;
    }
  }

  /// Fetches all unique test categories.
  Future<List<String>> fetchCategories() async {
    try {
      final response = await _supabase.rpc('get_distinct_categories');
      return List<String>.from(response as List);
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      throw Exception('Failed to load questions: $e');
    }
  }

  // ΓöÇΓöÇ MOCK TESTS ADMIN ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

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
          title: '≡ƒåò New Mock Test Available!',
          body: 'Check out the new test: ${test.title}',
        );
      } catch (notiErr) {}
    } catch (e) {
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
      throw Exception('Failed to delete test: ${e.message}');
    } catch (e) {
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
    } catch (e) {
      throw Exception('Failed to update test: $e');
    }
  }

  // ΓöÇΓöÇ RESULTS ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  /// Replaces storage paths with signed URLs for UI consumption.
  Future<List<MockTest>> _populateSignedUrls(List<MockTest> tests) async {
    return await Future.wait(
      tests.map((test) async {
        String? contentUrl;
        String? imageUrl;
        const bucket = 'mock_test';

        if (test.filePath.isNotEmpty) {
          final path =
              SupabaseUrlHelper.extractPathFromUrl(test.filePath, bucket);
          // Uses SupabaseUrlHelper with new 1-year expiry logic
          contentUrl =
              await SupabaseUrlHelper().getFreshSignedUrl(bucket, path);
        }

        if (test.coverImagePath != null && test.coverImagePath!.isNotEmpty) {
          final path = SupabaseUrlHelper.extractPathFromUrl(
              test.coverImagePath!, bucket);
          imageUrl = await SupabaseUrlHelper().getFreshSignedUrl(bucket, path);
        }

        return test.copyWith(
          contentUrl: contentUrl,
          signedUrl: imageUrl,
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
    } catch (e) {
      throw Exception('Failed to submit result: $e');
    }
  }

  Future<List<dynamic>> fetchUserResults(String authUserId) async {
    try {
      final response = await _supabase
          .from('results')
          .select('*, mock_tests(title, total_marks)')
          .eq('user_id', authUserId)
          .order('attempt_date', ascending: false);
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to load history: $e');
    }
  }

  // ΓöÇΓöÇ PURCHASES ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  Future<Set<int>> fetchPurchasedTestIds(String userId) async {
    try {
      final ordersResponse = await _supabase
          .from('orders')
          .select('order_id')
          .eq('user_id', userId)
          .inFilter('status', ['SUCCESS', 'COMPLETED']);

      if ((ordersResponse as List).isEmpty) return {};

      final orderIds = (ordersResponse).map((o) => o['order_id']).toList();

      final itemsResponse = await _supabase
          .from('order_items')
          .select('test_id')
          .inFilter('order_id', orderIds);

      return (itemsResponse as List)
          .where((i) => i['test_id'] != null)
          .map((i) => i['test_id'] as int)
          .toSet();
    } catch (e) {
      return {};
    }
  }

  Future<List<MockTest>> fetchUserTests(String authUserId) async {
    try {
      final ordersResponse = await _supabase
          .from('orders')
          .select('order_id')
          .eq('user_id', authUserId)
          .inFilter('status', ['SUCCESS', 'COMPLETED']);

      final orderIds =
          (ordersResponse as List).map((o) => o['order_id']).toList();
      if (orderIds.isEmpty) return [];

      final itemsResponse = await _supabase
          .from('order_items')
          .select('test_id')
          .inFilter('order_id', orderIds);

      final testIds = (itemsResponse as List)
          .where((i) => i['test_id'] != null)
          .map((i) => i['test_id'] as int)
          .toSet()
          .toList();

      if (testIds.isEmpty) return [];

      final testsResponse = await _supabase
          .from('mock_tests')
          .select()
          .inFilter('test_id', testIds);

      final List<MockTest> purchasedTests =
          await compute(_parseMockTests, testsResponse as List<dynamic>);

      return await _populateSignedUrls(purchasedTests);
    } catch (e) {
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
          } catch (e, stack) {
            CrashlyticsService.instance
                .recordError(e, stack, reason: 'streamPurchasedTests failed');
            return <MockTest>[];
          }
        });
  }

  /// Handles free test claims.
  Future<void> claimFreeTest({
    required int testId,
    required String authUserId,
  }) async {
    try {
      final existingOrder = await _supabase
          .from('order_items')
          .select('order_id, orders!inner(user_id, status)')
          .eq('test_id', testId)
          .eq('orders.user_id', authUserId)
          .eq('orders.status', 'SUCCESS')
          .maybeSingle();
      if (existingOrder != null) return;
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final newOrder = await _supabase
          .from('orders')
          .insert({
            'user_id': authUserId,
            'status': 'SUCCESS',
            'total_amount': 0.0,
            'payment_gateway_id': 'FREE_CLAIM',
            'created_at': timestamp,
          })
          .select('order_id')
          .single();
      await _supabase.from('order_items').insert({
        'order_id': newOrder['order_id'],
        'test_id': testId,
        'price_at_purchase': 0.0,
        'created_at': timestamp,
      });
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'claimFreeTest failed');
      throw Exception('Failed to claim test: $e');
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
    } catch (e) {
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

      if (orderResponse.isNotEmpty) {
        try {
          await AdminNotificationService().sendToTopic(
            topic: 'admin_updates',
            title: '≡ƒÄë New Sale! (Γé╣$amount)',
            body: 'Order #$orderId has been completed.',
            data: {
              'type': 'sale_alert',
              'order_id': orderId,
              'amount': amount.toString()
            },
          );
        } catch (_) {}
      }

      try {
        final orderItems = await _supabase
            .from('order_items')
            .select('test_id, resource_id')
            .eq('order_id', orderId);

        final purchasedTestIds = (orderItems as List)
            .where((i) => i['test_id'] != null)
            .map((i) => i['test_id'] as int)
            .toList();

        final purchasedResourceIds = (orderItems)
            .where((i) => i['resource_id'] != null)
            .map((i) => i['resource_id'] as int)
            .toList();

        if (purchasedTestIds.isNotEmpty || purchasedResourceIds.isNotEmpty) {
          final pendingOrder = await _supabase
              .from('orders')
              .select('order_id')
              .eq('user_id', userId)
              .eq('status', 'PENDING')
              .maybeSingle();

          if (pendingOrder != null) {
            final cartOrderId = pendingOrder['order_id'];
            if (purchasedTestIds.isNotEmpty) {
              await _supabase
                  .from('order_items')
                  .delete()
                  .eq('order_id', cartOrderId)
                  .inFilter('test_id', purchasedTestIds);
            }
            if (purchasedResourceIds.isNotEmpty) {
              await _supabase
                  .from('order_items')
                  .delete()
                  .eq('order_id', cartOrderId)
                  .inFilter('resource_id', purchasedResourceIds);
            }
          }
        }
      } catch (_) {}

      if (offerId != null) {
        try {
          await _supabase.from('offer_redemptions').insert({
            'offer_id': offerId,
            'user_id': userId,
            'order_id': orderId,
            'discount_amount': discountAmount,
            'redeemed_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (_) {}
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
  Future<List<dynamic>> fetchAllTestsRaw() async {
    return await _supabase
        .from('mock_tests')
        .select()
        .order('created_at', ascending: false);
  }

  /// Uploads a generated result PDF.
  Future<void> uploadResultPdf(String path, File file) async {
    try {
      await _supabase.storage.from('mock_test').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'uploadResultPdf failed');
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

// ΓöÇΓöÇ ISOLATED PARSERS ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

List<MockTest> _parseMockTests(List<dynamic> jsonList) {
  return jsonList.map((json) => MockTest.fromJson(json)).toList();
}

List<Question> _decodeAndParseQuestions(String jsonString) {
  final List<dynamic> data = json.decode(jsonString);
  return data.map((q) => Question.fromJson(q)).toList();
}
