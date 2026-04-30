import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/healthcare_resume_template_support.dart';
import 'package:resume_builder/features/templates/widgets/healthcare_resume_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-healthcare');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('factory returns the dedicated healthcare pdf template', () {
    final template = PdfTemplateFactory.getTemplate('professional_tone');
    expect(template, isA<HealthcareResumePdfTemplate>());
  });

  test('healthcare contact items keep social links and address', () {
    final items = HealthcareResumeTemplateSupport.contactItems(
      PersonalInfo(
        phone: '(555) 123-4567',
        email: 'john.smith@email.com',
        address: 'New York, NY',
        linkedIn: 'https://linkedin.com/in/johnsmith/',
        github: 'https://github.com/johnsmith',
        website: 'https://johnsmith.dev/',
      ),
      compactLinks: true,
      includeAddress: true,
    );

    expect(
      items.map((item) => item.label),
      equals([
        '(555) 123-4567',
        'john.smith@email.com',
        'New York, NY',
        'linkedin.com/in/johnsmith',
        'github.com/johnsmith',
        'johnsmith.dev',
      ]),
    );
  });

  test(
      'healthcare support keeps projects, certifications, languages, and custom sections',
      () {
    final customSections = [
      CustomSection(
        id: 'healthcare_licenses_certifications',
        title: 'Licenses & Certifications',
        items: [
          CustomSectionItem(
            id: 'license-1',
            title: 'BLS Certification',
            subtitle: 'American Heart Association',
            description: 'Details: https://example.com/bls',
            date: DateTime(2025, 1, 1),
          ),
        ],
      ),
      CustomSection(
        id: 'healthcare_specializations',
        title: 'Specializations',
        items: [
          CustomSectionItem(id: 'spec-1', title: 'Acute Care'),
          CustomSectionItem(id: 'spec-2', title: 'Care Coordination'),
        ],
      ),
    ];

    final projects = HealthcareResumeTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Patient Intake Automation',
          description:
              'Improved intake workflows across regional clinics. Docs: https://example.com/intake. Demo: https://health.example.com/intake',
          url: 'https://health.example.com/intake',
          technologies: const ['Flutter', 'FHIR'],
        ),
      ],
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );

    expect(projects, hasLength(1));
    expect(
      projects.single.detailLines,
      equals(['Improved intake workflows across regional clinics.']),
    );
    expect(
      projects.single.links,
      equals(['health.example.com/intake', 'example.com/intake']),
    );

    final certifications = HealthcareResumeTemplateSupport.certificationEntries(
      const <Certification>[],
      customSections: customSections,
      maxItems: null,
      compactLinks: true,
    );

    expect(certifications, hasLength(1));
    expect(certifications.single.name, 'BLS Certification');
    expect(certifications.single.links, equals(['example.com/bls']));

    expect(
      HealthcareResumeTemplateSupport.languageLines(
        [
          Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
          Language(
              id: 'lang-2', name: 'Spanish', proficiency: 'Conversational'),
        ],
        maxItems: null,
      ),
      equals(['English  |  Professional', 'Spanish  |  Conversational']),
    );

    final bodySections = HealthcareResumeTemplateSupport.bodyCustomSections(
      customSections,
      maxSections: null,
      maxItemsPerSection: null,
    );
    expect(bodySections, hasLength(1));
    expect(bodySections.single.title, 'Specializations');
    expect(bodySections.single.lines,
        containsAll(['Acute Care', 'Care Coordination']));
  });

  test('healthcare pdf generates with dedicated layout', () async {
    final now = DateTime(2026, 4, 13);
    final resume = ResumeModel(
      id: 'healthcare-test',
      title: 'HealthCare Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://linkedin.com/in/seenai',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com',
        jobTitle: 'Senior Manager',
      ),
      objective:
          'Builds healthcare delivery systems. Improves quality and reporting. Leads cross-functional execution.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Healthcare Informatics',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2019, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Cigna Health Care',
          position: 'Clinical Systems Lead',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Led healthcare workflow improvements across patient intake, reporting, and operations.',
          achievements: const [
            'Improved intake quality and turnaround time across distributed teams.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Acute Care'),
        Skill(id: 'skill-2', name: 'EMR Integration'),
        Skill(id: 'skill-3', name: 'Communication'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Patient Intake Automation',
          description:
              'Improved intake workflows across regional clinics. Docs: https://example.com/intake',
          url: 'https://health.example.com/intake',
          technologies: const ['Flutter', 'FHIR'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
          issueDate: DateTime(2025, 1, 1),
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'German', proficiency: 'Conversational'),
      ],
      customSections: [
        CustomSection(
          id: 'healthcare_licenses_certifications',
          title: 'Licenses & Certifications',
          items: [
            CustomSectionItem(
              id: 'license-1',
              title: 'BLS Certification',
              subtitle: 'American Heart Association',
              description: 'Details: https://example.com/bls',
              date: DateTime(2025, 1, 1),
            ),
          ],
        ),
      ],
      templateId: 'professional_tone',
      createdAt: now,
      updatedAt: now,
    );

    final document = await HealthcareResumePdfTemplate().generate(
      resume,
      PdfColors.blue,
    );
    final bytes = await document.save();

    expect(bytes, isNotEmpty);
  });

  testWidgets(
      'healthcare preview keeps address, social links, and project links visible',
      (tester) async {
    final now = DateTime(2026, 4, 13);
    final resume = ResumeModel(
      id: 'healthcare-preview',
      title: 'HealthCare Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://linkedin.com/in/seenai',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com',
        jobTitle: 'Senior Manager',
      ),
      objective:
          'Builds healthcare delivery systems. Improves quality and reporting. Leads cross-functional execution.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Healthcare Informatics',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2019, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Cigna Health Care',
          position: 'Clinical Systems Lead',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Led healthcare workflow improvements across patient intake, reporting, and operations.',
          achievements: const [
            'Improved intake quality and turnaround time across distributed teams.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Acute Care'),
        Skill(id: 'skill-2', name: 'EMR Integration'),
        Skill(id: 'skill-3', name: 'Communication'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Patient Intake Automation',
          description:
              'Improved intake workflows across regional clinics. Docs: https://example.com/intake',
          url: 'https://health.example.com/intake',
          technologies: const ['Flutter', 'FHIR'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
          issueDate: DateTime(2025, 1, 1),
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'German', proficiency: 'Conversational'),
      ],
      customSections: [
        CustomSection(
          id: 'healthcare_licenses_certifications',
          title: 'Licenses & Certifications',
          items: [
            CustomSectionItem(
              id: 'license-1',
              title: 'BLS Certification',
              subtitle: 'American Heart Association',
              description: 'Details: https://example.com/bls',
              date: DateTime(2025, 1, 1),
            ),
          ],
        ),
      ],
      templateId: 'professional_tone',
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
              child: HealthcareResumeTemplatePreview(
                accentColor: Colors.blue,
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hyderabad, India'), findsOneWidget);
    expect(find.text('linkedin.com/in/seenai'), findsOneWidget);
    expect(find.text('github.com/gmk'), findsOneWidget);
    expect(find.text('seenaigmk.com'), findsOneWidget);
    expect(find.text('EXPERIENCE'), findsOneWidget);
    expect(find.text('Patient Intake Automation'), findsOneWidget);
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(find.text('LANGUAGES'), findsOneWidget);
    expect(find.text('health.example.com/intake'), findsOneWidget);
    expect(find.text('BLS Certification'), findsOneWidget);
    expect(find.text('English  |  Professional'), findsOneWidget);
    expect(find.text('Improved intake workflows across regional clinics.'),
        findsOneWidget);

    final experienceTop = tester.getTopLeft(find.text('EXPERIENCE')).dy;
    final projectsTop = tester.getTopLeft(find.text('PROJECTS')).dy;
    final languagesTop = tester.getTopLeft(find.text('LANGUAGES')).dy;

    expect(experienceTop, lessThan(projectsTop));
    expect(projectsTop, lessThan(languagesTop));
  });
}
