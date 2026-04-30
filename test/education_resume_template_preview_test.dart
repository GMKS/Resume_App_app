import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/widgets/education_resume_template_preview.dart';

void main() {
  ResumeModel buildResume() {
    final now = DateTime(2026, 4, 9);
    return ResumeModel(
      id: 'education-preview-test',
      title: 'Education Resume',
      personalInfo: PersonalInfo(
        fullName: 'GMK Seenai',
        email: 'seenai1977@gmail.com',
        phone: '+91 9886750145',
        address: 'Hyderabad, India',
        linkedIn: 'https://www..linkedin.com/seenai-com/',
        github: 'https://github.com/gmk',
        website: 'https://seenai.edu',
        jobTitle: 'Senior Manager',
      ),
      objective:
          'Over 14 years in software delivery, automation, and quality engineering across enterprise systems.',
      experience: [
        Experience(
          id: 'exp-1',
          company: 'Tata Consultancy Services Limited',
          position: 'Automation Lead',
          location: 'Hyderabad, India',
          startDate: DateTime(2019, 1, 1),
          endDate: DateTime(2025, 1, 1),
          description:
              'Led the automation team in developing and executing test automation scripts.',
        ),
      ],
      education: [
        Education(
          id: 'edu-1',
          institution: 'Holy Jesus and Mary PG College',
          degree: 'MCA',
          fieldOfStudy: 'Computer Applications',
          startDate: DateTime(2007, 1, 1),
          endDate: DateTime(2009, 1, 1),
          grade: '1st Grade',
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'React'),
        Skill(id: 'skill-2', name: 'JavaScript'),
      ],
      projects: [
        Project(
          id: 'project-1',
          title: 'Automation Dashboard',
          description: 'Created a reporting dashboard for Selenium execution.',
          url: 'https://example.com/automation-dashboard',
        ),
      ],
      certifications: [
        Certification(id: 'cert-1', name: 'Scrum Master'),
      ],
      languages: [
        Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
      ],
      templateId: 'education_resume',
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('education preview keeps fixed palette and compact links',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 254,
              child: EducationResumeTemplatePreview(
                accentColor: const Color(0xFF8B5CF6),
                templateColor: const Color(0xFF10B981),
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
          (widget.data ?? '').contains('linkedin.com/seenai-com') &&
          (widget.data ?? '').contains('github.com/gmk') &&
          (widget.data ?? '').contains('seenai.edu'),
    );
    expect(compactLinks, findsOneWidget);

    final titleText = tester.widget<Text>(find.text('Senior Manager'));
    expect(titleText.style?.color, const Color(0xFFD4B896));

    final educationHeader = tester.widget<Text>(find.text('EDUCATION').first);
    expect(educationHeader.style?.color, const Color(0xFF333C4D));
    expect(tester.takeException(), isNull);
  });
}
