import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/widgets/flexcolor_sidebar_template_preview.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 16);
    return ResumeModel(
      id: 'flexcolor-preview-test',
      title: 'FlexColor Sidebar Resume',
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
          location: 'Remote',
          startDate: DateTime(2022, 1, 1),
          endDate: DateTime(2025, 3, 1),
          description:
              'Led a team of 5 to deliver cloud-based platform features and improve release quality.',
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'State University',
          degree: 'B.Sc. Computer Science',
          fieldOfStudy: 'Software Engineering',
          startDate: DateTime(2015, 8, 1),
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
          title: 'Portfolio Website',
          description: 'Built a responsive portfolio and resume workflow.',
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
      templateId: 'blue_gray',
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('flexcolor preview no longer shows the FLEX badge',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 254,
              child: FlexColorSidebarTemplatePreview(
                accentColor: const Color(0xFF475569),
                resume: buildResume(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('FLEX'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}