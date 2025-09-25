import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static FirebaseAnalytics? _analytics;
  static FirebaseCrashlytics? _crashlytics;
  static FirebasePerformance? _performance;
  static SharedPreferences? _prefs;

  // User behavior tracking
  static final Map<String, dynamic> _userProperties = {};
  static final List<Map<String, dynamic>> _eventQueue = [];
  static DateTime? _sessionStart;
  static String? _userId;
  static String? _abTestGroup;

  /// Initialize analytics services
  static Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      _performance = FirebasePerformance.instance;
      _prefs = await SharedPreferences.getInstance();

      // Set up crash reporting
      FlutterError.onError = _crashlytics!.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics!.recordError(error, stack, fatal: true);
        return true;
      };

      // Generate or retrieve user ID
      _userId = _prefs!.getString('user_id');
      if (_userId == null) {
        _userId = _generateUserId();
        await _prefs!.setString('user_id', _userId!);
      }

      await _analytics!.setUserId(id: _userId);

      // Initialize A/B testing
      await _initializeABTesting();

      // Start session tracking
      _startSession();

      debugPrint('Analytics initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize analytics: $e');
    }
  }

  /// Generate unique user ID
  static String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 10000)}';
  }

  /// Initialize A/B testing
  static Future<void> _initializeABTesting() async {
    try {
      // Determine A/B test group (simple random assignment)
      _abTestGroup = _prefs!.getString('ab_test_group');
      if (_abTestGroup == null) {
        final random = DateTime.now().millisecondsSinceEpoch % 100;
        if (random < 33) {
          _abTestGroup = 'pricing_low'; // $3.99/month
        } else if (random < 66) {
          _abTestGroup = 'pricing_standard'; // $4.99/month
        } else {
          _abTestGroup = 'pricing_high'; // $5.99/month
        }
        await _prefs!.setString('ab_test_group', _abTestGroup!);
      }

      await setUserProperty('ab_test_group', _abTestGroup!);
      trackEvent('ab_test_assigned', {'group': _abTestGroup!});
    } catch (e) {
      debugPrint('A/B testing initialization failed: $e');
    }
  }

  /// Get A/B test group
  static String getABTestGroup() => _abTestGroup ?? 'pricing_standard';

  /// Get pricing based on A/B test
  static Map<String, dynamic> getPricingForUser() {
    switch (_abTestGroup) {
      case 'pricing_low':
        return {
          'monthly_price': '\$3.99',
          'monthly_value': 3.99,
          'yearly_price': '\$29.99',
          'yearly_value': 29.99,
          'lifetime_price': '\$39.99',
          'lifetime_value': 39.99,
        };
      case 'pricing_high':
        return {
          'monthly_price': '\$5.99',
          'monthly_value': 5.99,
          'yearly_price': '\$49.99',
          'yearly_value': 49.99,
          'lifetime_price': '\$59.99',
          'lifetime_value': 59.99,
        };
      default: // pricing_standard
        return {
          'monthly_price': '\$4.99',
          'monthly_value': 4.99,
          'yearly_price': '\$39.99',
          'yearly_value': 39.99,
          'lifetime_price': '\$49.99',
          'lifetime_value': 49.99,
        };
    }
  }

  /// Start user session
  static void _startSession() {
    _sessionStart = DateTime.now();
    trackEvent('session_start', {
      'timestamp': _sessionStart!.toIso8601String(),
      'user_id': _userId,
    });
  }

  /// End user session
  static void endSession() {
    if (_sessionStart != null) {
      final sessionDuration = DateTime.now()
          .difference(_sessionStart!)
          .inSeconds;
      trackEvent('session_end', {
        'duration_seconds': sessionDuration,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _sessionStart = null;
    }
  }

  /// Track custom events
  static Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? parameters,
  ]) async {
    try {
      final eventData = {
        'event_name': eventName,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': _userId,
        'ab_test_group': _abTestGroup,
        ...?parameters,
      };

      // Add to local queue for offline support
      _eventQueue.add(eventData);

      // Send to Firebase
      await _analytics?.logEvent(
        name: eventName,
        parameters: parameters?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      // Store locally for analytics dashboard
      await _storeEventLocally(eventData);

      debugPrint('Event tracked: $eventName with parameters: $parameters');
    } catch (e) {
      debugPrint('Failed to track event: $e');
    }
  }

  /// Store event locally for offline analytics
  static Future<void> _storeEventLocally(Map<String, dynamic> eventData) async {
    try {
      final String today = DateTime.now().toIso8601String().split('T')[0];
      final String key = 'analytics_$today';

      List<String> events = _prefs!.getStringList(key) ?? [];
      events.add(jsonEncode(eventData));

      // Keep only last 100 events per day to prevent storage bloat
      if (events.length > 100) {
        events = events.sublist(events.length - 100);
      }

      await _prefs!.setStringList(key, events);
    } catch (e) {
      debugPrint('Failed to store event locally: $e');
    }
  }

  /// Track screen views
  static Future<void> trackScreenView(
    String screenName, [
    Map<String, dynamic>? parameters,
  ]) async {
    await _analytics?.logScreenView(screenName: screenName);
    await trackEvent('screen_view', {
      'screen_name': screenName,
      ...?parameters,
    });
  }

  /// Track user properties
  static Future<void> setUserProperty(String name, String value) async {
    try {
      _userProperties[name] = value;
      await _analytics?.setUserProperty(name: name, value: value);

      // Store locally
      await _prefs!.setString('user_property_$name', value);
    } catch (e) {
      debugPrint('Failed to set user property: $e');
    }
  }

  /// Track conversion events
  static Future<void> trackConversion(String productId, [double? value]) async {
    await trackEvent('purchase', {
      'product_id': productId,
      'value': value ?? 0,
      'currency': 'USD',
    });

    await trackEvent('conversion', {
      'product_id': productId,
      'conversion_type': 'purchase',
      'value': value ?? 0,
    });
  }

  /// Track user engagement
  static Future<void> trackEngagement(
    String action, [
    Map<String, dynamic>? context,
  ]) async {
    await trackEvent('user_engagement', {
      'action': action,
      'engagement_time_msec': DateTime.now().millisecondsSinceEpoch,
      ...?context,
    });
  }

  /// Track feature usage
  static Future<void> trackFeatureUse(
    String featureName, [
    Map<String, dynamic>? metadata,
  ]) async {
    await trackEvent('feature_used', {
      'feature_name': featureName,
      'usage_count': await _incrementFeatureUsage(featureName),
      ...?metadata,
    });
  }

  /// Increment feature usage counter
  static Future<int> _incrementFeatureUsage(String featureName) async {
    final key = 'feature_usage_$featureName';
    final currentCount = _prefs!.getInt(key) ?? 0;
    final newCount = currentCount + 1;
    await _prefs!.setInt(key, newCount);
    return newCount;
  }

  /// Track errors
  static Future<void> trackError(String error, [StackTrace? stackTrace]) async {
    await _crashlytics?.recordError(error, stackTrace);
    await trackEvent('error_occurred', {
      'error_message': error,
      'has_stack_trace': stackTrace != null,
    });
  }

  /// Track performance
  static Trace? startTrace(String traceName) {
    try {
      final trace = _performance?.newTrace(traceName);
      trace?.start();
      return trace;
    } catch (e) {
      debugPrint('Failed to start trace: $e');
      return null;
    }
  }

  /// Stop performance trace
  static void stopTrace(Trace? trace) {
    try {
      trace?.stop();
    } catch (e) {
      debugPrint('Failed to stop trace: $e');
    }
  }

  /// Get analytics data for dashboard
  static Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final String today = DateTime.now().toIso8601String().split('T')[0];
      final String yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .split('T')[0];

      final todayEvents = _prefs!.getStringList('analytics_$today') ?? [];
      final yesterdayEvents =
          _prefs!.getStringList('analytics_$yesterday') ?? [];

      // Parse events
      final todayParsed = todayEvents
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList();
      final yesterdayParsed = yesterdayEvents
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList();

      // Calculate metrics
      final conversions = todayParsed
          .where((e) => e['event_name'] == 'conversion')
          .length;
      final screenViews = todayParsed
          .where((e) => e['event_name'] == 'screen_view')
          .length;
      final featureUses = todayParsed
          .where((e) => e['event_name'] == 'feature_used')
          .length;

      return {
        'today_events': todayParsed.length,
        'yesterday_events': yesterdayParsed.length,
        'conversions': conversions,
        'screen_views': screenViews,
        'feature_uses': featureUses,
        'ab_test_group': _abTestGroup,
        'user_id': _userId,
        'session_active': _sessionStart != null,
      };
    } catch (e) {
      debugPrint('Failed to get analytics summary: $e');
      return {};
    }
  }

  /// Track onboarding progress
  static Future<void> trackOnboardingStep(
    String step,
    int stepNumber,
    int totalSteps,
  ) async {
    await trackEvent('onboarding_step', {
      'step_name': step,
      'step_number': stepNumber,
      'total_steps': totalSteps,
      'completion_percentage': (stepNumber / totalSteps * 100).round(),
    });
  }

  /// Track onboarding completion
  static Future<void> trackOnboardingCompleted(int totalTime) async {
    await trackEvent('onboarding_completed', {
      'total_time_seconds': totalTime,
      'completed_at': DateTime.now().toIso8601String(),
    });

    await setUserProperty('onboarding_completed', 'true');
  }

  /// Track retention events
  static Future<void> trackRetention(String type) async {
    await trackEvent('retention_event', {
      'type': type, // 'daily', 'weekly', 'monthly'
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Check if user is new (for onboarding)
  static bool isNewUser() {
    return _prefs!.getString('user_property_onboarding_completed') == null;
  }

  /// Get user journey data
  static Future<List<Map<String, dynamic>>> getUserJourney() async {
    final events = <Map<String, dynamic>>[];

    // Get last 7 days of events
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now()
          .subtract(Duration(days: i))
          .toIso8601String()
          .split('T')[0];
      final dayEvents = _prefs!.getStringList('analytics_$date') ?? [];

      for (final eventString in dayEvents) {
        try {
          events.add(jsonDecode(eventString) as Map<String, dynamic>);
        } catch (e) {
          // Skip malformed events
        }
      }
    }

    // Sort by timestamp
    events.sort(
      (a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String),
    );

    return events;
  }
}
