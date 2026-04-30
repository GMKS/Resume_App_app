import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/modern_edge_template_support.dart';
import 'package:resume_builder/features/templates/widgets/modern_edge_resume_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-modern-edge');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  ResumeModel buildResume({List<CustomSection> customSections = const []}) {
    final now = DateTime(2026, 4, 13);
    return ResumeModel(
      id: 'modern-edge-test',
      title: 'Modern Edge Photo Resume',
      personalInfo: PersonalInfo(
        fullName: 'John Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        address: 'New York, NY',
        linkedIn: 'https://linkedin.com/in/johnsmith',
        github: 'https://github.com/johnsmith',
        website: 'https://johnsmith.dev',
        jobTitle: 'Product Designer',
      ),
      objective:
          'Builds polished products. Improves launch quality. Aligns design with engineering.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Des.',
          fieldOfStudy: 'Product Design',
          startDate: DateTime(2015, 1, 1),
          endDate: DateTime(2019, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Studio North',
          position: 'Senior Product Designer',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Led design systems across web and mobile. Improved launch readiness across product squads.',
          achievements: const [
            'Reduced handoff churn by aligning product, design, and engineering reviews.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
        Skill(id: 'skill-3', name: 'Firebase'),
        Skill(id: 'skill-4', name: 'Figma'),
        Skill(id: 'skill-5', name: 'Analytics'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Platform Refresh',
          description:
              'Delivered a cleaner onboarding flow. Improved retention dashboards. Docs: https://example.com/platform',
          url: 'https://platform.example.com',
          technologies: const ['Flutter', 'Firebase'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'Google UX Design Certificate',
          issuer: 'Google',
          issueDate: DateTime(2025, 1, 1),
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'French', proficiency: 'Conversational'),
      ],
      customSections: customSections,
      templateId: 'modern_edge',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the dedicated modern edge pdf template', () {
    final template = PdfTemplateFactory.getTemplate('modern_edge');
    expect(template, isA<ModernEdgeResumePdfTemplate>());
  });

  test('modern edge contact items keep address and social links', () {
    final items = ModernEdgeTemplateSupport.contactItems(
      PersonalInfo(
        phone: '(555) 123-4567',
        email: 'john.smith@email.com',
        address: 'New York, NY',
        linkedIn: 'https://linkedin.com/in/johnsmith/',
        github: 'https://github.com/johnsmith',
        website: 'https://johnsmith.dev/',
      ),
      compactLinks: true,
      includeAddress: true,
    );

    expect(
      items.map((item) => item.label),
      equals([
        '(555) 123-4567',
        'john.smith@email.com',
        'New York, NY',
        'linkedin.com/in/johnsmith',
        'github.com/johnsmith',
        'johnsmith.dev',
      ]),
    );
  });

  test(
      'modern edge extracts all summary points, project links, skills, education, and languages',
      () {
    final summaryLines = ModernEdgeTemplateSupport.summaryLines(
      'Builds polished products. Improves launch quality. Aligns design with engineering.',
      maxItems: null,
    );

    expect(
      summaryLines,
      equals([
        'Builds polished products.',
        'Improves launch quality.',
        'Aligns design with engineering.',
      ]),
    );

    final projects = ModernEdgeTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Platform Refresh',
          description:
              'Delivered a cleaner onboarding flow. Improved retention dashboards. Docs: https://example.com/platform',
          url: 'https://platform.example.com',
          technologies: const ['Flutter', 'Firebase'],
        ),
      ],
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );

    expect(projects, hasLength(1));
    expect(
      projects.single.detailLines,
      equals([
        'Delivered a cleaner onboarding flow.',
        'Improved retention dashboards.',
      ]),
    );
    expect(
      projects.single.links,
      equals(['platform.example.com', 'example.com/platform']),
    );
    expect(projects.single.technologyLine, 'Flutter  |  Firebase');

    final skills = ModernEdgeTemplateSupport.skillNames([
      Skill(id: 'skill-1', name: 'Flutter'),
      Skill(id: 'skill-2', name: 'Dart'),
      Skill(id: 'skill-3', name: 'Firebase'),
      Skill(id: 'skill-4', name: 'Figma'),
      Skill(id: 'skill-5', name: 'Analytics'),
    ]);

    expect(
      skills,
      equals(['Flutter', 'Dart', 'Firebase', 'Figma', 'Analytics']),
    );

    final educationEntries = ModernEdgeTemplateSupport.educationEntries(
      [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2015, 1, 1),
          endDate: DateTime(2019, 1, 1),
        ),
        Education(
          id: 'edu-2',
          institution: 'Design Institute',
          degree: 'Certificate',
          fieldOfStudy: 'UX Strategy',
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(2021, 1, 1),
        ),
      ],
      maxItems: null,
      yearOnly: true,
    );

    expect(educationEntries, hasLength(2));
    expect(educationEntries.first.dateRange, '2015 - 2019');
    expect(educationEntries.last.dateRange, '2020 - 2021');

    final languages = ModernEdgeTemplateSupport.languageLines(
      [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'French', proficiency: 'Conversational'),
      ],
      maxItems: null,
    );

    expect(
      languages,
      equals(['English  |  Professional', 'French  |  Conversational']),
    );
  });

  test('modern edge pdf generates with dedicated layout', () async {
    final resume = buildResume(
      customSections: [
        CustomSection(
          id: 'leadership_highlights',
          title: 'Leadership Highlights',
          items: [
            CustomSectionItem(
              id: 'leadership-1',
              title: 'Cross-Team Delivery',
              subtitle: 'Program Leadership',
              description:
                  'Led audit readiness and stakeholder reporting across release trains.',
            ),
          ],
        ),
      ],
    );

    await StorageService.prefs.setString(
      'section_order_${resume.id}',
      'summary,leadership_highlights,experience,projects,certifications,languages',
    );

    final document = await ModernEdgeResumePdfTemplate().generate(
      resume,
      PdfColors.blue,
    );
    final bytes = await document.save();

    expect(bytes, isNotEmpty);
  });

  test('modern edge pdf generates with multiple legacy and user custom sections', () async {
    final resume = buildResume(
      customSections: [
        CustomSection(
          id: 'leadership_highlights',
          title: 'Leadership Highlights',
          order: 1,
          items: [
            CustomSectionItem(
              id: 'leadership-1',
              title: 'Cross-Team Delivery',
              subtitle: 'Program Leadership',
              description:
                  'Led audit readiness across release trains.\nAligned delivery updates with executives.',
              date: DateTime(2025, 4, 1),
            ),
          ],
        ),
        CustomSection(
          id: 'user_custom_open_source',
          title: 'Open Source Contributions',
          order: 2,
          items: [
            CustomSectionItem(
              id: 'oss-1',
              title: 'Design Tokens Package',
              description:
                  'Maintained shared Flutter theming primitives for internal apps.',
            ),
            CustomSectionItem(
              id: 'oss-2',
              title: 'Accessibility Audit Toolkit',
              description:
                  'Documented reusable checks for preview and export workflows.',
            ),
          ],
        ),
      ],
    );

    final document = await ModernEdgeResumePdfTemplate().generate(
      resume,
      PdfColors.blue,
    );
    final bytes = await document.save();

    expect(bytes, isNotEmpty);
  });

  testWidgets('modern edge preview includes custom sections', (tester) async {
    final resume = buildResume(
      customSections: [
        CustomSection(
          id: 'leadership_highlights',
          title: 'Leadership Highlights',
          items: [
            CustomSectionItem(
              id: 'leadership-1',
              title: 'Cross-Team Delivery',
              subtitle: 'Program Leadership',
              description:
                  'Led audit readiness and stakeholder reporting across release trains.',
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 520,
              child: ModernEdgeResumeTemplatePreview(
                accentColor: const Color(ModernEdgeTemplateSupport.accentHex),
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Leadership Highlights'), findsOneWidget);
    expect(find.text('Cross-Team Delivery'), findsOneWidget);
    expect(
      find.text(
        'Led audit readiness and stakeholder reporting across release trains.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('modern edge preview includes all custom section data', (
    tester,
  ) async {
    final resume = buildResume(
      customSections: [
        CustomSection(
          id: 'leadership_highlights',
          title: 'Leadership Highlights',
          items: [
            CustomSectionItem(
              id: 'leadership-1',
              title: 'Cross-Team Delivery',
              subtitle: 'Program Leadership',
              description:
                  'Led audit readiness across release trains.\nAligned delivery updates with executives.',
              date: DateTime(2025, 4, 1),
            ),
          ],
        ),
        CustomSection(
          id: 'user_custom_open_source',
          title: 'Open Source Contributions',
          items: [
            CustomSectionItem(
              id: 'oss-1',
              title: 'Design Tokens Package',
              description:
                  'Maintained shared Flutter theming primitives for internal apps.',
            ),
            CustomSectionItem(
              id: 'oss-2',
              title: 'Accessibility Audit Toolkit',
              description:
                  'Documented reusable checks for preview and export workflows.',
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 520,
              child: ModernEdgeResumeTemplatePreview(
                accentColor: const Color(ModernEdgeTemplateSupport.accentHex),
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Leadership Highlights'), findsOneWidget);
    expect(find.text('Cross-Team Delivery'), findsOneWidget);
    expect(find.text('Program Leadership  |  Apr 2025'), findsOneWidget);
    expect(find.text('Led audit readiness across release trains.'), findsOneWidget);
    expect(
      find.text('Aligned delivery updates with executives.'),
      findsOneWidget,
    );
    expect(find.text('Open Source Contributions'), findsOneWidget);
    expect(find.text('Design Tokens Package'), findsOneWidget);
    expect(find.text('Accessibility Audit Toolkit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('modern edge compact preview keeps custom sections visible', (
    tester,
  ) async {
    final resume = buildResume(
      customSections: [
        CustomSection(
          id: 'leadership_highlights',
          title: 'Leadership Highlights',
          items: [
            CustomSectionItem(
              id: 'leadership-1',
              title: 'Cross-Team Delivery',
              description:
                  'Led audit readiness and stakeholder reporting across release trains.',
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 254,
              child: ModernEdgeResumeTemplatePreview(
                accentColor: const Color(ModernEdgeTemplateSupport.accentHex),
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Leadership Highlights'), findsOneWidget);
    expect(find.text('Cross-Team Delivery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
