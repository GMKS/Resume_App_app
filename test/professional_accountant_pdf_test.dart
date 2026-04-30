import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/storage_service.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/professional_accountant_template_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp
        .createTemp('resume-app-professional-accountant');
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
    final now = DateTime(2026, 4, 9);
    return ResumeModel(
      id: 'professional-accountant-pdf-test',
      title: 'Professional Accountant Resume',
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
          'Over 13.6 years in software testing and delivery, with strong experience in planning, operational reporting, stakeholder communication, and measurable quality improvements across enterprise systems.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 2, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Managed automation delivery, reporting workflows, and cross-team execution status for enterprise programs.',
          achievements: const [
            'Guided team managers and contributed to framework development.',
            'Managed client interactions for status updates, metrics, and team-related communication.',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'JNTU University',
          degree: 'MCA',
          fieldOfStudy: 'Computer Applications',
          startDate: DateTime(2007, 8, 1),
          endDate: DateTime(2011, 5, 1),
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Audit'),
        Skill(id: 'skill-2', name: 'Forecasting'),
        Skill(id: 'skill-3', name: 'Project Management'),
        Skill(id: 'skill-4', name: 'SQL'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Finance Reporting Hub',
          description:
              'Created reporting dashboards and executive summaries for distributed delivery teams. https://example.com/reporting-hub',
          url: 'https://example.com/reporting-hub',
          technologies: const ['Flutter', 'PDF', 'Reporting'],
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'PMP Certification',
          issuer: 'PMI',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'French', proficiency: 'Professional'),
      ],
      templateId: 'professional_accountant',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the dedicated professional accountant pdf template',
      () {
    final template = PdfTemplateFactory.getTemplate('professional_accountant');
    expect(template, isA<ProfessionalAccountantResumePdfTemplate>());
  });

  test('template support compacts contact links in template order', () {
    final items = ProfessionalAccountantTemplateSupport.contactItems(
      PersonalInfo(
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://linkedin.com/in/seenai/',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com/',
      ),
    );

    expect(
      items.map((item) => item.kind),
      equals([
        ProfessionalAccountantContactKind.email,
        ProfessionalAccountantContactKind.phone,
        ProfessionalAccountantContactKind.location,
        ProfessionalAccountantContactKind.linkedin,
        ProfessionalAccountantContactKind.github,
        ProfessionalAccountantContactKind.website,
      ]),
    );
    expect(
      items.map((item) => item.label),
      equals([
        'seenai007@gmail.com',
        '+91 9885623465',
        'Hyderabad, India',
        'linkedin.com/in/seenai',
        'github.com/gmk',
        'seenaigmk.com',
      ]),
    );
  });

  test('template support extracts all unique project links from summary text',
      () {
    final content = ProfessionalAccountantTemplateSupport.projectContent(
      Project(
        id: 'project-links',
        title: 'Finance Reporting Hub',
        description: 'Delivered dashboard rollout.\n'
            'Docs: https://docs.example.com/guide.\n'
            'Demo: https://example.com/reporting-hub',
        url: 'https://example.com/reporting-hub/',
      ),
      maxSummaryLines: 4,
    );

    expect(content.details, equals(['Delivered dashboard rollout.']));
    expect(
      content.links,
      equals(['example.com/reporting-hub', 'docs.example.com/guide']),
    );
  });

  test('professional accountant pdf generates bytes with project links',
      () async {
    final resume = buildResume();

    await initPdfSettings(resume);
    final template = PdfTemplateFactory.getTemplate('professional_accountant');
    final pdf = await template.generate(resume, PdfColor.fromHex('#6366F1'));
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
  });
}
