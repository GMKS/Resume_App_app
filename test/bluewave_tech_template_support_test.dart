import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/bluewave_tech_template_support.dart';
import 'package:resume_builder/features/templates/widgets/bluewave_tech_resume_template_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('resume-app-bluewave');
    Hive.init(hiveDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('factory returns the dedicated bluewave tech pdf template', () {
    final template = PdfTemplateFactory.getTemplate('bluewave_tech');
    expect(template, isA<BluewaveTechResumePdfTemplate>());
  });

  test('bluewave support keeps dynamic sidebar data and project links', () {
    final items = BluewaveTechTemplateSupport.contactItems(
      PersonalInfo(
        phone: '+91 9885623465',
        email: 'seenai007@gmail.com',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/seenai',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com',
      ),
      compactLinks: true,
      includeAddress: true,
    );

    expect(
      items.map((item) => item.label),
      equals([
        '+91 9885623465',
        'seenai007@gmail.com',
        'Hyderabad, India',
        'linkedin.com/seenai',
        'github.com/gmk',
        'seenaigmk.com',
      ]),
    );

    expect(
      BluewaveTechTemplateSupport.skillNames(
        [
          Skill(id: 'skill-1', name: 'Flutter'),
          Skill(id: 'skill-2', name: 'Azure'),
          Skill(id: 'skill-3', name: 'Kubernetes'),
          Skill(id: 'skill-4', name: 'Platform Engineering'),
          Skill(id: 'skill-5', name: 'Azure'),
        ],
        maxItems: null,
      ),
      equals([
        'Flutter',
        'Azure',
        'Kubernetes',
        'Platform Engineering',
      ]),
    );

    final experienceEntries = BluewaveTechTemplateSupport.experienceEntries(
      [
        Experience(
          id: 'exp-1',
          company: 'BlueWave Labs',
          position: 'Senior Manager',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Modernized release pipelines and platform observability for product teams.',
          achievements: const [
            'Led Kubernetes platform rollout across engineering squads.',
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
        'Led Kubernetes platform rollout across engineering squads.',
        'Modernized release pipelines and platform observability for product teams.',
      ]),
    );

    final projectEntries = BluewaveTechTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Observability Platform',
          description:
              'Unified telemetry, release health, and diagnostics workflows. Docs: https://docs.example.com/observability',
          url: 'https://observability.example.com/platform',
          technologies: const ['Flutter', 'Azure', 'OpenTelemetry'],
        ),
      ],
      maxItems: null,
      maxDetailLines: null,
      compactLinks: true,
    );

    expect(projectEntries, hasLength(1));
    expect(
      projectEntries.single.detailLines,
      equals(['Unified telemetry, release health, and diagnostics workflows.']),
    );
    expect(
      projectEntries.single.links,
      equals([
        'observability.example.com/platform',
        'docs.example.com/observability',
      ]),
    );

    final certificationEntries =
        BluewaveTechTemplateSupport.certificationEntries(
      [
        Certification(
          id: 'cert-1',
          name: 'AWS Solutions Architect',
          issuer: 'Amazon Web Services',
          issueDate: DateTime(2025, 2, 1),
          credentialId: 'AWS-123',
          credentialUrl: 'https://example.com/cert/aws-123',
        ),
      ],
      maxItems: null,
      compactLinks: true,
    );

    expect(certificationEntries, hasLength(1));
    expect(
      certificationEntries.single.detailLines.single,
      contains('Amazon Web Services'),
    );
    expect(
      certificationEntries.single.detailLines.single,
      contains('Feb 2025'),
    );
    expect(
      certificationEntries.single.detailLines.single,
      contains('ID AWS-123'),
    );
    expect(
      certificationEntries.single.links,
      equals(['example.com/cert/aws-123']),
    );

    expect(
      BluewaveTechTemplateSupport.languageLines(
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
      'bluewave preview shows social links, grouped sidebar data, and project links',
      (tester) async {
    final now = DateTime(2026, 4, 13);
    final resume = ResumeModel(
      id: 'bluewave-preview',
      title: 'BlueWave Tech Resume',
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
          'Builds scalable platform experiences. Leads engineering execution. Improves reliability and developer velocity.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'JNTU Hyderabad',
          degree: 'B.Tech',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2010, 1, 1),
          endDate: DateTime(2014, 1, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'BlueWave Labs',
          position: 'Senior Manager',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Scaled observability, platform workflows, and delivery tooling across teams.',
          achievements: const [
            'Led Kubernetes rollout and platform guardrails for engineering squads.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Azure'),
        Skill(id: 'skill-3', name: 'Kubernetes'),
        Skill(id: 'skill-4', name: 'Platform Engineering'),
        Skill(id: 'skill-5', name: 'Observability'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Observability Platform',
          description:
              'Unified telemetry, diagnostics, and release health dashboards. Docs: https://docs.example.com/observability',
          url: 'https://observability.example.com/platform',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Solutions Architect',
          issuer: 'Amazon Web Services',
          issueDate: DateTime(2025, 2, 1),
        ),
        Certification(
          id: 'cert-2',
          name: 'Certified Kubernetes Administrator',
          issuer: 'CNCF',
          issueDate: DateTime(2024, 9, 1),
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
        Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
      ],
      templateId: 'bluewave_tech',
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
              child: BluewaveTechResumeTemplatePreview(
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
    expect(find.text('SKILLS'), findsOneWidget);
    expect(find.textContaining('Kubernetes'), findsWidgets);
    expect(find.text('Observability Platform'), findsOneWidget);
    expect(find.text('observability.example.com/platform'), findsOneWidget);
    expect(find.textContaining('AWS Solutions Architect'), findsOneWidget);
    expect(find.textContaining('English  |  Native'), findsOneWidget);
    expect(find.textContaining('Spanish  |  Professional'), findsOneWidget);
    expect(find.text('▸'), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  test('bluewave pdf generates with dedicated multipage layout', () async {
    final now = DateTime(2026, 4, 13);
    final resume = ResumeModel(
      id: 'bluewave-pdf',
      title: 'BlueWave Tech Resume',
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
          'Builds scalable platform experiences. Leads engineering execution. Improves reliability and developer velocity.',
      education: [
        Education(
          id: 'edu-1',
          institution: 'JNTU Hyderabad',
          degree: 'B.Tech',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2010, 1, 1),
          endDate: DateTime(2014, 1, 1),
        ),
        Education(
          id: 'edu-2',
          institution: 'IIIT Hyderabad',
          degree: 'M.Tech',
          fieldOfStudy: 'Software Systems',
          startDate: DateTime(2015, 1, 1),
          endDate: DateTime(2017, 1, 1),
        ),
        Education(
          id: 'edu-3',
          institution: 'Stanford Online',
          degree: 'Certificate',
          fieldOfStudy: 'Distributed Systems',
          startDate: DateTime(2018, 1, 1),
          endDate: DateTime(2018, 12, 1),
        ),
      ],
      experience: [
        Experience(
          id: 'exp-1',
          company: 'BlueWave Labs',
          position: 'Senior Manager',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          isCurrentlyWorking: true,
          description:
              'Scaled observability, platform workflows, and delivery tooling across teams.',
          achievements: const [
            'Led Kubernetes rollout and platform guardrails for engineering squads.',
            'Improved release visibility and service diagnostics with a unified telemetry platform.',
          ],
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Azure'),
        Skill(id: 'skill-3', name: 'Kubernetes'),
        Skill(id: 'skill-4', name: 'Platform Engineering'),
        Skill(id: 'skill-5', name: 'Observability'),
        Skill(id: 'skill-6', name: 'SRE'),
        Skill(id: 'skill-7', name: 'CI/CD'),
        Skill(id: 'skill-8', name: 'Terraform'),
        Skill(id: 'skill-9', name: 'Azure DevOps'),
        Skill(id: 'skill-10', name: 'System Design'),
        Skill(id: 'skill-11', name: 'Cost Optimization'),
        Skill(id: 'skill-12', name: 'Incident Response'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Observability Platform',
          description:
              'Unified telemetry, diagnostics, and release health dashboards. Docs: https://docs.example.com/observability',
          url: 'https://observability.example.com/platform',
          technologies: const ['Flutter', 'Azure', 'OpenTelemetry'],
        ),
        Project(
          id: 'project-2',
          title: 'Developer Enablement Portal',
          description:
              'Centralized golden paths, delivery automation, and platform onboarding workflows.',
          url: 'https://platform.example.com/portal',
          technologies: const ['Flutter', 'Azure AD', 'Bicep'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Solutions Architect',
          issuer: 'Amazon Web Services',
          issueDate: DateTime(2025, 2, 1),
        ),
        Certification(
          id: 'cert-2',
          name: 'Certified Kubernetes Administrator',
          issuer: 'CNCF',
          issueDate: DateTime(2024, 9, 1),
        ),
        Certification(
          id: 'cert-3',
          name: 'Azure Solutions Architect Expert',
          issuer: 'Microsoft',
          issueDate: DateTime(2024, 7, 1),
        ),
        Certification(
          id: 'cert-4',
          name: 'HashiCorp Terraform Associate',
          issuer: 'HashiCorp',
          issueDate: DateTime(2023, 11, 1),
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
        Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
        Language(id: 'lang-3', name: 'French', proficiency: 'Conversational'),
        Language(id: 'lang-4', name: 'Hindi', proficiency: 'Professional'),
        Language(id: 'lang-5', name: 'Telugu', proficiency: 'Native'),
        Language(id: 'lang-6', name: 'German', proficiency: 'Basic'),
      ],
      templateId: 'bluewave_tech',
      createdAt: now,
      updatedAt: now,
    );

    final pdf = await BluewaveTechResumePdfTemplate().generate(
      resume,
      PdfColors.blue,
    );

    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);
  });
}
