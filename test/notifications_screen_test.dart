import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/features/profile/screens/notifications_screen.dart';

/// Helper: wraps [NotificationsScreen] in a minimal [MaterialApp] so widgets
/// that rely on [MediaQuery], [Theme], etc. work correctly in tests.
Widget buildTestApp() {
  return const MaterialApp(
    home: NotificationsScreen(),
  );
}

void main() {
  // Give SharedPreferences a clean, empty store before every test.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // Group 1 – Structural rendering
  // ---------------------------------------------------------------------------
  group('NotificationsScreen – structure', () {
    testWidgets('renders AppBar with title "Notifications"',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('renders all three section headers',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.text('ACTIVITY'), findsOneWidget);
      expect(find.text('ACCOUNT'), findsOneWidget);
    });

    testWidgets('renders all six notification toggle titles',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Email Notifications'), findsOneWidget);
      expect(find.text('Resume Reminders'), findsOneWidget);
      expect(find.text('Job Alerts'), findsOneWidget);
      expect(find.text('Subscription Alerts'), findsOneWidget);
      expect(find.text('Tips & Updates'), findsOneWidget);
    });

    testWidgets('renders subtitle text for each toggle',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Receive alerts on your device'), findsOneWidget);
      expect(find.text('Receive updates to your email'), findsOneWidget);
      expect(find.text('Reminders to update your resume'), findsOneWidget);
      expect(find.text('New job opportunities matching your profile'),
          findsOneWidget);
      expect(find.text('Renewal reminders and plan updates'), findsOneWidget);
      expect(find.text('App tips, news and feature announcements'),
          findsOneWidget);
    });

    testWidgets('renders exactly six Switch widgets',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Switch.adaptive resolves to Switch on non-Apple platforms in tests.
      expect(find.byType(Switch), findsNWidgets(6));
    });
  });

  // ---------------------------------------------------------------------------
  // Group 2 – Default toggle states (using default SharedPreferences values)
  // ---------------------------------------------------------------------------
  group('NotificationsScreen – default toggle states', () {
    Future<List<bool>> getSwitchValues(WidgetTester tester) {
      return Future.value(
        tester
            .widgetList<Switch>(find.byType(Switch))
            .map((s) => s.value)
            .toList(),
      );
    }

    testWidgets('Push Notifications is ON by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final switches = await getSwitchValues(tester);
      // First switch = Push Notifications
      expect(switches[0], isTrue);
    });

    testWidgets('Email Notifications is OFF by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final switches = await getSwitchValues(tester);
      // Second switch = Email Notifications
      expect(switches[1], isFalse);
    });

    testWidgets('Resume Reminders is ON by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final switches = await getSwitchValues(tester);
      // Third switch = Resume Reminders
      expect(switches[2], isTrue);
    });

    testWidgets('Job Alerts is ON by default', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final switches = await getSwitchValues(tester);
      // Fourth switch = Job Alerts
      expect(switches[3], isTrue);
    });

    testWidgets('Subscription Alerts is ON by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final switches = await getSwitchValues(tester);
      // Fifth switch = Subscription Alerts
      expect(switches[4], isTrue);
    });

    testWidgets('Tips & Updates is OFF by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final switches = await getSwitchValues(tester);
      // Sixth switch = Tips & Updates
      expect(switches[5], isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Group 3 – Toggling each switch
  // ---------------------------------------------------------------------------
  group('NotificationsScreen – toggle interaction', () {
    testWidgets('tapping Push Notifications turns it OFF',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Find the switch next to "Push Notifications" and tap it.
      final pushSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Push Notifications'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Switch),
      );

      expect(tester.widget<Switch>(pushSwitch).value, isTrue);
      await tester.tap(pushSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(pushSwitch).value, isFalse);
    });

    testWidgets('tapping Email Notifications turns it ON',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final emailSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Email Notifications'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Switch),
      );

      expect(tester.widget<Switch>(emailSwitch).value, isFalse);
      await tester.tap(emailSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(emailSwitch).value, isTrue);
    });

    testWidgets('tapping Resume Reminders turns it OFF',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final reminderSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Resume Reminders'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Switch),
      );

      expect(tester.widget<Switch>(reminderSwitch).value, isTrue);
      await tester.tap(reminderSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(reminderSwitch).value, isFalse);
    });

    testWidgets('tapping Job Alerts turns it OFF', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final jobSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Job Alerts'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Switch),
      );

      expect(tester.widget<Switch>(jobSwitch).value, isTrue);
      await tester.tap(jobSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(jobSwitch).value, isFalse);
    });

    testWidgets('tapping Subscription Alerts turns it OFF',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final subSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Subscription Alerts'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Switch),
      );

      expect(tester.widget<Switch>(subSwitch).value, isTrue);
      await tester.tap(subSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(subSwitch).value, isFalse);
    });

    testWidgets('tapping Tips & Updates turns it ON',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final tipsSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Tips & Updates'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Switch),
      );

      // Scroll the item into view before tapping.
      await tester.ensureVisible(tipsSwitch);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(tipsSwitch).value, isFalse);
      await tester.tap(tipsSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(tipsSwitch).value, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Group 4 – SharedPreferences persistence
  // ---------------------------------------------------------------------------
  group('NotificationsScreen – SharedPreferences persistence', () {
    testWidgets('toggling Push Notifications saves "notif_push" to prefs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final pushSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Push Notifications'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Switch),
      );

      await tester.tap(pushSwitch); // true → false
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notif_push'), isFalse);
    });

    testWidgets('toggling Email Notifications saves "notif_email" to prefs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final emailSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Email Notifications'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Switch),
      );

      await tester.tap(emailSwitch); // false → true
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notif_email'), isTrue);
    });

    testWidgets(
        'toggling Resume Reminders saves "notif_resume_reminders" to prefs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final reminderSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Resume Reminders'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Switch),
      );

      await tester.tap(reminderSwitch); // true → false
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notif_resume_reminders'), isFalse);
    });

    testWidgets('toggling Job Alerts saves "notif_job_alerts" to prefs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final jobSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Job Alerts'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Switch),
      );

      await tester.tap(jobSwitch); // true → false
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notif_job_alerts'), isFalse);
    });

    testWidgets(
        'toggling Subscription Alerts saves "notif_subscription" to prefs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final subSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Subscription Alerts'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Switch),
      );

      await tester.tap(subSwitch); // true → false
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notif_subscription'), isFalse);
    });

    testWidgets('toggling Tips & Updates saves "notif_tips" to prefs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final tipsSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Tips & Updates'),
          matching: find.byType(Card),
        ),
        matching: find.byType(Switch),
      );

      // Scroll the item into view before tapping.
      await tester.ensureVisible(tipsSwitch);
      await tester.pumpAndSettle();

      await tester.tap(tipsSwitch); // false → true
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notif_tips'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Group 5 – Reads persisted values on startup
  // ---------------------------------------------------------------------------
  group('NotificationsScreen – loads saved prefs on init', () {
    testWidgets('loads all six values from SharedPreferences',
        (WidgetTester tester) async {
      // Pre-seed opposite of defaults.
      SharedPreferences.setMockInitialValues({
        'notif_push': false,
        'notif_email': true,
        'notif_resume_reminders': false,
        'notif_job_alerts': false,
        'notif_subscription': false,
        'notif_tips': true,
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();

      expect(switches[0].value, isFalse,
          reason: 'Push Notifications should be OFF');
      expect(switches[1].value, isTrue,
          reason: 'Email Notifications should be ON');
      expect(switches[2].value, isFalse,
          reason: 'Resume Reminders should be OFF');
      expect(switches[3].value, isFalse, reason: 'Job Alerts should be OFF');
      expect(switches[4].value, isFalse,
          reason: 'Subscription Alerts should be OFF');
      expect(switches[5].value, isTrue, reason: 'Tips & Updates should be ON');
    });
  });
}
