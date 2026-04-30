import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/vertical_timeline_template_support.dart';
import 'package:resume_builder/features/templates/widgets/vertical_timeline_template_preview.dart';

void main() {
  ResumeModel buildResume({List<CustomSection> customSections = const []}) {
    final now = DateTime(2026, 4, 20);
    return ResumeModel(
      id: 'vertical-timeline-preview-test',
      title: 'Vertical Timeline Resume',
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
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TechCorp',
          position: 'Senior Developer',
          startDate: DateTime(2021, 1, 1),
          isCurrentlyWorking: true,
          description: 'Improved preview accuracy and export fidelity.',
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
      templateId: 'vertical_timeline',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('factory returns the dedicated vertical timeline pdf template', () {
    final template = PdfTemplateFactory.getTemplate('vertical_timeline');
    expect(template, isA<VerticalTimelineTemplate>());
  });

  test('keeps explicit social fields and all unique project links', () {
    final items = VerticalTimelineTemplateSupport.contactItems(
      PersonalInfo(
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://linkedin.com/in/seenai/',
        github: 'https://github.com/gmk',
        website: 'https://github.com/gmk/',
      ),
    );

    expect(
      items.map((item) => item.kind),
      equals([
        VerticalTimelineContactKind.email,
        VerticalTimelineContactKind.phone,
        VerticalTimelineContactKind.location,
        VerticalTimelineContactKind.linkedin,
        VerticalTimelineContactKind.github,
        VerticalTimelineContactKind.website,
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
        'github.com/gmk',
      ]),
    );

    final projectEntries = VerticalTimelineTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-links',
          title: 'Finance Reporting Hub',
          description: 'Delivered dashboard rollout.\n'
              'Docs: https://docs.example.com/guide.\n'
              'GitHub: https://example.com/reporting-hub',
          url: 'https://example.com/reporting-hub/',
        ),
      ],
      maxDetailLines: 4,
      compactLinks: true,
    );

    expect(projectEntries, hasLength(1));
    expect(projectEntries.single.title, 'Finance Reporting Hub');
    expect(
      projectEntries.single.detailLines,
      equals(['Delivered dashboard rollout.']),
    );
    expect(
      projectEntries.single.links,
      equals(['example.com/reporting-hub', 'docs.example.com/guide']),
    );
  });

  testWidgets('vertical timeline preview renders custom sections', (tester) async {
    final resume = buildResume(
      customSections: [
        CustomSection(
          id: 'user_custom_leadership',
          title: 'Leadership Highlights',
          items: [
            CustomSectionItem(
              id: 'leadership-1',
              title: 'Cross-Team Delivery',
              description: 'Led audit readiness and stakeholder reporting across release trains.',
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
              child: VerticalTimelineTemplatePreview(
                accentColor: const Color(0xFF0EA5E9),
                resume: resume,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('LEADERSHIP HIGHLIGHTS'), findsOneWidget);
    expect(find.text('Cross-Team Delivery'), findsOneWidget);
    expect(
      find.text('Led audit readiness and stakeholder reporting across release trains.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}