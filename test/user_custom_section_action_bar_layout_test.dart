import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/features/editor/widgets/user_custom_section_action_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add Entry action stays fully visible on narrow screens',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              child: UserCustomSectionActionBar(
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final labelFinder = find.text('Add Entry');
    expect(labelFinder, findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(
      find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
      findsOneWidget,
    );

    final labelRect = tester.getRect(labelFinder);
    expect(labelRect.left, greaterThanOrEqualTo(0));
    expect(labelRect.right, lessThanOrEqualTo(500));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}