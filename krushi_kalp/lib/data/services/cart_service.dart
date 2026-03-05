import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/order_item.dart';

class CartService {
  static final _supabase = Supabase.instance.client;

  // --- READ ---
  static Future<List<OrderItem>> fetchCartItems(String userId) async {
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

      // 3. (Optional) Fetch global offer if needed - reusing logic from TestService
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

      final List<OrderItem> items = (itemsResponse as List).map((json) {
        // Attach offer data manually if needed by UI, or handle in UI
        // For now, just parsing to OrderItem
        // OrderItem model has 'offers' map, so we can inject it
        if (globalOfferData != null) {
          json['offers'] = globalOfferData;
        }
        return OrderItem.fromJson(json);
      }).toList();

      return items;
    } catch (e) {
      debugPrint("CartService: Error fetching cart items: $e");
      return [];
    }
  }

  // --- WRITE ---

  /// Checks if user already owns the item (Status = SUCCESS)
  static Future<bool> checkOwnership({
    required String userId,
    int? testId,
    int? resourceId,
  }) async {
    try {
      if (testId == null && resourceId == null) return false;

      // Check in order_items joined with orders where status is SUCCESS
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
      debugPrint("CartService: Error checking ownership: $e");
      return false; // Fail safe? Or throw? Better to allow check to fail as false to not block, but might risk double buy.
    }
  }

  static Future<void> addToCart({
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
        // Create new
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
        'test_id': testId, // Can be null
        'resource_id': resourceId, // Can be null
        'price_at_purchase': price,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('CartService: Error adding to cart: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<void> removeCartItem(int itemId) async {
    try {
      await _supabase.from('order_items').delete().eq('item_id', itemId);
    } catch (e) {
      debugPrint('CartService: Error removing item: $e');
      throw Exception('Failed to remove item: $e');
    }
  }
}
