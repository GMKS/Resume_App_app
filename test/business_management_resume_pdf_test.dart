import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/widgets/business_management_resume_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-business');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  ResumeModel buildResume(String templateId) {
    final now = DateTime(2026, 4, 8);
    return ResumeModel(
      id: 'business-management-pdf-test-$templateId',
      title: 'Business Management Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seena007@gmail.com',
        phone: '+91 9889533165',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/seenai',
        github: 'https://github.com/gmk',
        website: 'www.seenaigmk.com',
        jobTitle: 'Senior Manager',
      ),
      objective:
          'Over 13.6 years in software testing or development, with a solid understanding of testing, coding, and debugging procedures.\n'
          'Programming Skills: Proficient in programming languages such as Selenium using Core Java, Selenium, Cucumber, TestNG.\n'
          'Test Automation: Developed and maintained automated test frameworks using Core Java and Selenium WebDriver.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Led the automation team in developing and executing test automation scripts.',
          achievements: const [
            'Managed client interactions for status updates, metrics, and team-related communication.',
            'Participated in retrospective meetings and handled project estimation, scheduling, and risk management.',
            'Built API framework enhancements using Rest Assured.',
          ],
        ),
        Experience(
          id: 'exp-2',
          company: 'UST Global Pvt Limited',
          position: 'Senior Software Engineer',
          location: 'Hyderabad, India',
          startDate: DateTime(2017, 2, 1),
          endDate: DateTime(2018, 3, 1),
          description:
              'Developed and maintained automation test scripts using Selenium and Core Java.',
          achievements: const [
            'Implemented data-driven and page object model frameworks.',
            'Collaborated with Agile teams for timely delivery and high-quality software.',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'JNTU University',
          degree: 'B.Tech',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2007, 8, 1),
          endDate: DateTime(2011, 5, 1),
        ),
      ],
      skills: [
        Skill(id: 's1', name: 'Selenium'),
        Skill(id: 's2', name: 'Java'),
        Skill(id: 's3', name: 'REST APIs'),
        Skill(id: 's4', name: 'TestNG'),
        Skill(id: 's5', name: 'Cucumber'),
        Skill(id: 's6', name: 'CI/CD'),
      ],
      projects: [
        Project(
          id: 'p1',
          title: 'Automation Framework Refresh',
          description:
              'Built a maintainable BDD test framework with reusable suites and reporting.',
          url: 'https://example.com/framework',
          technologies: const ['Java', 'Selenium', 'Cucumber'],
        ),
      ],
      certifications: [
        Certification(
          id: 'c1',
          name: 'ISTQB Certified Tester',
          issuer: 'ISTQB',
          credentialId: 'CT-12345',
        ),
      ],
      languages: [
        Language(id: 'l1', name: 'English', proficiency: 'Professional'),
        Language(id: 'l2', name: 'Telugu', proficiency: 'Native'),
      ],
      customSections: [
        CustomSection(
          id: 'user_custom_speaking',
          title: 'Speaking Engagements',
          items: [
            CustomSectionItem(
              id: 'speaking-1',
              title: 'QA Leadership Summit',
              subtitle: 'Keynote',
              description:
                  'Presented a delivery governance playbook for enterprise automation programs.',
              date: DateTime(2024, 4, 1),
            ),
          ],
        ),
      ],
      templateId: templateId,
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('executive preview includes generic custom sections', (
    tester,
  ) async {
    final resume = buildResume('executive');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 520,
              child: BusinessManagementResumeTemplatePreview(
                accentColor: const Color(0xFF5A607D),
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('SPEAKING ENGAGEMENTS'), findsOneWidget);
    expect(find.text('QA Leadership Summit'), findsOneWidget);
    expect(
      find.text(
        'Presented a delivery governance playbook for enterprise automation programs.',
      ),
      findsOneWidget,
    );
  });

  test('executive uses isolated business management pdf template', () async {
    final resume = buildResume('executive');
    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('executive');

    expect(template, isA<BusinessManagementResumePdfTemplate>());

    final pdf = await template.generate(resume, PdfColor.fromHex('#5A607D'));
    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);
  });
}
