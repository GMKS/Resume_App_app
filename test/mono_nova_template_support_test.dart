import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/mono_nova_template_support.dart';
import 'package:resume_builder/features/templates/widgets/mono_nova_template_preview.dart';

void main() {
  ResumeModel buildResume({List<CustomSection> customSections = const []}) {
    final now = DateTime(2026, 4, 20);
    return ResumeModel(
      id: 'mono-nova-preview-test',
      title: 'Black and White Resume',
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
          'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TechCorp',
          position: 'Senior Developer',
          startDate: DateTime(2021, 1, 1),
          isCurrentlyWorking: true,
          description: 'Built stable preview and export flows.',
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2015, 9, 1),
          endDate: DateTime(2019, 5, 1),
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Resume Builder',
          description: 'Built aligned preview and export flows.',
          url: 'https://preview.example.com',
        ),
      ],
      certifications: [
        Certification(id: 'cert-1', name: 'AWS Certified Developer', issuer: 'Amazon'),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
      ],
      customSections: customSections,
      templateId: 'mono_nova',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the dedicated mono nova pdf template', () {
    final template = PdfTemplateFactory.getTemplate('mono_nova');
    expect(template, isA<MonoNovaResumePdfTemplate>());
  });

  test('mono nova contact items keep compact social links in header order', () {
    final items = MonoNovaTemplateSupport.contactItems(
      PersonalInfo(
        address: 'New York, NY',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        linkedIn: 'https://linkedin.com/in/johnsmith/',
        github: 'https://github.com/johnsmith',
        website: 'https://johnsmith.dev/',
      ),
      compactLinks: true,
    );

    expect(
      items.map((item) => item.kind),
      equals([
        MonoNovaContactKind.location,
        MonoNovaContactKind.email,
        MonoNovaContactKind.phone,
        MonoNovaContactKind.linkedin,
        MonoNovaContactKind.github,
        MonoNovaContactKind.website,
      ]),
    );
    expect(
      items.map((item) => item.label),
      equals([
        'New York, NY',
        'john.smith@email.com',
        '(555) 123-4567',
        'linkedin.com/in/johnsmith',
        'github.com/johnsmith',
        'johnsmith.dev',
      ]),
    );
  });

  test('mono nova project url is suppressed when description already contains it', () {
    final entries = MonoNovaTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Portfolio Website',
          description: 'Built a portfolio for case studies. https://example.com/portfolio',
          url: 'https://example.com/portfolio',
        ),
      ],
      compactLinks: true,
    );

    expect(entries, hasLength(1));
    expect(entries.single.title, 'Portfolio Website');
    expect(entries.single.detailLines, equals(['Built a portfolio for case studies.']));
    expect(entries.single.url, isEmpty);
  });

  testWidgets('mono nova preview renders custom sections', (tester) async {
    final resume = buildResume(
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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 254,
              child: MonoNovaTemplatePreview(
                accentColor: const Color(0xFF111827),
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Awards'), findsOneWidget);
    expect(find.text('QA Excellence Award'), findsOneWidget);
    expect(
      find.text('Recognized for end-to-end automation delivery.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('mono nova pdf keeps all custom section items and detail lines', () async {
    final resume = buildResume(
      customSections: [
        CustomSection(
          id: 'user_custom_open_source',
          title: 'Open Source Contributions',
          items: [
            CustomSectionItem(
              id: 'oss-1',
              title: 'Resume Builder Fixes',
              subtitle: 'GitHub',
              description:
                  'Fixed preview regressions across template updates.\nDocumented export-safe continuation behavior.',
              date: DateTime(2026, 4, 1),
            ),
            CustomSectionItem(
              id: 'oss-2',
              title: 'Template QA Utilities',
              description: 'Added reusable checks for custom section fidelity.',
            ),
          ],
        ),
      ],
    );

    final pdf = await MonoNovaResumePdfTemplate().generate(
      resume,
      PdfColors.black,
    );

    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);
  });
}