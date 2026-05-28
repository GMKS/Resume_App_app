import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';

import 'support/resume_editor_custom_section_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeResumeEditorCustomSectionStorage(
      'resume-editor-reorder-custom-section-titles',
    );
  });

  setUp(() async {
    await resetResumeEditorCustomSectionStorage();
    await StorageService.prefs.setString('subscription_plan', 'premium');
    await StorageService.prefs.setString(
      'subscription_expiry',
      DateTime(2030, 1, 1).millisecondsSinceEpoch.toString(),
    );

    final seededResume = buildResumeEditorCustomSectionResume().copyWith(
      customSections: [
        CustomSection(id: 'awards', title: 'Awards', order: 0),
        CustomSection(id: 'publications', title: 'Publications', order: 1),
        CustomSection(
          id: 'user_custom_open_source',
          title: 'Open Source Contributions',
          order: 2,
        ),
      ],
    );
    await StorageService.resumeBox.put(
      resumeEditorCustomSectionResumeId,
      seededResume,
    );
    await StorageService.prefs.setString(
      'section_order_$resumeEditorCustomSectionResumeId',
      'personal,summary,Awards,publications,Open Source Contributions,experience,education,skills,projects,certifications,languages',
    );
  });

  testWidgets('reorder sheet shows stored custom section titles', (
    tester,
  ) async {
    await tester.pumpWidget(buildResumeEditorCustomSectionTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.scrollUntilVisible(
      find.text('Reorder'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Reorder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Reorder Sections'), findsOneWidget);
    expect(find.text('Awards'), findsWidgets);
    expect(find.text('Publications'), findsWidgets);
    expect(find.text('Open Source Contributions'), findsWidgets);
    expect(find.text('Custom Section'), findsNothing);

    await disposeTestWidgetTree(tester);
  });
}
