import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/analytics_service.dart';

class RetentionService {
  static final RetentionService _instance = RetentionService._internal();
  factory RetentionService() => _instance;
  RetentionService._internal();

  static FlutterLocalNotificationsPlugin? _notifications;
  static SharedPreferences? _prefs;
  static Timer? _engagementTimer;
  static bool _isInitialized = false;

  /// Initialize retention service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _notifications = FlutterLocalNotificationsPlugin();
      _prefs = await SharedPreferences.getInstance();

      // Initialize notifications
      await _initializeNotifications();

      // Schedule retention notifications
      await _scheduleRetentionNotifications();

      // Start engagement tracking
      _startEngagementTracking();

      // Check for returning users
      await _checkReturnUser();

      _isInitialized = true;
      debugPrint('Retention service initialized');
    } catch (e) {
      debugPrint('Failed to initialize retention service: $e');
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications?.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestNotificationPermissions();
  }

  /// Request notification permissions
  static Future<void> _requestNotificationPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          ?.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _notifications
          ?.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  /// Handle notification taps
  static void _onNotificationTapped(NotificationResponse response) {
    AnalyticsService.trackEvent('notification_tapped', {
      'notification_id': response.id,
      'payload': response.payload,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Handle different notification types
    if (response.payload != null) {
      final payload = jsonDecode(response.payload!);
      final type = payload['type'] as String?;

      switch (type) {
        case 'resume_reminder':
          // Navigate to resume creation
          break;
        case 'feature_tip':
          // Navigate to specific feature
          break;
        case 'premium_offer':
          // Navigate to premium upgrade
          break;
      }
    }
  }

  /// Schedule retention notifications
  static Future<void> _scheduleRetentionNotifications() async {
    await _cancelAllNotifications();

    // Day 1: Welcome back (if not used)
    await _scheduleNotification(
      id: 1,
      title: '👋 Welcome back to Resume Builder!',
      body: 'Ready to create your professional resume? Let\'s get started!',
      scheduledDate: DateTime.now().add(const Duration(days: 1)),
      payload: {'type': 'welcome_back'},
    );

    // Day 3: Feature highlight
    await _scheduleNotification(
      id: 2,
      title: '✨ Did you know?',
      body: 'You can export your resume in multiple formats. Try it now!',
      scheduledDate: DateTime.now().add(const Duration(days: 3)),
      payload: {'type': 'feature_tip', 'feature': 'export'},
    );

    // Day 7: Premium offer
    await _scheduleNotification(
      id: 3,
      title: '🚀 Unlock Premium Features',
      body: 'Get AI-powered content generation and all professional templates!',
      scheduledDate: DateTime.now().add(const Duration(days: 7)),
      payload: {'type': 'premium_offer'},
    );

    // Day 14: Resume reminder
    await _scheduleNotification(
      id: 4,
      title: '📄 Time to update your resume?',
      body: 'Keep your resume fresh with the latest achievements and skills.',
      scheduledDate: DateTime.now().add(const Duration(days: 14)),
      payload: {'type': 'resume_reminder'},
    );

    // Day 30: Re-engagement
    await _scheduleNotification(
      id: 5,
      title: '💼 Your dream job awaits!',
      body: 'Don\'t let opportunities pass by. Update your resume today!',
      scheduledDate: DateTime.now().add(const Duration(days: 30)),
      payload: {'type': 'reengagement'},
    );
  }

  /// Schedule a single notification
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'retention_channel',
        'Retention Notifications',
        channelDescription: 'Notifications to improve user engagement',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications?.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        payload: payload != null ? jsonEncode(payload) : null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Track scheduled notification
      AnalyticsService.trackEvent('notification_scheduled', {
        'notification_id': id,
        'title': title,
        'scheduled_for': scheduledDate.toIso8601String(),
        'type': payload?['type'] ?? 'unknown',
      });
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> _cancelAllNotifications() async {
    await _notifications?.cancelAll();
  }

  /// Start engagement tracking
  static void _startEngagementTracking() {
    _engagementTimer?.cancel();
    _engagementTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _trackEngagementMetrics();
    });
  }

  /// Track engagement metrics
  static Future<void> _trackEngagementMetrics() async {
    try {
      final lastActive = _prefs?.getString('last_active');
      final now = DateTime.now().toIso8601String();

      if (lastActive != null) {
        final lastActiveTime = DateTime.parse(lastActive);
        final timeDiff = DateTime.now().difference(lastActiveTime);

        // Track session length
        if (timeDiff.inMinutes >= 5) {
          AnalyticsService.trackEngagement('session_5min');
        }
        if (timeDiff.inMinutes >= 15) {
          AnalyticsService.trackEngagement('session_15min');
        }
        if (timeDiff.inMinutes >= 30) {
          AnalyticsService.trackEngagement('session_30min');
        }
      }

      await _prefs?.setString('last_active', now);
    } catch (e) {
      debugPrint('Failed to track engagement: $e');
    }
  }

  /// Check if user is returning
  static Future<void> _checkReturnUser() async {
    try {
      final lastLaunch = _prefs?.getString('last_launch');
      final now = DateTime.now();

      if (lastLaunch != null) {
        final lastLaunchTime = DateTime.parse(lastLaunch);
        final daysSinceLastLaunch = now.difference(lastLaunchTime).inDays;

        if (daysSinceLastLaunch >= 1) {
          AnalyticsService.trackRetention('daily');

          // Cancel welcome back notification if user returned
          await _notifications?.cancel(1);
        }

        if (daysSinceLastLaunch >= 7) {
          AnalyticsService.trackRetention('weekly');
        }

        if (daysSinceLastLaunch >= 30) {
          AnalyticsService.trackRetention('monthly');
        }

        // Track days since last use
        AnalyticsService.trackEvent('user_returned', {
          'days_since_last_use': daysSinceLastLaunch,
          'is_returning_user': true,
        });
      } else {
        // First time user
        AnalyticsService.trackEvent('first_launch', {
          'timestamp': now.toIso8601String(),
          'is_new_user': true,
        });
      }

      await _prefs?.setString('last_launch', now.toIso8601String());
    } catch (e) {
      debugPrint('Failed to check return user: $e');
    }
  }

  /// Send targeted retention campaign
  static Future<void> sendRetentionCampaign(String campaignType) async {
    try {
      Map<String, String> campaignData;

      switch (campaignType) {
        case 'inactive_user':
          campaignData = {
            'title': '📱 We miss you at Resume Builder!',
            'body': 'Come back and finish creating your professional resume.',
          };
          break;
        case 'feature_discovery':
          campaignData = {
            'title': '🔍 Discover New Features',
            'body': 'Check out our latest AI-powered resume improvements!',
          };
          break;
        case 'premium_trial':
          campaignData = {
            'title': '🎁 Free Premium Trial Available',
            'body': 'Try all premium features free for 7 days. No commitment!',
          };
          break;
        case 'resume_update':
          campaignData = {
            'title': '📝 Time for a Resume Refresh?',
            'body': 'Keep your resume updated with your latest achievements.',
          };
          break;
        default:
          return;
      }

      await _scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch % 1000,
        title: campaignData['title']!,
        body: campaignData['body']!,
        scheduledDate: DateTime.now().add(const Duration(minutes: 1)),
        payload: {'type': 'retention_campaign', 'campaign': campaignType},
      );

      AnalyticsService.trackEvent('retention_campaign_sent', {
        'campaign_type': campaignType,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to send retention campaign: $e');
    }
  }

  /// Track user churn risk
  static Future<void> trackChurnRisk() async {
    try {
      final lastActive = _prefs?.getString('last_active');
      if (lastActive == null) return;

      final lastActiveTime = DateTime.parse(lastActive);
      final daysSinceActive = DateTime.now().difference(lastActiveTime).inDays;

      String churnRisk = 'low';
      if (daysSinceActive >= 7) {
        churnRisk = 'medium';
      }
      if (daysSinceActive >= 14) {
        churnRisk = 'high';
      }
      if (daysSinceActive >= 30) {
        churnRisk = 'critical';
      }

      AnalyticsService.trackEvent('churn_risk_assessed', {
        'risk_level': churnRisk,
        'days_since_active': daysSinceActive,
        'user_segment': _getUserSegment(),
      });

      // Send targeted retention campaign based on risk
      if (churnRisk == 'high' || churnRisk == 'critical') {
        await sendRetentionCampaign('inactive_user');
      }
    } catch (e) {
      debugPrint('Failed to track churn risk: $e');
    }
  }

  /// Get user segment for targeted campaigns
  static String _getUserSegment() {
    final featureUsageCount = _prefs?.getInt('total_feature_usage') ?? 0;
    final resumeCount = _prefs?.getInt('resume_count') ?? 0;

    if (resumeCount == 0) return 'new_user';
    if (resumeCount == 1 && featureUsageCount < 5) return 'exploring_user';
    if (resumeCount >= 2 && featureUsageCount >= 10) return 'active_user';
    if (resumeCount >= 5) return 'power_user';

    return 'casual_user';
  }

  /// Get retention metrics
  static Future<Map<String, dynamic>> getRetentionMetrics() async {
    try {
      final firstLaunch = _prefs?.getString('first_launch');
      final lastLaunch = _prefs?.getString('last_launch');
      final totalSessions = _prefs?.getInt('total_sessions') ?? 0;

      DateTime? firstLaunchTime;
      DateTime? lastLaunchTime;

      if (firstLaunch != null) firstLaunchTime = DateTime.parse(firstLaunch);
      if (lastLaunch != null) lastLaunchTime = DateTime.parse(lastLaunch);

      final daysSinceFirstUse = firstLaunchTime != null
          ? DateTime.now().difference(firstLaunchTime).inDays
          : 0;

      final daysSinceLastUse = lastLaunchTime != null
          ? DateTime.now().difference(lastLaunchTime).inDays
          : 0;

      return {
        'days_since_first_use': daysSinceFirstUse,
        'days_since_last_use': daysSinceLastUse,
        'total_sessions': totalSessions,
        'user_segment': _getUserSegment(),
        'churn_risk': daysSinceLastUse >= 14 ? 'high' : 'low',
      };
    } catch (e) {
      debugPrint('Failed to get retention metrics: $e');
      return {};
    }
  }

  /// Stop engagement tracking
  static void dispose() {
    _engagementTimer?.cancel();
  }
}
