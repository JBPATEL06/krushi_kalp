import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/cart_service.dart';
import '../../data/services/test_service.dart';
import '../../data/services/offer_service.dart';
import '../../domain/models/offer.dart';
import '../../domain/models/order_item.dart'; // Added
import '../../utils/price_calculator.dart';
import '../widgets/common/network_error_state.dart';
import 'cart/widgets/cart_item_widget.dart';
import 'cart/widgets/cart_order_summary.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/cart_provider.dart'; // Fixed import
// ... (imports remain)

// ... (imports remain)

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<Map<String, dynamic>>> _cartFuture;
  late PaymentService _paymentService;
  List<Map<String, dynamic>> _currentCartItems = [];

  // --- Coupon Logic ---
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
    _paymentService.dispose();
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

          // Map to UI model and Sign URLs
          final cartItems = await Future.wait(items.map((item) async {
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
              // Only sign if we know it's a mock test storage path for now
              if (mockTest != null) {
                path = path.replaceAll('mock_test/', '');
                try {
                  imageUrl = await Supabase.instance.client.storage
                      .from('mock_test')
                      .createSignedUrl(path, 60 * 60);
                } catch (e) {
                  // ignore error
                }
              } else {
                imageUrl = path;
              }
            } else {
              imageUrl = path;
            }

            // --- Calculate Automatic Sale Price ---
            final priceData = PriceCalculator.calculateDisplayPrice(
              basePrice: originalPrice,
              activeOffers: saleOffers,
              testId: item.testId,
              resourceId: item.resourceId,
              userId: user.id,
            );

            final double finalPrice = priceData['finalPrice'];
            final double mrp = priceData['mrp'];
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
            };
          }));

          _processGlobalOffer(cartItems);
          // _processMrpDisplay(cartItems); // REMOVED: Handled inline

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
      await TestService.removeCouponFromOrder(orderId);
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

    // Assume all items belong to same order
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
        offerId: null, // Per-item offers handled by applied_offer_id
        discountAmount: discount,
        userId: user!.id,
      );

      await _refreshCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Purchase Complete!"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
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
            totalAmount: totalBasePrice, cartItems: items);
      } catch (_) {}
    }
    return 0.0;
  }

  double _calculateTotal(List<Map<String, dynamic>> items) {
    return _calculateSubtotal(items) - _calculateTotalDiscount(items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
                  onRefresh: _refreshCart,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Builder(builder: (context) {
                      // Trigger auto-apply check once when we have data
                      // We use a simplified check to avoid loops: e.g. check only if we haven't lately?
                      // Or just rely on the fact that if we apply, stream updates.
                      // Ideally this runs only if items changed or on init.
                      // For MVP, we let it run. But we need to use addPostFrameCallback to avoid build issues.
                      if (cartItems.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _checkAutoApply();
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ITEMS (${cartItems.length})',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...cartItems.map((item) => CartItemWidget(
                                item: item,
                                onRemove: () => _deleteItem(
                                  item['item_id'] as int,
                                ),
                              )),
                          const SizedBox(height: 24),

                          // --- COUPON INPUT SECTION ---
                          // --- COUPON INPUT SECTION ---
                          // --- COUPON INPUT SECTION ---
                          Container(
                            decoration: BoxDecoration(
                              color: _appliedGlobalOffer != null
                                  ? Colors.green.withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _appliedGlobalOffer != null
                                    ? Colors.green
                                    : Colors.grey.shade300,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: TextField(
                              controller: _couponController,
                              enabled: !_isApplyingCoupon,
                              readOnly: _appliedGlobalOffer != null,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _appliedGlobalOffer != null
                                    ? Colors.green.shade800
                                    : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Have a coupon code?',
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.normal),
                                prefixIcon: Icon(
                                  Icons.local_offer_outlined,
                                  color: _appliedGlobalOffer != null
                                      ? Colors.green
                                      : Colors.grey.shade400,
                                  size: 22,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                suffixIcon: _isApplyingCoupon
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      )
                                    : _appliedGlobalOffer == null
                                        ? TextButton(
                                            onPressed: _applyOrderCoupon,
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.blue[900],
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            child: const Text("APPLY"),
                                          )
                                        : IconButton(
                                            onPressed: _removeOrderCoupon,
                                            icon: const Icon(Icons.close,
                                                color: Colors.red),
                                            tooltip: 'Remove Coupon',
                                          ),
                              ),
                            ),
                          ),
                          if (_couponError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 16),
                              child: Text(
                                _couponError!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            ),
                          // ----------------------------

                          const SizedBox(height: 32),
                          CartOrderSummary(
                            subtotal: _calculateSubtotal(cartItems),
                            discountAmount: _calculateTotalDiscount(cartItems),
                            couponCode: null, // Logic moved global
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }),
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
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your cart is empty',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Provider.of<NavigationProvider>(context, listen: false)
                        .setIndex(2); // 2 = Store tab
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
    final total = _calculateTotal(items);

    return Container(
      padding: const EdgeInsets.only(left: 24, top: 24, right: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final user = Supabase.instance.client.auth.currentUser;

                    // Fetch phone from DB to prefill Razorpay (no blocking)
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
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Proceed to Payment',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
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
