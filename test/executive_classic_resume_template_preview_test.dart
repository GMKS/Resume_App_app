import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/widgets/executive_classic_resume_template_preview.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 16);
    return ResumeModel(
      id: 'executive-classic-preview-test',
      title: 'Executive Classic Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://www.linkedin.com/seenai',
        github: 'https://github.com/gmk',
        website: 'https://seenaigmk.com',
        jobTitle: 'Senior Manager',
      ),
      objective:
          'Over 13.6 years in software testing or development, with a solid understanding of testing, coding, and debugging procedures.\n'
          'Programming Skills: Proficient in programming languages such as Selenium using Core Java, Selenium, Cucumber, TestNG.',
      experience: const [],
      education: const [],
      skills: const [],
      projects: const [],
      certifications: const [],
      languages: const [],
      templateId: 'executive_classic',
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('executive classic preview shows checkmarks and full-size website',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 254,
              child: ExecutiveClassicResumeTemplatePreview(
                accentColor: const Color(0xFF6366F1),
                resume: buildResume(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsNWidgets(2));

    final websiteText = tester.widget<Text>(find.text('seenaigmk.com'));
    expect(websiteText.style?.fontSize, 2.6);
    expect(tester.takeException(), isNull);
  });
}