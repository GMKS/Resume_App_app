import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/services/storage_service.dart';

import 'support/resume_editor_custom_section_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeResumeEditorCustomSectionStorage(
      'resume-editor-custom-section-dedupe',
    );
  });

  setUp(() async {
    await resetResumeEditorCustomSectionStorage();
  });

  testWidgets('rapid repeated create taps only create one section',
      (tester) async {
    await tester.pumpWidget(buildResumeEditorCustomSectionTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await openAddCustomSectionSheet(tester);

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'Awards');
    await tester.enterText(
      textFields.at(1),
      'Recognized for release quality leadership',
    );

    final createButton = find.text('Create Section');
    await tester.tap(createButton);
    await tester.tap(createButton, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.takeException(), isNull);
    expect(
      find.text('A custom section with this title already exists'),
      findsNothing,
    );

    final savedResume = StorageService.getResume(
      resumeEditorCustomSectionResumeId,
    );
    expect(savedResume, isNotNull);
    final matchingSections = savedResume!.customSections
        .where((section) => section.title == 'Awards')
        .toList(growable: false);
    expect(matchingSections.length, 1);

    await disposeTestWidgetTree(tester);
  });
}