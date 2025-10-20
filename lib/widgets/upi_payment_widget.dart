import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/upi_payment_service.dart';
import '../services/premium_service.dart';

class UpiPaymentWidget extends StatefulWidget {
  final String planType;
  final double amount;
  final VoidCallback onPaymentStart;
  final Function(Map<String, dynamic>) onPaymentSuccess;
  final Function(String) onPaymentError;

  const UpiPaymentWidget({
    super.key,
    required this.planType,
    required this.amount,
    required this.onPaymentStart,
    required this.onPaymentSuccess,
    required this.onPaymentError,
  });

  @override
  State<UpiPaymentWidget> createState() => _UpiPaymentWidgetState();
}

class _UpiPaymentWidgetState extends State<UpiPaymentWidget> {
  bool _isLoading = false;
  String? _selectedUpiApp;

  @override
  Widget build(BuildContext context) {
    // Check if UPI is available (India region)
    if (!UpiPaymentService.isUpiAvailable('INR', 'IN')) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UPI Payment Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pay with UPI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        UpiPaymentService.formatUpiAmount(widget.amount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'INSTANT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // UPI Apps Grid
          const Text(
            'Choose your UPI app:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: UpiPaymentService.upiApps.length,
            itemBuilder: (context, index) {
              final appKey = UpiPaymentService.upiApps.keys.toList()[index];
              final app = UpiPaymentService.upiApps[appKey]!;
              final isSelected = _selectedUpiApp == appKey;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedUpiApp = appKey;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(
                            int.parse('FF${app['color']}', radix: 16),
                          ).withOpacity(0.1)
                        : Colors.grey[50],
                    border: Border.all(
                      color: isSelected
                          ? Color(int.parse('FF${app['color']}', radix: 16))
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse('FF${app['color']}', radix: 16),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            app['icon']!,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        app['name']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Color(int.parse('FF${app['color']}', radix: 16))
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.check_circle,
                            color: Color(
                              int.parse('FF${app['color']}', radix: 16),
                            ),
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _selectedUpiApp != null && !_isLoading
                  ? _handleUpiPayment
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedUpiApp != null
                    ? const Color(0xFF1E88E5)
                    : Colors.grey[400],
                foregroundColor: Colors.white,
                elevation: _selectedUpiApp != null ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payment, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          _selectedUpiApp != null
                              ? 'Pay ${UpiPaymentService.formatUpiAmount(widget.amount)}'
                              : 'Select UPI App',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Security Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your payment is protected by bank-level security',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpiPayment() async {
    if (_selectedUpiApp == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      widget.onPaymentStart();

      // Create UPI payment intent
      final paymentIntent = await UpiPaymentService.createUpiPaymentIntent(
        planType: widget.planType,
        upiApp: _selectedUpiApp!,
      );

      setState(() {
        _isLoading = false;
      });

      // Show user they need to complete payment in UPI app
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('Complete Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You will be redirected to ${UpiPaymentService.upiApps[_selectedUpiApp]!['name']} to complete the payment.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Make sure to complete the payment in your UPI app',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) {
        widget.onPaymentError('Payment cancelled by user');
        return;
      }

      // Open Razorpay checkout with real payment intent
      _openRazorpayCheckout(paymentIntent);
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Payment Failed'),
              ],
            ),
            content: Text(error.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      widget.onPaymentError(error.toString());
    }
  }

  void _openRazorpayCheckout(Map<String, dynamic> paymentIntent) {
    final razorpay = Razorpay();

    // Set up event handlers for this checkout session
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
      PaymentSuccessResponse response,
    ) async {
      debugPrint('Razorpay Payment Success: ${response.paymentId}');

      // Show loading while verifying
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Verifying payment...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      try {
        // Verify payment on server BEFORE upgrading
        final result = await UpiPaymentService.verifyUpiPayment(
          planType: widget.planType,
          amount: widget.amount,
          currency: 'INR',
          razorpayPaymentId: response.paymentId!,
          razorpayOrderId: response.orderId!,
          razorpaySignature: response.signature!,
        );

        // Close verification dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Only upgrade if server verification succeeds
        if (result['success'] == true && result['verified'] == true) {
          await PremiumService.upgradeToPremium();

          // Show success UI only after verification
          if (mounted) {
            UpiPaymentService.showUpiSuccessDialog(
              context,
              _selectedUpiApp!,
              result,
            );
          }
          widget.onPaymentSuccess(result);
        } else {
          throw Exception('Payment verification failed');
        }
      } catch (e) {
        // Close verification dialog if open
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Show error
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Verification Failed'),
                ],
              ),
              content: Text(
                'Payment verification failed. Please contact support if amount was deducted.\n\nError: $e',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        widget.onPaymentError('Payment verification failed: $e');
      } finally {
        razorpay.clear();
      }
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (
      PaymentFailureResponse response,
    ) {
      debugPrint(
        'Razorpay Payment Error: ${response.code} - ${response.message}',
      );

      String errorMessage = 'Payment failed';

      // Better error messages
      if (response.message?.contains('UPI') == true) {
        errorMessage =
            'UPI payment failed. Please check your UPI app and try again.';
      } else if (response.message?.contains('cancelled') == true) {
        errorMessage = 'Payment was cancelled';
      } else {
        errorMessage = 'Payment failed: ${response.message}';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Payment Failed'),
              ],
            ),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      widget.onPaymentError(errorMessage);
      razorpay.clear();
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (
      ExternalWalletResponse response,
    ) {
      debugPrint('Razorpay External Wallet: ${response.walletName}');
      razorpay.clear();
    });

    // Build checkout options
    final paymentData = paymentIntent['paymentData'];
    final options = {
      'key': paymentData['key'],
      'amount': paymentData['amount'], // Amount in paise
      'name': 'Resume Builder Premium',
      'description': 'Premium subscription - ${widget.planType}',
      'order_id': paymentData['orderId'],
      'prefill': {'contact': '', 'email': ''},
      'method': {'upi': true}, // Only allow UPI
      'theme': {'color': '#1E88E5'},
    };

    // Set preferred UPI app
    if (_selectedUpiApp != null) {
      final appDetails = UpiPaymentService.upiApps[_selectedUpiApp];
      if (appDetails != null) {
        options['notes'] = {
          'upi_app': _selectedUpiApp,
          'app_name': appDetails['name'],
        };
      }
    }

    // Open Razorpay checkout
    try {
      razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      widget.onPaymentError('Failed to open payment: $e');
      razorpay.clear();
    }
  }
}
