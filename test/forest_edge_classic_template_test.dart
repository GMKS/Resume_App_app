import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/forest_edge_classic_template_support.dart';
import 'package:resume_builder/features/templates/widgets/forest_edge_classic_resume_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir =
        await Directory.systemTemp.createTemp('resume-app-forest-edge-classic');
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
    final now = DateTime(2026, 4, 15);
    return ResumeModel(
      id: 'forest-edge-classic',
      title: 'Forest Edge Classic Resume',
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
          'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products. Improves delivery quality through dependable systems and clear communication.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'Bachelor of Science',
          fieldOfStudy: 'Software Engineering',
          startDate: DateTime(2018, 1, 1),
          endDate: DateTime(2022, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TechCorp',
          position: 'Senior Developer',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Led teams of 5 to deliver cloud-based platforms for enterprise products.',
          achievements: const [
            'Built reliable release workflows and clearer developer tooling.',
          ],
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
              'Developed a responsive portfolio showcasing projects and skills. Docs: https://docs.example.com/portfolio',
          url: 'https://johnsmith.dev/portfolio',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
          issueDate: DateTime(2025, 1, 1),
          credentialUrl: 'https://example.com/cert/aws-123',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
      ],
      templateId: 'forest_edge_classic',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the dedicated forest edge classic pdf template', () {
    final template = PdfTemplateFactory.getTemplate('forest_edge_classic');
    expect(template, isA<ForestEdgeClassicResumePdfTemplate>());
  });

  test('support keeps classic contacts, links, certifications, and languages',
      () {
    final resume = buildResume();

    final contacts = ForestEdgeClassicTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    expect(
      contacts.map((item) => item.label),
      equals([
        'john.smith@email.com',
        '(555) 123-4567',
        'linkedin.com/in/johnsmith',
        'johnsmith.dev',
        'github.com/johnsmith',
        'New York, NY',
      ]),
    );

    final projectEntries = ForestEdgeClassicTemplateSupport.projectEntries(
      resume.projects,
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    expect(projectEntries, hasLength(1));
    expect(
      projectEntries.single.detailLines,
      contains(
          'Developed a responsive portfolio showcasing projects and skills.'),
    );
    expect(
      projectEntries.single.links,
      equals([
        'johnsmith.dev/portfolio',
        'docs.example.com/portfolio',
      ]),
    );

    final certifications =
        ForestEdgeClassicTemplateSupport.certificationEntries(
      resume.certifications,
      maxItems: null,
      compactLinks: true,
    );
    expect(certifications, hasLength(1));
    expect(certifications.single.name, 'AWS Certified Developer');
    expect(certifications.single.detailLines, contains('Amazon'));
    expect(certifications.single.links, equals(['example.com/cert/aws-123']));

    final languageLines = ForestEdgeClassicTemplateSupport.languageLines(
      resume.languages,
      maxItems: null,
    );
    expect(languageLines, equals(['English Professional']));
  });

  testWidgets('preview exposes the dedicated forest edge classic sections',
      (tester) async {
    final resume = buildResume();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 340,
              child: ForestEdgeClassicResumeTemplatePreview(
                accentColor: Colors.green,
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('EXPERIENCE'), findsOneWidget);
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(find.text('EDUCATION'), findsOneWidget);
    expect(find.text('SKILLS'), findsOneWidget);
    expect(find.text('LANGUAGES'), findsOneWidget);
    expect(find.text('CERTIFICATIONS'), findsOneWidget);
    expect(find.text('DETAILS'), findsNothing);
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    expect(find.text('github.com/johnsmith'), findsOneWidget);
    expect(find.text('New York, NY'), findsOneWidget);
    expect(find.text('johnsmith.dev'), findsOneWidget);
    expect(find.text('johnsmith.dev/portfolio'), findsOneWidget);
    expect(find.textContaining('Portfolio Website'), findsOneWidget);
  });

  test('pdf generates with the dedicated forest edge classic template',
      () async {
    final resume = buildResume();
    final template = PdfTemplateFactory.getTemplate('forest_edge_classic');
    final pdf = await template.generate(resume, PdfColor.fromHex('#C58B43'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
