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
    hiveDir = await Directory.systemTemp.createTemp('resume-app-academic');
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
    final now = DateTime(2026, 4, 8);
    return ResumeModel(
      id: 'academic-pdf-test',
      title: 'Academic Resume',
      personalInfo: PersonalInfo(
        fullName: 'John Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        address: 'New York, NY',
        linkedIn: 'https://linkedin.com/in/johnsmith',
        github: 'https://github.com/johnsmith',
        website: 'https://johnsmith.dev',
        jobTitle: 'Software Engineer',
      ),
      objective:
          'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc. Computer Science',
          fieldOfStudy: 'Software Engineering',
          startDate: DateTime(2015, 8, 1),
          endDate: DateTime(2019, 5, 1),
        ),
      ],
      skills: [
        Skill(id: 's1', name: 'Flutter'),
        Skill(id: 's2', name: 'Dart'),
        Skill(id: 's3', name: 'Firebase'),
        Skill(id: 's4', name: 'REST APIs'),
        Skill(id: 's5', name: 'Git'),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TechCorp',
          position: 'Senior Developer',
          startDate: DateTime(2021, 1, 1),
          endDate: DateTime(2025, 3, 1),
          description: 'Led team of 5 to deliver cloud-based platform.',
        ),
      ],
      projects: [
        Project(
          id: 'p1',
          title: 'Portfolio Website',
          description: 'Built a responsive portfolio and resume workflow.',
          url: 'https://johnsmith.dev/portfolio',
        ),
      ],
      certifications: [
        Certification(
          id: 'c1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
        ),
      ],
      languages: [
        Language(id: 'l1', name: 'English', proficiency: 'Professional'),
        Language(id: 'l2', name: 'German', proficiency: 'Professional'),
      ],
      templateId: 'academic',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('academic template uses dedicated pdf renderer', () {
    final template = PdfTemplateFactory.getTemplate('academic');
    expect(template, isA<AcademicResumePdfTemplate>());
  });

  test('academic template generates pdf bytes', () async {
    final resume = buildResume();
    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('academic');
    final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
