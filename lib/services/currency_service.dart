import 'dart:io';

class CurrencyService {
  static String _userCountry = 'US';
  static String _userCurrency = 'USD';

  // Pricing by country/currency
  static const Map<String, Map<String, dynamic>> _countryPricing = {
    'US': {
      'currency': 'USD',
      'symbol': '\$',
      'monthly': 4.99,
      'yearly': 39.99,
      'lifetime': 49.99,
    },
    'IN': {
      'currency': 'INR',
      'symbol': '₹',
      'monthly': 399.00,
      'yearly': 2999.00,
      'lifetime': 3999.00,
    },
    'GB': {
      'currency': 'GBP',
      'symbol': '£',
      'monthly': 3.99,
      'yearly': 29.99,
      'lifetime': 39.99,
    },
    'CA': {
      'currency': 'CAD',
      'symbol': 'C\$',
      'monthly': 6.99,
      'yearly': 52.99,
      'lifetime': 69.99,
    },
    'AU': {
      'currency': 'AUD',
      'symbol': 'A\$',
      'monthly': 7.99,
      'yearly': 59.99,
      'lifetime': 79.99,
    },
    'DE': {
      'currency': 'EUR',
      'symbol': '€',
      'monthly': 4.49,
      'yearly': 34.99,
      'lifetime': 44.99,
    },
    'FR': {
      'currency': 'EUR',
      'symbol': '€',
      'monthly': 4.49,
      'yearly': 34.99,
      'lifetime': 44.99,
    },
    'BR': {
      'currency': 'BRL',
      'symbol': 'R\$',
      'monthly': 24.99,
      'yearly': 189.99,
      'lifetime': 249.99,
    },
    'MX': {
      'currency': 'MXN',
      'symbol': '\$',
      'monthly': 89.99,
      'yearly': 699.99,
      'lifetime': 899.99,
    },
  };

  static Future<void> initialize() async {
    try {
      // Try to detect user's country from locale
      final locale = Platform.localeName;
      if (locale.contains('_')) {
        final countryCode = locale.split('_').last;
        if (_countryPricing.containsKey(countryCode)) {
          _userCountry = countryCode;
          _userCurrency = _countryPricing[countryCode]!['currency'];
        }
      }
    } catch (e) {
      print('Error detecting locale: $e');
      // Default to US
      _userCountry = 'US';
      _userCurrency = 'USD';
    }
  }

  static String get userCountry => _userCountry;
  static String get userCurrency => _userCurrency;

  static Map<String, dynamic> get currentPricing =>
      _countryPricing[_userCountry] ?? _countryPricing['US']!;

  static String formatPrice(String type) {
    final pricing = currentPricing;
    final symbol = pricing['symbol'];
    final price = pricing[type];

    if (price != null) {
      if (_userCurrency == 'INR' ||
          _userCurrency == 'BRL' ||
          _userCurrency == 'MXN') {
        return '$symbol${price.toStringAsFixed(0)}';
      } else {
        return '$symbol${price.toStringAsFixed(2)}';
      }
    }

    // Fallback to USD pricing
    final usdPricing = _countryPricing['US']!;
    return '\$${usdPricing[type].toStringAsFixed(2)}';
  }

  static double getPrice(String type) {
    final pricing = currentPricing;
    return pricing[type]?.toDouble() ?? 0.0;
  }

  static String getCurrencySymbol() {
    return currentPricing['symbol'] ?? '\$';
  }

  // Helper method to get localized subscription terms
  static String getSubscriptionTerms() {
    switch (_userCountry) {
      case 'IN':
        return 'Subscription will auto-renew. Cancel anytime from your Google Play account. Prices may vary by region.';
      case 'GB':
        return 'Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.';
      case 'DE':
      case 'FR':
        return 'Das Abonnement verlängert sich automatisch, es sei denn, es wird mindestens 24 Stunden vor Ablauf gekündigt.';
      default:
        return 'Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.';
    }
  }
}
