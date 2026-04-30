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
    hiveDir = await Directory.systemTemp.createTemp('resume-app-two-column');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('generates two column pdf with full experience and project sections',
      () async {
    final now = DateTime(2026, 4, 7);
    final resume = ResumeModel(
      id: 'two-column-pdf-test',
      title: 'Two Column Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/in/seenai',
        github: 'https://github.com/seenai',
        website: 'https://www.seenaigmk.com',
        jobTitle: 'Senior Test Automation Engineer',
      ),
      objective:
          'Automation leader with deep experience in UI, API, and data workflow validation across enterprise products. Builds maintainable frameworks, improves release confidence, and partners with engineering teams to reduce regressions at scale.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Led automation strategy for large QA programs spanning UI, services, and integrations while coordinating test planning with developers and analysts.',
          achievements: const [
            'Designed reusable Selenium and API automation workflows that reduced regression execution time.',
            'Guided team members on framework standards, reporting, and defect triage.',
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
              'Built automation coverage for web and service layers, supported release validation, and improved defect isolation using structured debugging.',
          achievements: const [
            'Maintained automation suites in Selenium, Core Java, and TestNG.',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'Holy Jesus and Mary PG College',
          degree: 'MCA',
          fieldOfStudy: 'Computer Applications',
          startDate: DateTime(2006, 6, 1),
          endDate: DateTime(2009, 4, 1),
          location: 'Hyderabad, India',
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Selenium'),
        Skill(id: 'skill-2', name: 'Core Java'),
        Skill(id: 'skill-3', name: 'Cucumber'),
        Skill(id: 'skill-4', name: 'TestNG'),
        Skill(id: 'skill-5', name: 'SQL'),
        Skill(id: 'skill-6', name: 'REST Assured'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Builder',
          description:
              'Built a preview and export workflow that keeps picker previews and rendered resume output aligned across template-specific renderers while preserving updated summary, experience, and project content.',
          url: 'https://example.com/resume-builder',
          technologies: const ['Flutter', 'Hive', 'Firebase'],
        ),
        Project(
          id: 'project-2',
          title: 'Automation Reporting Hub',
          description:
              'Created a reporting dashboard that consolidated execution outcomes, highlighted release risks, and linked detailed evidence for distributed QA teams.',
          url: 'https://example.com/automation-reporting',
          technologies: const ['Dart', 'REST APIs', 'Charts'],
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
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
      ],
      templateId: 'two_column',
      createdAt: now,
      updatedAt: now,
    );

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('two_column');
    final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
