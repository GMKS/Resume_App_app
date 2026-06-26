import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/subscription_model.dart';
import '../models/subscription_pricing.dart';
import 'app_config_service.dart';

class RazorpayOrderCreationResult {
  const RazorpayOrderCreationResult({
    required this.success,
    required this.message,
    this.orderId,
    this.amount,
    this.currency,
    this.receipt,
  });

  final bool success;
  final String message;
  final String? orderId;
  final int? amount;
  final String? currency;
  final String? receipt;
}

class RazorpayPaymentVerificationResult {
  const RazorpayPaymentVerificationResult({
    required this.verified,
    required this.message,
    this.paymentId,
    this.orderId,
    this.paymentStatus,
    this.signatureVerified = false,
  });

  final bool verified;
  final String message;
  final String? paymentId;
  final String? orderId;
  final String? paymentStatus;
  final bool signatureVerified;
}

class RazorpayOrderStatusResult {
  const RazorpayOrderStatusResult({
    required this.verified,
    required this.pending,
    required this.cancelled,
    required this.message,
    this.paymentId,
    this.orderId,
    this.orderStatus,
    this.paymentStatus,
  });

  final bool verified;
  final bool pending;
  final bool cancelled;
  final String message;
  final String? paymentId;
  final String? orderId;
  final String? orderStatus;
  final String? paymentStatus;
}

class PaymentVerificationService {
  static Uri? get _createOrderUri => _buildFunctionUri('create-razorpay-order');
  static Uri? get _orderStatusUri =>
      _buildFunctionUri('check-razorpay-order-status');
  static Uri? get _verifyPaymentUri =>
      _buildFunctionUri('verify-razorpay-payment');

  static bool get isRazorpayBackendConfigured =>
      _createOrderUri != null &&
      _orderStatusUri != null &&
      _verifyPaymentUri != null;

  static String get diagnosticsSummary =>
      'backendConfigured=$isRazorpayBackendConfigured '
      'createOrderUrl=${_createOrderUri?.toString() ?? 'missing'} '
      'orderStatusUrl=${_orderStatusUri?.toString() ?? 'missing'} '
      'verifyPaymentUrl=${_verifyPaymentUri?.toString() ?? 'missing'}';

  Future<RazorpayOrderCreationResult> createRazorpayOrder({
    required SubscriptionPlan plan,
    required SubscriptionPricingOption pricing,
  }) async {
    final uri = _createOrderUri;
    if (uri == null) {
      return const RazorpayOrderCreationResult(
        success: false,
        message: 'Secure Razorpay order creation is not configured.',
      );
    }

    final receipt =
        'resume_${plan.name}_${DateTime.now().millisecondsSinceEpoch}';
    final payload = <String, dynamic>{
      'plan': plan.name,
      'amount': pricing.price.amountInMinorUnits,
      'currency': pricing.price.currencyCode,
      'receipt': receipt,
      'displayPrice': pricing.price.formatCurrent(),
      'periodLabel': pricing.periodLabel,
    };

    debugPrint(
      'PaymentVerificationService.createRazorpayOrder: uri=$uri '
      'plan=${plan.name} amount=${pricing.price.amountInMinorUnits} '
      'currency=${pricing.price.currencyCode}',
    );

    try {
      final response = await http
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
      final body = _decodeJson(response.body);
      final success = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['success'] == true;
      final orderId = _readString(body, 'orderId');

      return RazorpayOrderCreationResult(
        success: success && orderId != null && orderId.isNotEmpty,
        message: _readString(body, 'message') ??
            (success
                ? 'Order created successfully.'
                : 'Could not create Razorpay order.'),
        orderId: orderId,
        amount: _readInt(body, 'amount'),
        currency: _readString(body, 'currency'),
        receipt: _readString(body, 'receipt'),
      );
    } catch (error) {
      debugPrint(
        'PaymentVerificationService.createRazorpayOrder: failed with $error',
      );
      return RazorpayOrderCreationResult(
        success: false,
        message: 'Could not create a secure payment order. $error',
      );
    }
  }

  Future<RazorpayPaymentVerificationResult> verifyRazorpayPayment({
    required SubscriptionPlan plan,
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    final uri = _verifyPaymentUri;
    if (uri == null) {
      return const RazorpayPaymentVerificationResult(
        verified: false,
        message: 'Secure Razorpay payment verification is not configured.',
      );
    }

    final payload = <String, dynamic>{
      'plan': plan.name,
      'paymentId': paymentId,
      'orderId': orderId,
      'signature': signature,
    };

    debugPrint(
      'PaymentVerificationService.verifyRazorpayPayment: uri=$uri '
      'plan=${plan.name} orderId=$orderId paymentId=$paymentId',
    );

    try {
      final response = await http
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
      final body = _decodeJson(response.body);
      final verified = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['success'] == true &&
          body['verified'] == true;

      return RazorpayPaymentVerificationResult(
        verified: verified,
        message: _readString(body, 'message') ??
            (verified
                ? 'Payment verified successfully.'
                : 'Payment verification failed.'),
        paymentId: _readString(body, 'paymentId') ?? paymentId,
        orderId: _readString(body, 'orderId') ?? orderId,
        paymentStatus: _readString(body, 'paymentStatus'),
        signatureVerified: body['signatureVerified'] == true,
      );
    } catch (error) {
      debugPrint(
        'PaymentVerificationService.verifyRazorpayPayment: failed with $error',
      );
      return RazorpayPaymentVerificationResult(
        verified: false,
        message: 'Could not verify the payment with the backend. $error',
        paymentId: paymentId,
        orderId: orderId,
      );
    }
  }

  Future<RazorpayOrderStatusResult> checkRazorpayOrderStatus({
    required SubscriptionPlan plan,
    required String orderId,
  }) async {
    final uri = _orderStatusUri;
    if (uri == null) {
      return const RazorpayOrderStatusResult(
        verified: false,
        pending: false,
        cancelled: false,
        message: 'Secure Razorpay order status checks are not configured.',
      );
    }

    final payload = <String, dynamic>{
      'plan': plan.name,
      'orderId': orderId,
    };

    debugPrint(
      'PaymentVerificationService.checkRazorpayOrderStatus: '
      'uri=$uri plan=${plan.name} orderId=$orderId',
    );

    try {
      final response = await http
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));
      final body = _decodeJson(response.body);

      return RazorpayOrderStatusResult(
        verified: body['verified'] == true,
        pending: body['pending'] == true,
        cancelled: body['cancelled'] == true,
        message: _readString(body, 'message') ??
            'Payment could not be completed. Please try again.',
        paymentId: _readString(body, 'paymentId'),
        orderId: _readString(body, 'orderId') ?? orderId,
        orderStatus: _readString(body, 'orderStatus'),
        paymentStatus: _readString(body, 'paymentStatus'),
      );
    } catch (error) {
      debugPrint(
        'PaymentVerificationService.checkRazorpayOrderStatus: failed with $error',
      );
      return const RazorpayOrderStatusResult(
        verified: false,
        pending: false,
        cancelled: false,
        message: 'Could not confirm the payment status. Please try again.',
      );
    }
  }

  static Uri? _buildFunctionUri(String functionName) {
    final baseUrl = _functionBaseUrl();
    if (baseUrl.isEmpty) {
      return null;
    }
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.tryParse('$normalizedBase/$functionName');
  }

  static String _functionBaseUrl() {
    final otpBaseUrl = AppConfigService.read('OTP_BASE_URL');
    if (otpBaseUrl.isNotEmpty) {
      return otpBaseUrl;
    }

    for (final url in <String>[
      AppConfigService.read('OTP_SEND_URL'),
      AppConfigService.read('OTP_VERIFY_URL'),
    ]) {
      if (url.isEmpty) {
        continue;
      }
      final lastSlash = url.lastIndexOf('/');
      if (lastSlash > 0) {
        return url.substring(0, lastSlash);
      }
    }

    return '';
  }

  static Map<String, dynamic> _decodeJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (_) {
      return const <String, dynamic>{};
    }
    return const <String, dynamic>{};
  }

  static String? _readString(Map<String, dynamic> body, String key) {
    final value = body[key];
    if (value == null) {
      return null;
    }
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? null : stringValue;
  }

  static int? _readInt(Map<String, dynamic> body, String key) {
    final value = body[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
