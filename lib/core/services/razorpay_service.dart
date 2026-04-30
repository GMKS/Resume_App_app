import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/subscription_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RAZORPAY CONFIGURATION
// Replace _keyId with your actual Razorpay Key ID from:
// https://dashboard.razorpay.com/app/keys
// Use rzp_test_... for testing, rzp_live_... for production.
// ─────────────────────────────────────────────────────────────────────────────
const String _razorpayKeyId = 'rzp_test_SLWLwXG99kgVa2';

class RazorpayService {
  late Razorpay _razorpay;

  static bool get supportsNativeCheckout => !kIsWeb;

  static bool get isTestMode => _razorpayKeyId.startsWith('rzp_test_');

  // Callbacks set by the screen
  void Function(PaymentSuccessResponse)? onSuccess;
  void Function(PaymentFailureResponse)? onFailure;
  void Function(ExternalWalletResponse)? onExternalWallet;

  // Plan details: amount in paise (INR × 100), display price, description
  static const Map<SubscriptionPlan, Map<String, dynamic>> planDetails = {
    SubscriptionPlan.weekly: {
      'displayName': 'Weekly Pro',
      'displayPrice': '₹499/week',
      'amount': 49900, // ₹499 in paise
      'description': '7 days of full premium access',
    },
    SubscriptionPlan.monthly: {
      'displayName': 'Monthly Pro',
      'displayPrice': '₹849/month',
      'amount': 84900, // ₹849 in paise
      'description': '30 days of full premium access',
    },
    SubscriptionPlan.quarterly: {
      'displayName': 'Quarterly Pro',
      'displayPrice': '₹2,099/3 months',
      'amount': 209900, // ₹2,099 in paise
      'description': '90 days of full premium access',
    },
    SubscriptionPlan.yearly: {
      'displayName': 'Yearly Pro',
      'displayPrice': '₹6,699/year',
      'amount': 669900, // ₹6,699 in paise
      'description': '365 days of full premium access',
    },
  };

  void initialize() {
    if (!supportsNativeCheckout) {
      return;
    }
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  void dispose() {
    if (!supportsNativeCheckout) {
      return;
    }
    _razorpay.clear();
  }

  /// Opens Razorpay checkout for the given plan.
  /// [userPhone] should be E.164 format e.g. "+919916750642"
  void openCheckout({
    required SubscriptionPlan plan,
    String? userPhone,
    String? userEmail,
    String? userName,
  }) {
    if (!supportsNativeCheckout) {
      return;
    }

    final details = planDetails[plan];
    if (details == null) {
      return;
    }

    final options = {
      'key': _razorpayKeyId,
      'amount': details['amount'], // Amount in paise
      'currency': 'INR',
      'name': 'Resume Builder',
      'description': details['description'],
      'timeout': 300, // 5 minutes
      'prefill': {
        'contact': userPhone ?? '',
        'email': userEmail ?? '',
        'name': userName ?? '',
      },
      'notes': {
        'plan': plan.name,
        'app': 'resume_builder',
      },
      'theme': {
        'color': '#1565C0',
      },
      // Retry configuration
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
    };

    try {
      _razorpay.open(options);
    } catch (_) {
      return;
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    onSuccess?.call(response);
  }

  void _onPaymentFailure(PaymentFailureResponse response) {
    onFailure?.call(response);
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    onExternalWallet?.call(response);
  }

  /// Returns human-readable error message from Razorpay error code
  static String getErrorMessage(int? code) {
    switch (code) {
      case Razorpay.PAYMENT_CANCELLED:
        return 'Payment cancelled.';
      case Razorpay.NETWORK_ERROR:
        return 'Network error. Please check your connection.';
      case Razorpay.INVALID_OPTIONS:
        return 'Invalid payment options. Please contact support.';
      case Razorpay.TLS_ERROR:
        return 'Security error. Please update your device.';
      case Razorpay.INCOMPATIBLE_PLUGIN:
        return 'App update required for payments.';
      default:
        return 'Payment failed. Please try again.';
    }
  }
}
