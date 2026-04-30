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
    hiveDir = await Directory.systemTemp.createTemp('resume-app-infographic');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('generates infographic pdf with the dedicated infographic renderer',
      () async {
    final now = DateTime(2026, 4, 10);
    final resume = ResumeModel(
      id: 'infographic-pdf-test',
      title: 'Infographic Resume',
      personalInfo: PersonalInfo(
        fullName: 'Jordan Smith',
        email: 'jordan@example.com',
        phone: '+1 555 123 4567',
        address: 'Seattle, WA',
        linkedIn: 'linkedin.com/in/jordansmith',
        github: 'github.com/jordansmith',
        website: 'jordansmith.dev',
        jobTitle: 'Senior Flutter Developer',
      ),
      objective:
          'Builds high-fidelity resume workflows that connect editing, preview, and export. → Aligns product requirements with resilient UI architecture and measurable delivery. → Turns dense process flows into clear visual systems for end users and internal teams.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Bluewave Labs',
          position: 'Senior Flutter Developer',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          endDate: DateTime(2026, 3, 1),
          description:
              'Led Flutter web and mobile delivery for customer-facing resume tooling.',
          achievements: const [
            'Reduced preview rendering regressions across major template updates.',
            'Introduced dedicated template smoke coverage and export validation.',
          ],
        ),
        Experience(
          id: 'exp-2',
          company: 'Creative Forge',
          position: 'Flutter Engineer',
          location: 'Portland, OR',
          startDate: DateTime(2020, 6, 1),
          endDate: DateTime(2021, 12, 1),
          description:
              'Built polished UI systems and reusable component libraries.',
          achievements: const [
            'Delivered reusable design-system widgets for a multi-template app.',
          ],
        ),
        Experience(
          id: 'exp-3',
          company: 'North Atlas',
          position: 'UI Engineer',
          location: 'New York, NY',
          startDate: DateTime(2018, 1, 1),
          endDate: DateTime(2020, 5, 1),
          description:
              'Supported design-to-development handoff workflows for responsive products.',
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2014, 9, 1),
          endDate: DateTime(2018, 5, 1),
          grade: '3.8 GPA',
        ),
        Education(
          id: 'edu-2',
          institution: 'Design Systems Institute',
          degree: 'Certificate',
          fieldOfStudy: 'Product Strategy',
          startDate: DateTime(2019, 1, 1),
          endDate: DateTime(2019, 12, 1),
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter', proficiency: 5),
        Skill(id: 'skill-2', name: 'Dart', proficiency: 5),
        Skill(id: 'skill-3', name: 'Firebase', proficiency: 4),
        Skill(id: 'skill-4', name: 'Testing', proficiency: 4),
        Skill(id: 'skill-5', name: 'CI/CD', proficiency: 4),
        Skill(id: 'skill-6', name: 'UX Systems', proficiency: 5),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Builder',
          description:
              'Cross-platform resume editor with live previews and export-safe layouts. '
              'Added project link preservation for preview and export. Docs: https://docs.example.com/resume-builder',
          technologies: ['Flutter', 'Hive', 'Firebase'],
          url: 'https://example.com/resume-builder',
        ),
        Project(
          id: 'project-2',
          title: 'Signal Dashboard',
          description:
              'Built a health dashboard that aligned release progress, blockers, and design review insights.',
          technologies: ['Flutter Web', 'Analytics'],
          url: 'https://example.com/signal-dashboard',
        ),
        Project(
          id: 'project-3',
          title: 'Launch Map',
          description:
              'Visualized delivery dependencies and readiness checkpoints across multiple teams.',
          technologies: ['Data Viz', 'Planning'],
          url: 'https://example.com/launch-map',
        ),
        Project(
          id: 'project-4',
          title: 'Workflow Atlas',
          description:
              'Mapped internal workflows into reusable guided views for operations and QA.',
          technologies: ['UX Research', 'Systems'],
          url: 'https://example.com/workflow-atlas',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'Flutter Certified Developer',
          issuer: 'Google',
        ),
        Certification(
          id: 'cert-2',
          name: 'Professional Scrum Master',
          issuer: 'Scrum.org',
        ),
        Certification(
          id: 'cert-3',
          name: 'Design Systems Mastery',
          issuer: 'InVision',
        ),
        Certification(
          id: 'cert-4',
          name: 'Accessibility Foundations',
          issuer: 'Deque',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
        Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
        Language(id: 'lang-3', name: 'German', proficiency: 'Conversational'),
      ],
      templateId: 'infographic',
      createdAt: now,
      updatedAt: now,
    );

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('infographic');

    expect(template, isA<InfographicResumePdfTemplate>());

    final pdf = await template.generate(resume, PdfColor.fromHex('#5E8FA2'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
