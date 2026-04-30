import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/minimal_clean_template_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-minimal-clean');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('factory returns the dedicated minimal clean pdf template', () {
    final template = PdfTemplateFactory.getTemplate('minimal_clean');
    expect(template, isA<MinimalCleanResumePdfTemplate>());
  });

  test('minimal clean contact items keep address and social links', () {
    final items = MinimalCleanTemplateSupport.contactItems(
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

  test('minimal clean keeps summary points, project links, and languages', () {
    final summaryLines = MinimalCleanTemplateSupport.summaryLines(
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

    final projects = MinimalCleanTemplateSupport.projectEntries(
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

    final languages = MinimalCleanTemplateSupport.languageLines(
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

  test('minimal clean pdf generates with dedicated layout', () async {
    final now = DateTime(2026, 4, 13);
    final resume = ResumeModel(
      id: 'minimal-clean-test',
      title: 'Minimal Clean Resume',
      personalInfo: PersonalInfo(
        fullName: 'John Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        address: 'New York, NY',
        linkedIn: 'https://linkedin.com/in/johnsmith',
        github: 'https://github.com/johnsmith',
        website: 'https://johnsmith.dev',
        jobTitle: 'Senior Product Designer',
      ),
      objective:
          'Builds polished products. Improves launch quality. Aligns teams around clear delivery.',
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
              'Led product-system updates and shipped cleaner onboarding flows.',
          achievements: const [
            'Improved launch readiness across research, design, and engineering handoff.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
        Skill(id: 'skill-3', name: 'Firebase'),
        Skill(id: 'skill-4', name: 'Figma'),
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
          name: 'Google UX Design Certificate',
          issuer: 'Google',
          issueDate: DateTime(2025, 1, 1),
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'French', proficiency: 'Conversational'),
      ],
      templateId: 'minimal_clean',
      createdAt: now,
      updatedAt: now,
    );

    final document = await MinimalCleanResumePdfTemplate().generate(
      resume,
      PdfColors.blue,
    );
    final bytes = await document.save();

    expect(bytes, isNotEmpty);
  });
}
