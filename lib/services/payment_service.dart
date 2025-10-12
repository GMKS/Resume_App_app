import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class PaymentService {
  static const String _baseUrl = AppConfig.apiBaseUrl;

  // Get user's subscription status
  static Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/subscription/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to get subscription status');
      }
    } catch (error) {
      print('Error getting subscription status: $error');
      rethrow;
    }
  }

  // Get subscription plans and pricing
  static Future<Map<String, dynamic>> getSubscriptionPlans({
    String currency = 'USD',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subscription/plans?currency=$currency'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to get subscription plans');
      }
    } catch (error) {
      print('Error getting subscription plans: $error');
      rethrow;
    }
  }

  // Check trial eligibility
  static Future<Map<String, dynamic>> checkTrialEligibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/subscription/trial/eligibility'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to check trial eligibility');
      }
    } catch (error) {
      print('Error checking trial eligibility: $error');
      rethrow;
    }
  }

  // Start free trial
  static Future<Map<String, dynamic>> startFreeTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/subscription/trial/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to start trial');
      }
    } catch (error) {
      print('Error starting trial: $error');
      rethrow;
    }
  }

  // Create payment intent
  static Future<Map<String, dynamic>> createPaymentIntent({
    required String planType,
    String currency = 'USD',
    String? paymentProvider,
    String? paymentMethod,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/payment/create-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'planType': planType,
          'currency': currency,
          if (paymentProvider != null) 'paymentProvider': paymentProvider,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to create payment intent');
      }
    } catch (error) {
      print('Error creating payment intent: $error');
      rethrow;
    }
  }

  // Verify payment and activate subscription
  static Future<Map<String, dynamic>> verifyPayment({
    required String paymentProvider,
    required String planType,
    required double amount,
    required String currency,
    // Stripe parameters
    String? paymentIntentId,
    // Razorpay parameters
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
    // PayPal parameters
    String? paypalOrderId,
    // Test mode
    bool testMode = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final Map<String, dynamic> body = {
        'paymentProvider': paymentProvider,
        'planType': planType,
        'amount': amount,
        'currency': currency,
      };

      // Add provider-specific parameters
      switch (paymentProvider) {
        case 'stripe':
          if (paymentIntentId != null) {
            body['paymentIntentId'] = paymentIntentId;
          }
          break;
        case 'razorpay':
          if (razorpayPaymentId != null) {
            body['razorpayPaymentId'] = razorpayPaymentId;
          }
          if (razorpayOrderId != null) {
            body['razorpayOrderId'] = razorpayOrderId;
          }
          if (razorpaySignature != null) {
            body['razorpaySignature'] = razorpaySignature;
          }
          break;
        case 'paypal':
          if (paypalOrderId != null) body['paypalOrderId'] = paypalOrderId;
          break;
        case 'test':
          body['testMode'] = testMode;
          break;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/payment/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Platform': 'Flutter',
          'X-App-Version': AppConfig.appVersion,
        },
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Payment verification failed');
      }
    } catch (error) {
      print('Error verifying payment: $error');
      rethrow;
    }
  }

  // Cancel subscription
  static Future<Map<String, dynamic>> cancelSubscription({
    String reason = 'user_request',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/subscription/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to cancel subscription');
      }
    } catch (error) {
      print('Error cancelling subscription: $error');
      rethrow;
    }
  }

  // Get payment history
  static Future<List<Map<String, dynamic>>> getPaymentHistory({
    int limit = 10,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/payment/history?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to get payment history');
      }
    } catch (error) {
      print('Error getting payment history: $error');
      rethrow;
    }
  }

  // Test premium activation (for development only)
  static Future<Map<String, dynamic>> activateTestPremium({
    String planType = 'monthly',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/test/activate-premium'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'planType': planType}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to activate test premium');
      }
    } catch (error) {
      print('Error activating test premium: $error');
      rethrow;
    }
  }

  // Format currency amount
  static String formatAmount(double amount, String currency) {
    switch (currency) {
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      case 'GBP':
        return '£${amount.toStringAsFixed(2)}';
      case 'INR':
        return '₹${amount.toStringAsFixed(0)}';
      case 'CAD':
        return 'C\$${amount.toStringAsFixed(2)}';
      case 'AUD':
        return 'A\$${amount.toStringAsFixed(2)}';
      default:
        return '$currency ${amount.toStringAsFixed(2)}';
    }
  }

  // Get currency symbol
  static String getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return currency;
    }
  }

  // Show payment success dialog
  static void showPaymentSuccessDialog(
    BuildContext context,
    Map<String, dynamic> subscriptionData,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Payment Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Welcome to Premium!'),
            const SizedBox(height: 16),
            Text(
              'Your ${subscriptionData['subscription']['planType']} subscription is now active.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enjoy unlimited access to all premium features.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close payment screen too
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  // Show payment error dialog
  static void showPaymentErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 64),
        title: const Text('Payment Failed'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
