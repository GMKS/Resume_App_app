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
    hiveDir = await Directory.systemTemp.createTemp('resume-app-startup-pdf');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('generates startup pdf with startup-specific layout data', () async {
    final now = DateTime(2026, 4, 1);
    final resume = ResumeModel(
      id: 'startup-pdf-test',
      title: 'Startup Resume',
      personalInfo: PersonalInfo(
        fullName: 'John Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        address: 'New York, NY',
        linkedIn: 'linkedin.com/in/johnsmith',
        github: 'github.com/johnsmith',
        website: 'johnsmith.dev',
        jobTitle: 'Software Engineer',
      ),
      objective:
          'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TechCorp',
          position: 'Senior Developer',
          startDate: DateTime(2021, 1, 1),
          endDate: DateTime(2024, 12, 1),
          achievements: const [
            'Led team of 5 to deliver cloud-based platform.',
            'Reduced load time by 40% via code optimisation.',
          ],
        ),
        Experience(
          id: 'exp-2',
          company: 'StartupXYZ',
          position: 'Junior Developer',
          startDate: DateTime(2019, 1, 1),
          endDate: DateTime(2020, 12, 1),
          achievements: const [
            'Implemented reusable UI components for the core dashboard.',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science Software Engineering',
          startDate: DateTime(2015, 9, 1),
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
      projects: [
        Project(
          id: 'p1',
          title: 'Portfolio Website',
          description:
              'Developed a responsive portfolio site showcasing projects and skills.',
          technologies: const ['Flutter Web'],
        ),
        Project(
          id: 'p2',
          title: 'Task Management App',
          description:
              'Built a productivity-focused app with authentication and offline sync.',
          technologies: const ['Flutter', 'Firebase'],
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
        Language(id: 'l1', name: 'English', proficiency: 'Native'),
      ],
      templateId: 'startup',
      customSections: [
        CustomSection(
          id: 'startup_achievements',
          title: 'Achievements',
          items: [
            CustomSectionItem(
              id: 'a1',
              title: 'Improved release confidence across template updates.',
            ),
            CustomSectionItem(
              id: 'a2',
              title:
                  'Cut preview regression triage time through focused tests.',
            ),
          ],
        ),
        CustomSection(
          id: 'startup_tools',
          title: 'Tools',
          items: [
            CustomSectionItem(id: 't1', title: 'Flutter, Dart, Firebase'),
            CustomSectionItem(id: 't2', title: 'REST APIs, Git'),
          ],
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('startup');
    final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
