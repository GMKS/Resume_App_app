import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/balanced_two_column_template_support.dart';
import 'package:resume_builder/features/templates/widgets/balanced_two_column_layout_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-balanced');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  ResumeModel buildResume({
    List<CustomSection> customSections = const <CustomSection>[],
  }) {
    final now = DateTime(2026, 4, 14);
    return ResumeModel(
      id: 'balanced-two-column',
      title: 'Balanced Two Column Layout',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/in/seenai',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com',
        jobTitle: 'Senior Manager',
      ),
      objective:
          'Leads delivery for cross-functional platform initiatives. Builds maintainable systems that balance execution speed and operational clarity. Improves visibility across engineering programs. Coaches teams through execution planning and quality programs.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'JNTU Hyderabad',
          degree: 'B.Tech',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2010, 1, 1),
          endDate: DateTime(2014, 1, 1),
        ),
        Education(
          id: 'edu-2',
          institution: 'IIM Kozhikode',
          degree: 'MBA',
          fieldOfStudy: 'Operations',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2018, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'BlueWave Labs',
          position: 'Senior Manager',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Scaled observability, delivery workflows, and platform standards across product teams.',
          achievements: const [
            'Led Kubernetes rollout and platform guardrails for engineering squads.',
            'Improved service diagnostics and release visibility across teams.',
          ],
        ),
        Experience(
          id: 'exp-2',
          company: 'Growth Systems',
          position: 'Engineering Manager',
          location: 'Bengaluru',
          startDate: DateTime(2019, 1, 1),
          endDate: DateTime(2021, 12, 1),
          description:
              'Aligned delivery, hiring, and planning rhythms with business priorities.',
          achievements: const [
            'Improved release predictability through shared operating metrics.',
          ],
        ),
        Experience(
          id: 'exp-3',
          company: 'Velocity Apps',
          position: 'Technical Lead',
          location: 'Hyderabad',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2018, 12, 1),
          description:
              'Built delivery foundations for customer-facing web and mobile products.',
          achievements: const [
            'Established reusable UI and QA workflows for distributed teams.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Program Management'),
        Skill(id: 'skill-2', name: 'Platform Strategy'),
        Skill(id: 'skill-3', name: 'Flutter'),
        Skill(id: 'skill-4', name: 'Azure'),
        Skill(id: 'skill-5', name: 'Kubernetes'),
        Skill(id: 'skill-6', name: 'Stakeholder Leadership'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Observability Platform',
          description:
              'Unified telemetry, diagnostics, and delivery scorecards. Docs: https://docs.example.com/observability',
          url: 'https://observability.example.com/platform',
          technologies: const ['Flutter', 'Azure', 'OpenTelemetry'],
        ),
        Project(
          id: 'project-2',
          title: 'Platform Scorecard',
          description:
              'Centralized reliability, quality, and release metrics for portfolio reviews.',
          url: 'https://platform.example.com/scorecard',
          technologies: const ['Power BI', 'Azure', 'Governance'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Solutions Architect',
          issuer: 'Amazon Web Services',
          issueDate: DateTime(2025, 2, 1),
          credentialUrl: 'https://example.com/cert/aws-123',
        ),
        Certification(
          id: 'cert-2',
          name: 'PMP',
          issuer: 'PMI',
          issueDate: DateTime(2024, 8, 1),
        ),
        Certification(
          id: 'cert-3',
          name: 'CKA',
          issuer: 'CNCF',
          issueDate: DateTime(2024, 5, 1),
        ),
        Certification(
          id: 'cert-4',
          name: 'Azure Architect Expert',
          issuer: 'Microsoft',
          issueDate: DateTime(2023, 11, 1),
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
        Language(id: 'lang-2', name: 'Hindi', proficiency: 'Professional'),
        Language(id: 'lang-3', name: 'Telugu', proficiency: 'Native'),
        Language(id: 'lang-4', name: 'Spanish', proficiency: 'Beginner'),
        Language(id: 'lang-5', name: 'German', proficiency: 'Beginner'),
      ],
      customSections: customSections,
      templateId: 'balanced_two_column_layout',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the dedicated balanced two column pdf template', () {
    final template =
        PdfTemplateFactory.getTemplate('balanced_two_column_layout');
    expect(template, isA<BalancedTwoColumnLayoutTemplate>());
  });

  test('balanced support keeps contacts, links, certifications, and languages',
      () {
    final contacts = BalancedTwoColumnTemplateSupport.contactItems(
      PersonalInfo(
        phone: '+91 9885623465',
        email: 'seenai007@gmail.com',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/in/seenai',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com',
      ),
      compactLinks: true,
      includeAddress: true,
    );

    expect(
      contacts.map((item) => item.label),
      equals([
        '+91 9885623465',
        'seenai007@gmail.com',
        'Hyderabad, India',
        'linkedin.com/in/seenai',
        'github.com/gmk',
        'seenaigmk.com',
      ]),
    );

    final experiences = BalancedTwoColumnTemplateSupport.experienceEntries(
      [
        Experience(
          id: 'exp-1',
          company: 'BlueWave Labs',
          position: 'Senior Manager',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Scaled observability, delivery workflows, and platform standards across product teams.',
          achievements: const [
            'Led Kubernetes rollout and platform guardrails for engineering squads.',
          ],
        ),
      ],
      maxItems: null,
      maxDetailLines: null,
      yearOnly: false,
    );

    expect(experiences, hasLength(1));
    expect(
      experiences.single.detailLines,
      containsAll([
        'Scaled observability, delivery workflows, and platform standards across product teams.',
        'Led Kubernetes rollout and platform guardrails for engineering squads.',
      ]),
    );

    final summaryExperiences =
        BalancedTwoColumnTemplateSupport.experienceEntries(
      [
        Experience(
          id: 'exp-1',
          company: 'BlueWave Labs',
          position: 'Senior Manager',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Scaled observability, delivery workflows, and platform standards across product teams.',
          achievements: const [
            'Led Kubernetes rollout and platform guardrails for engineering squads.',
          ],
        ),
      ],
      maxItems: 1,
      maxDetailLines: 0,
      yearOnly: false,
    );

    expect(summaryExperiences, hasLength(1));
    expect(summaryExperiences.single.detailLines, isEmpty);

    final projects = BalancedTwoColumnTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Observability Platform',
          description:
              'Unified telemetry, diagnostics, and delivery scorecards. Docs: https://docs.example.com/observability',
          url: 'https://observability.example.com/platform',
          technologies: const ['Flutter', 'Azure', 'OpenTelemetry'],
        ),
      ],
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );

    expect(projects, hasLength(1));
    expect(
      projects.single.detailLines,
      equals(['Unified telemetry, diagnostics, and delivery scorecards.']),
    );
    expect(
      projects.single.links,
      equals([
        'observability.example.com/platform',
        'docs.example.com/observability',
      ]),
    );

    final certifications =
        BalancedTwoColumnTemplateSupport.certificationEntries(
      [
        Certification(
          id: 'cert-1',
          name: 'AWS Solutions Architect',
          issuer: 'Amazon Web Services',
          issueDate: DateTime(2025, 2, 1),
          credentialUrl: 'https://example.com/cert/aws-123',
        ),
      ],
      maxItems: null,
      compactLinks: true,
    );

    expect(certifications, hasLength(1));
    expect(certifications.single.detailLines, contains('Amazon Web Services'));
    expect(certifications.single.detailLines, contains('Feb 2025'));
    expect(
      certifications.single.links,
      equals(['example.com/cert/aws-123']),
    );

    expect(
      BalancedTwoColumnTemplateSupport.languageLines(
        [
          Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
          Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
        ],
        maxItems: null,
      ),
      equals(['English  |  Native', 'Spanish  |  Professional']),
    );
  });

  testWidgets(
      'balanced preview shows full summary points and compact full experience details',
      (tester) async {
    final resume = buildResume();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 340,
              child: BalancedTwoColumnLayoutTemplatePreview(
                accentColor: Colors.amber,
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('EXPERIENCE SUMMARY'), findsOneWidget);
    expect(find.textContaining('github.com/gmk'), findsOneWidget);
    expect(find.textContaining('seenaigmk.com'), findsOneWidget);
    expect(find.textContaining('Hyderabad, India'), findsOneWidget);
    expect(
      find.textContaining('Coaches teams through execution planning'),
      findsOneWidget,
    );
    expect(find.textContaining('Velocity Apps'), findsOneWidget);
    expect(
      find.textContaining(
          'Improved service diagnostics and release visibility'),
      findsOneWidget,
    );
    expect(find.textContaining('Observability Platform'), findsOneWidget);
    expect(find.textContaining('observability.example.com/platform'),
        findsOneWidget);
    expect(find.textContaining('AWS Solutions Architect'), findsOneWidget);
    expect(find.textContaining('English'), findsOneWidget);
    expect(find.textContaining('+1 more roles in PDF preview'), findsNothing);
  });

  testWidgets(
      'balanced preview renders all custom section entries without repeating the heading line',
      (tester) async {
    final resume = buildResume(
      customSections: [
        CustomSection(
          id: 'user_custom_projects',
          title: 'Volunteer Work',
          order: 0,
          items: const [
            CustomSectionItem(
              id: 'vol-1',
              title: '',
              subtitle: 'Community',
              description:
                  'Resume Clinic\nReviewed student resumes\nImproved interview confidence',
            ),
            CustomSectionItem(
              id: 'vol-2',
              title: 'Mentor Circle',
              description: 'Guided early-career engineers\nRan monthly portfolio reviews',
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
              width: 240,
              height: 340,
              child: BalancedTwoColumnLayoutTemplatePreview(
                accentColor: Colors.amber,
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('VOLUNTEER WORK'), findsOneWidget);
    expect(find.text('Resume Clinic'), findsOneWidget);
    expect(find.text('Reviewed student resumes'), findsOneWidget);
    expect(find.text('Improved interview confidence'), findsOneWidget);
    expect(find.text('Mentor Circle'), findsOneWidget);
    expect(find.text('Ran monthly portfolio reviews'), findsOneWidget);
  });

  test('balanced pdf generates with dedicated flowing layout', () async {
    final resume = buildResume();
    final template =
        PdfTemplateFactory.getTemplate('balanced_two_column_layout');
    final pdf = await template.generate(resume, PdfColor.fromHex('#B28B5C'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
