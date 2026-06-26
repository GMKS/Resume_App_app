import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/features/profile/screens/video_tutorials_screen.dart';

void main() {
  testWidgets('shows the app guide walkthroughs and opens a guide sheet',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppGuideScreen(),
      ),
    );

    expect(find.text('App Guide'), findsWidgets);
    expect(find.text('Feature walkthroughs'), findsOneWidget);
    expect(find.text('Create a New Resume'), findsOneWidget);

    await tester.tap(find.text('Create a New Resume'));
    await tester.pumpAndSettle();

    expect(find.text('Step-by-step path'), findsOneWidget);
    expect(find.text('Create Resume (+)'), findsOneWidget);
    expect(
      find.text(
        'Use this flow when you want to build a fresh resume from scratch.',
      ),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Use AI Assistant'),
      260,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('Use AI Assistant'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Upgrade to Pro & Manage Subscription'),
      500,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upgrade to Pro & Manage Subscription'), findsOneWidget);
    expect(find.text('Settings & Support'), findsOneWidget);
  });
}
