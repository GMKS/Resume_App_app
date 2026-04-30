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
    hiveDir = await Directory.systemTemp.createTemp('resume-app-pink-rose');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('generates pink rose modern pdf with github and project links',
      () async {
    final now = DateTime(2026, 4, 7);
    final resume = ResumeModel(
      id: 'pink-rose-modern-pdf-test',
      title: 'Pink Rose Modern Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/in/seenai',
        github: 'https://github.com/seenai',
        website: 'https://www.seenaigmk.com',
        jobTitle: 'Senior manager',
      ),
      objective:
          'Over 13 years in software testing and delivery with strong experience across quality engineering, automation strategy, debugging, and release readiness. Builds practical frameworks, documents clear test cases, and improves delivery confidence through collaboration with engineering teams.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Led the automation team in developing and executing test automation scripts while coordinating status updates, metrics, and stakeholder communication.',
          achievements: const [
            'Guided team members and contributed to framework development for UI and services.',
            'Managed client interactions for status reporting, estimation, scheduling, and risk management.',
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
              'Developed and maintained automation scripts using Selenium and Core Java and supported timely Agile delivery.',
          achievements: const [
            'Implemented data-driven and page-object model frameworks.',
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
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'React'),
        Skill(id: 'skill-2', name: 'JavaScript'),
        Skill(id: 'skill-3', name: 'Communication'),
        Skill(id: 'skill-4', name: 'SQL'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Builder',
          description:
              'Built a preview and export workflow that keeps template-specific output aligned with edited resume content, including longer summaries and visible project links.',
          url: 'https://example.com/resume-builder',
          technologies: const ['Flutter', 'Firebase', 'Hive'],
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
        Language(id: 'lang-2', name: 'German', proficiency: 'Professional'),
      ],
      templateId: 'elegant_pink',
      createdAt: now,
      updatedAt: now,
    );

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('elegant_pink');
    final pdf = await template.generate(resume, PdfColor.fromHex('#D87093'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
