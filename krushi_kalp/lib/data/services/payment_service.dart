import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  // --- SINGLETON ---
  static PaymentService? _instance;
  static PaymentService get instance {
    if (_instance == null) {
      throw Exception(
          'PaymentService must be initialized with callbacks first.');
    }
    return _instance!;
  }

  static void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _instance = PaymentService._internal(
      onSuccess: onSuccess,
      onFailure: onFailure,
      onExternalWallet: onExternalWallet,
    );
  }

  late Razorpay _razorpay;

  // Key read from .env — never hardcoded in source code
  static String get _razorpayKey => dotenv.env['RAZORPAY_KEY_ID'] ?? '';

  final Function(PaymentSuccessResponse) onSuccess;
  final Function(PaymentFailureResponse) onFailure;
  final Function(ExternalWalletResponse) onExternalWallet;

  PaymentService._internal({
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
    var options = {
      'key': _razorpayKey,
      'amount': (amount * 100).toInt(),
      'name': 'Krushi kalp',
      'description': description ?? 'Purchase',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        if (contact != null && contact.isNotEmpty) 'contact': contact,
        'email': email ?? '',
      },
      'readonly': {
        'email': true,
      },
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
      
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
