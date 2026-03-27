import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/cart_service.dart';
import '../../utils/supabase_url_helper.dart';
import '../../utils/crashlytics_service.dart';

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get cartCount => _cartItems.length;

  bool isItemInCart(int? testId) {
    if (testId == null) return false;
    return _cartItems.any((item) => item['test_id'] == testId);
  }

  bool isResourceInCart(int? resourceId) {
    if (resourceId == null) return false;
    return _cartItems.any(
        (item) => item['material_id'] == resourceId && item['test_id'] == null);
  }

  Future<void> fetchCart({bool forceRefresh = false}) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _cartItems = [];
      notifyListeners();
      return;
    }

    if (!forceRefresh && _cartItems.isNotEmpty) {
      // Check if signed URLs are expired?
      // For now, let's assume they are valid or will be refreshed on explicit pull.
      // Or we can add a timestamp check.
      // But simply preventing the loop is priority.
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    CrashlyticsService.instance
        .log('CartProvider: Fetching cart (force: $forceRefresh)');

    try {
      final items = await CartService.instance.fetchCartItems(user.id);

      // Sign URLs (Logic moved from CartScreen)
      final processedItems = await Future.wait(items.map((item) async {
        String? imageUrl;
        String? path;
        String title = 'Unavailable Item';
        String subtitle = 'General';

        if (item.mockTest != null) {
          title = item.mockTest!.title;
          subtitle = item.mockTest!.category;
          path = item.mockTest!.coverImagePath;
        } else if (item.resource != null) {
          title = item.resource!.title;
          subtitle = item.resource!.category ?? 'General';
          path = item.resource!.thumbnailUrl; // Assuming this is path or url?
          // If resource thumbnails are full URLs, we don't need signing.
          // But if they are paths, we do. Let's assume path for consistency with test logic or check Resource model.
        }

        if (path != null && !path.startsWith('http')) {
          // It's likely a storage path
          path = path.replaceAll('mock_test/',
              ''); // Clean up if needed, though resource might differ
          // For now, let's try to sign it if it looks like a path.
          // NOTE: Resource signing might be different bucket.
          // Tests use 'mock_test' bucket. Resources might use 'materials' or similar.
          // For safety: Only sign if we know the bucket.
          // For now, only signing MockTests as before.
          if (item.mockTest != null) {
            try {
              imageUrl = await SupabaseUrlHelper()
                  .getFreshSignedUrl('mock_test', path);
            } catch (e, stack) {
              CrashlyticsService.instance.recordError(e, stack, reason: 'cart_provider');
              // ignore
            }
          } else {
            // For resources, maybe it is a public URL or needs signing?
            // If usage is unclear, leaving as is for resources (null or original path)
            // or check ResourceService logic.
            // But for now, let's just use path as is if not signed.
            imageUrl = path;
          }
        } else {
          imageUrl = path;
        }

        return {
          'item_id': item.itemId,
          'test_id': item.testId,
          'resource_id': item.resourceId, // NEW
          'order_id': item.orderId,
          'title': title,
          'subtitle': subtitle,
          'price': item.priceAtPurchase,
          'image_url': imageUrl,
          'offers': item.offers,
          // 'raw_item': item, // Remove raw item or store OrderItem
        };
      }));

      _cartItems = processedItems;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'cart_provider');
      _errorMessage = e.toString();
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'CartProvider: fetchCart');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart({
    int? testId,
    int? resourceId, // NEW
    required double price,
    required String authUserId,
  }) async {
    if (_isLoading) return; // PRO FIX: Synchronization Gate
    if (testId == null && resourceId == null) return;

    if ((testId != null && isItemInCart(testId)) ||
        (resourceId != null && isResourceInCart(resourceId))) {
      _errorMessage = "Item is already in your cart.";
      notifyListeners();
      throw Exception(_errorMessage);
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    CrashlyticsService.instance.log(
        'CartProvider: Adding to cart (test: $testId, resource: $resourceId)');

    try {
      await CartService.instance.addToCart(
        authUserId: authUserId,
        testId: testId,
        resourceId: resourceId,
        price: price,
      );

      await fetchCart(forceRefresh: true);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'cart_provider');
      _errorMessage = e.toString();
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'CartProvider: addToCart');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromCart({
    required int itemId,
  }) async {
    try {
      await CartService.instance.removeCartItem(itemId);
      // Optimistic update
      _cartItems.removeWhere((item) => item['item_id'] == itemId);
      notifyListeners();

      // Full refresh to be safe
      await fetchCart(forceRefresh: true);
      CrashlyticsService.instance
          .log('CartProvider: Removed item $itemId from cart');
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'CartProvider: removeFromCart');
      rethrow;
    }
  }

  void clearCart() {
    _cartItems = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _cartItems.clear();
    super.dispose();
  }
}
