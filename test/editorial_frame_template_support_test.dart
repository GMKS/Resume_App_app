import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/editorial_frame_template_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir =
        await Directory.systemTemp.createTemp('resume-app-editorial-frame');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('factory returns the dedicated editorial frame pdf template', () {
    final template = PdfTemplateFactory.getTemplate('editorial_frame');
    expect(template, isA<EditorialFrameResumePdfTemplate>());
  });

  test('editorial frame contact items keep github and website links', () {
    final items = EditorialFrameTemplateSupport.contactItems(
      PersonalInfo(
        phone: '(555) 123-4567',
        email: 'john.smith@email.com',
        linkedIn: 'https://linkedin.com/in/johnsmith/',
        github: 'https://github.com/johnsmith',
        website: 'https://johnsmith.dev/',
      ),
      compactLinks: true,
    );

    expect(
      items.map((item) => item.label),
      equals([
        '(555) 123-4567',
        'john.smith@email.com',
        'linkedin.com/in/johnsmith',
        'github.com/johnsmith',
        'johnsmith.dev',
      ]),
    );
  });

  test('editorial frame project entries keep summaries and extracted links',
      () {
    final entries = EditorialFrameTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Portfolio Website',
          description:
              'Built a portfolio with case studies. https://example.com/portfolio',
          url: 'https://example.com/portfolio',
          technologies: const ['Flutter', 'Firebase'],
        ),
      ],
      maxDetailLines: null,
      compactLinks: true,
    );

    expect(entries, hasLength(1));
    expect(entries.single.title, 'Portfolio Website');
    expect(
      entries.single.detailLines,
      equals(['Built a portfolio with case studies.']),
    );
    expect(entries.single.links, equals(['example.com/portfolio']));
  });

  test('editorial frame experience entries can include all summary lines', () {
    final entries = EditorialFrameTemplateSupport.experienceEntries(
      [
        Experience(
          id: 'experience-1',
          position: 'Senior Developer',
          company: 'TechCorp',
          startDate: DateTime(2021, 1, 1),
          endDate: DateTime(2024, 1, 1),
          description: 'Built release automation.\nImproved test coverage.',
          achievements: const ['Reduced incident volume by 40%.'],
        ),
      ],
      maxDetailLines: null,
    );

    expect(entries, hasLength(1));
    expect(
      entries.single.detailLines,
      equals([
        'Built release automation.',
        'Improved test coverage.',
        'Reduced incident volume by 40%.',
      ]),
    );
  });

  test('editorial frame pdf generates with dense expertise lists', () async {
    final now = DateTime(2026, 4, 11);
    final resume = ResumeModel(
      id: 'resume-1',
      title: 'Senior Engineer',
      personalInfo: PersonalInfo(
        fullName: 'Jane Doe',
        email: 'jane.doe@example.com',
        phone: '(555) 111-2222',
        linkedIn: 'https://linkedin.com/in/janedoe',
        github: 'https://github.com/janedoe',
        website: 'https://janedoe.dev',
      ),
      objective:
          'Delivers complex product work with reliable execution and stakeholder alignment.',
      education: [
        Education(
          id: 'education-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2020, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'experience-1',
          company: 'TechCorp',
          position: 'Lead Engineer',
          startDate: DateTime(2021, 1, 1),
          description:
              'Led modernization delivery across multiple client programs.',
          achievements: const [
            'Improved release quality across mobile and web.'
          ],
          isCurrentlyWorking: true,
        ),
      ],
      skills: List.generate(
        18,
        (index) => Skill(
          id: 'skill-$index',
          name: 'Expertise ${index + 1}',
        ),
      ),
      projects: [
        Project(
          id: 'project-1',
          title: 'Platform Refresh',
          description:
              'Rebuilt resume generation flows for production scale. https://example.com/platform-refresh',
          url: 'https://example.com/platform-refresh',
        ),
      ],
      certifications: [
        Certification(
          id: 'certification-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
        ),
      ],
      languages: [
        Language(
          id: 'language-1',
          name: 'English',
          proficiency: 'Native',
        ),
      ],
      templateId: 'editorial_frame',
      createdAt: now,
      updatedAt: now,
    );

    final document = await EditorialFrameResumePdfTemplate().generate(
      resume,
      PdfColors.brown,
    );
    final bytes = await document.save();

    expect(bytes, isNotEmpty);
  });
}
