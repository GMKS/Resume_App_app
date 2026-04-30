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
    hiveDir = await Directory.systemTemp.createTemp('resume-app-flexcolor');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('generates flexcolor sidebar pdf with aligned sidebar layout', () async {
    final now = DateTime(2026, 4, 7);
    final resume = ResumeModel(
      id: 'flexcolor-sidebar-pdf-test',
      title: 'FlexColor Sidebar Resume',
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
          'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products. Builds maintainable systems and clear user-facing experiences.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TechCorp',
          position: 'Senior Developer',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Led a team of 5 to deliver cloud-based platform features and improve release quality across multiple squads.',
          achievements: const [
            'Improved deployment confidence by standardizing reusable UI and API validation workflows.',
          ],
        ),
      ],
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
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
        Skill(id: 'skill-3', name: 'Firebase'),
        Skill(id: 'skill-4', name: 'REST APIs'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Portfolio Website',
          description:
              'Built a responsive portfolio and resume workflow with consistent template previews and export output.',
          url: 'https://johnsmith.dev/portfolio',
          technologies: const ['Flutter', 'Firebase'],
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
      templateId: 'blue_gray',
      createdAt: now,
      updatedAt: now,
    );

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('blue_gray');
    final pdf = await template.generate(resume, PdfColor.fromHex('#475569'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
