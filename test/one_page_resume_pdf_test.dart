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
    hiveDir = await Directory.systemTemp.createTemp('resume-app-one-page-pdf');
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
      id: 'one-page-resume-pdf-test',
      title: 'One Page Resume',
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
          '→ Results-driven engineer with a record of shipping reliable web and mobile products while improving team delivery quality.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Northwind Labs',
          position: 'Senior Software Engineer',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          endDate: DateTime(2026, 1, 1),
          description:
              'Led the migration of resume preview and export flows to isolated template renderers.',
          achievements: const [
            'Reduced preview regressions by aligning template picker and PDF renderers.',
            'Improved export fidelity for dynamic contact links and right-edge alignment.',
          ],
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
          grade: 'GPA: 3.8/4.0',
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
        Skill(id: 'skill-3', name: 'PDF'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Builder',
          description:
              'Built a resume editor with live preview parity and export-ready templates. https://example.com/resume-builder',
          url: 'https://example.com/resume-builder',
          technologies: const ['Flutter', 'Riverpod', 'PDF'],
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
      templateId: 'one_page_resume',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the dedicated one page resume pdf template', () {
    final template = PdfTemplateFactory.getTemplate('one_page_resume');
    expect(template, isA<OnePageResumePdfTemplate>());
  });

  test('one page resume pdf generates bytes', () async {
    final resume = buildResume();
    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('one_page_resume');
    final pdf = await template.generate(resume, PdfColor.fromHex('#3B82F6'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
