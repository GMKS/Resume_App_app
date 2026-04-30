import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/widgets/one_page_resume_template_preview.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 9);
    return ResumeModel(
      id: 'one-page-preview-test',
      title: 'One Page Resume',
      personalInfo: PersonalInfo(
        fullName: 'Jordan Smith',
        email: 'jordan@example.com',
        phone: '+1 555 0100',
        address: 'Seattle, WA',
        linkedIn: 'https://linkedin.com/in/jordansmith',
        github: 'https://github.com/jordansmith',
        website: 'https://jordansmith.dev',
        jobTitle: 'Senior Software Engineer',
      ),
      objective:
          '→ Results-driven engineer who improves export fidelity and template isolation without breaking existing resume flows.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Northwind Labs',
          position: 'Senior Software Engineer',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          endDate: DateTime(2026, 1, 1),
          description:
              'Led template extraction work and aligned preview output with generated PDFs.',
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2016, 1, 1),
          endDate: DateTime(2020, 1, 1),
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
          description:
              'Maintains preview and export parity for resume templates.',
          url: 'https://example.com/resume-builder',
        ),
      ],
      certifications: [
        Certification(id: 'cert-1', name: 'AWS Certified Developer'),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
      ],
      templateId: 'one_page_resume',
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('one page preview shows compact top links', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 254,
              child: OnePageResumeTemplatePreview(
                accentColor: const Color(0xFF3B82F6),
                resume: buildResume(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('linkedin.com/in/jordansmith'), findsOneWidget);
    expect(find.text('github.com/jordansmith'), findsOneWidget);
    expect(find.text('jordansmith.dev'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data ?? '').contains('\u2192'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Results-driven engineer who improves export fidelity and template isolation without breaking existing resume flows.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
