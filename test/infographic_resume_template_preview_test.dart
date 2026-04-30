import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/widgets/infographic_resume_template_preview.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 16);
    return ResumeModel(
      id: 'infographic-preview-test',
      title: 'Infographic Resume',
      personalInfo: PersonalInfo(
        fullName: 'Jordan Smith',
        email: 'jordan@example.com',
        phone: '+1 555 123 4567',
        address: 'Seattle, WA',
        website: 'https://jordansmith.dev',
        jobTitle: 'Senior Flutter Developer',
      ),
      objective:
          'Builds high-fidelity resume workflows across preview and export systems.',
      experience: const [],
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc.',
          fieldOfStudy: 'Computer Science',
          startDate: DateTime(2014, 9, 1),
          endDate: DateTime(2018, 5, 1),
        ),
        Education(
          id: 'edu-2',
          institution: 'Design Systems Institute',
          degree: 'Certificate',
          fieldOfStudy: 'Product Strategy',
          startDate: DateTime(2019, 1, 1),
          endDate: DateTime(2019, 12, 1),
        ),
      ],
      skills: const [],
      projects: [
        Project(
          id: 'project-1',
          title: 'Workflow Atlas',
          description:
              'Mapped operations into guided review paths for delivery teams. '
              'Added PDF-safe continuation handling for credentials. Docs: https://docs.example.com/workflow-atlas',
          technologies: ['Flutter', 'PDF'],
          url: 'https://github.com/example/workflow-atlas',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-1',
          name: 'Flutter Certified Developer',
          issuer: 'Google',
        ),
        Certification(
          id: 'cert-2',
          name: 'Professional Scrum Master',
          issuer: 'Scrum.org',
        ),
        Certification(
          id: 'cert-3',
          name: 'Accessibility Foundations',
          issuer: 'Deque',
        ),
      ],
      languages: const [],
      templateId: 'infographic',
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('infographic preview keeps credentials together and shows all project links',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 254,
              child: InfographicResumeTemplatePreview(
                accentColor: const Color(0xFF5E8FA2),
                resume: buildResume(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('CREDENTIALS'), findsOneWidget);
    expect(find.text('Flutter Certified Developer  •  Google'), findsOneWidget);
    expect(find.text('Professional Scrum Master  •  Scrum.org'), findsOneWidget);
    expect(find.text('Accessibility Foundations  •  Deque'), findsOneWidget);
    expect(find.text('Workflow Atlas'), findsOneWidget);
    expect(
      find.textContaining('Added PDF-safe continuation handling for credentials'),
      findsOneWidget,
    );
    expect(find.text('docs.example.com/workflow-atlas'), findsOneWidget);
    expect(find.text('github.com/example/workflow-atlas'), findsOneWidget);
    expect(find.textContaining('State University'), findsOneWidget);
    expect(find.textContaining('Design Systems Institute'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}