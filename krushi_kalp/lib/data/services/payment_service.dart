import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/env/env.dart';
import '../../utils/crashlytics_service.dart';

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
  static String get _razorpayKey => Env.razorpayKeyId;

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
      'name': 'Krushi Kalp',
      'description': description ?? 'Order Payment',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': contact ?? '',
        'email': email ?? '',
      },
      'notes': {
        'supabase_order_id': orderId, // Strictly adhere to notes-based referencing
      },
      'external': {
        'wallets': ['paytm']
      },
      // Explicitly configure UPI ID (VPA) to be prominent for users without local apps
      'config': {
        'display': {
          'blocks': {
            'upi': {
              'name': 'Pay via UPI ID',
              'instruments': [
                {
                  'method': 'upi',
                  'vpa': true, // Enables Enter UPI ID field
                },
              ],
            },
          },
          'sequence': ['block.upi', 'block.other'],
          'preferences': {
            'show_default_blocks': true,
          },
        },
      },
    };

    try {
      _razorpay.open(options);
    } catch (e, stack) {
      debugPrint('Razorpay Open Error: $e');
      CrashlyticsService.instance.recordError(e, stack, reason: 'razorpay_open_failed');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
