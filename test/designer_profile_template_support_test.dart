import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/designer_profile_template_support.dart';
import 'package:resume_builder/features/templates/widgets/designer_profile_resume_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir =
        await Directory.systemTemp.createTemp('resume-app-designer-profile');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('factory returns the dedicated designer profile pdf template', () {
    final template = PdfTemplateFactory.getTemplate('designer_profile');
    expect(template, isA<DesignerProfileResumePdfTemplate>());
  });

  test(
      'designer profile keeps address and social links in header contact order',
      () {
    final items = DesignerProfileTemplateSupport.contactItems(
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
      items.map((item) => item.kind),
      equals([
        DesignerProfileContactKind.phone,
        DesignerProfileContactKind.email,
        DesignerProfileContactKind.address,
        DesignerProfileContactKind.linkedin,
        DesignerProfileContactKind.github,
        DesignerProfileContactKind.website,
      ]),
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
      'designer profile extracts years, references, tools, projects, and awards',
      () {
    final summaryLines = DesignerProfileTemplateSupport.summaryLines(
      'Shapes brand systems. Improves launch storytelling. Partners with product teams.',
      maxItems: null,
    );

    expect(
      summaryLines,
      equals([
        'Shapes brand systems.',
        'Improves launch storytelling.',
        'Partners with product teams.',
      ]),
    );

    final customSections = [
      CustomSection(
        id: 'design_tools_software',
        title: 'Design Tools & Software',
        items: [
          CustomSectionItem(id: 'tool-1', title: 'Figma'),
          CustomSectionItem(id: 'tool-2', title: 'Adobe Illustrator'),
        ],
      ),
      CustomSection(
        id: 'design_specializations',
        title: 'Design Specializations',
        items: [
          CustomSectionItem(id: 'spec-1', title: 'Brand Systems'),
        ],
      ),
      CustomSection(
        id: 'design_awards_recognition',
        title: 'Awards & Recognition',
        items: [
          CustomSectionItem(
            id: 'award-1',
            title: 'AIGA Merit Award',
            subtitle: 'AIGA',
            description:
                'Recognized for digital rebrand execution. https://example.com/award',
            date: DateTime(2025, 1, 1),
          ),
        ],
      ),
    ];

    final educationEntries = DesignerProfileTemplateSupport.educationEntries(
      [
        Education(
          id: 'edu-1',
          institution: 'Parsons School of Design',
          degree: 'B.Des.',
          fieldOfStudy: 'Visual Design',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2020, 1, 1),
        ),
      ],
      yearOnly: true,
    );

    expect(educationEntries, hasLength(1));
    expect(educationEntries.single.dateRange, '2016 - 2020');

    final references = DesignerProfileTemplateSupport.referenceEntries(
      [
        Reference(
          id: 'ref-1',
          name: 'Avery Brooks',
          position: 'Creative Director',
          company: 'North Studio',
          email: 'avery@northstudio.com',
          phone: '(555) 222-3333',
        ),
      ],
    );

    expect(references, hasLength(1));
    expect(references.single.roleLine, 'Creative Director  |  North Studio');
    expect(
      references.single.contactLine,
      'avery@northstudio.com  |  (555) 222-3333',
    );

    final skills = DesignerProfileTemplateSupport.skillNames(
      const <Skill>[],
      customSections: customSections,
    );

    expect(
        skills, containsAll(['Figma', 'Adobe Illustrator', 'Brand Systems']));

    final projects = DesignerProfileTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Digital Rebrand System',
          description:
              'Rolled out refreshed design direction across web and marketing '
              'surfaces. Case study: https://example.com/rebrand',
          url: 'https://dribbble.com/shots/12345',
          technologies: const ['Figma', 'Illustrator'],
        ),
      ],
      maxDetailLines: 4,
      compactLinks: true,
    );

    expect(projects, hasLength(1));
    expect(projects.single.technologyLine, 'Figma  |  Illustrator');
    expect(
      projects.single.detailLines,
      equals([
        'Rolled out refreshed design direction across web and marketing surfaces.'
      ]),
    );
    expect(
      projects.single.links,
      equals(['dribbble.com/shots/12345', 'example.com/rebrand']),
    );

    final certifications = DesignerProfileTemplateSupport.certificationEntries(
      const <Certification>[],
      customSections: customSections,
      compactLinks: true,
    );

    expect(certifications, hasLength(1));
    expect(certifications.single.name, 'AIGA Merit Award');
    expect(certifications.single.detailLines, contains('AIGA'));
    expect(certifications.single.detailLines, contains('2025'));
    expect(certifications.single.links, equals(['example.com/award']));
  });

  test('designer profile pdf generates with dedicated layout', () async {
    final now = DateTime(2026, 4, 12);
    final resume = ResumeModel(
      id: 'designer-profile-test',
      title: 'Design/Creative Resume',
      personalInfo: PersonalInfo(
        fullName: 'John Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        address: 'New York, NY',
        linkedIn: 'https://linkedin.com/in/johnsmith',
        website: 'https://johnsmith.dev',
        jobTitle: 'Creative Director',
      ),
      objective:
          'Creative design leader delivering cohesive visual systems, polished launch storytelling, and user-facing experiences across product and brand touchpoints.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'Parsons School of Design',
          degree: 'B.Des.',
          fieldOfStudy: 'Visual Design',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2020, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'North Studio',
          position: 'Creative Director',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Led brand refresh initiatives across product, web, and campaign systems.',
          achievements: const [
            'Guided cross-functional rollout for launch assets and design systems.'
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Figma'),
        Skill(id: 'skill-2', name: 'Brand Systems'),
        Skill(id: 'skill-3', name: 'Adobe Illustrator'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Digital Rebrand System',
          description:
              'Rolled out refreshed design direction across web and marketing surfaces.',
          url: 'https://example.com/rebrand',
          technologies: const ['Figma', 'Illustrator'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'Adobe Certified Professional',
          issuer: 'Adobe',
          issueDate: DateTime(2025, 1, 1),
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
      ],
      references: [
        Reference(
          id: 'ref-1',
          name: 'Avery Brooks',
          position: 'Creative Director',
          company: 'North Studio',
          email: 'avery@northstudio.com',
        ),
      ],
      customSections: [
        CustomSection(
          id: 'design_tools_software',
          title: 'Design Tools & Software',
          items: [
            CustomSectionItem(id: 'tool-1', title: 'Adobe CC'),
          ],
        ),
      ],
      templateId: 'designer_profile',
      createdAt: now,
      updatedAt: now,
    );

    final document = await DesignerProfileResumePdfTemplate().generate(
      resume,
      PdfColors.blue,
    );
    final bytes = await document.save();

    expect(bytes, isNotEmpty);
  });

  testWidgets('designer profile preview includes generic custom sections', (
    tester,
  ) async {
    final now = DateTime(2026, 4, 12);
    final resume = ResumeModel(
      id: 'designer-profile-preview-test',
      title: 'Design/Creative Resume',
      personalInfo: PersonalInfo(
        fullName: 'John Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        jobTitle: 'Creative Director',
      ),
      experience: const [],
      education: const [],
      skills: const [],
      projects: const [],
      certifications: const [],
      languages: const [],
      references: const [],
      customSections: [
        CustomSection(
          id: 'user_custom_client_highlights',
          title: 'Client Highlights',
          items: [
            CustomSectionItem(
              id: 'highlight-1',
              title: 'Fortune 500 Rollout',
              description:
                  'Led a cross-channel identity launch for a global product portfolio.',
            ),
          ],
        ),
      ],
      templateId: 'designer_profile',
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
              child: DesignerProfileResumeTemplatePreview(
                accentColor: Colors.black,
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Client Highlights'), findsOneWidget);
    expect(find.text('Fortune 500 Rollout'), findsOneWidget);
    expect(
      find.text(
        'Led a cross-channel identity launch for a global product portfolio.',
      ),
      findsOneWidget,
    );
  });
}
