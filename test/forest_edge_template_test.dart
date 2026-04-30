import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/forest_edge_template_support.dart';
import 'package:resume_builder/features/templates/widgets/forest_edge_resume_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-forest-edge');
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
      id: 'forest-edge',
      title: 'Forest Edge Resume',
      personalInfo: PersonalInfo(
        fullName: 'Alex Chen',
        email: 'alex.chen@email.com',
        phone: '+1 (555) 123-4567',
        address: 'Seattle, WA',
        linkedIn: 'https://linkedin.com/in/alexchen',
        github: 'https://github.com/alexchen',
        website: 'https://alexchen.dev',
        jobTitle: 'Senior Engineering Manager',
      ),
      objective:
          'Builds scalable platform experiences for enterprise products and distributed teams. Translates ambiguous initiatives into dependable systems, tooling, and execution plans. Combines strong communication, debugging, and release discipline across delivery programs.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'University of Washington',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2020, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'BlueWave Labs',
          position: 'Senior Engineering Manager',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Led platform modernization and delivery execution across multiple product teams.',
          achievements: const [
            'Scaled developer tooling and release quality for distributed teams.',
            'Improved executive reporting and incident response communication.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Azure'),
        Skill(id: 'skill-3', name: 'Communication'),
        Skill(id: 'skill-4', name: 'Leadership'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Observability Platform',
          description:
              'Unified telemetry, release health, and service alerting workflows. Reduced time to detect production regressions across services. Docs: https://docs.example.com/observability Live: https://alexchen.dev/observability',
          url: 'https://alexchen.dev/observability',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Solutions Architect',
          issuer: 'Amazon Web Services',
          issueDate: DateTime(2024, 1, 1),
          expiryDate: DateTime(2027, 1, 1),
          credentialId: 'AWS-123456',
          credentialUrl: 'https://example.com/cert/aws-123456',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
        Language(id: 'lang-2', name: 'German', proficiency: 'Professional'),
      ],
      templateId: 'forest_edge',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the dedicated forest edge pdf template', () {
    final template = PdfTemplateFactory.getTemplate('forest_edge');
    expect(template, isA<ForestEdgeResumePdfTemplate>());
  });

  test(
      'support keeps website/github contact links plus project and certification links',
      () {
    final resume = buildResume();

    final contacts = ForestEdgeTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    expect(
      contacts.map((item) => item.label),
      equals([
        '+1 (555) 123-4567',
        'Seattle, WA',
        'alex.chen@email.com',
        'linkedin.com/in/alexchen',
        'github.com/alexchen',
        'alexchen.dev',
      ]),
    );

    final summaryLines = ForestEdgeTemplateSupport.summaryLines(
      resume.objective,
      maxItems: null,
    );
    expect(summaryLines.length, greaterThanOrEqualTo(3));

    final projectEntries = ForestEdgeTemplateSupport.projectEntries(
      resume.projects,
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    expect(projectEntries, hasLength(1));
    expect(
      projectEntries.single.detailLines,
      contains(
          'Reduced time to detect production regressions across services.'),
    );
    expect(
      projectEntries.single.links,
      equals([
        'alexchen.dev/observability',
        'docs.example.com/observability',
      ]),
    );

    final certifications = ForestEdgeTemplateSupport.certificationEntries(
      resume.certifications,
      maxItems: null,
      compactLinks: true,
    );
    expect(certifications, hasLength(1));
    final details = certifications.single.detailLines.join(' | ');
    expect(details, contains('Amazon Web Services'));
    expect(details, contains('Issued Jan 2024'));
    expect(details, contains('Expires Jan 2027'));
    expect(details, contains('Credential ID: AWS-123456'));
    expect(
        certifications.single.links, equals(['example.com/cert/aws-123456']));
  });

  testWidgets('preview shows chevron about bullets and Forest Edge links',
      (tester) async {
    final resume = buildResume();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 340,
              child: ForestEdgeResumeTemplatePreview(
                accentColor: Colors.green,
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('ABOUT ME'), findsOneWidget);
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(find.text('CERTIFICATIONS'), findsOneWidget);
    expect(find.textContaining('github.com/alexchen'), findsOneWidget);
    expect(find.text('alexchen.dev'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
  });

  test('pdf generates with the dedicated forest edge template', () async {
    final resume = buildResume();
    final template = PdfTemplateFactory.getTemplate('forest_edge');
    final pdf = await template.generate(resume, PdfColor.fromHex('#C9D3DE'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
