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
    hiveDir =
        await Directory.systemTemp.createTemp('resume-app-ats-standard-pdf');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('generates ats standard format pdf matching the full section set',
      () async {
    final now = DateTime(2026, 4, 6);
    final resume = ResumeModel(
      id: 'ats-standard-format-pdf-test',
      title: 'ATS Standard Resume',
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
          'Over 13.6 years in software testing and development, with strong experience in testing, coding, debugging, and automation delivery across UI, service, and data workflows.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Managed automation delivery across UI, API, and regression workflows while coordinating status updates with stakeholders.',
          achievements: const [
            'Led the automation team in developing and executing test automation scripts.',
            'Guided team members and contributed to framework development.',
            'Managed client interactions for status updates, metrics, and communication.',
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
              'Built and maintained Selenium automation coverage for browser and service workflows.',
          achievements: const [
            'Developed and maintained automation test scripts using Selenium and Core Java.',
            'Implemented data-driven and page object model frameworks.',
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
        Skill(id: 'skill-1', name: 'React'),
        Skill(id: 'skill-2', name: 'JavaScript'),
        Skill(id: 'skill-3', name: 'Communication'),
        Skill(id: 'skill-4', name: 'Project Management'),
        Skill(id: 'skill-5', name: 'SQL'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Cigna Health Care',
          description:
              'Built analytics and automation workflows for health-claims operations and reporting.',
          url: 'https://example.com/cigna-health-care',
        ),
        Project(
          id: 'project-2',
          title: 'One Pulse Application',
          description:
              'Created workflow automation and project tracking updates for distributed delivery teams.',
          url: 'https://example.com/one-pulse',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Cloud Practitioner',
          issuer: 'Amazon',
        ),
        Certification(
          id: 'cert-2',
          name: 'PMP Certification',
          issuer: 'PMI',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'German', proficiency: 'Professional'),
      ],
      templateId: 'ats_standard_format',
      createdAt: now,
      updatedAt: now,
    );

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('ats_standard_format');
    final pdf = await template.generate(resume, PdfColor.fromHex('#5569E8'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
