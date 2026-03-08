import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/services/payment_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/cart_service.dart';
import '../../data/services/offer_service.dart';
import '../../data/services/test_service.dart';
import '../../domain/models/offer.dart';
import '../../domain/models/order_item.dart';
import '../../utils/price_calculator.dart';
import '../../core/theme/app_spacing.dart';

import '../widgets/common/network_error_state.dart';
import '../widgets/common/responsive_wrapper.dart';
import 'cart/widgets/cart_item_widget.dart';
import 'cart/widgets/cart_order_summary.dart';
import '../providers/navigation_provider.dart';
import '../providers/cart_provider.dart';
import '../../utils/supabase_url_helper.dart'; // Ensure correct URL construction
import '../../utils/error_utils.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<Map<String, dynamic>>> _cartFuture;

  List<Map<String, dynamic>> _currentCartItems = [];

  // --- Coupon Logic ---
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;
  bool _isProcessing = false; // PRO FIX: Synchronization Gate
  String? _couponError;
  Offer? _appliedGlobalOffer;
  bool _hasAutoSale = false; // NEW FLAG

  @override
  void initState() {
    super.initState();
    _loadCart();
    PaymentService.init(
      onSuccess: _handlePaymentSuccess,
      onFailure: (response) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Payment Failed: ${response.code} - ${response.message}",
              ),
            ),
          );
        }
      },
      onExternalWallet: (response) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("External Wallet Selected: ${response.walletName}"),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    PaymentService.instance.dispose();
    super.dispose();
  }

  void _loadCart() {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      setState(() {
        _cartFuture = Future.wait([
          CartService.instance.fetchCartItems(user.id),
          OfferService.instance.fetchActiveSaleOffers(),
        ]).then((results) async {
          final items = results[0] as List<OrderItem>;
          final saleOffers = results[1] as List<Offer>;

          // Map to UI model and Sign URLs
          final cartItems = await Future.wait(
            items.map((item) async {
              String? imageUrl;
              String? path;
              String title = 'Unavailable Item';
              String subtitle = 'General';
              double originalPrice = item.priceAtPurchase; // Default fallback

              final mockTest = item.mockTest;
              final resource = item.resource;

              if (mockTest != null) {
                title = mockTest.title;
                subtitle = mockTest.category;
                path = mockTest.coverImagePath;
                originalPrice = mockTest.price;
              } else if (resource != null) {
                title = resource.title;
                subtitle = resource.category ?? 'General';
                path = resource.thumbnailUrl;
                originalPrice = resource.price;
              }

              if (path != null && !path.startsWith('http')) {
                try {
                  imageUrl = await SupabaseUrlHelper()
                      .getFreshSignedUrl('mock_test', path);
                } catch (e) {
                  imageUrl = path;
                }
              } else {
                imageUrl = path;
              }

              // --- Calculate Automatic Sale Price ---
              final priceData = PriceCalculator.calculateDisplayPrice(
                basePrice: originalPrice,
                baseMrp: (item.resource?.mrp ?? item.mockTest?.mrp)
                    ?.toDouble(), // Fetch original MRP
                activeOffers: saleOffers,
                testId: item.testId,
                resourceId: item.resourceId,
                userId: user.id,
              );

              final double finalPrice = priceData['finalPrice'];
              final double mrp = priceData['mrp'];
              final Offer? appliedSale = priceData['offer'];
              // --------------------------------------

              return {
                'item_id': item.itemId,
                'test_id': item.testId,
                'resource_id': item.resourceId,
                'order_id': item.orderId,
                'title': title,
                'subtitle': subtitle,
                'price': finalPrice, // Use calculated sale price
                'mrp': mrp, // Use calculated MRP
                'original_price': originalPrice,
                'image_url': imageUrl,
                'color': Colors.blue[50], // Placeholder color
                'offers': item.offers,
                'appliedSale': appliedSale, // Store to detect later
              };
            }),
          );
          _processGlobalOffer(cartItems);

          // Check if ANY item has an auto sale applied
          _hasAutoSale = cartItems.any((item) => item['appliedSale'] != null);

          // If a sale is active, force strip any coupon just in case
          if (_hasAutoSale &&
              _appliedGlobalOffer != null &&
              !_appliedGlobalOffer!.isSale) {
            _appliedGlobalOffer = null;
            if (!_isApplyingCoupon) _couponController.clear();
          }

          return cartItems;
        });
      });
    } else {
      _cartFuture = Future.value([]);
      _hasAutoSale = false;
    }
  }

  void _processGlobalOffer(List<Map<String, dynamic>> cartItems) {
    if (cartItems.isNotEmpty) {
      final offersData = cartItems.first['offers'];
      if (offersData != null && offersData is Map && offersData.isNotEmpty) {
        try {
          final offer = Offer.fromJson(Map<String, dynamic>.from(offersData));
          if (offer.isSale || (offer.code == null || offer.code!.isEmpty)) {
            _appliedGlobalOffer = null;
            if (!_isApplyingCoupon) _couponController.clear();
          } else {
            _appliedGlobalOffer = offer;
            _couponController.text = offer.code ?? '';
          }
        } catch (_) {
          _appliedGlobalOffer = null;
        }
      } else {
        _appliedGlobalOffer = null;
        if (!_isApplyingCoupon) _couponController.clear();
      }
    } else {
      _appliedGlobalOffer = null;
    }
  }

  // _processMrpDisplay REMOVED

  Future<void> _refreshCart() async {
    _loadCart();
    // await _checkAutoApply(); // Optional
  }

  // Updated to check BEST offer for the WHOLE cart
  Future<void> _checkAutoApply() async {
    // Logic REMOVED as per user request.
    // Coupon codes must be applied manually.
    // Sales (is_sale=true) are applied via PriceCalculator automatically in UI.
  }

  Future<void> _applyOrderCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty || _currentCartItems.isEmpty) return;

    setState(() {
      _isApplyingCoupon = true;
      _couponError = null;
    });

    try {
      final offer = await OfferService.instance.verifyCoupon(code);
      if (offer != null) {
        final total = _calculateSubtotal(_currentCartItems);
        final testIds =
            _currentCartItems.map((e) => e['test_id'] as int).toList();

        if (offer.isValid(
          userId: AuthService.instance.currentUser!.id,
          cartTotal: total,
          cartTestIds: testIds,
        )) {
          final orderId = _currentCartItems.first['order_id'] as String;
          await OfferService.instance.applyCouponToOrder(
            orderId: orderId,
            offerId: offer.id,
          );
          await _refreshCart(); // Refresh to show discount
        } else {
          setState(() => _couponError = "Coupon not valid for these items");
        }
      } else {
        setState(() => _couponError = "Invalid Code");
      }
    } catch (e) {
      setState(() => _couponError = "Error applying coupon");
    } finally {
      if (mounted) setState(() => _isApplyingCoupon = false);
    }
  }

  Future<void> _removeOrderCoupon() async {
    if (_currentCartItems.isEmpty) return;
    setState(() => _isApplyingCoupon = true);
    try {
      final orderId = _currentCartItems.first['order_id'] as String;
      await OfferService.instance.removeCouponFromOrder(orderId);
      _couponController.clear();
      await _refreshCart(); // Refresh to remove discount logic
    } catch (e) {
      // handle error
    } finally {
      if (mounted) setState(() => _isApplyingCoupon = false);
    }
  }

  Future<void> _deleteItem(int itemId) async {
    try {
      await context.read<CartProvider>().removeFromCart(itemId: itemId);
      await _refreshCart();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item removed')));
      }
    } catch (e) {
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId;
    if (paymentId == null) return;

    if (_isProcessing) return; // PRO FIX: Double-tap gate
    _isProcessing = true;

    if (_currentCartItems.isEmpty) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    // Assume all items belong to same order
    final orderId = _currentCartItems.first['order_id'] as String;
    final total = _calculateTotal(_currentCartItems);
    final discount = _calculateTotalDiscount(_currentCartItems);
    final user = AuthService.instance.currentUser;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Successful! Processing...")),
        );
      }

      await TestService.instance.checkout(
        orderId: orderId,
        paymentId: paymentId,
        amount: total,
        offerId: null, // Per-item offers handled by applied_offer_id
        discountAmount: discount,
        userId: user!.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Purchase Complete! 🥳"),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to Home tab and pop the cart screen
        Provider.of<NavigationProvider>(context, listen: false).setIndex(0);
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  double _calculateSubtotal(List<Map<String, dynamic>> items) =>
      items.fold(0, (sum, item) {
        final price = (item['price'] as num).toDouble();
        return sum + price;
      });

  double _calculateTotalDiscount(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 0.0;

    // Check if there is a global offer (it would be on the first item)
    final offersData = items.first['offers'];
    if (offersData != null && offersData is Map && offersData.isNotEmpty) {
      try {
        final offer = Offer.fromJson(Map<String, dynamic>.from(offersData));
        final totalBasePrice = _calculateSubtotal(items);

        return offer.calculateDiscountAmount(
          totalAmount: totalBasePrice,
          cartItems: items,
        );
      } catch (_) {}
    }
    return 0.0;
  }

  double _calculateTotal(List<Map<String, dynamic>> items) {
    return _calculateSubtotal(items) - _calculateTotalDiscount(items);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Shopping Cart',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontSize: context.sp(20),
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colorScheme.onSurface,
            size: context.sp(24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return NetworkErrorState(
              message: isNetworkError(snapshot.error)
                  ? 'Unable to load cart. Check your connection.'
                  : 'Something went wrong.',
              onRetry: _refreshCart,
            );
          }

          final cartItems = snapshot.data ?? [];
          _currentCartItems = cartItems;

          if (cartItems.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshCart,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(
                        AppSpacing.lg), // FIXED: AppSpacing.lg (16.0)
                    child: Builder(
                      builder: (context) {
                        // Trigger auto-apply check once when we have data
                        if (cartItems.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _checkAutoApply();
                          });
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR CURRICULUM (${cartItems.length} ITEMS)',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: context.sp(14),
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: context.h(AppSpacing.lg)),
                            ...cartItems.map(
                              (item) => CartItemWidget(
                                item: item,
                                onRemove: () =>
                                    _deleteItem(item['item_id'] as int),
                              ),
                            ),
                            const SizedBox(
                                height: AppSpacing
                                    .xxl), // FIXED: AppSpacing.xxl (24)

                            // --- COUPON INPUT SECTION ---
                            Text(
                              'STUDENT DISCOUNT CODE',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: context.sp(13),
                              ),
                            ),
                            SizedBox(height: context.h(AppSpacing.md)),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: context.h(50),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(
                                        context.w(AppSpacing.radiusMd),
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _couponController,
                                      enabled:
                                          !_isApplyingCoupon && !_hasAutoSale,
                                      readOnly: _appliedGlobalOffer != null ||
                                          _hasAutoSale,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: context.sp(14),
                                        color: _hasAutoSale
                                            ? theme.colorScheme.onSurfaceVariant
                                            : theme.colorScheme.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: _hasAutoSale
                                            ? 'Disabled during Store Sale'
                                            : 'Enter code (e.g. SCHOLAR20)',
                                        hintStyle: TextStyle(
                                          color:
                                              theme.colorScheme.outlineVariant,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: context.w(AppSpacing.md),
                                          vertical: context.h(12),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            context.w(AppSpacing.radiusMd),
                                          ),
                                          borderSide: BorderSide(
                                            color: _appliedGlobalOffer != null
                                                ? theme.colorScheme.primary
                                                : theme
                                                    .colorScheme.outlineVariant,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            context.w(AppSpacing.radiusMd),
                                          ),
                                          borderSide: BorderSide(
                                            color: _appliedGlobalOffer != null
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            context.w(AppSpacing.radiusMd),
                                          ),
                                          borderSide: BorderSide(
                                            color: theme
                                                .colorScheme.outlineVariant
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: context.w(AppSpacing.md)),
                                SizedBox(
                                  height: context.h(50),
                                  child: ElevatedButton(
                                    onPressed: _hasAutoSale
                                        ? null
                                        : (_appliedGlobalOffer == null
                                            ? _applyOrderCoupon
                                            : _removeOrderCoupon),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _hasAutoSale
                                          ? theme.colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.5)
                                          : (_appliedGlobalOffer == null
                                              ? theme.colorScheme
                                                  .surfaceContainerHighest
                                              : theme.colorScheme.errorContainer
                                                  .withValues(alpha: 0.3)),
                                      foregroundColor: _hasAutoSale
                                          ? theme.colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.5)
                                          : (_appliedGlobalOffer == null
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.error),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          context.w(AppSpacing.radiusMd),
                                        ),
                                        side: BorderSide(
                                          color: _hasAutoSale
                                              ? Colors.transparent
                                              : theme
                                                  .colorScheme.outlineVariant,
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.w(AppSpacing.xl),
                                      ),
                                    ),
                                    child: _isApplyingCoupon
                                        ? SizedBox(
                                            width: 20, // FIXED: standard size
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: theme.colorScheme.primary,
                                            ),
                                          )
                                        : Text(
                                            _appliedGlobalOffer == null
                                                ? "Apply"
                                                : "Remove",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            if (_hasAutoSale)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: context
                                      .h(AppSpacing.sm), // FIXED: AppSpacing.sm
                                  left: context
                                      .w(AppSpacing.xs), // FIXED: AppSpacing.xs
                                ),
                                child: Text(
                                  "✨ Store sale discounts are already active on items in your cart.",
                                  style: TextStyle(
                                    color: const Color(
                                        0xFF10B981), // Success Emerald
                                    fontSize: context.sp(12),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (_couponError != null && !_hasAutoSale)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: context
                                      .h(AppSpacing.sm), // FIXED: AppSpacing.sm
                                  left: context
                                      .w(AppSpacing.xs), // FIXED: AppSpacing.xs
                                ),
                                child: Text(
                                  _couponError!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: context.sp(12),
                                  ),
                                ),
                              ),

                            // ----------------------------
                            const SizedBox(
                                height: AppSpacing
                                    .xxxl), // FIXED: AppSpacing.xxxl (32)
                            CartOrderSummary(
                              subtotal: _calculateSubtotal(cartItems),
                              discountAmount: _calculateTotalDiscount(
                                cartItems,
                              ),
                              couponCode: null,
                            ),
                            SizedBox(
                                height: AppSpacing.lg +
                                    MediaQuery.of(context)
                                        .padding
                                        .bottom), // FIXED: AppSpacing.lg (16)
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              _buildBottomCheckoutBar(cartItems),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshCart,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 64, // FIXED: Skip large icon
                  color: Colors.grey,
                ),
                const SizedBox(
                    height: AppSpacing.lg), // FIXED: AppSpacing.lg (16)
                Text(
                  'Your cart is empty',
                  style: TextStyle(
                      fontSize: context.sp(18),
                      fontWeight: FontWeight.bold), // FIXED: context.sp(18)
                ),
                const SizedBox(height: AppSpacing.sm), // FIXED: AppSpacing.sm
                const SizedBox(height: AppSpacing.sm), // FIXED: AppSpacing.sm
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Provider.of<NavigationProvider>(
                      context,
                      listen: false,
                    ).setIndex(2); // 2 = Store tab
                  },
                  child: const Text('Go to Store'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCheckoutBar(List<Map<String, dynamic>> items) {
    final theme = Theme.of(context);
    final total = _calculateTotal(items);

    return SafeArea(
      bottom: true,
      child: Container(
        padding: const EdgeInsets.only(
            left: AppSpacing.xxl,
            top: AppSpacing.xxl,
            right: AppSpacing.xxl), // FIXED: AppSpacing.xxl (24)
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(
              bottom: AppSpacing.xxl), // FIXED: AppSpacing.xxl (24)
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs), // FIXED: AppSpacing.xs
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: context.sp(24),
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xxl), // FIXED: AppSpacing.xxl
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          if (_isProcessing) return;
                          setState(() => _isProcessing = true);

                          final user = AuthService.instance.currentUser;

                          // Pre-fill phone if available locally, do not block network to fetch it.
                          // Razorpay UI will prompt user if phone is missing.
                          String? userPhone = user?.phone;

                          PaymentService.instance.openCheckout(
                            amount: total,
                            orderId:
                                'cart_checkout_${DateTime.now().millisecondsSinceEpoch}',
                            email: user?.email,
                            contact: userPhone,
                          );

                          if (mounted) {
                            setState(() => _isProcessing = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: context.h(16)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.w(AppSpacing.radiusMd),
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Proceed to Payment',
                        style: TextStyle(
                          fontSize: context.sp(16), // FIXED: context.sp(16)
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                          width: AppSpacing.sm), // FIXED: AppSpacing.sm
                      Icon(Icons.arrow_forward_rounded, size: context.sp(20)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
