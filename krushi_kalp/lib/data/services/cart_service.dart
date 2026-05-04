import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/order_item.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/resource.dart';
import '../../utils/supabase_url_helper.dart';
import '../../utils/crashlytics_service.dart';

/// Service class for managing the shopping cart and pending orders.
class CartService {
  // --- SINGLETON ---
  CartService._();
  static final CartService instance = CartService._();

  final _supabase = Supabase.instance.client;

  // ── READ ─────────────────────────────────────────────────────────────────

  /// Fetches all items in the user's current PENDING payment (the cart).
  Future<List<OrderItem>> fetchCartItems(String userId) async {
    try {
      // 1. Find PENDING payment
      final pendingPaymentRes = await _supabase
          .from('payment')
          .select('id, offer_code')
          .eq('user_id', userId)
          .eq('status', 'PENDING')
          .order('created_at', ascending: false)
          .limit(1);

      if (pendingPaymentRes.isEmpty) return [];

      final String paymentId = pendingPaymentRes.first['id'];
      final String? appliedOfferCode =
          pendingPaymentRes.first['offer_code'] as String?;

      // 2. Fetch raw items from 'access' table (No joins here to respect 'No FK' policy)
      final List<dynamic> itemsResponse = await _supabase
          .from('access')
          .select('*')
          .eq('payment_id', paymentId)
          .eq('is_active', false)
          .order('granted_at');

      if (itemsResponse.isEmpty) return [];

      // 3. Manual Stitching: Collect IDs for bulk fetching
      final testIds = itemsResponse
          .where((i) => i['item_type'] == 'test')
          .map((i) => i['item_id'] as int)
          .toList();
      final resourceIds = itemsResponse
          .where((i) => i['item_type'] == 'resource')
          .map((i) => i['item_id'] as int)
          .toList();

      // 4. Bulk fetch related data
      Map<int, dynamic> testsMap = {};
      Map<int, dynamic> resourcesMap = {};

      if (testIds.isNotEmpty) {
        final tests = await _supabase
            .from('mock_tests')
            .select('*')
            .inFilter('test_id', testIds);
        for (var t in tests) {
          testsMap[t['test_id']] = t;
        }
      }

      if (resourceIds.isNotEmpty) {
        final resources = await _supabase
            .from('resources')
            .select('*')
            .inFilter('id', resourceIds);
        for (var r in resources) {
          resourcesMap[r['id']] = r;
        }
      }

      // 5. Fetch offer if applied
      Map<String, dynamic>? globalOfferData;
      if (appliedOfferCode != null) {
        try {
          final offerRes = await _supabase
              .from('offers')
              .select()
              .eq('code', appliedOfferCode)
              .maybeSingle();
          globalOfferData = offerRes;
        } catch (_) {}
      }

      // 6. Assemble the final list
      final List<OrderItem> rawItems = itemsResponse.map((json) {
        final String itemType = json['item_type'] ?? '';
        final int itemId = json['item_id'] ?? 0;

        // Manually inject the 'joined' data
        if (itemType == 'test') {
          json['mock_tests'] = testsMap[itemId];
        } else if (itemType == 'resource') {
          json['resources'] = resourcesMap[itemId];
        }

        // Map access table schema to OrderItem model expectations
        json['order_id'] = json['payment_id'];
        json['item_id'] = json['id']; // use access.id as item_id
        if (itemType == 'test') {
          json['test_id'] = itemId;
        } else if (itemType == 'resource') {
          json['resource_id'] = itemId;
        }
        json['price_at_purchase'] = json['price_paid'];
        json['created_at'] = json['granted_at'];

        if (globalOfferData != null) {
          json['offers'] = globalOfferData;
        }
        return OrderItem.fromJson(json);
      }).toList();

      // 7. Transform items to include fresh signed URLs for thumbnails
      return await _signCartItems(rawItems);
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'cart_service: fetchCartItems');
      return [];
    }
  }

  /// Internal helper to sign thumbnails for items displayed in the cart.
  Future<List<OrderItem>> _signCartItems(List<OrderItem> items) async {
    return await Future.wait(items.map((item) async {
      MockTest? signedTest = item.mockTest;
      Resource? signedResource = item.resource;
      const bucket = 'mock_test';

      if (signedTest != null && signedTest.coverImagePath != null) {
        final path = SupabaseUrlHelper.extractPathFromUrl(
            signedTest.coverImagePath!, bucket);
        final url = await SupabaseUrlHelper().getFreshSignedUrl(bucket, path);
        signedTest = signedTest.copyWith(signedUrl: url);
      }

      if (signedResource != null &&
          (signedResource.thumbnailUrl?.isNotEmpty ?? false)) {
        final path = SupabaseUrlHelper.extractPathFromUrl(
            signedResource.thumbnailUrl!, bucket);
        final url = await SupabaseUrlHelper().getFreshSignedUrl(bucket, path);
        signedResource = signedResource.copyWith(thumbnailUrl: url);
      }

      return OrderItem(
        itemId: item.itemId,
        orderId: item.orderId,
        testId: item.testId,
        resourceId: item.resourceId,
        priceAtPurchase: item.priceAtPurchase,
        appliedOfferId: item.appliedOfferId,
        createdAt: item.createdAt,
        mockTest: signedTest,
        resource: signedResource,
        offers: item.offers,
      );
    }));
  }

  // ── WRITE ────────────────────────────────────────────────────────────────

  /// Checks if user already owns the item (Status = SUCCESS)
  Future<bool> checkOwnership({
    required String userId,
    int? testId,
    int? resourceId,
  }) async {
    try {
      if (testId == null && resourceId == null) return false;

      var query = _supabase
          .from('access')
          .select('id')
          .eq('user_id', userId);

      if (testId != null) {
        query = query.eq('item_id', testId).eq('item_type', 'test');
      } else {
        query = query.eq('item_id', resourceId!).eq('item_type', 'resource');
      }

      final response = await query.limit(1).maybeSingle();
      return response != null;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'cart_service: checkOwnership');
      return false;
    }
  }

  /// Adds an item to the user's cart. Handles duplicate and ownership checks using the new schema.
  Future<void> addToCart({
    required String authUserId,
    int? testId,
    int? resourceId,
    required double price,
  }) async {
    if (testId == null && resourceId == null) {
      throw Exception("Must provide either testId or resourceId");
    }

    try {
      // 0. OWNERSHIP CHECK (Already uses 'access' table via instance)
      final isOwned = await checkOwnership(
        userId: authUserId,
        testId: testId,
        resourceId: resourceId,
      );

      if (isOwned) {
        throw Exception("You already own this item.");
      }

      // 1. Find/Create PENDING payment
      final pendingPaymentRes = await _supabase
          .from('payment')
          .select('id')
          .eq('user_id', authUserId)
          .eq('status', 'PENDING')
          .order('created_at', ascending: false)
          .limit(1);

      String paymentId;
      if (pendingPaymentRes.isNotEmpty) {
        paymentId = pendingPaymentRes.first['id'];

        // DUPLICATE CHECK (In Cart - using access table)
        final existingItem = await _supabase
            .from('access')
            .select('id')
            .eq('payment_id', paymentId)
            .eq('item_id', (testId ?? resourceId)!)
            .eq('item_type', testId != null ? 'test' : 'resource')
            .eq('is_active', false)
            .maybeSingle();

        if (existingItem != null) {
          throw Exception("Item is already in your cart.");
        }
      } else {
        // Create new PENDING payment with user snapshot
        // We import AuthService logic here to get the snapshot
        final userProfileRes = await _supabase
            .from('users')
            .select('*')
            .eq('id', authUserId)
            .maybeSingle();
        
        final userSnapshot = userProfileRes ?? {
          'email': 'unknown',
          'username': 'User',
        };

        final newPayment = await _supabase
            .from('payment')
            .insert({
              'user_id': authUserId,
              'user_snapshot': userSnapshot,
              'status': 'PENDING',
              'amount': 0, // Will be calculated by triggers or on checkout
              'gateway': 'razorpay',
              'created_at': DateTime.now().toIso8601String(),
            })
            .select('id')
            .single();
        paymentId = newPayment['id'];
      }

      // 2. Insert Item into 'access' table (is_active = false for Cart)
      // Fetch item snapshot — required for admin revenue display
      Map<String, dynamic> itemSnapshot = {};
      if (testId != null) {
        final testRes = await _supabase
            .from('mock_tests')
            .select('test_id, title, category, price, description, language')
            .eq('test_id', testId)
            .single();
        itemSnapshot = Map<String, dynamic>.from(testRes);
      } else {
        final resRes = await _supabase
            .from('resources')
            .select('id, title, type, category, price, description')
            .eq('id', resourceId!)
            .single();
        itemSnapshot = Map<String, dynamic>.from(resRes);
      }

      await _supabase.from('access').insert({
        'user_id': authUserId,
        'payment_id': paymentId,
        'item_type': testId != null ? 'test' : 'resource',
        'item_id': testId ?? resourceId,
        'item_snapshot': itemSnapshot,
        'price_paid': price,
        'is_active': false,
        'granted_at': DateTime.now().toIso8601String(),
      });
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'cart_service: addToCart');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Removes a specific item from the cart (access table).
  Future<void> removeCartItem(int itemId) async {
    try {
      await _supabase.from('access').delete().eq('id', itemId).eq('is_active', false);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'cart_service: removeCartItem');
      throw Exception('Failed to remove item: $e');
    }
  }
}
