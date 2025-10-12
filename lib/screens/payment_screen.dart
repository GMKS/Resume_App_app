import 'package:flutter/material.dart';
import '../services/upi_payment_service.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: UpiPaymentService.createUpiPaymentButton(
          context: context,
          planType: 'monthly',
          amount: 299.0,
          onPaymentStart: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Payment started...')));
          },
          onPaymentSuccess: (result) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment successful!')),
            );
          },
          onPaymentError: (error) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Payment failed: $error')));
          },
        ),
      ),
    );
  }
}
