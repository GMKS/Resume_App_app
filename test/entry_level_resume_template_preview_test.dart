import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/entry_level_template_support.dart';
import 'package:resume_builder/features/templates/widgets/entry_level_resume_template_preview.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 9);
    return ResumeModel(
      id: 'entry-level-preview-test',
      title: 'Entry Level Resume',
      personalInfo: PersonalInfo(
        fullName: 'John Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        address: 'New York, NY',
        linkedIn: 'https://linkedin.com/in/johnsmith',
        github: 'https://github.com/johnsmith',
        website: 'https://portfolio.johnsmith.dev',
        jobTitle: 'Software Engineer',
      ),
      objective:
          'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.\nBuilds reliable user experiences with clear communication and strong execution.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'TechCorp',
          position: 'Senior Developer',
          location: 'New York, NY',
          startDate: DateTime(2021, 1, 1),
          endDate: DateTime(2024, 12, 1),
          achievements: const [
            'Led team of 5 to deliver cloud-based platform.',
            'Improved preview accuracy by aligning renderer output with production templates.',
          ],
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
          grade: 'GPA: 3.8/4.0',
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter'),
        Skill(id: 'skill-2', name: 'Dart'),
        Skill(id: 'skill-3', name: 'Firebase'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Portfolio Website',
          description:
              'Developed a responsive portfolio site showcasing projects and engineering skills.',
          url: 'https://portfolio.johnsmith.dev',
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
      ],
      templateId: 'entry_level',
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets(
    'entry level preview keeps the mint palette and renders full key content',
    (tester) async {
      const runtimeAccent = Color(0xFF7C3AED);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 254,
                child: EntryLevelResumeTemplatePreview(
                  accentColor: runtimeAccent,
                  resume: buildResume(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.color == const Color(EntryLevelTemplateSupport.pageHex),
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data == 'JOHN SMITH' &&
              widget.style?.color ==
                  const Color(EntryLevelTemplateSupport.accentHex),
        ),
        findsOneWidget,
      );
      expect(find.text('New York, NY'), findsOneWidget);
      expect(find.text('linkedin.com/in/johnsmith'), findsOneWidget);
      expect(find.text('github.com/johnsmith'), findsOneWidget);
      expect(find.text('portfolio.johnsmith.dev'), findsWidgets);
      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('EXPERIENCE'), findsOneWidget);
      expect(find.text('PROJECTS'), findsOneWidget);
      expect(find.text('Portfolio Website'), findsOneWidget);
      expect(
        find.text(
          'Developed a responsive portfolio site showcasing projects and engineering skills.',
        ),
        findsOneWidget,
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
      expect(tester.takeException(), isNull);
    },
  );
}