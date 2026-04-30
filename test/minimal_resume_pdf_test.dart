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
    hiveDir = await Directory.systemTemp.createTemp('resume-app-minimal-pdf');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('generates minimal resume pdf with warm beige background shell',
      () async {
    final now = DateTime(2026, 4, 7);
    final resume = ResumeModel(
      id: 'minimal-resume-pdf-test',
      title: 'Minimal Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/seenai',
        github: 'https://github.com/gmk',
        website: 'www.seenaigmk.com',
        jobTitle: 'Senior manager',
      ),
      objective:
          'Over 13.6 years in software testing or development, with a solid understanding of testing, coding, and debugging procedures. Programming skills include Selenium using Core Java, Selenium, Cucumber, and TestNG. Test automation includes designing suites across UI, services, and data workflows while collaborating with developers to improve quality and delivery.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          achievements: const [
            'Led the automation team in developing and executing test automation scripts.',
            'Guided team members and contributed to test framework development.',
          ],
        ),
        Experience(
          id: 'exp-2',
          company: 'UST Global Pvt Limited',
          position: 'Senior Software Engineer',
          location: 'Hyderabad, India',
          startDate: DateTime(2017, 2, 1),
          endDate: DateTime(2018, 3, 1),
          achievements: const [
            'Developed and maintained automation test scripts using Selenium and Core Java.',
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
        Skill(id: 'skill-3', name: 'Cucumber'),
        Skill(id: 'skill-4', name: 'TestNG'),
        Skill(id: 'skill-5', name: 'SQL'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Builder',
          description:
              'Built a preview and export workflow that keeps template picker and rendered output aligned.',
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
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
      ],
      templateId: 'minimal',
      createdAt: now,
      updatedAt: now,
    );

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('minimal');
    final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
