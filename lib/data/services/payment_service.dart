import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';

class PaymentService {
  late Razorpay _razorpay;
  // Placeholder key. User must replace this with their actual Key ID from Razorpay Dashboard.
  static const String _kRazorpayKey = 'rzp_test_SDYlrlqdT29Zl6';

  final Function(PaymentSuccessResponse) onSuccess;
  final Function(PaymentFailureResponse) onFailure;
  final Function(ExternalWalletResponse) onExternalWallet;

  PaymentService({
    required this.onSuccess,
    required this.onFailure,
    required this.onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  void openCheckout({
    required double amount,
    required String orderId,
    String? description,
    String? email,
    String? contact,
  }) {
    // Use a dummy number to skip the phone prompt if user doesn't have one
    // Razorpay requires a contact number, so we provide one to suppress the UI input
    final validContact =
        (contact != null && contact.isNotEmpty) ? contact : '9876543210';

    var options = {
      'key': _kRazorpayKey,
      'amount': (amount * 100).toInt(), // Razorpay takes amount in paise
      'name': 'Krushi kalp',
      'description': description ?? 'Test Purchase',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': validContact,
        'email': email ?? 'user@krushikalp.com',
      },
      'readonly': {
        'email': true,
        'contact': true,
      },
      // RESTRICT TO UPI ONLY
      // ALLOW UPI (Intent & Collect)
      // We disable other methods to prioritize UPI as requested,
      // but keep the standard UI standard to ensure GPay/PhonePe intent apps are detected.
      'method': {
        'netbanking': false,
        'card': false,
        'wallet': false,
        'upi': true,
      },
      'external': {
        'wallets': ['google_pay', 'phonepe']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
