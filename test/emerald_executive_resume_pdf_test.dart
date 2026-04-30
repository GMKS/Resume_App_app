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
    hiveDir = await Directory.systemTemp.createTemp('resume-app-emerald-pdf');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 9);
    return ResumeModel(
      id: 'emerald-resume-pdf-test',
      title: 'Emerald Executive',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai@example.com',
        phone: '+91 99999 22226',
        address: 'Hyderabad, India',
        linkedIn: 'https://linkedin.com/in/seenai',
        website: 'https://seenai.dev',
        jobTitle: 'Senior Manager',
      ),
      objective:
          '→ Over 13 years in software testing and development with strong experience in automation and debugging → Experienced in mentoring teams through complex release cycles → Able to align test strategy with executive reporting expectations → Delivers high-quality release validation under tight timelines → Keeps summary updates visible in generated output after resume edits',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2021, 3, 1),
          description:
              'Led the automation team in developing and executing test automation scripts.',
          achievements: const [
            'Managed test scheduling and cross-team communication.',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'Holy Jesus and Mary PU College',
          degree: 'MCA',
          fieldOfStudy: 'Computer Applications',
          startDate: DateTime(2006, 1, 1),
          endDate: DateTime(2009, 1, 1),
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Selenium'),
        Skill(id: 'skill-2', name: 'Core Java'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'QA Dashboard',
          description:
              'Built dashboards that aligned operational updates with executive visibility.',
          url: 'https://example.com/qa-dashboard',
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
      templateId: 'emerald_executive',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the dedicated emerald executive pdf template', () {
    final template = PdfTemplateFactory.getTemplate('emerald_executive');
    expect(template, isA<EmeraldExecutiveResumePdfTemplate>());
  });

  test('emerald executive pdf generates bytes', () async {
    final resume = buildResume();
    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('emerald_executive');
    final pdf = await template.generate(resume, PdfColor.fromHex('#16653D'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
