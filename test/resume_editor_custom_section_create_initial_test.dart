import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/services/storage_service.dart';

import 'support/resume_editor_custom_section_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeResumeEditorCustomSectionStorage(
      'resume-editor-custom-section-create-initial',
    );
  });

  setUp(() async {
    await resetResumeEditorCustomSectionStorage();
  });

  testWidgets('creates a user custom section with initial content',
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
      'Won the release quality award\nImproved smoke coverage',
    );

    await tester.tap(find.text('Create Section'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    final savedResume = StorageService.getResume(
      resumeEditorCustomSectionResumeId,
    );
    expect(savedResume, isNotNull);
    expect(
      savedResume!.customSections.any((section) => section.title == 'Awards'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Create Section'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);

    await disposeTestWidgetTree(tester);
  });
}