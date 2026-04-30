import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/minimal_clean_ats_template_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp(
      'resume-app-minimal-clean-ats',
    );
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('factory returns the dedicated minimal clean ats pdf template', () {
    final template = PdfTemplateFactory.getTemplate('minimal_clean_ats');
    expect(template, isA<MinimalCleanAtsResumePdfTemplate>());
  });

  test('minimal clean ats contact items keep social links and address', () {
    final items = MinimalCleanAtsTemplateSupport.contactItems(
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
      'minimal clean ats keeps summary points, project links, skills, certifications, and languages',
      () {
    final summaryLines = MinimalCleanAtsTemplateSupport.summaryLines(
      'Builds polished products. Improves launch quality. Aligns teams around clear delivery.',
      maxItems: null,
    );

    expect(
      summaryLines,
      equals([
        'Builds polished products.',
        'Improves launch quality.',
        'Aligns teams around clear delivery.',
      ]),
    );

    final projects = MinimalCleanAtsTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Platform Refresh',
          description:
              'Delivered a cleaner onboarding flow. Docs: https://example.com/platform. Demo: https://platform.example.com',
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
      equals(['Delivered a cleaner onboarding flow.']),
    );
    expect(
      projects.single.links,
      equals(['platform.example.com', 'example.com/platform']),
    );

    expect(
      MinimalCleanAtsTemplateSupport.skillNames([
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
        Skill(id: 'skill-3', name: 'Firebase'),
      ]),
      equals(['Flutter', 'Dart', 'Firebase']),
    );

    final certifications = MinimalCleanAtsTemplateSupport.certificationEntries(
      [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
          issueDate: DateTime(2025, 1, 1),
          credentialUrl: 'https://example.com/cert/aws-123',
        ),
      ],
      maxItems: null,
      compactLinks: true,
    );

    expect(certifications, hasLength(1));
    expect(certifications.single.name, 'AWS Certified Developer');
    expect(certifications.single.links, equals(['example.com/cert/aws-123']));

    expect(
      MinimalCleanAtsTemplateSupport.languageLines(
        [
          Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
          Language(id: 'lang-2', name: 'German', proficiency: 'Conversational'),
        ],
        maxItems: null,
      ),
      equals(['English  |  Professional', 'German  |  Conversational']),
    );
  });

  test('minimal clean ats pdf generates with dedicated layout', () async {
    final now = DateTime(2026, 4, 13);
    final resume = ResumeModel(
      id: 'minimal-clean-ats-test',
      title: 'Minimal Clean ATS',
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
          'Builds polished products. Improves launch quality. Aligns teams around clear delivery.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2019, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TechCorp',
          position: 'Senior Developer',
          location: 'Remote',
          startDate: DateTime(2021, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Led a cross-functional team to deliver a cloud-based platform.',
          achievements: const [
            'Improved release readiness across delivery, QA, and engineering.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
        Skill(id: 'skill-3', name: 'Firebase'),
        Skill(id: 'skill-4', name: 'REST APIs'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Platform Refresh',
          description:
              'Delivered a cleaner onboarding flow. Docs: https://example.com/platform',
          url: 'https://platform.example.com',
          technologies: const ['Flutter', 'Firebase'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
          issueDate: DateTime(2025, 1, 1),
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'German', proficiency: 'Conversational'),
      ],
      templateId: 'minimal_clean_ats',
      createdAt: now,
      updatedAt: now,
    );

    final document = await MinimalCleanAtsResumePdfTemplate().generate(
      resume,
      PdfColors.red,
    );
    final bytes = await document.save();

    expect(bytes, isNotEmpty);
  });
}
