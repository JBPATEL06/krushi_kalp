import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/services/cart_service.dart';
import '../../data/services/auth_service.dart';
import '../../utils/crashlytics_service.dart';
import 'cart_state.dart';

part 'cart_notifier.g.dart';

@Riverpod(keepAlive: true)
class CartNotifier extends _$CartNotifier {
  @override
  CartState build() {
    return const CartState();
  }

  bool isItemInCart(int? testId) {
    if (testId == null) return false;
    return state.cartItems.any((item) => item.testId == testId);
  }

  bool isResourceInCart(int? resourceId) {
    if (resourceId == null) return false;
    return state.cartItems.any((item) => item.resourceId == resourceId);
  }

  Future<void> fetchCart({bool forceRefresh = false}) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      state = state.copyWith(cartItems: [], isLoading: false);
      return;
    }

    if (!forceRefresh && state.cartItems.isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    CrashlyticsService.instance.log('CartNotifier: Fetching cart (force: $forceRefresh)');

    try {
      final items = await CartService.instance.fetchCartItems(user.id);
      state = state.copyWith(cartItems: items);
    } catch (e, stack) {
      state = state.copyWith(errorMessage: e.toString());
      CrashlyticsService.instance.recordError(e, stack, reason: 'CartNotifier: fetchCart');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addToCart({
    int? testId,
    int? resourceId,
    required double price,
    required String authUserId,
  }) async {
    if (state.isLoading) return;
    if (testId == null && resourceId == null) return;

    if (isItemInCart(testId) || isResourceInCart(resourceId)) {
      state = state.copyWith(errorMessage: "Item is already in your cart.");
      throw Exception(state.errorMessage);
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    CrashlyticsService.instance.log('CartNotifier: Adding to cart (test: $testId, resource: $resourceId)');

    try {
      await CartService.instance.addToCart(
        authUserId: authUserId,
        testId: testId,
        resourceId: resourceId,
        price: price,
      );

      await fetchCart(forceRefresh: true);
    } catch (e, stack) {
      state = state.copyWith(errorMessage: e.toString());
      CrashlyticsService.instance.recordError(e, stack, reason: 'CartNotifier: addToCart');
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> removeFromCart({required int itemId}) async {
    // 1. Optimistic update (Instant UI change)
    final originalItems = state.cartItems;
    final newItems = state.cartItems.where((item) => item.itemId != itemId).toList();
    
    state = state.copyWith(
      cartItems: newItems,
      errorMessage: null,
    );

    try {
      await CartService.instance.removeCartItem(itemId);
      // 2. Fetch fresh state from server in background
      // Note: We don't set isLoading=true here to avoid a flickering spinner for a simple removal
      await fetchCart(forceRefresh: true);
    } catch (e, stack) {
      // 3. Revert on failure
      state = state.copyWith(
        cartItems: originalItems,
        errorMessage: 'Failed to remove item: ${e.toString()}',
      );
      CrashlyticsService.instance.recordError(e, stack, reason: 'CartNotifier: removeFromCart');
      rethrow;
    }
  }

  void clearCart() {
    state = state.copyWith(cartItems: []);
  }
}
