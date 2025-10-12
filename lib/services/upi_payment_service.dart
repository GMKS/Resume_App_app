import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'payment_service.dart';

class UpiPaymentService {
  static const String _baseUrl = AppConfig.apiBaseUrl;

  // Supported UPI apps in India
  static const Map<String, Map<String, String>> upiApps = {
    'googlepay': {
      'name': 'Google Pay',
      'package': 'com.google.android.apps.nbu.paisa.user',
      'icon': '💳',
      'color': '4285F4', // Google Blue
    },
    'phonepe': {
      'name': 'PhonePe',
      'package': 'com.phonepe.app',
      'icon': '📱',
      'color': '5F259F', // PhonePe Purple
    },
    'paytm': {
      'name': 'Paytm',
      'package': 'net.one97.paytm',
      'icon': '💰',
      'color': '00BAF2', // Paytm Blue
    },
    'amazonpay': {
      'name': 'Amazon Pay',
      'package': 'in.amazon.mShop.android.shopping',
      'icon': '🛒',
      'color': 'FF9900', // Amazon Orange
    },
    'mobikwik': {
      'name': 'MobiKwik',
      'package': 'com.mobikwik_new',
      'icon': '🔵',
      'color': 'E91E63', // MobiKwik Pink
    },
  };

  // Create UPI payment intent
  static Future<Map<String, dynamic>> createUpiPaymentIntent({
    required String planType,
    required String upiApp,
    String currency = 'INR',
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
          'paymentProvider': 'razorpay',
          'paymentMethod': upiApp,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      } else {
        throw Exception(
          data['message'] ?? 'Failed to create UPI payment intent',
        );
      }
    } catch (error) {
      print('Error creating UPI payment intent: $error');
      rethrow;
    }
  }

  // Verify UPI payment
  static Future<Map<String, dynamic>> verifyUpiPayment({
    required String planType,
    required double amount,
    required String currency,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    try {
      return await PaymentService.verifyPayment(
        paymentProvider: 'razorpay',
        planType: planType,
        amount: amount,
        currency: currency,
        razorpayPaymentId: razorpayPaymentId,
        razorpayOrderId: razorpayOrderId,
        razorpaySignature: razorpaySignature,
      );
    } catch (error) {
      print('Error verifying UPI payment: $error');
      rethrow;
    }
  }

  // Show UPI app selection dialog
  static Future<String?> showUpiAppSelector(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.blue),
            SizedBox(width: 8),
            Text('Choose Payment App'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: upiApps.length,
            itemBuilder: (context, index) {
              final appKey = upiApps.keys.toList()[index];
              final app = upiApps[appKey]!;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(int.parse('FF${app['color']}', radix: 16)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        app['icon']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  title: Text(
                    app['name']!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Pay with ${app['name']}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.of(context).pop(appKey),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Get UPI app details
  static Map<String, String>? getUpiAppDetails(String appKey) {
    return upiApps[appKey];
  }

  // Check if UPI is available (India only)
  static bool isUpiAvailable(String currency, String? country) {
    return currency == 'INR' || country == 'IN';
  }

  // Format UPI payment amount for display
  static String formatUpiAmount(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  // Show UPI payment processing dialog
  static void showUpiProcessingDialog(BuildContext context, String upiApp) {
    final app = upiApps[upiApp];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(
                  int.parse('FF${app?['color'] ?? '000000'}', radix: 16),
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: Text(
                  app?['icon'] ?? '💳',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Processing ${app?['name'] ?? 'UPI'} Payment',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Please complete the payment in ${app?['name'] ?? 'your UPI app'}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Show UPI payment success dialog
  static void showUpiSuccessDialog(
    BuildContext context,
    String upiApp,
    Map<String, dynamic> subscriptionData,
  ) {
    final app = upiApps[upiApp];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Center(
                child: Icon(Icons.check, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Paid via ${app?['name'] ?? 'UPI'}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ${subscriptionData['subscription']['planType']} subscription is now active!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Create UPI payment widget
  static Widget createUpiPaymentButton({
    required BuildContext context,
    required String planType,
    required double amount,
    required VoidCallback onPaymentStart,
    required Function(Map<String, dynamic>) onPaymentSuccess,
    required Function(String) onPaymentError,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            // Show UPI app selector
            final selectedApp = await showUpiAppSelector(context);
            if (selectedApp == null) return;

            onPaymentStart();

            // Create payment intent
            final paymentIntent = await createUpiPaymentIntent(
              planType: planType,
              upiApp: selectedApp,
            );

            // Show processing dialog
            showUpiProcessingDialog(context, selectedApp);

            // Simulate payment processing (replace with actual UPI payment flow)
            await Future.delayed(const Duration(seconds: 3));

            // For demo purposes, simulate successful payment
            // In real implementation, this would be handled by Razorpay SDK
            final mockPaymentResult = {
              'razorpayPaymentId':
                  'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
              'razorpayOrderId': paymentIntent['paymentData']['orderId'],
              'razorpaySignature':
                  'mock_signature_${DateTime.now().millisecondsSinceEpoch}',
            };

            // Verify payment
            final result = await verifyUpiPayment(
              planType: planType,
              amount: amount,
              currency: 'INR',
              razorpayPaymentId: mockPaymentResult['razorpayPaymentId']!,
              razorpayOrderId: mockPaymentResult['razorpayOrderId']!,
              razorpaySignature: mockPaymentResult['razorpaySignature']!,
            );

            Navigator.of(context).pop(); // Close processing dialog
            showUpiSuccessDialog(context, selectedApp, result);
            onPaymentSuccess(result);
          } catch (error) {
            Navigator.of(context).pop(); // Close processing dialog if open
            onPaymentError(error.toString());
          }
        },
        icon: const Icon(Icons.payment),
        label: Text('Pay ${formatUpiAmount(amount)} with UPI'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }
}
