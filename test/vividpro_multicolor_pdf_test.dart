import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/widgets/multicolor_resume_template_preview.dart';
import 'package:resume_builder/features/templates/widgets/vividpro_resume_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir =
        await Directory.systemTemp.createTemp('resume-app-vividpro-multicolor');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  ResumeModel buildResume(
    String templateId, {
    List<CustomSection> customSections = const [],
  }) {
    final now = DateTime(2026, 4, 9);
    return ResumeModel(
      id: 'vividpro-multicolor-$templateId',
      title: 'Template Alignment Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'linkedin.com/in/seenai',
        github: 'github.com/gmk',
        website: 'www.seenaigmk.com',
        jobTitle: 'Senior Manager',
      ),
      objective:
          'Over 13.6 years in software testing and development, with strong experience in testing, coding, debugging, and automation delivery across UI, service, and data workflows. Programming skills include Selenium, Core Java, Cucumber, and TestNG with practical leadership across release cycles.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Managed automation delivery across UI, API, and regression workflows while coordinating stakeholder updates, metrics, and communication for distributed teams.',
          achievements: const [
            'Led the automation team in developing and executing test automation scripts.',
            'Guided team members and contributed to framework development.',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'Holy Jesus and Mary PG College',
          degree: 'MCA',
          fieldOfStudy: 'Computer Applications',
          startDate: DateTime(2006, 2, 1),
          endDate: DateTime(2009, 2, 1),
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Selenium'),
        Skill(id: 'skill-2', name: 'Core Java'),
        Skill(id: 'skill-3', name: 'REST APIs'),
        Skill(id: 'skill-4', name: 'TestNG'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Builder',
          description:
              'Built a preview and export workflow that keeps template-specific output aligned with edited resume content and right-edge section guides.',
          url: 'https://example.com/resume-builder',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
      ],
      customSections: customSections,
      templateId: templateId,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('cool blue pdf generates bytes after body alignment changes', () async {
    final resume = buildResume(
      'cool_blue',
      customSections: [
        CustomSection(
          id: 'user_custom_awards',
          title: 'Awards',
          items: [
            CustomSectionItem(
              id: 'award-1',
              title: 'QA Excellence Award',
              description: 'Recognized for end-to-end automation delivery.',
            ),
          ],
        ),
      ],
    );

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('cool_blue');
    final pdf = await template.generate(resume, PdfColor.fromHex('#0EA5E9'));
    final bytes = await pdf.save();

    expect(template, isA<CoolBlueTemplate>());
    expect(bytes, isNotEmpty);
  });

  test('multicolor pdf generates bytes after right-edge alignment changes',
      () async {
    final resume = buildResume(
      'multicolor',
      customSections: [
        CustomSection(
          id: 'user_custom_publications',
          title: 'Publications',
          items: [
            CustomSectionItem(
              id: 'publication-1',
              title: 'Testing at Scale',
              description: 'Documented durable automation patterns for UI and API coverage.',
            ),
          ],
        ),
      ],
    );

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('multicolor');
    final pdf = await template.generate(resume, PdfColor.fromHex('#7C3AED'));
    final bytes = await pdf.save();

    expect(template, isA<MulticolorTemplate>());
    expect(bytes, isNotEmpty);
  });

  testWidgets('vividpro preview renders custom sections', (tester) async {
    final resume = buildResume(
      'cool_blue',
      customSections: [
        CustomSection(
          id: 'user_custom_awards',
          title: 'Awards',
          items: [
            CustomSectionItem(
              id: 'award-1',
              title: 'QA Excellence Award',
              description: 'Recognized for end-to-end automation delivery.',
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox.shrink(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 254,
              child: VividProResumeTemplatePreview(
                accentColor: const Color(0xFF0EA5E9),
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Awards'), findsOneWidget);
    expect(find.text('QA Excellence Award'), findsOneWidget);
    expect(
      find.text('Recognized for end-to-end automation delivery.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('multicolor preview renders custom sections', (tester) async {
    final resume = buildResume(
      'multicolor',
      customSections: [
        CustomSection(
          id: 'user_custom_publications',
          title: 'Publications',
          items: [
            CustomSectionItem(
              id: 'publication-1',
              title: 'Testing at Scale',
              description: 'Documented durable automation patterns for UI and API coverage.',
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
              child: MulticolorResumeTemplatePreview(
                accentColor: const Color(0xFF7C3AED),
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Publications'), findsOneWidget);
    expect(find.text('Testing at Scale'), findsOneWidget);
    expect(
      find.text('Documented durable automation patterns for UI and API coverage.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}