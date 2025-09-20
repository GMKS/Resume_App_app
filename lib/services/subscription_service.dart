import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

bool isPremiumUser = false;

Future<void> checkSubscriptionStatus() async {
  final isSubscribed = await InAppPurchase.instance.isAvailable();
  isPremiumUser = isSubscribed;
}

void showPremiumMessage(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Upgrade to premium for unlimited resumes!')),
  );
}
