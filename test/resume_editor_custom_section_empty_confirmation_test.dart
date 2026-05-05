import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/services/storage_service.dart';

import 'support/resume_editor_custom_section_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeResumeEditorCustomSectionStorage(
      'resume-editor-custom-section-empty-confirmation',
    );
  });

  setUp(() async {
    await resetResumeEditorCustomSectionStorage();
  });

  testWidgets('creates an empty user custom section after confirmation',
      (tester) async {
    await tester.pumpWidget(buildResumeEditorCustomSectionTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await openAddCustomSectionSheet(tester);

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'Publications');
    await tester.tap(find.text('Create Section'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Save Empty Section?'), findsOneWidget);
    await tester.tap(find.text('Save Section'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    final savedResume = StorageService.getResume(
      resumeEditorCustomSectionResumeId,
    );
    expect(savedResume, isNotNull);
    final savedSection = savedResume!.customSections.firstWhere(
      (section) => section.title == 'Publications',
    );
    expect(savedSection.items, isEmpty);
    expect(tester.takeException(), isNull);
    expect(find.text('Save Empty Section?'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);

    await disposeTestWidgetTree(tester);
  });
}