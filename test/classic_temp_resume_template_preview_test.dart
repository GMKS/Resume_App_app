import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/widgets/classic_temp_resume_template_preview.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 9);
    return ResumeModel(
      id: 'classic-temp-preview-test',
      title: 'Classic Temp Resume',
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
          'Improves resume template fidelity and keeps preview output aligned with generated PDFs.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Bluewave Labs',
          position: 'Senior Flutter Developer',
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          endDate: DateTime(2026, 1, 1),
          description:
              'Aligned preview and PDF output for resume templates without changing unrelated layouts.',
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
              'Maintains preview and export parity for template layouts.',
          url: 'https://example.com/resume-builder',
        ),
      ],
      certifications: [
        Certification(id: 'cert-1', name: 'AWS Certified Developer'),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
      ],
      templateId: 'classic_temp',
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets(
      'classic temp preview keeps compact links and fixed blue headings',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 254,
              child: ClassicTempResumeTemplatePreview(
                accentColor: const Color(0xFFE11D48),
                resume: buildResume(),
              ),
            ),
          ),
        ),
      ),
    );

    final compactLinks = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          (widget.data ?? '').contains('linkedin.com/in/jordansmith') &&
          (widget.data ?? '').contains('github.com/jordansmith') &&
          (widget.data ?? '').contains('jordansmith.dev'),
    );
    expect(compactLinks, findsOneWidget);

    final profileHeader = tester.widget<Text>(find.text('PROFILE').first);
    expect(profileHeader.style?.color, const Color(0xFF6189BF));
    expect(find.text('\u2192'), findsOneWidget);

    expect(find.byType(Icon), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
