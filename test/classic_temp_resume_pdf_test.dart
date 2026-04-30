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
        await Directory.systemTemp.createTemp('resume-app-classic-temp-pdf');
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
      id: 'classic-temp-resume-pdf-test',
      title: 'Classic Temp Resume',
      personalInfo: PersonalInfo(
        fullName: 'Jordan Smith',
        email: 'jordan@example.com',
        phone: '+1 555 0100',
        address: 'Seattle, WA',
        linkedIn: 'https://linkedin.com/in/jordansmith',
        github: 'https://github.com/jordansmith',
        website: 'https://jordansmith.dev',
        jobTitle: 'Senior Software Engineer',
      ),
      objective:
          'Improves resume template fidelity and keeps preview output aligned with generated PDFs.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Bluewave Labs',
          position: 'Senior Flutter Developer',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          endDate: DateTime(2026, 1, 1),
          description:
              'Aligned preview and PDF output for resume templates without changing unrelated layouts.',
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2020, 1, 1),
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Builder',
          description:
              'Maintains preview and export parity for template layouts.',
          url: 'https://example.com/resume-builder',
        ),
      ],
      certifications: [
        Certification(id: 'cert-1', name: 'AWS Certified Developer'),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
      ],
      templateId: 'classic_temp',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the dedicated classic temp pdf template', () {
    final template = PdfTemplateFactory.getTemplate('classic_temp');
    expect(template, isA<ClassicTempResumePdfTemplate>());
  });

  test('classic temp pdf generates bytes', () async {
    final resume = buildResume();
    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('classic_temp');
    final pdf = await template.generate(resume, PdfColor.fromHex('#6189BF'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
