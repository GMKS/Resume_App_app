import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../services/analytics_service.dart';
import '../services/premium_service.dart';

class InAppPurchaseService {
  static final InAppPurchaseService _instance =
      InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Product IDs - these should match your App Store Connect / Google Play Console
  static const String monthlyPremiumId = 'resume_builder_monthly_premium';
  static const String yearlyPremiumId = 'resume_builder_yearly_premium';
  static const String lifetimePremiumId = 'resume_builder_lifetime_premium';

  static const Set<String> _productIds = {
    monthlyPremiumId,
    yearlyPremiumId,
    lifetimePremiumId,
  };

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _loading = true;
  String? _errorMessage;

  // Getters
  bool get isAvailable => _isAvailable;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;

  /// Initialize the purchase service
  Future<void> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      if (!_isAvailable) {
        _errorMessage = 'In-app purchases not available';
        _loading = false;
        return;
      }

      // Set up purchase stream listener
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription.cancel(),
        onError: (error) => _handleError('Purchase stream error: $error'),
      );

      // Load products
      await _loadProducts();

      // Restore previous purchases
      await restorePurchases();
    } catch (e) {
      _handleError('Failed to initialize purchases: $e');
    }
  }

  /// Load available products from the store
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      _loading = false;

      // Track analytics
      AnalyticsService.trackEvent('products_loaded', {
        'product_count': _products.length,
        'not_found_count': response.notFoundIDs.length,
      });
    } catch (e) {
      _handleError('Failed to load products: $e');
    }
  }

  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    try {
      final ProductDetails? productDetails = _products
          .where((product) => product.id == productId)
          .firstOrNull;

      if (productDetails == null) {
        _handleError('Product not found: $productId');
        return false;
      }

      // Track purchase attempt
      AnalyticsService.trackEvent('purchase_attempted', {
        'product_id': productId,
        'price': productDetails.price,
        'currency': productDetails.currencyCode,
      });

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null, // Optional: user ID for tracking
      );

      bool success = false;
      if (productDetails.id == lifetimePremiumId) {
        // One-time purchase
        success = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      } else {
        // Subscription
        success = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      }

      return success;
    } catch (e) {
      _handleError('Purchase failed: $e');
      return false;
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _processPurchase(purchaseDetails);
    }
  }

  /// Process individual purchase
  Future<void> _processPurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      // Handle pending purchase (e.g., awaiting approval)
      AnalyticsService.trackEvent('purchase_pending', {
        'product_id': purchaseDetails.productID,
      });
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      // Handle purchase error
      _handleError('Purchase error: ${purchaseDetails.error}');
      AnalyticsService.trackEvent('purchase_failed', {
        'product_id': purchaseDetails.productID,
        'error': purchaseDetails.error?.message ?? 'Unknown error',
      });
    } else if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      // Verify purchase on your server (recommended for production)
      final isValid = await _verifyPurchase(purchaseDetails);

      if (isValid) {
        // Grant premium access
        await PremiumService.upgradeToPremium();

        // Track successful purchase
        AnalyticsService.trackEvent('purchase_completed', {
          'product_id': purchaseDetails.productID,
          'transaction_id': purchaseDetails.purchaseID,
          'restored': purchaseDetails.status == PurchaseStatus.restored,
        });

        // Track conversion for analytics
        AnalyticsService.trackConversion(purchaseDetails.productID);
      }
    }

    // Always complete the purchase to close the transaction
    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  /// Verify purchase (implement server-side verification in production)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In production, send the purchase token to your server for verification
    // For now, we'll just return true

    // Example server verification:
    // final response = await http.post(
    //   Uri.parse('https://your-server.com/verify-purchase'),
    //   body: jsonEncode({
    //     'receipt_data': purchaseDetails.verificationData.serverVerificationData,
    //     'product_id': purchaseDetails.productID,
    //   }),
    // );
    // return response.statusCode == 200;

    return true;
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();

      AnalyticsService.trackEvent('purchases_restored', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _handleError('Failed to restore purchases: $e');
    }
  }

  /// Get product details by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    if (Platform.isIOS) {
      return await _checkIOSSubscription();
    } else if (Platform.isAndroid) {
      return await _checkAndroidSubscription();
    }
    return false;
  }

  /// Check iOS subscription status
  Future<bool> _checkIOSSubscription() async {
    if (!kIsWeb && Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition storeKitPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();

      try {
        await storeKitPlatformAddition.setDelegate(
          ExamplePaymentQueueDelegate(),
        );
        final transactions = await SKPaymentQueueWrapper().transactions();

        for (final transaction in transactions) {
          if (_productIds.contains(transaction.payment.productIdentifier) &&
              transaction.transactionState ==
                  SKPaymentTransactionStateWrapper.purchased) {
            return true;
          }
        }
      } catch (e) {
        debugPrint('iOS subscription check failed: $e');
      }
    }
    return false;
  }

  /// Check Android subscription status
  Future<bool> _checkAndroidSubscription() async {
    if (!kIsWeb && Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition androidAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

      try {
        final response = await androidAddition.queryPastPurchases();

        for (final purchase in response.pastPurchases) {
          if (_productIds.contains(purchase.productID) &&
              purchase.status == PurchaseStatus.purchased) {
            return true;
          }
        }
      } catch (e) {
        debugPrint('Android subscription check failed: $e');
      }
    }
    return false;
  }

  /// Handle errors
  void _handleError(String error) {
    _errorMessage = error;
    _loading = false;
    debugPrint('InAppPurchaseService Error: $error');

    AnalyticsService.trackEvent('purchase_error', {
      'error_message': error,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Dispose resources
  void dispose() {
    _subscription.cancel();
  }
}

/// iOS Payment Queue Delegate
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
