import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/offer.dart';
import '../../utils/price_calculator.dart';
import '../../data/services/offer_service.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/test_service.dart';
import '../../domain/models/resource.dart';
import '../../data/services/resource_service.dart';
import '../providers/navigation_provider.dart';
import '../widgets/common/app_button.dart';
import '../providers/test_provider.dart';
import '../providers/resource_provider.dart';

class DirectCheckoutSheet extends StatefulWidget {
  final MockTest? test; // Make nullable
  final Resource? resource; // Add Resource
  final Offer? initialOffer;

  const DirectCheckoutSheet(
      {super.key, this.test, this.resource, this.initialOffer})
      : assert(test != null || resource != null,
            'Either test or resource must be provided');

  @override
  State<DirectCheckoutSheet> createState() => _DirectCheckoutSheetState();
}

class _DirectCheckoutSheetState extends State<DirectCheckoutSheet> {
  final TextEditingController _couponController = TextEditingController();

  Offer? _appliedOffer;
  double _finalPrice = 0.0;
  bool _isApplyingCoupon = false;
  bool _isProcessing = false;
  String? _couponError;
  bool _hasAutoSale = false; // NEW FLAG

  // Helpers
  double get _basePrice => widget.test?.price ?? widget.resource?.price ?? 0.0;
  String get _title => widget.test?.title ?? widget.resource?.title ?? 'Item';
  String get _category =>
      widget.test?.category ?? widget.resource?.category ?? 'General';
  String? get _imageUrl =>
      widget.test?.signedUrl ?? widget.resource?.thumbnailUrl;
  int? get _testId => widget.test?.id;
  int? get _resourceId => widget.resource?.id;

  @override
  void initState() {
    super.initState();
    PaymentService.init(
      onSuccess: _onPaymentSuccessActual,
      onFailure: (response) {
        if (mounted) {
          setState(() => _isProcessing = false);
          Navigator.pop(context); // Close sheet on failure/cancel
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Payment Failed: ${response.message}")),
          );
        }
      },
      onExternalWallet: (response) {},
    );

    // Initialize with passed offer if any
    _applyInitialOffer();
  }

  void _applyInitialOffer() {
    final user = AuthService.instance.currentUser;
    
    final priceData = PriceCalculator.calculateDisplayPrice(
      basePrice: _basePrice,
      baseMrp: (widget.resource?.mrp ?? widget.test?.mrp)?.toDouble(),
      activeOffers: widget.initialOffer != null ? [widget.initialOffer!] : [],
      testId: _testId,
      resourceId: _resourceId,
      userId: user?.id,
    );
    _appliedOffer = priceData['offer'];
    _finalPrice = priceData['finalPrice'];

    // Check if the Sale actually applied successfully
    _hasAutoSale = _appliedOffer != null && _appliedOffer!.isSale;

    
  }

  @override
  void dispose() {
    _couponController.dispose();
    PaymentService.instance.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isApplyingCoupon = true;
      _couponError = null;
    });

    try {
      final user = AuthService.instance.currentUser;
      final offer = await OfferService.instance.verifyCoupon(code);

      if (offer != null) {
        // Validate specific constraints
        if (user != null &&
            offer.isValid(
                userId: user.id,
                cartTotal: _basePrice,
                cartTestIds: _testId != null ? [_testId!] : [])) {
          setState(() {
            final priceData = PriceCalculator.calculateDisplayPrice(
              basePrice: _basePrice,
              activeOffers: [offer],
              testId: _testId,
              userId: user.id,
            );
            _appliedOffer = offer;
            _finalPrice = priceData['finalPrice'];
            
          });
        } else {
          setState(() => _couponError = "Coupon not valid for this item/order");
        }
      } else {
        setState(() => _couponError = "Invalid Coupon Code");
      }
    } catch (e) {
      setState(() => _couponError = "Error applying coupon");
    } finally {
      setState(() => _isApplyingCoupon = false);
    }
  }

  void _removeCoupon() {
    setState(() {
      _couponController.clear();
      _couponError = null;
      _appliedOffer = null; // Clear offer to allow new entry
      _finalPrice = _basePrice; // Reset to base price
      // Re-apply any initial sale if present
      if (widget.initialOffer != null) {
        _applyInitialOffer();
      }
    });
  }

  Future<void> _initiatePurchase() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Please login first")));
      }
      return;
    }

    if (_isProcessing) return; // PRO FIX: Synchronization Gate
    setState(() => _isProcessing = true);

    try {
      

      // Fire off profile fetch in parallel to hide network latency
      Future<Map<String, dynamic>?> profileFuture = Future.value(null);
      if (user.phone == null || user.phone!.isEmpty) {
        profileFuture = AuthService.instance.getUserProfile(user.id);
      }

      String orderId;
      if (widget.resource != null) {
        // Resource Order
        orderId = await ResourceService.instance.createDirectOrder(
          resourceId: _resourceId!,
          price: _basePrice,
          userId: user.id,
        );
      } else {
        // Test Order
        orderId = await TestService.instance.createDirectOrder(
          testId: _testId!,
          price: _basePrice, // Store Base Price
          authUserId: user.id,
        );
      }

      

      if (!mounted) return; // PRO FIX: Check mounted after async DB call

      if (_finalPrice <= 0) {
        
        _pendingOrderId = orderId;
        await _completeCheckout(
            "FREE_CLAIM_${DateTime.now().millisecondsSinceEpoch}");
        return;
      }

      // Resolve the parallel profile fetch
      String? userPhone = user.phone;
      if (userPhone == null || userPhone.isEmpty) {
        try {
          final profile = await profileFuture;
          if (profile != null && profile['phone'] != null) {
            userPhone = profile['phone'];
          }
        } catch (_) {}
      }

      if (!mounted)
        return; // PRO FIX: Avoid using context/opening Razorpay if disposed

      // 2. Open Razorpay
      PaymentService.instance.openCheckout(
        amount: _finalPrice,
        orderId: orderId,
        email: user.email,
        contact: userPhone, // Prefill if available
      );

      _pendingOrderId = orderId;
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  String? _pendingOrderId; // To track the order being paid for

  Future<void> _completeCheckout(String paymentId) async {
    final user = AuthService.instance.currentUser;
    if (user == null || _pendingOrderId == null) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    try {
      
      await TestService.instance.checkout(
        orderId: _pendingOrderId!,
        paymentId: paymentId,
        amount: _finalPrice,
        offerId: _appliedOffer?.id,
        discountAmount: (_basePrice - _finalPrice),
        userId: user.id,
      );
      

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Purchase Successful! 🎉",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer)),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer));
        // Navigate to Home tab
        Provider.of<NavigationProvider>(context, listen: false).setIndex(0);

        // SYNC FIX: Auto-refresh data in background
        if (widget.test != null) {
          context.read<TestProvider>().fetchUserTests(user.id);
        } else if (widget.resource != null) {
          context.read<ResourceProvider>().fetchPurchasedResources(user.id);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Checkout Error: $e")));
      }
    }
  }

  Future<void> _onPaymentSuccessActual(PaymentSuccessResponse response) async {
    await _completeCheckout(response.paymentId!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          bottom: true,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _imageUrl != null
                          ? Image.network(_imageUrl!,
                              width: 60, height: 60, fit: BoxFit.cover)
                          : Container(
                              width: 60,
                              height: 60,
                              color: theme.colorScheme.surfaceVariant,
                              child: Icon(Icons.book,
                                  color: theme.colorScheme.outline)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(_category,
                              style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 24),

                // Coupon Input
                const Text("Coupon Code",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        enabled: _appliedOffer == null &&
                            !_isProcessing &&
                            !_hasAutoSale,
                        decoration: InputDecoration(
                            hintText: _hasAutoSale
                                ? "Disabled during Store Sale"
                                : "Enter Code",
                            errorText: _hasAutoSale ? null : _couponError,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.outlineVariant
                                        .withOpacity(0.5)))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _appliedOffer == null || _hasAutoSale
                        ? AppButton(
                            text: "Apply",
                            onPressed: _isApplyingCoupon ||
                                    _isProcessing ||
                                    _hasAutoSale
                                ? null
                                : _applyCoupon,
                            isLoading: _isApplyingCoupon,
                            width: 80,
                            height: 48,
                            type: AppButtonType.secondary,
                          )
                        : IconButton(
                            onPressed: _isProcessing ? null : _removeCoupon,
                            icon: Icon(Icons.highlight_remove,
                                color: theme.colorScheme.error)),
                  ],
                ),
                if (_hasAutoSale)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "✨ Store sale discounts are already active.",
                      style: TextStyle(
                        color: const Color(0xFF10B981), // Success Emerald
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (_appliedOffer != null && !_hasAutoSale)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                        _appliedOffer!.code != null
                            ? "Code Applied: ${_appliedOffer!.code}"
                            : "Offer Applied: ${_appliedOffer!.title}",
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                  ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal"),
                    Text("₹${_basePrice.toStringAsFixed(2)}"),
                  ],
                ),
                if (_appliedOffer != null && (_basePrice - _finalPrice) > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Discount",
                          style: TextStyle(color: theme.colorScheme.primary)),
                      Text("-₹${(_basePrice - _finalPrice).toStringAsFixed(2)}",
                          style: TextStyle(color: theme.colorScheme.primary)),
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total To Pay",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("₹${_finalPrice.toStringAsFixed(2)}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: theme.colorScheme.primary)),
                  ],
                ),

                const SizedBox(height: 24),

                // ACTION BUTTON
                AppButton(
                  text: _finalPrice <= 0 ? "Claim Now" : "Pay Now",
                  onPressed: _initiatePurchase,
                  isLoading: _isProcessing,
                  width: double.infinity,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ));
  }
}
