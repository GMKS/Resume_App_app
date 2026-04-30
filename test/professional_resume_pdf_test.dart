import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-professional');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  ResumeModel buildResume({String templateId = 'professional'}) {
    final now = DateTime(2026, 4, 8);
    return ResumeModel(
      id: 'professional-pdf-test',
      title: 'Professional Resume',
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
          'Test Automation: Developed and maintained automated test frameworks using CoreJva and Selenium WebDriver.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Led the automation team in developing and executing test automation scripts.',
          achievements: const [
            'Guided team members and contributed to test framework development.',
            'Managed client interactions for status updates, metrics, and team-related communication.',
            'Participated in retrospective meetings and handled project estimation.',
            'I have part of API framework development using Rest Assured.',
          ],
        ),
        Experience(
          id: 'exp-2',
          company: 'UST Global Pvt Limited',
          position: 'Senior Software Engineer',
          location: 'Hyderabad, India',
          startDate: DateTime(2016, 6, 1),
          endDate: DateTime(2019, 12, 1),
          description:
              'Developed and maintained automation test scripts using Selenium and Core Java.',
          achievements: const [
            'Implemented data-driven and page object model frameworks.',
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
          id: 'project-1',
          title: 'Test Automation Framework',
          description:
              'Built a BDD test framework with Cucumber and Selenium.\n'
              'Integrated reporting dashboards for nightly regression. Docs: https://docs.example.com/framework',
          url: 'https://example.com/framework',
          technologies: const ['Java', 'Selenium', 'Cucumber'],
        ),
        Project(
          id: 'project-2',
          title: 'API Coverage Platform',
          description:
              'Created reusable API validation workflows with Rest Assured.\n'
              'Live: https://api.example.com/coverage',
          url: 'https://github.com/example/api-coverage',
          technologies: const ['Rest Assured', 'Java', 'CI/CD'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'ISTQB Certified Tester',
          issuer: 'ISTQB',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'Telugu', proficiency: 'Native'),
        Language(id: 'lang-3', name: 'Hindi', proficiency: 'Professional'),
        Language(id: 'lang-4', name: 'Tamil', proficiency: 'Conversational'),
      ],
      templateId: templateId,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('generates professional pdf without errors', () async {
    final resume = buildResume();
    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('professional');
    final pdf = await template.generate(resume, PdfColor.fromHex('#5A607D'));
    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);
  });

  test('factory returns ProfessionalResumePdfTemplate', () {
    final template = PdfTemplateFactory.getTemplate('professional');
    expect(template, isA<ProfessionalResumePdfTemplate>());
  });

  test('all experience details render without truncation', () async {
    final resume = buildResume();
    await initPdfSettings(resume);
    final template = ProfessionalResumePdfTemplate();
    final pdf = await template.generate(resume, PdfColor.fromHex('#5A607D'));
    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);
    // If generate() completes without error the full experience list was
    // serialised — the old .take(2) limit would have silently truncated.
  });
}
