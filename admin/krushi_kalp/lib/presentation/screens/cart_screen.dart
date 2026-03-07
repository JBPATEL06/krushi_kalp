import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/cart_service.dart';
import '../../data/services/test_service.dart';
import '../../data/services/offer_service.dart';
import '../../domain/models/offer.dart';
import '../../domain/models/order_item.dart';
import '../../utils/price_calculator.dart';
import '../widgets/common/network_error_state.dart';
import 'cart/widgets/cart_item_widget.dart';
import 'cart/widgets/cart_order_summary.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/cart_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<Map<String, dynamic>>> _cartFuture;
  late PaymentService _paymentService;
  List<Map<String, dynamic>> _currentCartItems = [];

  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;
  String? _couponError;
  Offer? _appliedGlobalOffer;

  @override
  void initState() {
    super.initState();
    _loadCart();
    _paymentService = PaymentService(
      onSuccess: _handlePaymentSuccess,
      onFailure: (response) {
        if (mounted) {
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Payment Failed: ${response.code} - ${response.message}"),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      onExternalWallet: (response) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text("External Wallet Selected: ${response.walletName}")),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _loadCart() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _cartFuture = Future.wait([
          CartService.fetchCartItems(user.id),
          OfferService.fetchActiveSaleOffers(),
        ]).then((results) async {
          final items = results[0] as List<OrderItem>;
          final saleOffers = results[1] as List<Offer>;
          final colorScheme = Theme.of(context).colorScheme;

          final cartItems = await Future.wait(items.map((item) async {
            String? imageUrl;
            String? path;
            String title = 'Unavailable Item';
            String subtitle = 'General';
            double originalPrice = item.priceAtPurchase;

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
              if (mockTest != null) {
                path = path.replaceAll('mock_test/', '');
                try {
                  imageUrl = await Supabase.instance.client.storage
                      .from('mock_test')
                      .createSignedUrl(path, 60 * 60);
                } catch (e) {}
              } else {
                imageUrl = path;
              }
            } else {
              imageUrl = path;
            }

            final priceData = PriceCalculator.calculateDisplayPrice(
              basePrice: originalPrice,
              activeOffers: saleOffers,
              testId: item.testId,
              resourceId: item.resourceId,
              userId: user.id,
            );

            return {
              'item_id': item.itemId,
              'test_id': item.testId,
              'resource_id': item.resourceId,
              'order_id': item.orderId,
              'title': title,
              'subtitle': subtitle,
              'price': priceData['finalPrice'],
              'mrp': priceData['mrp'],
              'original_price': originalPrice,
              'image_url': imageUrl,
              'color': colorScheme.primaryContainer.withOpacity(0.1),
              'offers': item.offers,
            };
          }));

          _processGlobalOffer(cartItems);
          return cartItems;
        });
      });
    } else {
      _cartFuture = Future.value([]);
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

  Future<void> _refreshCart() async {
    _loadCart();
  }

  Future<void> _applyOrderCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty || _currentCartItems.isEmpty) return;

    setState(() {
      _isApplyingCoupon = true;
      _couponError = null;
    });

    try {
      final offer = await OfferService.verifyCoupon(code);
      if (offer != null) {
        final total = _calculateSubtotal(_currentCartItems);
        final testIds =
            _currentCartItems.map((e) => e['test_id'] as int).toList();

        if (offer.isValid(
            userId: Supabase.instance.client.auth.currentUser!.id,
            cartTotal: total,
            cartTestIds: testIds)) {
          final orderId = _currentCartItems.first['order_id'] as String;
          await TestService.applyCouponToOrder(orderId, offer.id);
          await _refreshCart();
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
      await TestService.removeCouponFromOrder(orderId);
      _couponController.clear();
      await _refreshCart();
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isApplyingCoupon = false);
    }
  }

  Future<void> _deleteItem(int itemId) async {
    try {
      await context.read<CartProvider>().removeFromCart(itemId: itemId);
      await _refreshCart();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Item removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId;
    if (paymentId == null) return;
    if (_currentCartItems.isEmpty) return;

    final orderId = _currentCartItems.first['order_id'] as String;
    final total = _calculateTotal(_currentCartItems);
    final discount = _calculateTotalDiscount(_currentCartItems);
    final user = Supabase.instance.client.auth.currentUser;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment Successful! Processing...")));
      }

      await TestService.checkout(
        orderId: orderId,
        paymentId: paymentId,
        amount: total,
        offerId: null,
        discountAmount: discount,
        userId: user!.id,
      );

      await _refreshCart();
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Purchase Complete!"),
            backgroundColor: colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  double _calculateSubtotal(List<Map<String, dynamic>> items) =>
      items.fold(0, (sum, item) => sum + (item['price'] as num).toDouble());

  double _calculateTotalDiscount(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 0.0;
    final offersData = items.first['offers'];
    if (offersData != null && offersData is Map && offersData.isNotEmpty) {
      try {
        final offer = Offer.fromJson(Map<String, dynamic>.from(offersData));
        return offer.calculateDiscountAmount(
            totalAmount: _calculateSubtotal(items), cartItems: items);
      } catch (_) {}
    }
    return 0.0;
  }

  double _calculateTotal(List<Map<String, dynamic>> items) =>
      _calculateSubtotal(items) - _calculateTotalDiscount(items);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
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
                  : 'Error: ${snapshot.error}',
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
                  color: colorScheme.primary,
                  onRefresh: _refreshCart,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ITEMS (${cartItems.length})',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...cartItems.map((item) => CartItemWidget(
                              item: item,
                              onRemove: () =>
                                  _deleteItem(item['item_id'] as int),
                            )),
                        const SizedBox(height: AppSpacing.xl),

                        // Coupon Section
                        Container(
                          decoration: BoxDecoration(
                            color: _appliedGlobalOffer != null
                                ? colorScheme.tertiary.withOpacity(0.05)
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: _appliedGlobalOffer != null
                                  ? colorScheme.tertiary.withOpacity(0.5)
                                  : colorScheme.outline.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 2),
                          child: TextField(
                            controller: _couponController,
                            enabled: !_isApplyingCoupon,
                            readOnly: _appliedGlobalOffer != null,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _appliedGlobalOffer != null
                                  ? colorScheme.tertiary
                                  : colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Have a coupon code?',
                              hintStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.5)),
                              prefixIcon: Icon(
                                Icons.local_offer_rounded,
                                color: _appliedGlobalOffer != null
                                    ? colorScheme.tertiary
                                    : colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                                size: 22,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              suffixIcon: _isApplyingCoupon
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: colorScheme.primary),
                                      ),
                                    )
                                  : _appliedGlobalOffer == null
                                      ? TextButton(
                                          onPressed: _applyOrderCoupon,
                                          child: Text(
                                            "APPLY",
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        )
                                      : IconButton(
                                          onPressed: _removeOrderCoupon,
                                          icon: Icon(Icons.close_rounded,
                                              color: colorScheme.error),
                                        ),
                            ),
                          ),
                        ),
                        if (_couponError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 16),
                            child: Text(
                              _couponError!,
                              style: TextStyle(
                                  color: colorScheme.error, fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: AppSpacing.xxl),
                        CartOrderSummary(
                          subtotal: _calculateSubtotal(cartItems),
                          discountAmount: _calculateTotalDiscount(cartItems),
                          couponCode: null,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomCheckoutBar(context, cartItems),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                Icon(Icons.shopping_cart_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your cart is empty',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Provider.of<NavigationProvider>(context, listen: false)
                        .setIndex(2); // Store
                  },
                  child: const Text('Go Browse Store'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCheckoutBar(
      BuildContext context, List<Map<String, dynamic>> items) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = _calculateTotal(items);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final user = Supabase.instance.client.auth.currentUser;
                  String? userPhone = user?.phone;
                  if (user != null &&
                      (userPhone == null || userPhone.isEmpty)) {
                    try {
                      final profile = await Supabase.instance.client
                          .from('users')
                          .select('phonenumber')
                          .eq('id', user.id)
                          .maybeSingle();
                      userPhone = profile?['phonenumber'];
                    } catch (_) {}
                  }

                  _paymentService.openCheckout(
                    amount: total,
                    orderId:
                        'cart_checkout_${DateTime.now().millisecondsSinceEpoch}',
                    email: user?.email,
                    contact: userPhone,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Proceed to Payment',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: AppSpacing.sm),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
