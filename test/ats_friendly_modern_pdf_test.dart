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
        await Directory.systemTemp.createTemp('resume-app-ats-friendly-pdf');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('generates ats friendly modern pdf with full section content', () async {
    final now = DateTime(2026, 4, 6);
    final resume = ResumeModel(
      id: 'ats-friendly-modern-pdf-test',
      title: 'ATS Friendly Modern Resume',
      personalInfo: PersonalInfo(
        fullName: 'Avery Johnson',
        email: 'avery.johnson@example.com',
        phone: '+1 555 867 5309',
        address: 'Austin, TX',
        linkedIn: 'linkedin.com/in/averyjohnson',
        github: 'github.com/averyjohnson',
        website: 'averyjohnson.dev',
        jobTitle: 'Senior Product Engineer',
      ),
      objective:
          'Build accessible product experiences, modernize rendering workflows, and deliver reliable web and mobile releases across fast-moving teams.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Northstar Labs',
          position: 'Senior Product Engineer',
          location: 'Austin, TX',
          startDate: DateTime(2022, 1, 1),
          endDate: DateTime(2026, 3, 1),
          description:
              'Led product engineering for resume workflows spanning editor, preview, and export systems.',
          achievements: const [
            'Reworked PDF renderers to match live template previews with fewer regressions.',
            'Introduced targeted test coverage for entry-level, ATS-standard, and ATS-friendly layouts.',
          ],
        ),
        Experience(
          id: 'exp-2',
          company: 'Studio Foundry',
          position: 'Frontend Engineer',
          location: 'Remote',
          startDate: DateTime(2019, 6, 1),
          endDate: DateTime(2021, 12, 1),
          description:
              'Built responsive UX systems and data-rich dashboards for internal and customer teams.',
          achievements: const [
            'Improved design-system consistency across multiple production templates.',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'University of Texas',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2014, 9, 1),
          endDate: DateTime(2018, 5, 1),
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
        Skill(id: 'skill-3', name: 'Design Systems'),
        Skill(id: 'skill-4', name: 'Testing'),
        Skill(id: 'skill-5', name: 'Accessibility'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Preview Platform',
          description:
              'Built a preview and export platform that keeps in-app templates aligned with generated PDF output.\n'
              'Added a regression dashboard for exported resume fidelity. Docs: https://docs.example.com/preview-platform',
          technologies: ['Flutter', 'PDF', 'Testing'],
          url: 'https://preview.example.com',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'Certified Scrum Master',
          issuer: 'Scrum Alliance',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
        Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
        Language(id: 'lang-3', name: 'German', proficiency: 'Professional'),
      ],
      templateId: 'ats_friendly_modern',
      createdAt: now,
      updatedAt: now,
    );

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('ats_friendly_modern');
    expect(template, isA<AtsFriendlyModernResumePdfTemplate>());
    final pdf = await template.generate(resume, PdfColor.fromHex('#4A6785'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
