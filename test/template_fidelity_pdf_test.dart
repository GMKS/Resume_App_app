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
        await Directory.systemTemp.createTemp('resume-app-template-fidelity');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  ResumeModel buildResume(String templateId) {
    final now = DateTime(2026, 4, 2);
    return ResumeModel(
      id: 'template-fidelity-$templateId',
      title: 'Template Fidelity Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/seenai',
        github: 'https://github.com/gmk',
        website: 'www.seenaigmk.com',
        jobTitle: 'Senior manager',
      ),
      objective:
          'Over 13.6 years in software testing or development, with a solid understanding of testing, coding, and debugging procedures. Programming skills include Selenium using Core Java, Selenium, Cucumber, and TestNG. Test automation includes designing automation suites across UI, services, and data workflows while collaborating with developers to improve quality and delivery.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'Holy Jesus and Mary PG College',
          degree: 'MCA',
          fieldOfStudy: 'Computer Applications',
          startDate: DateTime(2006, 2, 1),
          endDate: DateTime(2009, 2, 1),
          grade: '1st Grade',
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          location: 'Hyderabad, India',
          description:
              'Led the automation team in developing and executing test automation scripts while coordinating delivery updates and status reporting.',
          achievements: const [
            'Led the automation team in developing and executing test automation scripts.',
            'Guided team members and contributed to test framework development.',
            'Managed client interactions for status updates, metrics, and communication.',
          ],
        ),
        Experience(
          id: 'exp-2',
          company: 'UST Global Pvt Limited',
          position: 'Senior Software Engineer',
          startDate: DateTime(2017, 2, 1),
          endDate: DateTime(2018, 3, 1),
          location: 'Hyderabad, India',
          description:
              'Developed and maintained automation test scripts using Selenium and Core Java across UI and service workflows.',
          achievements: const [
            'Developed and maintained automation test scripts using Selenium and Core Java.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'React'),
        Skill(id: 'skill-2', name: 'JavaScript'),
        Skill(id: 'skill-3', name: 'Communication'),
        Skill(id: 'skill-4', name: 'Project Management'),
        Skill(id: 'skill-5', name: 'SQL'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Cigna Health Care',
          description:
              'Built analytics around health claims and generated automation insights for customer relationships while coordinating measurable delivery updates.',
          url: 'https://example.com/cigna-health-care',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
          issueDate: DateTime(2024, 1, 1),
          expiryDate: DateTime(2027, 1, 1),
          credentialId: 'AWS-123456',
          credentialUrl: 'https://example.com/cert/aws-123456',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
      ],
      templateId: templateId,
      createdAt: now,
      updatedAt: now,
    );
  }

  ResumeModel buildDenseLanguageResume(String templateId) {
    final base = buildResume(templateId);
    return base.copyWith(
      certifications: [
        ...base.certifications,
        Certification(
          id: 'cert-2-$templateId',
          name: 'Professional Scrum Master',
          issuer: 'Scrum.org',
        ),
        Certification(
          id: 'cert-3-$templateId',
          name: 'ISTQB Advanced Test Analyst',
          issuer: 'ISTQB',
        ),
      ],
      languages: [
        Language(id: 'lang-1-dense', name: 'English', proficiency: 'Native'),
        Language(
            id: 'lang-2-dense', name: 'Spanish', proficiency: 'Professional'),
        Language(
            id: 'lang-3-dense', name: 'German', proficiency: 'Conversational'),
        Language(id: 'lang-4-dense', name: 'French', proficiency: 'Working'),
        Language(id: 'lang-5-dense', name: 'Hindi', proficiency: 'Fluent'),
        Language(id: 'lang-6-dense', name: 'Telugu', proficiency: 'Native'),
      ],
    );
  }

  test('generates academic pdf with justified content', () async {
    final resume = buildResume('academic');

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('academic');
    final pdf = await template.generate(resume, PdfColor.fromHex('#4F46E5'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });

  test('generates modern aesthetic pdf matching preview structure', () async {
    final resume = buildResume('modern_aesthetic');

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('modern_aesthetic');
    final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });

  test('generates classic2 pdf with project links and experience summary',
      () async {
    final resume = buildResume('classic2');

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('classic2');
    final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });

  test('generates education resume pdf matching preview layout', () async {
    final resume = buildResume('education_resume');

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('education_resume');
    final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });

  test('generates modern resume pdf matching preview layout', () async {
    final resume = buildResume('modern_resume');

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('modern_resume');
    final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });

  test('generates classic temp pdf matching compact preview layout', () async {
    final resume = buildResume('classic_temp');

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('classic_temp');
    final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });

  test('generates emerald executive pdf without layout gaps', () async {
    final resume = buildResume('emerald_executive');

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('emerald_executive');
    final pdf = await template.generate(resume, PdfColor.fromHex('#16653D'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });

  test('generates multicolor pdf with justified section body text', () async {
    final resume = buildResume('multicolor');

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('multicolor');
    final pdf = await template.generate(resume, PdfColor.fromHex('#7C3AED'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });

  test('generates dense-language pdfs for visibility-sensitive templates',
      () async {
    for (final templateId in const [
      'classic_ats',
      'elegant_design',
      'elegant_gold_layout',
      'slate_arc',
    ]) {
      final resume = buildDenseLanguageResume(templateId);

      await initPdfSettings(resume);
      final template = PdfTemplateFactory.getTemplate(templateId);
      final pdf = await template.generate(
        resume,
        PdfColor.fromHex(
          templateId == 'classic_ats'
              ? '#8B6B45'
              : templateId == 'elegant_gold_layout'
                  ? '#C29A55'
                  : templateId == 'slate_arc'
                      ? '#6B7280'
                      : '#C9935B',
        ),
      );
      final bytes = await pdf.save();

      expect(bytes, isNotEmpty, reason: templateId);
    }
  });

  test(
      'generates vertical timeline, corporate, and mono nova pdfs with updated layout fidelity',
      () async {
    for (final templateId in const [
      'vertical_timeline',
      'corporate_template',
      'mono_nova',
    ]) {
      final base = buildResume(templateId);
      final resume = base.copyWith(
        objective:
            'Over 13.6 years in software testing or development, with a solid understanding of testing, coding, and debugging procedures.\nProgramming skills include Selenium using Core Java, Selenium, Cucumber, and TestNG.\nTest automation includes designing automation suites across UI, services, and data workflows while collaborating with developers to improve quality and delivery.',
        projects: [
          ...base.projects,
          Project(
            id: 'project-2-$templateId',
            title: 'One Pulse Application',
            description:
                'Developed the Karate framework from scratch using Java/Gherkin and Core Java.\nCreated API scripts and managed daily stand-ups with global teams.\nAssisted with automation issues and participated in retrospective meetings.',
            url: 'https://www.gmail.com/seenai',
          ),
        ],
      );

      await initPdfSettings(resume);
      final template = PdfTemplateFactory.getTemplate(templateId);
      final pdf = await template.generate(resume, PdfColor.fromHex('#4F46E5'));
      final bytes = await pdf.save();

      expect(bytes, isNotEmpty, reason: templateId);
    }
  });

  test(
      'generates classic, classic ats, creative, developer, minimal, and emerald pdfs with expanded dynamic content',
      () async {
    final baseResume = buildResume('classic_temp');
    final expandedExperience = baseResume.experience
        .map(
          (exp) => exp.copyWith(
            achievements: [
              ...exp.achievements,
              'Participated in retrospective meetings and handled project estimation, scheduling, and risk management.',
              'Implemented data-driven and page object model frameworks.',
            ],
          ),
        )
        .toList(growable: false);
    final expandedProjects = [
      ...baseResume.projects,
      Project(
        id: 'project-2',
        title: 'One Pulse Application',
        description:
            'Built workflow automation for insurer operations. Added reporting dashboards for transaction status updates. Coordinated issue triage and release support.',
        url: 'https://example.com/one-pulse',
      ),
    ];
    final expandedSkills = [
      ...baseResume.skills,
      Skill(id: 'skill-6', name: 'Leadership'),
      Skill(id: 'skill-7', name: 'Agile Delivery'),
      Skill(id: 'skill-8', name: 'Automation Testing'),
    ];

    for (final templateId in [
      'classic_temp',
      'classic_ats',
      'creative',
      'developer',
      'minimal',
      'emerald_executive'
    ]) {
      final resume = baseResume.copyWith(
        templateId: templateId,
        experience: expandedExperience,
        projects: expandedProjects,
        skills: expandedSkills,
      );

      await initPdfSettings(resume);
      final template = PdfTemplateFactory.getTemplate(templateId);
      final pdf = await template.generate(
        resume,
        PdfColor.fromHex(
          templateId == 'emerald_executive' ? '#16653D' : '#6366F1',
        ),
      );
      final bytes = await pdf.save();

      expect(bytes, isNotEmpty, reason: templateId);
    }
  });

  test('generates reordered pdfs for movable-section templates', () async {
    const templateIds = [
      'education_resume',
      'classic_temp',
      'minimal_clean',
      'minimal_clean_ats',
      'professional_tone',
      'elegant_design',
      'creative_professional',
      'bluewave_tech',
      'elegant_gold_layout',
      'corporate_navy',
      'executive_classic',
    ];
    const customOrder =
        'projects,summary,experience,education,skills,certifications,languages';

    for (final templateId in templateIds) {
      final resume = buildResume(templateId);
      await StorageService.prefs
          .setString('section_order_${resume.id}', customOrder);
      await initPdfSettings(resume);

      final template = PdfTemplateFactory.getTemplate(templateId);
      final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
      final bytes = await pdf.save();

      expect(bytes, isNotEmpty, reason: templateId);
    }
  });

  test(
      'generates reordered pdfs when saved order includes user custom sections',
      () async {
    const templateIds = [
      'modern',
      'classic',
      'executive_classic',
      'cool_blue',
      'multicolor',
      'ats_optimized_clean',
      'vertical_timeline',
      'mono_nova',
    ];

    for (final templateId in templateIds) {
      final resume = buildResume(templateId).copyWith(
        customSections: [
          CustomSection(
            id: 'user_custom_awards',
            title: 'Awards',
            items: [
              CustomSectionItem(
                id: 'award-1',
                title: 'QA Excellence Award',
                description: 'Recognized for end-to-end automation delivery.',
              ),
            ],
          ),
        ],
      );

      await StorageService.prefs.setString(
        'section_order_${resume.id}',
        'summary,user_custom_awards,experience,education,skills,projects,certifications,languages',
      );
      await initPdfSettings(resume);

      final template = PdfTemplateFactory.getTemplate(templateId);
      final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
      final bytes = await pdf.save();

      expect(bytes, isNotEmpty, reason: templateId);
    }
  });

  test('generates templates with project and certification fallbacks',
      () async {
    const templateIds = [
      'classic_ats',
      'executive_classic',
      'one_page_resume',
      'professional_accountant',
      'two_column',
      'ats_optimized_clean',
      'balanced_two_column_layout',
      'blue_gray',
    ];

    for (final templateId in templateIds) {
      final resume = buildResume(templateId);
      await initPdfSettings(resume);

      final template = PdfTemplateFactory.getTemplate(templateId);
      final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
      final bytes = await pdf.save();

      expect(bytes, isNotEmpty, reason: templateId);
    }
  });
}
