import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  late PaymentService _paymentService;

  Offer? _appliedOffer;
  double _finalPrice = 0.0;
  bool _isApplyingCoupon = false;
  bool _isProcessing = false;
  String? _couponError;

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
    _paymentService = PaymentService(
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
    final user = Supabase.instance.client.auth.currentUser;
    debugPrint('DirectCheckout: Applying Initial Offer. User: ${user?.id}');
    final priceData = PriceCalculator.calculateDisplayPrice(
      basePrice: _basePrice,
      activeOffers: widget.initialOffer != null ? [widget.initialOffer!] : [],
      testId: _testId,
      userId: user?.id,
    );
    _appliedOffer = priceData['offer'];
    _finalPrice = priceData['finalPrice'];
    debugPrint(
        'DirectCheckout: Initial Result -> Offer: ${_appliedOffer?.title}, Price: $_finalPrice');
  }

  @override
  void dispose() {
    _couponController.dispose();
    _paymentService.dispose();
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
      final user = Supabase.instance.client.auth.currentUser;
      final offer = await OfferService.verifyCoupon(code);

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
            debugPrint(
                'DirectCheckout: Coupon Applied -> ${offer.code}, ID: ${offer.id}, New Price: $_finalPrice');
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
    });
  }

  Future<void> _initiatePurchase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      debugPrint(
          'DirectCheckout: Initiating Purchase. Item: $_title, Offer: ${_appliedOffer?.id}');

      String orderId;
      if (widget.resource != null) {
        // Resource Order
        orderId = await ResourceService().createDirectOrder(
          resourceId: _resourceId!,
          price: _basePrice,
          userId: user.id,
        );
      } else {
        // Test Order
        orderId = await TestService.createDirectOrder(
          testId: _testId!,
          price: _basePrice, // Store Base Price
          authUserId: user.id,
        );
      }

      debugPrint('DirectCheckout: Order Created: $orderId');

      if (!mounted) return; // Check if widget is still active

      if (_finalPrice <= 0) {
        debugPrint('DirectCheckout: Zero Price detected. Skipping Razorpay.');
        _pendingOrderId = orderId;
        await _completeCheckout(
            "FREE_CLAIM_${DateTime.now().millisecondsSinceEpoch}");
        return;
      }

      // Fetch phone from DB to prefill Razorpay (no blocking — Razorpay handles it)
      String? userPhone = user.phone;
      if (userPhone == null || userPhone.isEmpty) {
        try {
          final profile = await Supabase.instance.client
              .from('users')
              .select('phonenumber')
              .eq('id', user.id)
              .maybeSingle();
          userPhone = profile?['phonenumber'];
        } catch (_) {}
      }

      if (!mounted) return;

      // 2. Open Razorpay
      _paymentService.openCheckout(
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _pendingOrderId == null) return;

    try {
      debugPrint(
          'DirectCheckout: Completing Checkout. Order: $_pendingOrderId, Payment: $paymentId');
      await TestService.checkout(
        orderId: _pendingOrderId!,
        paymentId: paymentId,
        amount: _finalPrice,
        offerId: _appliedOffer?.id,
        discountAmount: (_basePrice - _finalPrice),
        userId: user.id,
      );
      debugPrint('DirectCheckout: Checkout Service Completed Successfully');

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
                        enabled: _appliedOffer == null && !_isProcessing,
                        decoration: InputDecoration(
                          hintText: "Enter Code",
                          errorText: _couponError,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _appliedOffer == null
                        ? AppButton(
                            text: "Apply",
                            onPressed: _isApplyingCoupon || _isProcessing
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
                if (_appliedOffer != null)
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
