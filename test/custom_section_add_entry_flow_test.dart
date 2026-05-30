import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/services/storage_service.dart';

import 'support/resume_editor_custom_section_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeResumeEditorCustomSectionStorage(
      'custom-section-add-entry-flow',
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

  testWidgets('user custom section add entry sheet opens without exception', (
    tester,
  ) async {
    await tester.pumpWidget(buildResumeEditorCustomSectionTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await openAddCustomSectionSheet(tester);

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'Personal Details');
    await tester.enterText(
      textFields.at(1),
      'Current role highlights',
    );

    await tester.tap(find.text('Create Section'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    final savedResume = StorageService.getResume(
      resumeEditorCustomSectionResumeId,
    );
    final createdSectionId = savedResume!.customSections
        .firstWhere((section) => section.title == 'Personal Details')
        .id;

    await tester.pumpWidget(
      buildResumeEditorCustomSectionTestApp(
        initialLocation:
            '/editor/$resumeEditorCustomSectionResumeId/user-custom/$createdSectionId',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.widgetWithText(FilledButton, 'Add Entry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Description / Content'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await disposeTestWidgetTree(tester);
  });
}
