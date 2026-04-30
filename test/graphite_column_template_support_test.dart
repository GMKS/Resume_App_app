import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/graphite_column_template_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir =
        await Directory.systemTemp.createTemp('resume-app-graphite-column');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('factory returns the dedicated graphite column pdf template', () {
    final template = PdfTemplateFactory.getTemplate('graphite_column');
    expect(template, isA<GraphiteColumnResumePdfTemplate>());
  });

  test('graphite column keeps social links in contact order', () {
    final items = GraphiteColumnTemplateSupport.contactItems(
      PersonalInfo(
        phone: '+91 9885623465',
        email: 'seenai007@gmail.com',
        address: 'Hyderabad, India',
        linkedIn: 'https://linkedin.com/in/seenai/',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com/',
      ),
      compactLinks: true,
      includeAddress: true,
    );

    expect(
      items.map((item) => item.kind),
      equals([
        GraphiteContactKind.phone,
        GraphiteContactKind.email,
        GraphiteContactKind.address,
        GraphiteContactKind.linkedin,
        GraphiteContactKind.github,
        GraphiteContactKind.website,
      ]),
    );
    expect(
      items.map((item) => item.label),
      equals([
        '+91 9885623465',
        'seenai007@gmail.com',
        'Hyderabad, India',
        'linkedin.com/in/seenai',
        'github.com/gmk',
        'seenaigmk.com',
      ]),
    );
  });

  test('graphite column keeps project links, certifications, and languages',
      () {
    final projects = GraphiteColumnTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Finance Reporting Hub',
          description: 'Delivered dashboard rollout.\n'
              'Docs: https://docs.example.com/guide\n'
              'Demo: https://example.com/reporting-hub',
          url: 'https://example.com/reporting-hub/',
        ),
      ],
      maxDetailLines: 4,
      compactLinks: true,
    );

    expect(projects, hasLength(1));
    expect(
        projects.single.detailLines, equals(['Delivered dashboard rollout.']));
    expect(
      projects.single.links,
      equals(['example.com/reporting-hub', 'docs.example.com/guide']),
    );

    final certifications = GraphiteColumnTemplateSupport.certificationEntries(
      [
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
      compactLinks: true,
    );

    expect(certifications, hasLength(1));
    final details = certifications.single.detailLines.join(' | ');
    expect(details, contains('Amazon'));
    expect(details, contains('Issued Jan 2024'));
    expect(details, contains('Expires Jan 2027'));
    expect(details, contains('Credential ID: AWS-123456'));
    expect(
      certifications.single.links,
      equals(['example.com/cert/aws-123456']),
    );

    expect(
      GraphiteColumnTemplateSupport.languageLines(
        [
          Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
          Language(id: 'lang-2', name: 'German', proficiency: 'Basic'),
        ],
      ),
      equals(['English  |  Professional', 'German  |  Basic']),
    );
  });

  test('graphite column pdf generates with updated links and sections',
      () async {
    final now = DateTime(2026, 4, 11);
    final resume = ResumeModel(
      id: 'graphite-column-test',
      title: 'Graphite Column Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://linkedin.com/in/seenai',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com',
        jobTitle: 'Senior manager',
      ),
      objective:
          'Over 13.6 years in software testing and development with strong experience in testing, coding, debugging, and automation delivery across UI, service, and data workflows.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'Holy Jesus and Mary PG College',
          degree: 'MCA',
          startDate: DateTime(2006, 1, 1),
          endDate: DateTime(2009, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Led automation delivery across UI, API, and regression workflows while coordinating customer updates.',
          achievements: const [
            'Guided framework development and mentoring for engineering teams.',
          ],
        ),
      ],
      skills: List.generate(
        6,
        (index) => Skill(
          id: 'skill-$index',
          name: 'Skill ${index + 1}',
        ),
      ),
      projects: [
        Project(
          id: 'project-1',
          title: 'Finance Reporting Hub',
          description: 'Delivered dashboard rollout.\n'
              'Docs: https://docs.example.com/guide\n'
              'Demo: https://example.com/reporting-hub',
          url: 'https://example.com/reporting-hub/',
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
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'German', proficiency: 'Basic'),
      ],
      templateId: 'graphite_column',
      createdAt: now,
      updatedAt: now,
    );

    final document = await GraphiteColumnResumePdfTemplate().generate(
      resume,
      PdfColors.blue,
    );
    final bytes = await document.save();

    expect(bytes, isNotEmpty);
  });
}
