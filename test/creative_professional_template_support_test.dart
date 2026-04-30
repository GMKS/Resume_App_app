import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/creative_professional_template_support.dart';
import 'package:resume_builder/features/templates/widgets/creative_professional_resume_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir =
        await Directory.systemTemp.createTemp('resume-app-creative-prof');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('factory returns the dedicated creative professional pdf template', () {
    final template = PdfTemplateFactory.getTemplate('creative_professional');
    expect(template, isA<CreativeProfessionalResumePdfTemplate>());
  });

  test('creative professional support keeps social links and dynamic data', () {
    final items = CreativeProfessionalTemplateSupport.contactItems(
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

    final experienceEntries =
        CreativeProfessionalTemplateSupport.experienceEntries(
      [
        Experience(
          id: 'exp-1',
          company: 'North Studio',
          position: 'Senior Designer',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Led visual direction and launched refreshed brand experiences for product and marketing teams.',
          achievements: const [
            'Built design systems used across launch campaigns and product marketing.',
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
        'Built design systems used across launch campaigns and product marketing.',
        'Led visual direction and launched refreshed brand experiences for product and marketing teams.',
      ]),
    );

    final projectEntries = CreativeProfessionalTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Brand Campaign System',
          description:
              'Refined launch storytelling for web, social, and print assets. Case study: https://example.com/case-study',
          url: 'https://portfolio.example.com/brand-system',
          technologies: const ['Figma', 'Adobe CC'],
        ),
      ],
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );

    expect(projectEntries, hasLength(1));
    expect(
      projectEntries.single.detailLines,
      equals(['Refined launch storytelling for web, social, and print assets.']),
    );
    expect(
      projectEntries.single.links,
      equals([
        'portfolio.example.com/brand-system',
        'example.com/case-study',
      ]),
    );

    final certificationEntries =
        CreativeProfessionalTemplateSupport.certificationEntries(
      [
        Certification(
          id: 'cert-1',
          name: 'Adobe Certified Professional',
          issuer: 'Adobe',
          issueDate: DateTime(2025, 1, 1),
          credentialId: 'ADOBE-123',
          credentialUrl: 'https://example.com/cert/adobe-123',
        ),
      ],
      maxItems: null,
      compactLinks: true,
    );

    expect(certificationEntries, hasLength(1));
    expect(certificationEntries.single.detailLines.single, contains('Adobe'));
    expect(certificationEntries.single.detailLines.single, contains('Jan 2025'));
    expect(certificationEntries.single.detailLines.single, contains('ID ADOBE-123'));
    expect(
      certificationEntries.single.links,
      equals(['example.com/cert/adobe-123']),
    );

    expect(
      CreativeProfessionalTemplateSupport.languageLines(
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
      'creative professional preview shows social links, diamond bullets, and project links',
      (tester) async {
    final now = DateTime(2026, 4, 13);
    final resume = ResumeModel(
      id: 'creative-prof-preview',
      title: 'Creative Professional Resume',
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
          'Leads campaign storytelling. Builds polished launch systems. Aligns product and marketing execution.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'Parsons School of Design',
          degree: 'B.Des.',
          fieldOfStudy: 'Visual Design',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2020, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'North Studio',
          position: 'Senior Designer',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Led visual direction and launched refreshed brand experiences for product and marketing teams.',
          achievements: const [
            'Built design systems used across launch campaigns and product marketing.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Figma'),
        Skill(id: 'skill-2', name: 'Illustration'),
        Skill(id: 'skill-3', name: 'Art Direction'),
        Skill(id: 'skill-4', name: 'Brand Strategy'),
        Skill(id: 'skill-5', name: 'Campaign Design'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Brand Campaign System',
          description:
              'Refined launch storytelling for web, social, and print assets. Case study: https://example.com/case-study',
          url: 'https://portfolio.example.com/brand-system',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'Adobe Certified Professional',
          issuer: 'Adobe',
          issueDate: DateTime(2025, 1, 1),
        ),
        Certification(
          id: 'cert-2',
          name: 'Google UX Design',
          issuer: 'Google',
          issueDate: DateTime(2024, 8, 1),
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
        Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
        Language(id: 'lang-3', name: 'French', proficiency: 'Conversational'),
      ],
      templateId: 'creative_professional',
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
              child: CreativeProfessionalResumeTemplatePreview(
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
    expect(find.text('◆'), findsNWidgets(3));
    expect(find.text('SKILLS'), findsOneWidget);
    expect(find.textContaining('Brand Strategy'), findsOneWidget);
    expect(find.text('Brand Campaign System'), findsOneWidget);
    expect(find.text('portfolio.example.com/brand-system'), findsOneWidget);
    expect(find.textContaining('English  |  Native'), findsOneWidget);
    expect(find.textContaining('French  |  Conversational'), findsOneWidget);
    expect(find.textContaining('Adobe Certified Professional'), findsOneWidget);
    expect(find.textContaining('Google UX Design'), findsOneWidget);
  });

  test('creative professional pdf generates with dedicated layout', () async {
    final now = DateTime(2026, 4, 13);
    final resume = ResumeModel(
      id: 'creative-prof-pdf',
      title: 'Creative Professional Resume',
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
          'Leads campaign storytelling. Builds polished launch systems. Aligns product and marketing execution.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'Parsons School of Design',
          degree: 'B.Des.',
          fieldOfStudy: 'Visual Design',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2020, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'North Studio',
          position: 'Senior Designer',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Led visual direction and launched refreshed brand experiences for product and marketing teams.',
          achievements: const [
            'Built design systems used across launch campaigns and product marketing.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Figma'),
        Skill(id: 'skill-2', name: 'Illustration'),
        Skill(id: 'skill-3', name: 'Art Direction'),
        Skill(id: 'skill-4', name: 'Brand Strategy'),
        Skill(id: 'skill-5', name: 'Campaign Design'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Brand Campaign System',
          description:
              'Refined launch storytelling for web, social, and print assets. Case study: https://example.com/case-study',
          url: 'https://portfolio.example.com/brand-system',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'Adobe Certified Professional',
          issuer: 'Adobe',
          issueDate: DateTime(2025, 1, 1),
          credentialId: 'ADOBE-123',
          credentialUrl: 'https://example.com/cert/adobe-123',
        ),
        Certification(
          id: 'cert-2',
          name: 'Google UX Design',
          issuer: 'Google',
          issueDate: DateTime(2024, 8, 1),
          credentialId: 'GOOGLE-UX-9',
          credentialUrl: 'https://example.com/cert/google-ux-9',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
        Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
        Language(id: 'lang-3', name: 'French', proficiency: 'Conversational'),
      ],
      templateId: 'creative_professional',
      createdAt: now,
      updatedAt: now,
    );

    final document = await CreativeProfessionalResumePdfTemplate().generate(
      resume,
      PdfColors.blue,
    );
    final bytes = await document.save();

    expect(bytes, isNotEmpty);
  });
}