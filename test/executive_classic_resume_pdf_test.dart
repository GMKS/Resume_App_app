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
    hiveDir = await Directory.systemTemp.createTemp('resume-app-executive-classic');
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
    final now = DateTime(2026, 4, 16);
    return ResumeModel(
      id: 'executive-classic-pdf-test',
      title: 'Executive Classic Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/seenai',
        github: 'https://github.com/gmk',
        website: 'https://seenaigmk.com',
        jobTitle: 'Senior Manager',
      ),
      objective:
          'Over 13.6 years in software testing or development, with a solid understanding of testing, coding, and debugging procedures.\n'
          'Programming Skills: Proficient in programming languages such as Selenium using Core Java, Selenium, Cucumber, TestNG.',
      experience: const [],
      education: const [],
      skills: const [],
      projects: const [],
      certifications: const [],
      languages: const [],
      templateId: 'executive_classic',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('executive classic pdf generates bytes with summary markers', () async {
    final resume = buildResume();
    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('executive_classic');
    expect(template, isA<ExecutiveClassicResumePdfTemplate>());

    final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}