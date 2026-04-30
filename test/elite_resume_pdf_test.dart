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
    hiveDir = await Directory.systemTemp.createTemp('resume-app-elite-pdf');
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
      id: 'elite-resume-pdf-test',
      title: 'Elite Resume',
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
          'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products. Improves preview fidelity, preserves detailed content, and builds maintainable resume export workflows.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TechCorp',
          position: 'Senior Developer',
          location: 'Remote',
          startDate: DateTime(2021, 1, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Led a team delivering cloud-based product features and improved release quality across preview, export, and sharing flows.',
          achievements: const [
            'Built reusable UI and PDF renderer components for multiple resume templates.',
            'Improved template fidelity by aligning generated output with picker previews.',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
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
          title: 'Resume Builder',
          description:
              'Built a preview and export workflow that keeps template-specific output aligned with updated resume content. https://johnsmith.dev/resume-builder',
          url: 'https://johnsmith.dev/resume-builder',
          technologies: const ['Flutter', 'PDF', 'Testing'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
          issueDate: DateTime(2024, 1, 1),
          credentialUrl: 'https://example.com/cert/aws-123456',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
      ],
      templateId: 'modern_resume',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the elite resume pdf template', () {
    final template = PdfTemplateFactory.getTemplate('modern_resume');
    expect(template, isA<EliteResumePdfTemplate>());
  });

  test('elite resume pdf generates bytes', () async {
    final resume = buildResume();
    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('modern_resume');
    final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
