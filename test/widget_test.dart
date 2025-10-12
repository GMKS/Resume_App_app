//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder_app/main.dart';

void main() {
  testWidgets('Resume Builder home screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that key UI elements are present.
    expect(find.text('Resume Builder'), findsOneWidget);
    expect(find.text('Create Resume'), findsOneWidget);
    expect(find.text('View Saved Resumes'), findsOneWidget);
  });
}
