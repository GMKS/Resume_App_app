import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/corporate_navy_template_support.dart';
import 'package:resume_builder/features/templates/widgets/corporate_navy_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir =
        await Directory.systemTemp.createTemp('resume-app-corporate-navy');
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
    final now = DateTime(2026, 4, 14);
    return ResumeModel(
      id: 'corporate-navy',
      title: 'Corporate Navy Resume',
      personalInfo: PersonalInfo(
        fullName: 'John Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        address: 'New York, NY',
        linkedIn: 'https://linkedin.com/in/johnsmith',
        github: 'https://github.com/johnsmith',
        website: 'https://johnsmith.dev',
        jobTitle: 'Operations Strategy Manager',
      ),
      objective:
          'Operations leader with a record of building reporting systems that keep executive stakeholders aligned. Drives process clarity across delivery, finance, and recruiting. Turns complex workflow gaps into measurable execution improvements for distributed teams.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'MBA',
          fieldOfStudy: 'Business Administration',
          startDate: DateTime(2017, 1, 1),
          endDate: DateTime(2019, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Northwind Logistics',
          position: 'Strategy Manager',
          location: 'New York, NY',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Own cross-functional reporting, delivery governance, and executive stakeholder updates.',
          achievements: const [
            'Reduced reporting turnaround time by 32% through consolidated dashboards.',
            'Established shared review cadences across operations, recruiting, and finance.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Program Management'),
        Skill(id: 'skill-2', name: 'Process Design'),
        Skill(id: 'skill-3', name: 'Stakeholder Communication'),
        Skill(id: 'skill-4', name: 'Dashboard Reporting'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Delivery Insights Dashboard',
          description:
              'Unified operational KPIs for leaders across recruiting, finance, and delivery. Introduced portfolio drill-down views for weekly reviews. Docs: https://docs.example.com/delivery-insights Live: https://example.com/delivery-insights',
          url: 'https://example.com/delivery-insights',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'PMP Certification',
          issuer: 'Project Management Institute',
          issueDate: DateTime(2024, 1, 1),
          expiryDate: DateTime(2027, 1, 1),
          credentialId: 'PMP-123456',
          credentialUrl: 'https://example.com/cert/pmp-123456',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
        Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
        Language(id: 'lang-3', name: 'German', proficiency: 'Conversational'),
      ],
      templateId: 'corporate_navy',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the dedicated corporate navy pdf template', () {
    final template = PdfTemplateFactory.getTemplate('corporate_navy');
    expect(template, isA<CorporateNavyResumePdfTemplate>());
  });

  test(
      'support keeps all summary, project links, socials, certifications, and languages',
      () {
    final resume = buildResume();

    final contacts = CorporateNavyTemplateSupport.contactItems(
      resume.personalInfo,
      compactLinks: true,
      includeAddress: true,
    );
    expect(
      contacts.map((item) => item.label),
      equals([
        '(555) 123-4567',
        'john.smith@email.com',
        'New York, NY',
        'linkedin.com/in/johnsmith',
        'github.com/johnsmith',
        'johnsmith.dev',
      ]),
    );

    final summaryLines = CorporateNavyTemplateSupport.summaryLines(
      resume.objective,
      maxItems: null,
    );
    expect(summaryLines.length, greaterThanOrEqualTo(3));
    expect(
      summaryLines.any(
        (line) => line.contains('Turns complex workflow gaps'),
      ),
      isTrue,
    );

    final projectEntries = CorporateNavyTemplateSupport.projectEntries(
      resume.projects,
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );
    expect(projectEntries, hasLength(1));
    expect(projectEntries.single.detailLines.length, greaterThanOrEqualTo(2));
    expect(
      projectEntries.single.detailLines,
      contains('Introduced portfolio drill-down views for weekly reviews.'),
    );
    expect(
      projectEntries.single.links,
      equals([
        'example.com/delivery-insights',
        'docs.example.com/delivery-insights',
      ]),
    );

    final certifications = CorporateNavyTemplateSupport.certificationEntries(
      resume.certifications,
      maxItems: null,
      compactLinks: true,
    );
    expect(certifications, hasLength(1));
    final certificationDetails = certifications.single.detailLines.join(' | ');
    expect(certificationDetails, contains('Project Management Institute'));
    expect(certificationDetails, contains('Issued Jan 2024'));
    expect(certificationDetails, contains('Expires Jan 2027'));
    expect(certificationDetails, contains('Credential ID: PMP-123456'));
    expect(
      certifications.single.links,
      equals(['example.com/cert/pmp-123456']),
    );

    final languages = CorporateNavyTemplateSupport.languageLines(
      resume.languages,
      maxItems: null,
    );
    expect(languages, hasLength(3));
    expect(languages, contains('German  |  Conversational'));
  });

  testWidgets('preview exposes the dedicated corporate navy sections',
      (tester) async {
    final resume = buildResume();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 340,
              child: CorporateNavyTemplatePreview(
                accentColor: Colors.blue,
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('CONTACT'), findsOneWidget);
    expect(find.text('ABOUT ME'), findsOneWidget);
    expect(find.text('EXPERIENCE'), findsOneWidget);
    expect(find.text('CERTIFICATIONS'), findsOneWidget);
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(find.text('LANGUAGES'), findsOneWidget);
    expect(find.textContaining('linkedin.com/in/johnsmith'), findsOneWidget);
    expect(find.textContaining('github.com/johnsmith'), findsOneWidget);
    expect(find.textContaining('johnsmith.dev'), findsOneWidget);
    expect(find.textContaining('Delivery Insights Dashboard'), findsOneWidget);
  });

  test('pdf generates with the dedicated corporate navy template', () async {
    final resume = buildResume();
    final template = PdfTemplateFactory.getTemplate('corporate_navy');
    final pdf = await template.generate(resume, PdfColor.fromHex('#4A6A91'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
