import 'package:flutter/material.dart';
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

      // Show processing dialog with selected UPI app
      UpiPaymentService.showUpiProcessingDialog(context, _selectedUpiApp!);

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
      final result = await UpiPaymentService.verifyUpiPayment(
        planType: widget.planType,
        amount: widget.amount,
        currency: 'INR',
        razorpayPaymentId: mockPaymentResult['razorpayPaymentId']!,
        razorpayOrderId: mockPaymentResult['razorpayOrderId']!,
        razorpaySignature: mockPaymentResult['razorpaySignature']!,
      );

      // Update premium status
      await PremiumService.updatePremiumStatus(true);

      Navigator.of(context).pop(); // Close processing dialog
      UpiPaymentService.showUpiSuccessDialog(context, _selectedUpiApp!, result);
      widget.onPaymentSuccess(result);
    } catch (error) {
      Navigator.of(context).pop(); // Close processing dialog if open

      // Show error dialog
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

      widget.onPaymentError(error.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
