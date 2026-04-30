import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/elegant_design_template_support.dart';
import 'package:resume_builder/features/templates/widgets/elegant_design_resume_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-elegant');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('factory returns the dedicated elegant design pdf template', () {
    final template = PdfTemplateFactory.getTemplate('elegant_design');
    expect(template, isA<ElegantDesignResumePdfTemplate>());
  });

  test('elegant design support keeps social links and dynamic resume data', () {
    final items = ElegantDesignTemplateSupport.contactItems(
      PersonalInfo(
        phone: '+91 9885623465',
        email: 'seenai007@gmail.com',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/seenai',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com',
      ),
      compactLinks: true,
      includeAddress: false,
    );

    expect(
      items.map((item) => item.label),
      equals([
        '+91 9885623465',
        'seenai007@gmail.com',
        'linkedin.com/seenai',
        'github.com/gmk',
        'seenaigmk.com',
      ]),
    );

    final experienceEntries = ElegantDesignTemplateSupport.experienceEntries(
      [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Led the automation team in developing and executing test automation scripts while coordinating delivery updates.',
          achievements: const [
            'Guided team members and contributed to framework development.',
          ],
        ),
      ],
      maxItems: null,
      maxDetailLines: null,
      yearOnly: false,
    );

    expect(experienceEntries, hasLength(1));
    expect(
      experienceEntries.single.detailLines,
      containsAll([
        'Guided team members and contributed to framework development.',
        'Led the automation team in developing and executing test automation scripts while coordinating delivery updates.',
      ]),
    );

    final projectEntries = ElegantDesignTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Cigna Health Care',
          description:
              'Built analytics around health claims and generated automation insights. Docs: https://docs.cigna.example/claims',
          url: 'https://example.com/cigna-health-care',
          technologies: const ['React', 'SQL'],
        ),
      ],
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );

    expect(projectEntries, hasLength(1));
    expect(
      projectEntries.single.detailLines,
      equals(['Built analytics around health claims and generated automation insights.']),
    );
    expect(
      projectEntries.single.links,
      equals([
        'example.com/cigna-health-care',
        'docs.cigna.example/claims',
      ]),
    );

    final certificationEntries =
        ElegantDesignTemplateSupport.certificationEntries(
      [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
          issueDate: DateTime(2024, 1, 1),
          credentialId: 'AWS-123456',
          credentialUrl: 'https://example.com/cert/aws-123456',
        ),
      ],
      maxItems: null,
      compactLinks: true,
    );

    expect(certificationEntries, hasLength(1));
    expect(
      certificationEntries.single.detailLines.single,
      contains('Amazon'),
    );
    expect(
      certificationEntries.single.detailLines.single,
      contains('Jan 2024'),
    );
    expect(
      certificationEntries.single.detailLines.single,
      contains('ID AWS-123456'),
    );
    expect(
      certificationEntries.single.links,
      equals(['example.com/cert/aws-123456']),
    );

    expect(
      ElegantDesignTemplateSupport.languageLines(
        [
          Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
          Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
        ],
        maxItems: null,
      ),
      equals(['English  |  Native', 'Spanish  |  Professional']),
    );
  });

  testWidgets(
      'elegant design preview shows numbered summary points and resume links',
      (tester) async {
    final now = DateTime(2026, 4, 13);
    final resume = ResumeModel(
      id: 'elegant-preview',
      title: 'Elegant Design Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/seenai',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com',
        jobTitle: 'Senior Manager',
      ),
      objective:
          'Leads automation strategy. Improves quality reporting. Builds resilient delivery workflows.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'Holy Jesus and Mary PG College',
          degree: 'MCA',
          fieldOfStudy: 'Computer Applications',
          startDate: DateTime(2006, 2, 1),
          endDate: DateTime(2009, 2, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Led the automation team in developing and executing test automation scripts while coordinating delivery updates.',
          achievements: const [
            'Guided team members and contributed to framework development.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'React'),
        Skill(id: 'skill-2', name: 'JavaScript'),
        Skill(id: 'skill-3', name: 'Communication'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Cigna Health Care',
          description:
              'Built analytics around health claims and generated automation insights. Docs: https://docs.cigna.example/claims',
          url: 'https://example.com/cigna-health-care',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
          issueDate: DateTime(2024, 1, 1),
        ),
        Certification(
          id: 'cert-2',
          name: 'Oracle Cloud Foundation',
          issuer: 'Oracle',
          issueDate: DateTime(2025, 2, 1),
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
        Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
      ],
      templateId: 'elegant_design',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 340,
              child: ElegantDesignResumeTemplatePreview(
                accentColor: Colors.blue,
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('linkedin.com/seenai'), findsOneWidget);
    expect(find.text('github.com/gmk'), findsOneWidget);
    expect(find.text('seenaigmk.com'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('3.'), findsOneWidget);
    expect(find.text('Cigna Health Care'), findsOneWidget);
    expect(find.text('example.com/cigna-health-care'), findsOneWidget);
    expect(find.text('CERTIFICATIONS'), findsOneWidget);
    expect(find.text('LANGUAGES'), findsOneWidget);
    expect(find.textContaining('AWS Certified Developer'), findsOneWidget);
    expect(find.textContaining('Oracle Cloud Foundation'), findsOneWidget);
    expect(find.textContaining('English  |  Native'), findsOneWidget);
    expect(find.textContaining('Spanish  |  Professional'), findsOneWidget);
  });

  test('elegant design pdf generates with dedicated layout', () async {
    final now = DateTime(2026, 4, 13);
    final resume = ResumeModel(
      id: 'elegant-pdf',
      title: 'Elegant Design Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/seenai',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com',
        jobTitle: 'Senior Manager',
      ),
      objective:
          'Leads automation strategy. Improves quality reporting. Builds resilient delivery workflows.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'Holy Jesus and Mary PG College',
          degree: 'MCA',
          fieldOfStudy: 'Computer Applications',
          startDate: DateTime(2006, 2, 1),
          endDate: DateTime(2009, 2, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Led the automation team in developing and executing test automation scripts while coordinating delivery updates.',
          achievements: const [
            'Guided team members and contributed to framework development.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'React'),
        Skill(id: 'skill-2', name: 'JavaScript'),
        Skill(id: 'skill-3', name: 'Communication'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Cigna Health Care',
          description:
              'Built analytics around health claims and generated automation insights. Docs: https://docs.cigna.example/claims',
          url: 'https://example.com/cigna-health-care',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
          issueDate: DateTime(2024, 1, 1),
          credentialId: 'AWS-123456',
          credentialUrl: 'https://example.com/cert/aws-123456',
        ),
        Certification(
          id: 'cert-2',
          name: 'Oracle Cloud Foundation',
          issuer: 'Oracle',
          issueDate: DateTime(2025, 2, 1),
          credentialId: 'ORACLE-456',
          credentialUrl: 'https://example.com/cert/oracle-456',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
        Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
      ],
      templateId: 'elegant_design',
      createdAt: now,
      updatedAt: now,
    );

    final document = await ElegantDesignResumePdfTemplate().generate(
      resume,
      PdfColors.blue,
    );
    final bytes = await document.save();

    expect(bytes, isNotEmpty);
  });
}