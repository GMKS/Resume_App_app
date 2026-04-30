import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/ats_friendly_modern_template_support.dart';
import 'package:resume_builder/features/templates/widgets/ats_friendly_modern_resume_template_preview.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 9);
    return ResumeModel(
      id: 'ats-friendly-modern-preview-test',
      title: 'ATS Friendly Modern Resume',
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
          'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products. Builds reliable user experiences with clear communication and strong execution.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TechCorp, Inc.',
          position: 'Senior Developer',
          startDate: DateTime(2021, 1, 1),
          endDate: DateTime(2024, 12, 1),
          achievements: const [
            'Led team of 5 to deliver cloud-based platform.',
            'Reduced load time by 40% through code optimization.',
          ],
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc. Computer Science',
          fieldOfStudy: 'Software Engineering',
          startDate: DateTime(2016, 9, 1),
          endDate: DateTime(2020, 5, 1),
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
        Skill(id: 'skill-3', name: 'Firebase'),
        Skill(id: 'skill-4', name: 'REST APIs'),
        Skill(id: 'skill-5', name: 'Git'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Portfolio Website',
          description:
              'Developed a responsive portfolio site showcasing projects and skills.\n'
              'Added a guided resume export walkthrough for first-time users. Docs: https://docs.example.com/portfolio',
          url: 'https://johnsmith.dev/portfolio',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
        ),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
        Language(id: 'lang-2', name: 'German', proficiency: 'Professional'),
        Language(id: 'lang-3', name: 'Japanese', proficiency: 'Professional'),
      ],
      templateId: 'ats_friendly_modern',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('ats friendly modern support preserves full project summaries and links',
      () {
    final resume = buildResume();

    final projects = AtsFriendlyModernTemplateSupport.projectEntries(
      resume.projects,
      maxItems: null,
      maxDetailLines: null,
    );
    expect(projects, hasLength(1));
    expect(
      projects.single.detailLines,
      containsAll([
        'Developed a responsive portfolio site showcasing projects and skills.',
        'Added a guided resume export walkthrough for first-time users.',
      ]),
    );
    expect(
      projects.single.links,
      equals(['docs.example.com/portfolio', 'johnsmith.dev/portfolio']),
    );

    expect(
      AtsFriendlyModernTemplateSupport.languageLabels(
        resume.languages,
        maxItems: null,
      ),
      equals([
        'English - Professional',
        'German - Professional',
        'Japanese - Professional',
      ]),
    );
  });

  testWidgets(
    'ats friendly modern preview matches the orange-tag original layout',
    (tester) async {
      const runtimeAccent = Color(0xFF16A34A);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 254,
                child: AtsFriendlyModernResumeTemplatePreview(
                  accentColor: runtimeAccent,
                  resume: buildResume(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('JOHN SMITH'), findsOneWidget);
      expect(find.text('Software Engineer'), findsOneWidget);
      expect(find.text('SUMMARY'), findsOneWidget);
      expect(find.text('SKILLS'), findsOneWidget);
      expect(find.text('EXPERIENCE'), findsOneWidget);
      expect(find.text('EDUCATION'), findsOneWidget);
      expect(find.text('PROJECTS'), findsOneWidget);
      expect(find.text('CERTIFICATIONS'), findsOneWidget);
      expect(find.text('LANGUAGES'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && (widget.data ?? '').contains('johnsmith.dev'),
        ),
        findsAtLeastNWidgets(1),
      );
      expect(find.text('Portfolio Website'), findsOneWidget);
      expect(
        find.textContaining('Added a guided resume export walkthrough'),
        findsOneWidget,
      );
      expect(find.text('docs.example.com/portfolio'), findsOneWidget);
      expect(find.text('johnsmith.dev/portfolio'), findsOneWidget);
      expect(find.text('AWS Certified Developer  •  Amazon'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data ?? '').contains('English - Professional'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.color ==
                  const Color(AtsFriendlyModernTemplateSupport.tagHex),
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.color ==
                  const Color(AtsFriendlyModernTemplateSupport.ruleHex),
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.textAlign == TextAlign.justify &&
              (widget.data ?? '').contains('high-quality solutions'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.textAlign == TextAlign.right &&
              (widget.data ?? '').contains('Jan 2021 - Dec 2024'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
