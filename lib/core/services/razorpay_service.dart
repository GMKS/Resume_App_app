import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../constants/app_info.dart';
import '../models/subscription_pricing.dart';
import '../models/subscription_model.dart';
import 'app_config_service.dart';

String _readPaymentConfig(String key) {
  return AppConfigService.read(key);
}

String get _razorpayKeyId => _readPaymentConfig('RAZORPAY_KEY_ID');

class RazorpayService {
  Razorpay? _razorpay;

  static bool get supportsNativeCheckout => !kIsWeb;
  static bool get isConfigured => _razorpayKeyId.isNotEmpty;

  // Callbacks set by the screen
  void Function(PaymentSuccessResponse)? onSuccess;
  void Function(PaymentFailureResponse)? onFailure;
  void Function(ExternalWalletResponse)? onExternalWallet;

  void initialize() {
    final razorpayKey = _razorpayKeyId;
    if (razorpayKey.isEmpty) {
      throw Exception('Razorpay Key ID is not configured.');
    }

    final razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _razorpay = razorpay;
  }

  void dispose() {
    if (!supportsNativeCheckout) {
      return;
    }
    _razorpay?.clear();
  }

  /// Opens Razorpay checkout for the given plan.
  /// [userPhone] should be E.164 format e.g. "+919916750642"
  bool openCheckout({
    required SubscriptionPlan plan,
    required SubscriptionPricingOption pricing,
    String? userPhone,
    String? userEmail,
    String? userName,
  }) {
    if (!supportsNativeCheckout) {
      return false;
    }

    if (!RazorpayService.isConfigured) {
      return false;
    }

    final options = {
      'key': _razorpayKeyId,
      'amount': pricing.price.amountInMinorUnits,
      'currency': pricing.price.currencyCode,
      'name': AppInfo.appName,
      'description': pricing.checkoutDescription,
      'timeout': 300, // 5 minutes
      'prefill': {
        'contact': userPhone ?? '',
        'email': userEmail ?? '',
        'name': userName ?? '',
      },
      'notes': {
        'plan': plan.name,
        'app': AppInfo.playStorePackageId,
        'display_price': pricing.price.formatCurrent(),
        'currency_code': pricing.price.currencyCode,
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
      _razorpay?.open(options);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
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
