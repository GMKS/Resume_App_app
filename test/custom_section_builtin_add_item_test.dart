import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/services/storage_service.dart';

import 'support/resume_editor_custom_section_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeResumeEditorCustomSectionStorage(
      'custom-section-built-in-item',
    );
  });

  setUp(() async {
    await resetResumeEditorCustomSectionStorage();
    await StorageService.prefs.setString('subscription_plan', 'premium');
    await StorageService.prefs.setString(
      'subscription_expiry',
      DateTime(2030, 1, 1).millisecondsSinceEpoch.toString(),
    );
  });

  testWidgets('built-in custom section add item sheet opens without exception',
      (tester) async {
    await tester.pumpWidget(
      buildResumeEditorCustomSectionTestApp(
        initialLocation:
            '/editor/$resumeEditorCustomSectionResumeId/custom/startup_achievements',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final addFirstItemButton = find.text('Add First Item');
    if (addFirstItemButton.evaluate().isNotEmpty) {
      await tester.tap(addFirstItemButton);
    } else {
      await tester.tap(find.byType(FloatingActionButton));
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await disposeTestWidgetTree(tester);
  });
}