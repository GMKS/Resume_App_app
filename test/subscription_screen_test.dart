import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/features/subscription/screens/subscription_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'user_country_code': 'US',
    });
  });

  testWidgets(
    'shows dummy card checkout state when payments are unconfigured in test builds',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SubscriptionScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Pay with Test Card'), findsOneWidget);
      expect(
        find.text('Local dummy checkout • No real charge'),
        findsOneWidget,
      );
      expect(
        find.text('Payments are not configured for this build yet.'),
        findsNothing,
      );
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );
}