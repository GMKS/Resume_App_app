import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/rosewood_panel_template_support.dart';
import 'package:resume_builder/features/templates/widgets/rosewood_panel_resume_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir =
        await Directory.systemTemp.createTemp('resume-app-rosewood-panel');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('factory returns the dedicated rosewood panel pdf template', () {
    final template = PdfTemplateFactory.getTemplate('rosewood_panel');
    expect(template, isA<RosewoodPanelResumePdfTemplate>());
  });

  test('rosewood panel contact items keep social links', () {
    final items = RosewoodPanelTemplateSupport.contactItems(
      PersonalInfo(
        phone: '(555) 123-4567',
        address: 'New York, NY',
        email: 'john.smith@email.com',
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
        'New York, NY',
        'john.smith@email.com',
        'linkedin.com/in/johnsmith',
        'github.com/johnsmith',
        'johnsmith.dev',
      ]),
    );
  });

  test(
      'rosewood panel extracts summary lines, awards, experience details, and project links',
      () {
    final summaryLines = RosewoodPanelTemplateSupport.summaryLines(
      'Built resilient launches. Improved release quality. Partnered with clients.',
      maxItems: null,
    );

    expect(
      summaryLines,
      equals([
        'Built resilient launches.',
        'Improved release quality.',
        'Partnered with clients.',
      ]),
    );

    final awards = RosewoodPanelTemplateSupport.awardEntries(
      [
        CustomSection(
          id: 'section-1',
          title: 'Awards',
          items: [
            CustomSectionItem(
              id: 'item-1',
              title: 'Recognition',
            ),
          ],
        ),
      ],
    );

    expect(awards, hasLength(1));
    expect(awards.single.title, 'Recognition');

    final experiences = RosewoodPanelTemplateSupport.experienceEntries(
      [
        Experience(
          id: 'experience-1',
          company: 'Tech Corp',
          position: 'Senior Developer',
          startDate: DateTime(2021, 1, 1),
          description: 'Built release automation.\nImproved test coverage.',
          achievements: const ['Reduced incident volume by 40%.'],
        ),
      ],
      maxDetailLines: null,
    );

    expect(experiences, hasLength(1));
    expect(
      experiences.single.detailLines,
      equals([
        'Built release automation.',
        'Improved test coverage.',
        'Reduced incident volume by 40%.',
      ]),
    );

    final projects = RosewoodPanelTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Portfolio Website',
          description:
              'Built a client showcase.\nImproved conversion flow.\nDemo: https://example.com/portfolio',
          url: 'https://example.com/portfolio',
        ),
      ],
      maxDetailLines: null,
      compactLinks: true,
    );

    expect(projects, hasLength(1));
    expect(projects.single.title, 'Portfolio Website');
    expect(
      projects.single.detailLines,
      equals(['Built a client showcase.', 'Improved conversion flow.']),
    );
    expect(projects.single.links, equals(['example.com/portfolio']));
  });

  test('rosewood panel pdf generates with dedicated layout', () async {
    final now = DateTime(2026, 4, 12);
    final resume = ResumeModel(
      id: 'rosewood-panel-test',
      title: 'Rosewood Panel Resume',
      personalInfo: PersonalInfo(
        fullName: 'John Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        address: 'New York, NY',
        linkedIn: 'https://linkedin.com/in/johnsmith',
        website: 'https://johnsmith.dev',
        jobTitle: 'Software Engineer',
      ),
      objective:
          'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2015, 1, 1),
          endDate: DateTime(2019, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tech Corp',
          position: 'Senior Developer',
          startDate: DateTime(2021, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Led team of 5 to deliver cloud-based platform.\nImproved deployment reliability across releases.',
          achievements: const [
            'Reduced operational regressions with stronger pre-release coverage.',
          ],
        ),
      ],
      skills: List.generate(
        12,
        (index) => Skill(
          id: 'skill-$index',
          name: 'Skill ${index + 1}',
        ),
      ),
      projects: [
        Project(
          id: 'project-1',
          title: 'Portfolio Website',
          description:
              'Built a client showcase.\nImproved conversion flow.\nDemo: https://example.com/portfolio',
          url: 'https://example.com/portfolio',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
          issueDate: DateTime(2024, 1, 1),
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
      ],
      customSections: [
        CustomSection(
          id: 'section-1',
          title: 'Awards',
          items: [
            CustomSectionItem(
              id: 'item-1',
              title: 'Recognition',
            ),
          ],
        ),
        CustomSection(
          id: 'section-2',
          title: 'Community Leadership',
          items: [
            CustomSectionItem(
              id: 'item-2',
              title: 'Engineering Guild Lead',
              subtitle: 'Internal Program',
              description: 'Hosted monthly architecture review workshops.',
              date: DateTime(2025, 6, 1),
            ),
          ],
        ),
      ],
      templateId: 'rosewood_panel',
      createdAt: now,
      updatedAt: now,
    );

    final document = await RosewoodPanelResumePdfTemplate().generate(
      resume,
      PdfColors.blue,
    );
    final bytes = await document.save();

    expect(bytes, isNotEmpty);
  });

  testWidgets('rosewood panel preview includes non-award custom sections', (
    tester,
  ) async {
    final now = DateTime(2026, 4, 12);
    final resume = ResumeModel(
      id: 'rosewood-panel-preview-test',
      title: 'Rosewood Panel Resume',
      personalInfo: PersonalInfo(
        fullName: 'John Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        jobTitle: 'Software Engineer',
      ),
      experience: const [],
      education: const [],
      skills: const [],
      projects: const [],
      certifications: const [],
      languages: const [],
      customSections: [
        CustomSection(
          id: 'section-2',
          title: 'Community Leadership',
          items: [
            CustomSectionItem(
              id: 'item-2',
              title: 'Engineering Guild Lead',
              description: 'Hosted monthly architecture review workshops.',
            ),
          ],
        ),
      ],
      templateId: 'rosewood_panel',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 520,
              child: RosewoodPanelResumeTemplatePreview(
                accentColor: Colors.blueGrey,
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('COMMUNITY LEADERSHIP'), findsOneWidget);
    expect(find.text('Engineering Guild Lead'), findsOneWidget);
    expect(
      find.text('Hosted monthly architecture review workshops.'),
      findsOneWidget,
    );
  });
}
