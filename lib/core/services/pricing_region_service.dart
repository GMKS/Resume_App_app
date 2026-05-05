import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription_pricing.dart';
import 'subscription_pricing_service.dart';
import 'user_session_service.dart';

class PricingRegionService {
  static const String _regionCacheKey = 'pricing_region';
  static const String _countryCacheKey = 'pricing_country_code';

  Future<PricingRegion> resolveRegion({
    Locale? localeOverride,
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRegion = _regionFromName(prefs.getString(_regionCacheKey));
    final cachedCountryCode =
        prefs.getString(_countryCacheKey)?.trim().toUpperCase();
    final loginCountryCode = UserSessionService.readStoredCountryCode(prefs);
    if (loginCountryCode != null && loginCountryCode.isNotEmpty) {
      final loginRegion = SubscriptionPricingService.regionFromCountryCode(
        loginCountryCode,
      );
      await prefs.setString(_regionCacheKey, loginRegion.name);
      await prefs.setString(_countryCacheKey, loginCountryCode);
      return loginRegion;
    }

    if (!forceRefresh) {
      if (cachedRegion != null) {
        return cachedRegion;
      }
    }

    final liveCountryCode = _countryCodeFromLocale(
        localeOverride ?? WidgetsBinding.instance.platformDispatcher.locale,
      ) ??
      await _countryCodeFromIp();
    final countryCode = loginCountryCode ??
      liveCountryCode ??
      (cachedCountryCode != null && cachedCountryCode.isNotEmpty
        ? cachedCountryCode
        : null);
    final region = SubscriptionPricingService.regionFromCountryCode(countryCode);

    await prefs.setString(_regionCacheKey, region.name);
    if (countryCode != null && countryCode.isNotEmpty) {
      await prefs.setString(_countryCacheKey, countryCode);
    }

    if (countryCode == null || countryCode.isEmpty) {
      return cachedRegion ?? region;
    }

    return region;
  }

  PricingRegion? _regionFromName(String? name) {
    if (name == null || name.isEmpty) {
      return null;
    }

    for (final region in PricingRegion.values) {
      if (region.name == name) {
        return region;
      }
    }
    return null;
  }

  String? _countryCodeFromLocale(Locale locale) {
    final code = locale.countryCode?.trim().toUpperCase();
    if (code == null || code.isEmpty) {
      return null;
    }
    return code;
  }

  Future<String?> _countryCodeFromIp() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return null;
      }

      final code = (body['country_code'] as String?)?.trim().toUpperCase();
      if (code == null || code.isEmpty) {
        return null;
      }
      return code;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }
}