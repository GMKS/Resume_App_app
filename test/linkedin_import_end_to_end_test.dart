import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/ai/screens/linkedin_import_screen.dart';
import 'package:resume_builder/features/templates/forest_edge_template_support.dart';
import 'package:resume_builder/features/templates/widgets/forest_edge_resume_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  const pastedProfile = '''
seenai07@yahoo.co
9916750642 (Home)
www.linkedin.com/in/seenai-gmk-74da9519
Seenai GMK
Automation Lead
Hyderabad, India

PROFESSIONAL SUMMARY
Line one about automation leadership.
Line two about Selenium and manual testing.
Line three about framework ownership.
Line four about release quality.
Line five about collaboration.
Line six about delivery metrics.
Line seven about integration testing.
Line eight about regression coverage.
Line nine about mentoring teams.
Line ten about continuous improvement.

WORK EXPERIENCE
Automation Lead Jan 2021 - Present
Tata Consultancy Services | Hyderabad, India
Description:
Led automation initiatives across enterprise releases.
''';

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    hiveDir = await Directory.systemTemp.createTemp(
      'resume-app-linkedin-import-e2e',
    );
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  setUp(() async {
    await StorageService.deleteAllResumes();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('LinkedIn import preserves identity through save/load for Forest Edge',
      () async {
    final resume = debugBuildLinkedInImportedResume(
      pastedProfile,
      id: 'linkedin-import-e2e',
      now: DateTime(2026, 4, 15),
      templateId: 'forest_edge',
    );

    await StorageService.saveResume(resume);
    final storedResume = StorageService.getResume('linkedin-import-e2e');

    expect(storedResume, isNotNull);

    final loadedResume = storedResume!;
    final contacts = ForestEdgeTemplateSupport.contactItems(
      loadedResume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    final summaryLines = ForestEdgeTemplateSupport.summaryLines(
      loadedResume.objective,
      maxItems: null,
    );

    expect(loadedResume.personalInfo.fullName, 'Seenai GMK');
    expect(loadedResume.personalInfo.jobTitle, 'Automation Lead');
    expect(loadedResume.personalInfo.email, 'seenai07@yahoo.co');
    expect(loadedResume.personalInfo.phone, contains('9916750642'));
    expect(
      loadedResume.personalInfo.linkedIn,
      contains('linkedin.com/in/seenai-gmk-74da9519'),
    );
    expect(ForestEdgeTemplateSupport.displayName(loadedResume), 'Seenai GMK');
    expect(
      ForestEdgeTemplateSupport.displayTitle(loadedResume),
      'Automation Lead',
    );
    expect(
      contacts.map((item) => item.label),
      containsAll(<String>[
        '9916750642 (Home)',
        'Hyderabad, India',
        'seenai07@yahoo.co',
        'linkedin.com/in/seenai-gmk-74da9519',
      ]),
    );
    expect(summaryLines.length, greaterThanOrEqualTo(10));
    expect(summaryLines.first, 'Line one about automation leadership.');
    expect(summaryLines, contains('Line ten about continuous improvement.'));
  });

  testWidgets('Forest Edge preview renders imported header fields',
      (tester) async {
    final resume = debugBuildLinkedInImportedResume(
      pastedProfile,
      templateId: 'forest_edge',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 340,
              child: ForestEdgeResumeTemplatePreview(
                accentColor: Colors.green,
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('SEENAI GMK'), findsOneWidget);
    expect(find.text('AUTOMATION LEAD'), findsOneWidget);
    expect(find.textContaining('9916750642'), findsOneWidget);
    expect(find.text('YOUR NAME'), findsNothing);
    expect(find.text('PROFESSIONAL TITLE'), findsNothing);
  });
}