import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/elegant_gold_layout_template_support.dart';
import 'package:resume_builder/features/templates/widgets/elegant_gold_layout_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-elegant-gold');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 14);
    return ResumeModel(
      id: 'elegant-gold-layout',
      title: 'Human Resources Resume',
      personalInfo: PersonalInfo(
        fullName: 'John Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        address: 'New York, NY',
        linkedIn: 'https://linkedin.com/in/johnsmith',
        github: 'https://github.com/johnsmith',
        website: 'https://johnsmith.dev',
        jobTitle: 'Software Engineer',
      ),
      objective:
          'Results-driven professional with expertise in delivering high-quality business systems with modern, user-focused workflows. Builds reliable internal tools and collaborates across product, design, and operations. Partners with HR leadership to turn policy and process goals into measurable employee experience gains.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2018, 1, 1),
          endDate: DateTime(2022, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TechCorp',
          position: 'Senior Developer',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Led UI, services, and automation improvements for shared platforms.',
          achievements: const [
            'Reduced lead time by 24% via role-specific workflows.',
          ],
        ),
        Experience(
          id: 'exp-2',
          company: 'Creative Systems',
          position: 'Flutter Developer',
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(2021, 12, 1),
          description:
              'Implemented reusable UI components for live user dashboards.',
          achievements: const [
            'Built product features and collaborated with design and QA on reliable releases.',
          ],
        ),
        Experience(
          id: 'exp-3',
          company: 'People Ops Cloud',
          position: 'HRIS Engineer',
          startDate: DateTime(2018, 1, 1),
          endDate: DateTime(2019, 12, 1),
          description:
              'Improved workforce reporting and onboarding automation for regional operations.',
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
        Skill(id: 'skill-3', name: 'Figma'),
        Skill(id: 'skill-4', name: 'REST APIs'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'HR Analytics Portal',
          description:
              'Unified workforce insights and employee lifecycle reporting. Operational dashboard used by HR partners and recruiters. Docs: https://docs.example.com/hr-portal',
          url: 'https://portal.example.com/hr',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'SHRM-CP',
          issuer: 'SHRM',
          issueDate: DateTime(2025, 3, 1),
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'German', proficiency: 'Professional'),
      ],
      customSections: [
        CustomSection(
          id: 'hr_talent_management',
          title: 'Talent Management Achievements',
          items: [
            CustomSectionItem(
              id: 'item-1',
              title: 'Retention Program',
              subtitle: 'Global rollout',
              description:
                  'Improved retention across distributed teams through structured career frameworks.\nBuilt manager coaching playbooks for follow-up reviews.',
              date: DateTime(2025, 1, 1),
            ),
            CustomSectionItem(
              id: 'item-2',
              title: 'Workforce Planning Council',
              subtitle: 'Executive Steering Group',
              description:
                  'Established monthly planning checkpoints for hiring and mobility decisions.',
              date: DateTime(2024, 5, 1),
            ),
          ],
        ),
      ],
      templateId: 'elegant_gold_layout',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the dedicated elegant gold pdf template', () {
    final template = PdfTemplateFactory.getTemplate('elegant_gold_layout');
    expect(template, isA<ElegantGoldLayoutTemplate>());
  });

  test('support normalizes hr sections, contacts, and project links', () {
    final normalized =
        ElegantGoldTemplateSupport.normalizedResume(buildResume());
    expect(normalized, isNotNull);
    expect(
      normalized!.customSections
          .any((section) => section.id == 'hr_certifications'),
      isTrue,
    );

    final contacts = ElegantGoldTemplateSupport.contactItems(
      normalized.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    expect(
      contacts.map((item) => item.label),
      equals([
        '(555) 123-4567',
        'john.smith@email.com',
        'linkedin.com/in/johnsmith',
        'github.com/johnsmith',
        'johnsmith.dev',
        'New York, NY',
      ]),
    );

    final summaryLines = ElegantGoldTemplateSupport.summaryLines(
      normalized.objective,
      maxItems: null,
    );
    expect(summaryLines.length, greaterThanOrEqualTo(3));
    expect(
      summaryLines.any(
        (line) => line.contains('Partners with HR leadership'),
      ),
      isTrue,
    );

    final projectEntries = ElegantGoldTemplateSupport.projectEntries(
      normalized.projects,
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    expect(projectEntries, hasLength(1));
    expect(projectEntries.single.detailLines.length, greaterThanOrEqualTo(2));
    expect(
      projectEntries.single.detailLines,
      contains('Operational dashboard used by HR partners and recruiters.'),
    );
    expect(projectEntries.single.links, contains('portal.example.com/hr'));
    expect(projectEntries.single.links, contains('docs.example.com/hr-portal'));

    final customSectionEntries =
        ElegantGoldTemplateSupport.customSectionEntries(
      normalized.customSections,
      maxItems: null,
    );
    expect(customSectionEntries, isNotEmpty);
    expect(
      customSectionEntries.first.itemLines.any(
        (line) => line.contains('Retention Program'),
      ),
      isTrue,
    );
    expect(
      customSectionEntries.first.itemLines,
      contains('Built manager coaching playbooks for follow-up reviews.'),
    );
    expect(
      customSectionEntries.first.itemLines,
      contains('Workforce Planning Council  |  Executive Steering Group  |  May 2024'),
    );
  });

  testWidgets(
      'preview stays screenshot-faithful, includes projects, and omits certifications',
      (tester) async {
    final resume = buildResume();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 340,
              child: ElegantGoldLayoutTemplatePreview(
                accentColor: Colors.amber,
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('CONTACT'), findsOneWidget);
    expect(find.text('ABOUT ME'), findsOneWidget);
    expect(find.text('EXPERIENCE'), findsOneWidget);
    expect(find.text('EDUCATION'), findsOneWidget);
    expect(find.text('SKILLS'), findsOneWidget);
    expect(find.text('LANGUAGES'), findsOneWidget);
    expect(find.textContaining('github.com/johnsmith'), findsOneWidget);
    expect(find.textContaining('johnsmith.dev'), findsOneWidget);
    expect(find.textContaining('New York, NY'), findsOneWidget);
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(find.textContaining('HR Analytics Portal'), findsOneWidget);
    expect(find.text('CERTIFICATIONS'), findsNothing);
  });

  test('pdf generates with dedicated elegant gold layout', () async {
    final resume = buildResume();
    final template = PdfTemplateFactory.getTemplate('elegant_gold_layout');
    final pdf = await template.generate(resume, PdfColor.fromHex('#C8A96A'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
