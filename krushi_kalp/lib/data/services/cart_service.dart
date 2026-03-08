import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/order_item.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/resource.dart';
import '../../utils/supabase_url_helper.dart';

/// Service class for managing the shopping cart and pending orders.
class CartService {
  // --- SINGLETON ---
  CartService._();
  static final CartService instance = CartService._();

  final _supabase = Supabase.instance.client;

  // ── READ ─────────────────────────────────────────────────────────────────

  /// Fetches all items in the user's current PENDING order (the cart).
  Future<List<OrderItem>> fetchCartItems(String userId) async {
    try {
      // 1. Find PENDING order
      final pendingOrderRes = await _supabase
          .from('orders')
          .select('order_id, offer_id')
          .eq('user_id', userId)
          .eq('status', 'PENDING')
          .limit(1);

      if (pendingOrderRes.isEmpty) return [];

      final String orderId = pendingOrderRes.first['order_id'];
      final int? appliedOfferId = pendingOrderRes.first['offer_id'] as int?;

      // 2. Fetch items with relations
      final itemsResponse = await _supabase
          .from('order_items')
          .select('*, mock_tests(*), resources(*)')
          .eq('order_id', orderId)
          .order('created_at');

      // 3. Fetch global offer if applied to the cart
      Map<String, dynamic>? globalOfferData;
      if (appliedOfferId != null) {
        try {
          final offerRes = await _supabase
              .from('offers')
              .select()
              .eq('offer_id', appliedOfferId)
              .maybeSingle();
          globalOfferData = offerRes;
        } catch (_) {}
      }

      final List<OrderItem> rawItems = (itemsResponse as List).map((json) {
        if (globalOfferData != null) {
          json['offers'] = globalOfferData;
        }
        return OrderItem.fromJson(json);
      }).toList();

      // 4. Transform items to include 1-year signed URLs for thumbnails
      return await _signCartItems(rawItems);
    } catch (e) {
      
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
          .from('order_items')
          .select('orders!inner(status, user_id)')
          .eq('orders.user_id', userId)
          .eq('orders.status', 'SUCCESS');

      if (testId != null) {
        query = query.eq('test_id', testId);
      } else {
        query = query.eq('resource_id', resourceId as Object);
      }

      final response = await query.limit(1).maybeSingle();
      return response != null;
    } catch (e) {
      
      return false;
    }
  }

  /// Adds an item to the user's cart. Handles duplicate and ownership checks.
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
      // 0. OWNERSHIP CHECK
      final isOwned = await checkOwnership(
        userId: authUserId,
        testId: testId,
        resourceId: resourceId,
      );

      if (isOwned) {
        throw Exception("You already own this item.");
      }

      // 1. Find/Create PENDING order
      final pendingOrderRes = await _supabase
          .from('orders')
          .select('order_id')
          .eq('user_id', authUserId)
          .eq('status', 'PENDING')
          .limit(1);

      String orderId;
      if (pendingOrderRes.isNotEmpty) {
        orderId = pendingOrderRes.first['order_id'];

        // DUPLICATE CHECK (In Cart)
        var query = _supabase
            .from('order_items')
            .select('item_id')
            .eq('order_id', orderId);

        if (testId != null) {
          query = query.eq('test_id', testId);
        } else {
          query = query.eq('resource_id', resourceId as Object);
        }

        final existingItem = await query.maybeSingle();
        if (existingItem != null) {
          throw Exception("Item is already in your cart.");
        }
      } else {
        final newOrder = await _supabase
            .from('orders')
            .insert({
              'user_id': authUserId,
              'status': 'PENDING',
              'total_amount': 0,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            })
            .select('order_id')
            .single();
        orderId = newOrder['order_id'];
      }

      // 2. Insert Item
      await _supabase.from('order_items').insert({
        'order_id': orderId,
        'test_id': testId,
        'resource_id': resourceId,
        'price_at_purchase': price,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Removes a specific item from the cart.
  Future<void> removeCartItem(int itemId) async {
    try {
      await _supabase.from('order_items').delete().eq('item_id', itemId);
    } catch (e) {
      
      throw Exception('Failed to remove item: $e');
    }
  }
}
