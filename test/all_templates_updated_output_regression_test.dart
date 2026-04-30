import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/resume_import_service.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/services/preview_pdf_service.dart';
import 'package:resume_builder/features/templates/screens/template_selection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  const allTemplateIds = <String>[
    'modern',
    'classic',
    'creative',
    'minimal',
    'developer',
    'two_column',
    'elegant_pink',
    'blue_gray',
    'professional',
    'executive',
    'startup',
    'academic',
    'sales',
    'modern_aesthetic',
    'classic2',
    'education_resume',
    'modern_resume',
    'professional_accountant',
    'one_page_resume',
    'classic_temp',
    'emerald_executive',
    'cool_blue',
    'multicolor',
    'entry_level',
    'ats_optimized_clean',
    'ats_standard_format',
    'ats_friendly_modern',
    'executive_classic',
    'classic_ats',
    'infographic',
    'vertical_timeline',
    'corporate_template',
    'mono_nova',
    'slate_arc',
    'editorial_frame',
    'graphite_column',
    'rosewood_panel',
    'designer_profile',
    'modern_edge',
    'minimal_clean',
    'minimal_clean_ats',
    'professional_tone',
    'elegant_design',
    'creative_professional',
    'bluewave_tech',
    'balanced_two_column_layout',
    'elegant_gold_layout',
    'corporate_navy',
    'forest_edge',
    'forest_edge_classic',
  ];

  const previewAccentColor = Color(0xFF6366F1);

  String normalizeText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }

  String? textFromWidget(Widget widget) {
    if (widget is Text) {
      return widget.data ?? widget.textSpan?.toPlainText();
    }
    if (widget is RichText) {
      return widget.text.toPlainText();
    }
    if (widget is SelectableText) {
      return widget.data ?? widget.textSpan?.toPlainText();
    }
    return null;
  }

  bool renderedTextContains(WidgetTester tester, String expected) {
    final normalizedExpected = normalizeText(expected);
    final finder = find.byWidgetPredicate((widget) {
      final text = textFromWidget(widget);
      return text != null && normalizeText(text).contains(normalizedExpected);
    });
    return finder.evaluate().isNotEmpty;
  }

  ResumeModel buildUpdatedResume(String templateId) {
    final now = DateTime(2026, 4, 25);
    return ResumeModel(
      id: 'updated-output-$templateId',
      title: 'Updated Output Resume',
      personalInfo: PersonalInfo(
        fullName: 'Avery Regression',
        email: 'avery.regression@example.com',
        phone: '+1 555 410 2201',
        address: 'Austin, TX',
        linkedIn: 'linkedin.com/in/avery-regression',
        github: 'github.com/avery-regression',
        website: 'averyregression.dev',
        jobTitle: 'Principal QA Architect',
      ),
      objective:
          'Designs resilient resume delivery systems across preview, export, and automation workflows while keeping template fidelity stable under frequent data updates.',
      education: <Education>[
        Education(
          id: 'edu-$templateId',
          institution: 'North Ridge University',
          degree: 'M.S.',
          fieldOfStudy: 'Software Quality Engineering',
          startDate: DateTime(2016, 8, 1),
          endDate: DateTime(2018, 5, 1),
          grade: 'Honors',
          description:
              'Focused on test architecture, automation design, and product quality systems.',
        ),
      ],
      experience: <Experience>[
        Experience(
          id: 'exp-1-$templateId',
          company: 'Northstar Delivery Labs',
          position: 'Lead Automation Strategist',
          location: 'Remote',
          startDate: DateTime(2021, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Owns automation architecture, cross-template regressions, and release verification for resume rendering flows.',
          achievements: const <String>[
            'Stabilized preview and export fidelity across fifty template variants.',
            'Introduced regression gates for updated resume data before release approval.',
          ],
        ),
        Experience(
          id: 'exp-2-$templateId',
          company: 'Signal Works Studio',
          position: 'Senior Test Engineer',
          location: 'Austin, TX',
          startDate: DateTime(2018, 6, 1),
          endDate: DateTime(2020, 12, 1),
          description:
              'Built automation suites for UI, document export, and workflow reliability.',
          achievements: const <String>[
            'Created resilient smoke coverage for resume previews and generated documents.',
          ],
        ),
      ],
      skills: <Skill>[
        Skill(id: 'skill-1-$templateId', name: 'Flutter'),
        Skill(id: 'skill-2-$templateId', name: 'Test Automation'),
        Skill(id: 'skill-3-$templateId', name: 'PDF Validation'),
        Skill(id: 'skill-4-$templateId', name: 'Selenium'),
        Skill(id: 'skill-5-$templateId', name: 'CI Quality Gates'),
      ],
      projects: <Project>[
        Project(
          id: 'project-$templateId',
          title: 'Signal Resume Platform',
          description:
              'Real-time resume editing platform with template previews, export validation, and release-quality regression coverage.',
          technologies: const <String>['Flutter', 'Hive', 'Firebase'],
          url: 'https://example.com/signal-resume-platform',
        ),
      ],
      certifications: <Certification>[
        Certification(
          id: 'cert-$templateId',
          name: 'Cross-Template Quality Certification',
          issuer: 'Quality Guild',
          issueDate: DateTime(2024, 4, 1),
          credentialId: 'CRED-7781',
          credentialUrl: 'https://example.com/certifications/CRED-7781',
        ),
      ],
      languages: <Language>[
        Language(id: 'lang-1-$templateId', name: 'English', proficiency: 'Native'),
        Language(id: 'lang-2-$templateId', name: 'Spanish', proficiency: 'Professional'),
      ],
      templateId: templateId,
      createdAt: now,
      updatedAt: now,
      colorScheme: 0,
    );
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    hiveDir = await Directory.systemTemp.createTemp(
      'resume-app-all-template-updated-output',
    );
    Hive.init(hiveDir.path);
    await StorageService.init();
    await PreviewPdfService.generateBytes(buildUpdatedResume('modern'));
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await StorageService.deleteAllResumes();
  });

  for (final templateId in allTemplateIds) {
    testWidgets(
      'renders $templateId preview thumbnail with updated resume data',
      (tester) async {
        final resume = buildUpdatedResume(templateId);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TemplatePreviewThumbnail(
                  templateId: templateId,
                  accentColor: previewAccentColor,
                  width: 140,
                  showShadow: false,
                  resume: resume,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(find.byType(TemplatePreviewThumbnail), findsOneWidget,
            reason: templateId);
        expect(
          renderedTextContains(tester, resume.personalInfo.fullName),
          isTrue,
          reason: '$templateId should show the updated name in preview output',
        );
        expect(tester.takeException(), isNull, reason: templateId);
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );

    test(
      'generates $templateId pdf output with updated markers',
      () async {
        final resume = buildUpdatedResume(templateId);
        final bytes = await PreviewPdfService.generateBytes(resume);
        final extractedText = ResumeImportService.extractTextFromBytes(
          bytes: bytes,
          fileName: '$templateId.pdf',
        );
        final normalizedText = normalizeText(extractedText);

        expect(bytes, isNotEmpty, reason: templateId);
        expect(
          normalizedText,
          contains(normalizeText(resume.personalInfo.fullName)),
          reason: '$templateId should keep the updated name in PDF output',
        );

        final includesUpdatedBodyData = normalizedText.contains(
              normalizeText(resume.experience.first.company),
            ) ||
            normalizedText.contains(
              normalizeText(resume.projects.first.title),
            ) ||
            normalizedText.contains(
              normalizeText(resume.certifications.first.name),
            );

        expect(
          includesUpdatedBodyData,
          isTrue,
          reason:
              '$templateId should keep updated section content beyond the header',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }
}